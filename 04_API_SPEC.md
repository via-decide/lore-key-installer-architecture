# REST API Specification

## 1. Overview

The Lore Key platform exposes versioned REST APIs for identity activation, validation, bundle resolution, environment state, reputation publishing, and offline synchronization. All production endpoints are served over HTTPS and use JSON request and response bodies unless explicitly noted.

## 2. Common API Standards

### 2.1 Base URLs

```text
https://api.lorekey.example.com/v1/aporaksha   # conceptual identity namespace
https://api.lorekey.example.com/v1/bundles
https://api.lorekey.example.com/v1/reputation
https://api.lorekey.example.com/v1/environments
```

The canonical implementation should avoid spaces in service paths. The Aporaksha service path is represented as `/v1/aporaksha`.

### 2.2 Authentication

| Flow | Authentication |
|---|---|
| Initial activation | Public client token plus physical key proof and anti-replay nonce. |
| Validation | Bearer access token or signed device assertion. |
| Bundle resolution | Bearer access token and active entitlement lease. |
| Reputation publishing | Bearer access token plus signed local event envelope. |
| Sync | Bearer access token plus device binding assertion. |
| Administration | Admin bearer token with role-based authorization and step-up authentication. |

### 2.3 Common Headers

| Header | Required | Description |
|---|---|---|
| `X-Request-Id` | Yes | Client-generated request ID for tracing. |
| `X-Idempotency-Key` | Required for writes | Stable key used to deduplicate retries. |
| `Authorization` | Except public activation bootstrap | Bearer token or signed assertion. |
| `X-Client-Version` | Yes | Installer or application version. |
| `X-Device-Id` | Required after activation | Stable device binding identifier. |

### 2.4 Common Error Schema

```json
{
  "error": {
    "code": "KEY_REVOKED",
    "message": "The Lore Key is revoked and cannot be activated.",
    "details": {
      "key_status": "REVOKED"
    },
    "request_id": "req_01HX...",
    "retry_after_seconds": null
  }
}
```

### 2.5 Status Codes

| Code | Meaning |
|---:|---|
| 200 | Successful read or idempotent write replay. |
| 201 | Resource created. |
| 202 | Accepted for asynchronous processing. |
| 400 | Invalid request schema or semantic validation failure. |
| 401 | Missing or invalid authentication. |
| 403 | Authenticated but not authorized or entitlement denied. |
| 404 | Resource not found. |
| 409 | Conflict with current state. |
| 422 | Valid schema but business rule failure. |
| 429 | Rate limit exceeded. |
| 500 | Internal service failure. |
| 503 | Temporarily unavailable. |

### 2.6 Rate Limits

| Endpoint Class | Default Limit |
|---|---:|
| Activation | 10 attempts/hour per key fingerprint and 50/hour per IP. |
| Validation | 120 requests/hour per device. |
| Bundle resolution | 60 requests/hour per user. |
| Reputation publishing | 100 events/day per user for MVP. |
| Sync | 1,000 events/hour per device. |
| Admin writes | Policy-controlled; all actions audited. |

## 3. Aporaksha Identity Service

### 3.1 `POST /v1/aporaksha/activate`

Activates or claims a physical Lore Key and binds it to a user identity and device.

#### Request Schema

```json
{
  "key_proof": {
    "type": "QR_SERIAL|NFC_UID|SECURE_CHALLENGE",
    "serial": "LK-2026-000001",
    "public_code": "Q7K9-2M4P-88XZ",
    "nfc_uid_hash": "sha256:...",
    "challenge_response": "base64url...",
    "nonce": "base64url..."
  },
  "user": {
    "email": "learner@example.com",
    "display_name": "Asha Learner",
    "region": "US",
    "consents": ["terms_v1", "privacy_v1"]
  },
  "device": {
    "device_id": "dev_01HX...",
    "platform": "windows",
    "public_key": "base64url-ed25519-public-key"
  }
}
```

#### Response Schema

```json
{
  "activation_id": "act_01HX...",
  "user_id": "usr_01HX...",
  "lore_key_id": "key_01HX...",
  "key_status": "CLAIMED",
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "lease": {
    "status": "ACTIVE",
    "expires_at": "2026-07-02T00:00:00Z"
  },
  "next_actions": ["VALIDATE", "RESOLVE_BUNDLE"]
}
```

#### Status Codes

- `201` activation created.
- `200` idempotent activation replay.
- `400` malformed key proof.
- `403` key suspended or revoked.
- `409` key already claimed by another identity.
- `429` rate limit exceeded.

#### Error Handling

Activation errors must distinguish invalid proof, revoked status, duplicate claim, and rate limiting. The service must never reveal enough information to enumerate valid serials.

#### Example

