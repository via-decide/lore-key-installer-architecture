-- 05 — Lore Key MVP PostgreSQL Schema
-- Target: PostgreSQL 15+
-- Runtime contract: server state in PostgreSQL; client state in IndexedDB for MVP.
-- Eventing: canonical events table plus transactional outbox.
-- Lore Key Installer Architecture PostgreSQL Schema
-- Target PostgreSQL version: 15+
-- Strategy: UUID primary keys, explicit lifecycle states, soft deletes, immutable audit logs,
-- idempotent event ingestion, and versioned bundles.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE TYPE user_status AS ENUM ('NEW', 'ACTIVATED', 'ENGAGED', 'CONTRIBUTOR', 'ALUMNI', 'SUSPENDED');
CREATE TYPE lore_key_status AS ENUM ('REGISTERED', 'UNCLAIMED', 'OWNED', 'ACTIVE', 'SUSPENDED', 'REVOKED');
CREATE TYPE ownership_status AS ENUM ('PENDING', 'ACTIVE', 'TRANSFER_PENDING', 'SUSPENDED', 'REVOKED');
CREATE TYPE device_status AS ENUM ('ACTIVE', 'SUSPENDED', 'REMOVED', 'LOST');
CREATE TYPE lease_status AS ENUM ('ACTIVE', 'EXPIRED', 'REVOKED', 'SUPERSEDED');
CREATE TYPE bundle_status AS ENUM ('DRAFT', 'SIGNED', 'PUBLISHED', 'DEPRECATED', 'REVOKED');
CREATE TYPE install_status AS ENUM ('PLANNED', 'DOWNLOADING', 'VERIFYING', 'INSTALLING', 'CONFIGURING', 'ACTIVE', 'FAILED', 'ROLLED_BACK');
CREATE TYPE environment_status AS ENUM ('LOCKED', 'AUTHENTICATING', 'INSTALLING', 'ACTIVE', 'OFFLINE', 'EXPIRED', 'RECOVERY');
CREATE TYPE event_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'CONFLICTED', 'SUPERSEDED');
CREATE TYPE outbox_status AS ENUM ('PENDING', 'PUBLISHED', 'FAILED');
CREATE TYPE reputation_status AS ENUM ('DRAFT', 'PENDING_VERIFICATION', 'ACCEPTED', 'REJECTED', 'REVOKED', 'SUPERSEDED');
CREATE TYPE projection_status AS ENUM ('CREATED', 'REVOKED', 'EXPIRED');
-- -----------------------------------------------------------------------------
-- Enumerated lifecycle types
-- -----------------------------------------------------------------------------

CREATE TYPE lore_key_status AS ENUM ('UNCLAIMED', 'CLAIMED', 'ACTIVE', 'SUSPENDED', 'REVOKED');
CREATE TYPE user_lifecycle_status AS ENUM ('NEW', 'ACTIVATED', 'ENGAGED', 'CONTRIBUTOR', 'ALUMNI');
CREATE TYPE environment_lifecycle_status AS ENUM ('LOCKED', 'AUTHENTICATING', 'INSTALLING', 'ACTIVE', 'OFFLINE', 'EXPIRED');
CREATE TYPE sync_event_status AS ENUM ('PENDING', 'PROCESSING', 'ACCEPTED', 'REJECTED', 'CONFLICTED');
CREATE TYPE reputation_event_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'REVOKED');

-- -----------------------------------------------------------------------------
-- Utility trigger for updated_at
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- users
-- -----------------------------------------------------------------------------

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email citext UNIQUE,
  display_name text NOT NULL,
  region text NOT NULL DEFAULT 'US',
  status user_status NOT NULL DEFAULT 'NEW',
  lifecycle_status user_lifecycle_status NOT NULL DEFAULT 'NEW',
  consent_versions jsonb NOT NULL DEFAULT '[]'::jsonb,
  recovery_public_key text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT users_identity_check CHECK (email IS NOT NULL OR recovery_public_key IS NOT NULL)
);
CREATE INDEX idx_users_status ON users(status) WHERE deleted_at IS NULL;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

  deletion_reason text,
  CONSTRAINT users_email_or_recovery_key CHECK (email IS NOT NULL OR recovery_public_key IS NOT NULL)
);

