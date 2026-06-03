# 04 — API Specification

## 1. API Standards

Base path: `/v1`. All requests and responses are JSON over HTTPS. All write requests require `X-Request-Id` and `X-Idempotency-Key`. All authenticated requests use `Authorization: Bearer <token>`. Device-scoped requests include `X-Device-Id` and `X-Device-Assertion`.

## 2. Common Schemas

### Error

```json
{
  "error": {
    "code": "KEY_REVOKED",
    "message": "The Lore Key is revoked.",
    "details": {},
    "request_id": "req_01",
    "retry_after_seconds": null
  }
}
```

### PhysicalSignal

```json
{
  "signal_type": "QR|NFC|SERIAL|SECURE_CHALLENGE",
  "serial": "LK-2026-000001",
  "public_code": "Q7K9-2M4P-88XZ",
  "nfc_uid_hash": "sha256:...",
  "challenge_response": null,
  "nonce": "base64url"
}
```

### OfflineLease

```json
{
  "lease_id": "lease_01",
  "user_id": "usr_01",
  "lore_key_id": "key_01",
  "device_id": "dev_01",
  "capabilities": ["RUN_ENVIRONMENT", "RECORD_PROGRESS", "QUEUE_SYNC"],
  "issued_at": "2026-06-03T00:00:00Z",
  "expires_at": "2026-07-03T00:00:00Z",
  "signature": "base64url-ed25519"
}
```

## 3. Aporaksha Identity Service

### POST `/v1/aporaksha/activate`

Creates ownership activation, device binding, tokens, and initial offline lease.

Request:

```json
{
  "physical_signal": {"signal_type":"QR","serial":"LK-2026-000001","public_code":"Q7K9-2M4P-88XZ","nonce":"n1"},
  "user": {"email":"learner@example.com","display_name":"Asha","region":"US","consents":["terms-2026-06","privacy-2026-06"]},
  "device": {"device_id":"dev_01","platform":"capacitor-ios","public_key":"base64url-ed25519"}
}
```

Response `201`:

```json
{
  "activation_id": "act_01",
  "user_id": "usr_01",
  "lore_key_id": "key_01",
  "ownership_status": "ACTIVE",
  "device_binding_status": "ACTIVE",
  "access_token": "jwt",
  "refresh_token": "jwt",
  "offline_lease": {"lease_id":"lease_01","user_id":"usr_01","lore_key_id":"key_01","device_id":"dev_01","capabilities":["RUN_ENVIRONMENT","RECORD_PROGRESS","QUEUE_SYNC"],"issued_at":"2026-06-03T00:00:00Z","expires_at":"2026-07-03T00:00:00Z","signature":"sig"}
}
```

Status codes: `201`, `200` idempotent replay, `400`, `401`, `403`, `409`, `422`, `429`.

### POST `/v1/aporaksha/validate`

Validates identity, ownership, device binding, and requested capabilities.

Request:

```json
{
  "user_id": "usr_01",
  "lore_key_id": "key_01",
  "device_id": "dev_01",
  "requested_capabilities": ["INSTALL_BUNDLE", "RUN_ENVIRONMENT"],
  "assertion": {"nonce":"n2","signed_at":"2026-06-03T00:00:00Z","signature":"sig"}
}
```

Response `200`:

```json
{
  "valid": true,
  "user_status": "ACTIVATED",
  "ownership_status": "ACTIVE",
  "key_status": "ACTIVE",
  "device_status": "ACTIVE",
  "granted_capabilities": ["INSTALL_BUNDLE", "RUN_ENVIRONMENT"],
  "offline_lease": {"lease_id":"lease_02","user_id":"usr_01","lore_key_id":"key_01","device_id":"dev_01","capabilities":["INSTALL_BUNDLE","RUN_ENVIRONMENT"],"issued_at":"2026-06-03T00:00:00Z","expires_at":"2026-07-03T00:00:00Z","signature":"sig"}
}
```

### POST `/v1/aporaksha/leases/renew`

Renews a lease after online validation. Returns `403` if key, user, or device cannot receive capabilities.

### POST `/v1/aporaksha/reputation/assertion`

Issues a short-lived Aporaksha identity assertion for Reputation Service signing.

Request:

```json
{"user_id":"usr_01","device_id":"dev_01","reputation_event_id":"rep_01"}
```

Response:

```json
{"assertion_id":"assert_01","expires_at":"2026-06-03T00:15:00Z","signature":"sig"}
```

## 4. Bundle Resolver Service