```bash
curl -X POST https://api.lorekey.example.com/v1/aporaksha/activate \
  -H 'X-Request-Id: req_demo' \
  -H 'X-Idempotency-Key: idem_activation_001' \
  -H 'Content-Type: application/json' \
  -d '{"key_proof":{"type":"QR_SERIAL","serial":"LK-2026-000001","public_code":"Q7K9-2M4P-88XZ","nonce":"abc"},"user":{"email":"learner@example.com","display_name":"Asha","region":"US","consents":["terms_v1","privacy_v1"]},"device":{"device_id":"dev_001","platform":"linux","public_key":"pub"}}'
```

### 3.2 `POST /v1/aporaksha/validate`

Validates a key, user, device binding, and offline lease.

#### Request Schema

```json
{
  "lore_key_id": "key_01HX...",
  "user_id": "usr_01HX...",
  "device_id": "dev_01HX...",
  "assertion": {
    "nonce": "base64url...",
    "signature": "base64url...",
    "signed_at": "2026-06-02T10:00:00Z"
  },
  "requested_capabilities": ["INSTALL", "OFFLINE_LEASE", "REPUTATION_PUBLISH"]
}
```

#### Response Schema

```json
{
  "valid": true,
  "key_status": "ACTIVE",
  "user_status": "ENGAGED",
  "device_binding": "ACTIVE",
  "capabilities": ["INSTALL", "OFFLINE_LEASE"],
  "lease": {
    "lease_id": "lease_01HX...",
    "issued_at": "2026-06-02T10:00:00Z",
    "expires_at": "2026-07-02T10:00:00Z",
    "max_offline_seconds": 2592000
  }
}
```

#### Status Codes

`200`, `401`, `403`, `409`, `429`.

#### Authentication

Bearer token plus signed device assertion.

### 3.3 `GET /v1/aporaksha/bundle`

Compatibility endpoint that redirects identity clients to the Bundle Resolver. New clients should use `GET /v1/bundles/resolve`.

#### Query Parameters

| Parameter | Required | Description |
|---|---|---|
| `lore_key_id` | Yes | Key identifier. |
| `application` | Yes | `StudyOS`, `PrepOS`, `SkillHex`, `ViaDecide`, or `Zayvora`. |
| `platform` | Yes | Target platform. |

#### Response Schema

```json
{
  "resolver_url": "https://api.lorekey.example.com/v1/bundles/resolve?...",
  "expires_at": "2026-06-02T10:15:00Z"
}
```

### 3.4 `GET /v1/aporaksha/state`

Returns consolidated identity, key, activation, entitlement, and environment state.

#### Response Schema

```json
{
  "user_id": "usr_01HX...",
  "lore_key_id": "key_01HX...",
  "key_status": "ACTIVE",
  "activation_state": "ACTIVE",
  "devices": [{"device_id":"dev_01HX...","status":"ACTIVE"}],
  "environments": [{"environment":"StudyOS","state":"ACTIVE","bundle_version":"1.2.0"}],
  "sync": {"last_synced_at":"2026-06-02T10:00:00Z","pending_events":0}
}
```

### 3.5 `POST /v1/aporaksha/reputation`

Compatibility endpoint that forwards to Reputation Service.

### 3.6 `POST /v1/aporaksha/sync`

Compatibility endpoint that forwards to sync ingestion under Environment Service.

## 4. Bundle Resolver Service

### 4.1 `GET /v1/bundles/resolve`

Resolves an entitled bundle and returns a signed manifest reference.

#### Query Parameters

| Parameter | Required | Description |
|---|---|---|
| `application` | Yes | Application name. |
| `platform` | Yes | `windows`, `macos`, `linux`, `android`. |
| `channel` | No | `stable`, `beta`, `cohort`. |
| `current_version` | No | Installed version. |

#### Response Schema

```json
{
  "bundle": {
    "bundle_id": "bun_StudyOS_foundations",
    "application": "StudyOS",
    "version": "1.2.0",
    "manifest_url": "https://cdn.lorekey.example.com/manifests/studyos/1.2.0.json",
    "manifest_sha256": "...",
    "signature": "base64url...",
    "publisher": "Lore Key Learning"
  },
  "policy": {
    "offline_lease_days": 30,
    "requires_device_binding": true,
    "allow_local_mirror": true
  }
}
```

#### Status Codes

`200`, `304`, `401`, `403`, `404`, `409`, `429`.

### 4.2 `GET /v1/bundles/{bundle_id}/versions/{version}/manifest`

Returns the manifest document.

#### Response Schema