CREATE INDEX idx_users_lifecycle_status ON users(lifecycle_status) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_region ON users(region) WHERE deleted_at IS NULL;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- lore_keys
-- -----------------------------------------------------------------------------

CREATE TABLE lore_keys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  serial text NOT NULL UNIQUE,
  public_code_hash text NOT NULL,
  nfc_uid_hash text,
  secure_element_public_key text,
  hardware_tier text NOT NULL DEFAULT 'QR_NFC',
  manufacturing_batch text NOT NULL,
  status lore_key_status NOT NULL DEFAULT 'REGISTERED',
  status_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT lore_keys_secure_element_check CHECK (hardware_tier <> 'SECURE_ELEMENT' OR secure_element_public_key IS NOT NULL)
);
CREATE INDEX idx_lore_keys_status ON lore_keys(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_lore_keys_batch ON lore_keys(manufacturing_batch);
CREATE TRIGGER trg_lore_keys_updated_at BEFORE UPDATE ON lore_keys FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE ownerships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  lore_key_id uuid NOT NULL REFERENCES lore_keys(id),
  status ownership_status NOT NULL DEFAULT 'PENDING',
  activated_at timestamptz,
  suspended_at timestamptz,
  revoked_at timestamptz,
  reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE UNIQUE INDEX uq_active_ownership_per_key ON ownerships(lore_key_id) WHERE status IN ('ACTIVE', 'SUSPENDED') AND deleted_at IS NULL;
CREATE INDEX idx_ownerships_user ON ownerships(user_id) WHERE deleted_at IS NULL;
CREATE TRIGGER trg_ownerships_updated_at BEFORE UPDATE ON ownerships FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  ownership_id uuid NOT NULL REFERENCES ownerships(id),
  device_id text NOT NULL,
  platform text NOT NULL,
  public_key text NOT NULL,
  status device_status NOT NULL DEFAULT 'ACTIVE',
  trust_tier text NOT NULL DEFAULT 'STANDARD',
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (user_id, device_id)
);
CREATE INDEX idx_devices_ownership ON devices(ownership_id) WHERE deleted_at IS NULL;
CREATE TRIGGER trg_devices_updated_at BEFORE UPDATE ON devices FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  manufacturing_batch text NOT NULL,
  status lore_key_status NOT NULL DEFAULT 'UNCLAIMED',
  claimed_by_user_id uuid REFERENCES users(id),
  claimed_at timestamptz,
  activated_at timestamptz,
  suspended_at timestamptz,
  revoked_at timestamptz,
  status_reason text,
  hardware_tier text NOT NULL DEFAULT 'QR_NFC',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT lore_keys_claim_consistency CHECK (
    (status = 'UNCLAIMED' AND claimed_by_user_id IS NULL) OR
    (status <> 'UNCLAIMED')
  )
);