### GET `/v1/bundles/resolve`

Query: `application`, `platform`, `channel`, `current_version`.

Response:

```json
{
  "bundle_id": "bundle_01",
  "bundle_code": "studyos-foundations",
  "version": "1.0.0",
  "manifest_url": "https://cdn.lorekey.example/bundles/studyos-foundations/1.0.0.viabundle.json",
  "manifest_sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "signature": "sig",
  "immutable": true,
  "offline_policy": {"max_offline_days": 30}
}
```

Authentication: bearer token plus device assertion. Status: `200`, `304`, `401`, `403`, `404`, `409`, `429`.

### GET `/v1/bundles/{bundle_code}/{version}`

Returns the `.viabundle.json` manifest or a signed redirect to immutable object storage.

## 5. Environment and Sync Service

### POST `/v1/environments/installs`

Records verified install telemetry.

Request:

```json
{
  "install_id": "inst_01",
  "bundle_code": "studyos-foundations",
  "bundle_version": "1.0.0",
  "environment": "StudyOS",
  "device_id": "dev_01",
  "state": "ACTIVE",
  "manifest_sha256": "sha256"
}
```

### POST `/v1/sync/batches`

Submits local event queue for reconciliation.

Request:

```json
{
  "sync_batch_id": "sync_01",
  "device_id": "dev_01",
  "base_state_vector": {"StudyOS": 7},
  "events": [
    {
      "event_id": "evt_01",
      "event_type": "PROGRESS_RECORDED",
      "application": "StudyOS",
      "occurred_at": "2026-06-03T00:00:00Z",
      "lease_id": "lease_01",
      "payload": {"subject_ref":"lesson-1","status":"completed","progress_value":1},
      "event_hash": "sha256:...",
      "signature": "sig"
    }
  ]
}
```

Response:

```json
{
  "sync_batch_id": "sync_01",
  "status": "ACCEPTED_WITH_RESULTS",
  "accepted_events": ["evt_01"],
  "rejected_events": [],
  "conflicts": [],
  "new_state_vector": {"StudyOS": 8}
}
```

## 6. Reputation Service

### POST `/v1/reputation/events`

Publishes reputation from verified events only.

Request:

```json
{
  "reputation_event_id": "rep_01",
  "source_achievement_id": "ach_01",
  "claim_type": "BADGE_EARNED",
  "claim": {"badge_code":"studyos.foundations.complete","title":"StudyOS Foundations"},
  "evidence_event_ids": ["evt_01", "evt_02"],
  "aporaksha_assertion_id": "assert_01",
  "consent": {"scope":"public", "consent_version":"reputation-2026-06"}
}
```

Response:

```json
{
  "reputation_event_id": "rep_01",
  "status": "ACCEPTED",
  "verification_level": "SERVER_VERIFIED_EVENTS",
  "server_signature": "sig",
  "public_url": "https://verify.lorekey.example/rep_01"
}
```

## 7. Zayvora Projection API

### POST `/v1/zayvora/projections`

Creates a permissioned memory projection from local or verified context.

Request:

```json
{
  "projection_id": "memproj_01",
  "user_id": "usr_01",
  "scope": ["learning_summary", "skill_context"],
  "source_event_ids": ["evt_01"],
  "permission": {"granted": true, "version": "zayvora-consent-2026-06"}
}
```

Response:

```json
{"projection_id":"memproj_01","status":"CREATED","expires_at":null}
```

## 8. Rate Limits

| Class | Limit |
|---|---:|
| Activation | 10 attempts/hour per signal hash and 50/hour per IP. |
| Validation | 120/hour per device. |
| Bundle resolve | 60/hour per device. |
| Sync | 1,000 events/hour per device. |
| Reputation publish | 100/day per user. |
| Projection | 100/day per user. |

## 9. Error Codes

`INVALID_PHYSICAL_SIGNAL`, `AUTH_REQUIRED`, `KEY_ALREADY_OWNED`, `KEY_SUSPENDED`, `KEY_REVOKED`, `DEVICE_NOT_BOUND`, `DEVICE_LIMIT_EXCEEDED`, `LEASE_EXPIRED`, `BUNDLE_NOT_ENTITLED`, `BUNDLE_REVOKED`, `INVALID_SIGNATURE`, `EVENT_SCHEMA_INVALID`, `EVENT_CONFLICT`, `EVIDENCE_NOT_VERIFIED`, `CONSENT_REQUIRED`, `RATE_LIMITED`.