```json
{
  "schema_version": "bundle-manifest-v1",
  "bundle_id": "bun_StudyOS_foundations",
  "version": "1.2.0",
  "artifacts": [
    {
      "name": "studyos-runtime.tar.zst",
      "url": "https://cdn.lorekey.example.com/artifacts/studyos-runtime.tar.zst",
      "sha256": "...",
      "size_bytes": 104857600
    }
  ],
  "install": {
    "entrypoint": "installer/install.json",
    "requires_admin": false
  },
  "signature": {
    "algorithm": "ed25519",
    "key_id": "pub_2026_01",
    "value": "base64url..."
  }
}
```

## 5. Reputation Service

### 5.1 `POST /v1/reputation/events`

Publishes a reputation event derived from validated local progress, achievements, or evidence references.

#### Request Schema

```json
{
  "event_id": "rep_01HX...",
  "user_id": "usr_01HX...",
  "source_application": "SkillHex",
  "achievement_id": "ach_01HX...",
  "claim_type": "PROJECT_COMPLETED",
  "claim": {
    "title": "Line-following robot build",
    "skill_nodes": ["embedded.c", "robotics.sensors"],
    "completed_at": "2026-06-02T09:00:00Z"
  },
  "evidence": [
    {"type":"LOCAL_EVENT_HASH","ref":"sha256:..."},
    {"type":"BUNDLE_VERSION","ref":"bun_skillhex_robotics@1.0.0"}
  ],
  "local_signature": "base64url...",
  "consent": {
    "publish_publicly": false,
    "share_with": ["mentor_01"]
  }
}
```

#### Response Schema

```json
{
  "event_id": "rep_01HX...",
  "status": "ACCEPTED",
  "verification": {
    "level": "DEVICE_SIGNED_AND_SERVER_VERIFIED",
    "verified_at": "2026-06-02T10:10:00Z"
  },
  "public_url": null
}
```

#### Status Codes

`201`, `200`, `400`, `401`, `403`, `409`, `422`, `429`.

## 6. Environment Service

### 6.1 `GET /v1/environments/state`

Returns environment state by user and device.

#### Response Schema

```json
{
  "device_id": "dev_01HX...",
  "environments": [
    {
      "environment": "StudyOS",
      "state": "ACTIVE",
      "installed_at": "2026-06-02T08:00:00Z",
      "bundle_id": "bun_StudyOS_foundations",
      "bundle_version": "1.2.0",
      "lease_expires_at": "2026-07-02T08:00:00Z"
    }
  ]
}
```

### 6.2 `POST /v1/environments/sync`

Ingests offline event batches from local applications.

#### Request Schema

```json
{
  "sync_batch_id": "sync_01HX...",
  "device_id": "dev_01HX...",
  "base_state_vector": {
    "StudyOS": 42,
    "PrepOS": 9
  },
  "events": [
    {
      "event_id": "evt_01HX...",
      "event_type": "LESSON_COMPLETED",
      "application": "StudyOS",
      "occurred_at": "2026-06-02T07:59:00Z",
      "payload": {"lesson_id":"lesson_001"},
      "hash": "sha256:...",
      "signature": "base64url..."
    }
  ]
}
```

#### Response Schema

```json
{
  "sync_batch_id": "sync_01HX...",
  "status": "ACCEPTED",
  "accepted_events": ["evt_01HX..."],
  "rejected_events": [],
  "new_state_vector": {
    "StudyOS": 43,
    "PrepOS": 9
  },
  "conflicts": []
}
```

#### Error Handling

- Invalid signatures reject individual events where possible.
- Reordered batches are accepted if event dependencies are satisfied.
- Conflicts return `409` only when client intervention is required; otherwise the response includes conflict metadata.

## 7. OpenAPI-Style Component Schemas

```yaml
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
    DeviceAssertion:
      type: apiKey
      in: header
      name: X-Device-Assertion
  schemas:
    LoreKeyStatus:
      type: string
      enum: [UNCLAIMED, CLAIMED, ACTIVE, SUSPENDED, REVOKED]
    EnvironmentState:
      type: string
      enum: [LOCKED, AUTHENTICATING, INSTALLING, ACTIVE, OFFLINE, EXPIRED]
    UserStatus:
      type: string
      enum: [NEW, ACTIVATED, ENGAGED, CONTRIBUTOR, ALUMNI]
    Error:
      type: object
      required: [error]
      properties:
        error:
          type: object
          required: [code, message, request_id]
```

## 8. API Bottlenecks and Controls

| Bottleneck | Control |
|---|---|
| Cohort activation spike | Queue-backed activation writes, pre-registered batches, autoscaling. |
| Bundle manifest hot paths | CDN caching and signed immutable manifests. |
| Sync burst after offline periods | Batch ingestion, idempotency, backpressure. |
| Reputation fraud review | Risk scoring, asynchronous verification, narrow MVP claim types. |