CREATE INDEX idx_lore_keys_status ON lore_keys(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_lore_keys_claimed_by_user_id ON lore_keys(claimed_by_user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_lore_keys_batch ON lore_keys(manufacturing_batch);
CREATE TRIGGER trg_lore_keys_updated_at BEFORE UPDATE ON lore_keys FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- activations
-- -----------------------------------------------------------------------------

CREATE TABLE activations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  lore_key_id uuid NOT NULL REFERENCES lore_keys(id),
  ownership_id uuid NOT NULL REFERENCES ownerships(id),
  device_id uuid NOT NULL REFERENCES devices(id),
  signal_type text NOT NULL,
  signal_fingerprint text NOT NULL,
  nonce_hash text NOT NULL,
  ip_hash text,
  user_agent text,
  idempotency_key text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX idx_activations_key ON activations(lore_key_id);
CREATE INDEX idx_activations_user ON activations(user_id);

CREATE TABLE offline_leases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  ownership_id uuid NOT NULL REFERENCES ownerships(id),
  device_id uuid NOT NULL REFERENCES devices(id),
  status lease_status NOT NULL DEFAULT 'ACTIVE',
  capabilities jsonb NOT NULL,
  issued_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  signature text NOT NULL,
  superseded_by uuid REFERENCES offline_leases(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_offline_leases_device_status ON offline_leases(device_id, status, expires_at);
  device_id text NOT NULL,
  device_platform text NOT NULL,
  device_public_key text NOT NULL,
  activation_method text NOT NULL,
  activation_nonce_hash text NOT NULL,
  ip_hash text,
  user_agent text,
  lease_expires_at timestamptz NOT NULL,
  idempotency_key text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (idempotency_key),
  UNIQUE (lore_key_id, device_id)
);

CREATE INDEX idx_activations_user_id ON activations(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_activations_lore_key_id ON activations(lore_key_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_activations_device_id ON activations(device_id) WHERE deleted_at IS NULL;
CREATE TRIGGER trg_activations_updated_at BEFORE UPDATE ON activations FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- bundles and bundle_versions
-- -----------------------------------------------------------------------------

CREATE TABLE bundles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bundle_code text NOT NULL UNIQUE,
  title text NOT NULL,
  primary_application text NOT NULL,
  publisher_id text NOT NULL,
  status bundle_status NOT NULL DEFAULT 'DRAFT',
  eligibility_rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  application text NOT NULL,
  title text NOT NULL,
  description text,
  publisher text NOT NULL,
  default_channel text NOT NULL DEFAULT 'stable',
  eligibility_rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX idx_bundles_application ON bundles(primary_application) WHERE deleted_at IS NULL;

CREATE INDEX idx_bundles_application ON bundles(application) WHERE deleted_at IS NULL;
CREATE TRIGGER trg_bundles_updated_at BEFORE UPDATE ON bundles FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE bundle_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bundle_id uuid NOT NULL REFERENCES bundles(id),
  semantic_version text NOT NULL,
  channel text NOT NULL DEFAULT 'stable',
  manifest_url text NOT NULL,
  manifest_sha256 text NOT NULL,
  signature text NOT NULL,
  signing_key_id text NOT NULL,
  status bundle_status NOT NULL DEFAULT 'SIGNED',
  artifact_count integer NOT NULL DEFAULT 0,
  total_size_bytes bigint NOT NULL DEFAULT 0,
  artifact_count integer NOT NULL DEFAULT 0,
  total_size_bytes bigint NOT NULL DEFAULT 0,
  min_installer_version text,
  is_deprecated boolean NOT NULL DEFAULT false,
  is_revoked boolean NOT NULL DEFAULT false,
  release_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (bundle_id, semantic_version, channel)
);
CREATE INDEX idx_bundle_versions_status ON bundle_versions(status) WHERE deleted_at IS NULL;
CREATE TRIGGER trg_bundle_versions_updated_at BEFORE UPDATE ON bundle_versions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE environments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  device_id uuid NOT NULL REFERENCES devices(id),
  name text NOT NULL,
  status environment_status NOT NULL DEFAULT 'LOCKED',
  capabilities jsonb NOT NULL DEFAULT '[]'::jsonb,
  local_state_vector jsonb NOT NULL DEFAULT '{}'::jsonb,
  last_opened_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (user_id, device_id, name)
);
CREATE TRIGGER trg_environments_updated_at BEFORE UPDATE ON environments FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE installs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  environment_id uuid NOT NULL REFERENCES environments(id),
  bundle_version_id uuid NOT NULL REFERENCES bundle_versions(id),
  device_id uuid NOT NULL REFERENCES devices(id),
  status install_status NOT NULL DEFAULT 'PLANNED',
  manifest_sha256 text NOT NULL,
  install_path_hash text,
  checkpoint jsonb NOT NULL DEFAULT '{}'::jsonb,
  installed_at timestamptz,
  failure_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX idx_installs_environment ON installs(environment_id) WHERE deleted_at IS NULL;
CREATE TRIGGER trg_installs_updated_at BEFORE UPDATE ON installs FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id text NOT NULL,
  user_id uuid NOT NULL REFERENCES users(id),
  device_id uuid REFERENCES devices(id),
  lease_id uuid REFERENCES offline_leases(id),
  application text NOT NULL,
  event_type text NOT NULL,
  aggregate_type text NOT NULL,
  aggregate_id text NOT NULL,
  payload jsonb NOT NULL,
  event_hash text NOT NULL,
  signature text,
  occurred_at timestamptz NOT NULL,
  status event_status NOT NULL DEFAULT 'PENDING',
  rejection_reason text,
  conflict_details jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, application, event_id)
);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_aggregate ON events(aggregate_type, aggregate_id);
CREATE INDEX idx_events_user_application ON events(user_id, application, occurred_at);

