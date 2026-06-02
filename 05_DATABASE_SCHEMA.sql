-- Lore Key Installer Architecture PostgreSQL Schema
-- Target PostgreSQL version: 15+
-- Strategy: UUID primary keys, explicit lifecycle states, soft deletes, immutable audit logs,
-- idempotent event ingestion, and versioned bundles.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

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
  lifecycle_status user_lifecycle_status NOT NULL DEFAULT 'NEW',
  consent_versions jsonb NOT NULL DEFAULT '[]'::jsonb,
  recovery_public_key text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
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
  resource_id uuid,
  request_id text NOT NULL,
  correlation_id text,
  ip_hash text,
  user_agent text,
  severity text NOT NULL DEFAULT 'INFO',
  reason text,
  before_state jsonb,
  after_state jsonb,
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
