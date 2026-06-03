-- 05 — Lore Key MVP PostgreSQL Schema
-- Target: PostgreSQL 15+
-- Runtime contract: server state in PostgreSQL; client state in IndexedDB for MVP.
-- Eventing: canonical events table plus transactional outbox.

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

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email citext UNIQUE,
  display_name text NOT NULL,
  region text NOT NULL DEFAULT 'US',
  status user_status NOT NULL DEFAULT 'NEW',
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

CREATE TABLE bundles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bundle_code text NOT NULL UNIQUE,
  title text NOT NULL,
  primary_application text NOT NULL,
  publisher_id text NOT NULL,
  status bundle_status NOT NULL DEFAULT 'DRAFT',
  eligibility_rules jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);
CREATE INDEX idx_bundles_application ON bundles(primary_application) WHERE deleted_at IS NULL;
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