CREATE TABLE progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  source_event_db_id uuid NOT NULL REFERENCES events(id),
  application text NOT NULL,
  subject_ref text NOT NULL,
  progress_type text NOT NULL,
  status text NOT NULL,
  progress_value numeric(8,4),
  materialized_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (user_id, application, subject_ref, progress_type)
);
CREATE INDEX idx_progress_user_application ON progress(user_id, application) WHERE deleted_at IS NULL;

CREATE INDEX idx_bundle_versions_bundle_id ON bundle_versions(bundle_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_bundle_versions_channel ON bundle_versions(channel) WHERE deleted_at IS NULL;
CREATE INDEX idx_bundle_versions_revoked ON bundle_versions(is_revoked) WHERE deleted_at IS NULL;
CREATE TRIGGER trg_bundle_versions_updated_at BEFORE UPDATE ON bundle_versions FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- environment_installs
-- -----------------------------------------------------------------------------

CREATE TABLE environment_installs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  lore_key_id uuid NOT NULL REFERENCES lore_keys(id),
  activation_id uuid REFERENCES activations(id),
  bundle_version_id uuid NOT NULL REFERENCES bundle_versions(id),
  device_id text NOT NULL,
  environment_name text NOT NULL,
  lifecycle_state environment_lifecycle_status NOT NULL DEFAULT 'LOCKED',
  install_path_hash text,
  installed_at timestamptz,
  last_opened_at timestamptz,
  lease_expires_at timestamptz,
  local_state_vector jsonb NOT NULL DEFAULT '{}'::jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (user_id, device_id, environment_name)
);

CREATE INDEX idx_environment_installs_user ON environment_installs(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_environment_installs_state ON environment_installs(lifecycle_state) WHERE deleted_at IS NULL;
CREATE INDEX idx_environment_installs_bundle_version ON environment_installs(bundle_version_id);
CREATE TRIGGER trg_environment_installs_updated_at BEFORE UPDATE ON environment_installs FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- user_progress
-- -----------------------------------------------------------------------------

CREATE TABLE user_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  environment_install_id uuid REFERENCES environment_installs(id),
  application text NOT NULL,
  progress_type text NOT NULL,
  subject_ref text NOT NULL,
  status text NOT NULL,
  progress_value numeric(8,4),
  event_id text NOT NULL,
  event_hash text NOT NULL,
  occurred_at timestamptz NOT NULL,
  source_device_id text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (user_id, application, event_id)
);

CREATE INDEX idx_user_progress_user_app ON user_progress(user_id, application) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_progress_subject ON user_progress(subject_ref) WHERE deleted_at IS NULL;
CREATE INDEX idx_user_progress_occurred_at ON user_progress(occurred_at);
CREATE TRIGGER trg_user_progress_updated_at BEFORE UPDATE ON user_progress FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- achievements
-- -----------------------------------------------------------------------------

CREATE TABLE achievements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  application text NOT NULL,
  achievement_code text NOT NULL,
  title text NOT NULL,
  evidence_event_ids jsonb NOT NULL,
  evidence_hash text NOT NULL,
  status text NOT NULL DEFAULT 'AWARDED',
  awarded_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  revocation_reason text,
  deleted_at timestamptz,
  UNIQUE (user_id, application, achievement_code)
);
CREATE INDEX idx_achievements_user ON achievements(user_id) WHERE deleted_at IS NULL;

CREATE TABLE reputation_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reputation_event_id text NOT NULL UNIQUE,
  user_id uuid NOT NULL REFERENCES users(id),
  achievement_id uuid REFERENCES achievements(id),
  status reputation_status NOT NULL DEFAULT 'DRAFT',
  claim_type text NOT NULL,
  claim jsonb NOT NULL,
  evidence_event_ids jsonb NOT NULL,
  evidence_hash text NOT NULL,
  aporaksha_assertion_id text,
  consent_version text NOT NULL,
  server_signature text,
  public_url text,
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX idx_reputation_events_user_status ON reputation_events(user_id, status) WHERE deleted_at IS NULL;
CREATE TRIGGER trg_reputation_events_updated_at BEFORE UPDATE ON reputation_events FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE zayvora_projections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  projection_id text NOT NULL UNIQUE,
  user_id uuid NOT NULL REFERENCES users(id),
  status projection_status NOT NULL DEFAULT 'CREATED',
  scope jsonb NOT NULL,
  source_event_ids jsonb NOT NULL,
  permission_version text NOT NULL,
  projection_payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  deleted_at timestamptz
);
CREATE INDEX idx_zayvora_projections_user ON zayvora_projections(user_id) WHERE deleted_at IS NULL;

CREATE TABLE outbox_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  aggregate_type text NOT NULL,
  aggregate_id text NOT NULL,
  payload jsonb NOT NULL,
  status outbox_status NOT NULL DEFAULT 'PENDING',
  attempts integer NOT NULL DEFAULT 0,
  next_attempt_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_outbox_pending ON outbox_events(status, next_attempt_at) WHERE status IN ('PENDING', 'FAILED');
  description text,
  evidence_hash text NOT NULL,
  evidence_refs jsonb NOT NULL DEFAULT '[]'::jsonb,
  awarded_at timestamptz NOT NULL,
  revoked_at timestamptz,
  revocation_reason text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (user_id, application, achievement_code)
);

CREATE INDEX idx_achievements_user ON achievements(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_achievements_awarded_at ON achievements(awarded_at);
CREATE TRIGGER trg_achievements_updated_at BEFORE UPDATE ON achievements FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- reputation_events
-- -----------------------------------------------------------------------------

CREATE TABLE reputation_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  achievement_id uuid REFERENCES achievements(id),
  event_type text NOT NULL,
  status reputation_event_status NOT NULL DEFAULT 'PENDING',
  claim jsonb NOT NULL,
  evidence_refs jsonb NOT NULL DEFAULT '[]'::jsonb,
  local_signature text NOT NULL,
  server_signature text,
  published_url text,
  verification_level text,
  rejection_reason text,
  idempotency_key text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (idempotency_key)
);

CREATE INDEX idx_reputation_events_user ON reputation_events(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_reputation_events_status ON reputation_events(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_reputation_events_achievement ON reputation_events(achievement_id);
CREATE TRIGGER trg_reputation_events_updated_at BEFORE UPDATE ON reputation_events FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- sync_queue
-- -----------------------------------------------------------------------------

CREATE TABLE sync_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id),
  device_id text NOT NULL,
  sync_batch_id text,
  event_id text NOT NULL,
  event_type text NOT NULL,
  application text NOT NULL,
  payload jsonb NOT NULL,
  event_hash text NOT NULL,
  signature text NOT NULL,
  status sync_event_status NOT NULL DEFAULT 'PENDING',
  attempts integer NOT NULL DEFAULT 0,
  next_attempt_at timestamptz,
  occurred_at timestamptz NOT NULL,
  processed_at timestamptz,
  rejection_reason text,
  conflict_details jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (user_id, application, event_id)
);

CREATE INDEX idx_sync_queue_status_next_attempt ON sync_queue(status, next_attempt_at) WHERE deleted_at IS NULL;
CREATE INDEX idx_sync_queue_user_device ON sync_queue(user_id, device_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_sync_queue_batch ON sync_queue(sync_batch_id) WHERE sync_batch_id IS NOT NULL;
CREATE TRIGGER trg_sync_queue_updated_at BEFORE UPDATE ON sync_queue FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- audit_logs
-- -----------------------------------------------------------------------------

CREATE TABLE audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id uuid REFERENCES users(id),
  actor_type text NOT NULL,
  action text NOT NULL,
  resource_type text NOT NULL,
  resource_id text,
  request_id text NOT NULL,
  correlation_id text,
  ip_hash text,
  resource_id uuid,
  request_id text NOT NULL,
  correlation_id text,
  ip_hash text,
  user_agent text,
  severity text NOT NULL DEFAULT 'INFO',
  reason text,
  before_state jsonb,
  after_state jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Implementation notes:
-- 1. All API write transactions that change business state must insert an audit_logs row.
-- 2. State-changing domain events must be inserted into events and/or outbox_events in the same transaction as the state change.
-- 3. Client IndexedDB stores pending local events; PostgreSQL events is the server reconciliation ledger.
-- 4. Soft deletion uses deleted_at; audit_logs and outbox_events are append-only operational records.
-- 5. Reputation events must reference accepted evidence events before server_signature is set.
-- 6. Zayvora projections require permission_version and explicit source_event_ids.
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_user_id, actor_type);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_request_id ON audit_logs(request_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);

-- -----------------------------------------------------------------------------
-- Soft delete strategy
-- -----------------------------------------------------------------------------
-- Business tables include deleted_at and optional deletion reason fields. Application
-- queries must filter deleted_at IS NULL for active views. Audit logs are immutable
-- and are not soft-deleted; privacy-sensitive references should be pseudonymized
-- during account deletion workflows rather than physically removed.

-- -----------------------------------------------------------------------------
-- Audit strategy
-- -----------------------------------------------------------------------------
-- Every write API must create an audit_logs row with actor, action, resource,
-- request_id, and state delta where safe. Security-relevant failures such as hash
-- mismatch, replay detection, revoked key validation, and reputation rejection must
-- also be recorded. Audit entries are append-only; corrections are represented as
-- subsequent entries.

-- -----------------------------------------------------------------------------
-- Migration notes
-- -----------------------------------------------------------------------------
-- 1. Create enum types before dependent tables.
-- 2. Install pgcrypto for gen_random_uuid and citext for case-insensitive email;
--    if citext is unavailable, replace users.email with lower-cased text plus a
--    functional unique index.
-- 3. Add tables in dependency order: users, lore_keys, activations, bundles,
--    bundle_versions, environment_installs, user_progress, achievements,
--    reputation_events, sync_queue, audit_logs.
-- 4. Use additive migrations for JSONB metadata fields before promoting fields to
--    first-class columns.
-- 5. Never rewrite audit logs during migrations except for approved privacy
--    pseudonymization operations.

-- -----------------------------------------------------------------------------
-- ER relationship explanation
-- -----------------------------------------------------------------------------
-- users 1:N activations
-- users 1:N environment_installs
-- users 1:N user_progress
-- users 1:N achievements
-- users 1:N reputation_events
-- lore_keys 1:N activations
-- lore_keys 1:N environment_installs
-- bundles 1:N bundle_versions
-- bundle_versions 1:N environment_installs
-- environment_installs 1:N user_progress
-- achievements 1:N reputation_events
-- users 1:N sync_queue
-- audit_logs optionally references users and any resource by resource_type/resource_id.
