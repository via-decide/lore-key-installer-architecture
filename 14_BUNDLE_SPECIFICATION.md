# 14 — `.viabundle.json` Specification

## 1. Format

A `.viabundle.json` is a signed immutable JSON manifest. It describes what the installer downloads, verifies, installs, and configures. It is not stored on the physical Lore Key.

Requirements:

- UTF-8 JSON.
- Deterministic canonical JSON for signatures.
- Ed25519 signatures.
- SHA-256 hashes.
- Semantic versioning.
- Published versions are immutable.

## 2. Manifest Shape

```json
{
  "schemaVersion": "viabundle.v1",
  "bundle": {"code":"studyos-foundations","version":"1.0.0","channel":"stable","publisherId":"pub_lorekey"},
  "metadata": {"title":"StudyOS Foundations","domain":"science","language":"en","estimatedHours":20},
  "licensing": {"requiresLoreKey":true,"allowedHardwareTiers":["QR_NFC","SECURE_ELEMENT"],"offlineLeaseDays":30,"maxDevices":2},
  "apps": [{"name":"StudyOS","versionRange":">=1.0.0 <2.0.0","capabilities":["lesson_progress"]}],
  "modules": [],
  "dependencies": [],
  "artifacts": [],
  "install": {"strategy":"runtime-module","entrypoint":"install.json","requiresAdmin":false},
  "offlinePolicy": {"cacheable":true,"leaseRequired":true,"maxOfflineDays":30},
  "reputationPolicy": {"eligibleAchievements":[],"requiresVerifiedEvents":true},
  "signature": {"algorithm":"ed25519","keyId":"pub_lorekey_2026_01","signedAt":"2026-06-03T00:00:00Z","value":"base64url"}
}
```

## 3. JSON Schema
# `.viabundle` Bundle Specification

## 1. Purpose

A `.viabundle` is a signed JSON manifest that describes an installable Lore Key environment bundle. It does not need to contain the artifacts inline. It defines metadata, licensing, applications, modules, dependencies, versioning, signatures, hashes, and policy so the installer can resolve and verify exactly what must be installed.

## 2. Format

| Property | Requirement |
|---|---|
| File extension | `.viabundle.json` for JSON manifests. |
| Encoding | UTF-8 JSON. |
| Canonicalization | RFC 8785 JSON canonicalization or equivalent deterministic canonical JSON for signatures. |
| Signature | Ed25519 for MVP. |
| Hash | SHA-256 for manifests and artifacts. |
| Versioning | Semantic Versioning 2.0.0. |
| Immutability | A published bundle version is immutable. |

## 3. Manifest Structure

```text
.viabundle
├── schemaVersion
├── bundle
├── metadata
├── licensing
├── apps
├── modules
├── dependencies
├── artifacts
├── install
├── compatibility
├── offlinePolicy
├── reputationPolicy
└── signature
```

## 4. Field Definitions

### 4.1 `bundle`

| Field | Type | Required | Description |
|---|---|---:|---|
| `code` | string | Yes | Stable bundle code. |
| `version` | semver | Yes | Immutable version. |
| `channel` | string | Yes | `stable`, `beta`, `cohort`, `security`. |
| `publisher` | string | Yes | Publisher display name. |
| `publisherId` | string | Yes | Trusted publisher identifier. |
| `createdAt` | datetime | Yes | Manifest creation time. |

### 4.2 `metadata`

Includes title, description, learning domain, target personas, language, region, tags, estimated hours, and support contact.

### 4.3 `licensing`

Defines entitlement and local use policy.

| Field | Description |
|---|---|
| `licenseId` | License policy identifier. |
| `licenseType` | `personal`, `cohort`, `institution`, `open`, `trial`. |
| `requiresLoreKey` | Whether validation is required for install. |
| `allowedHardwareTiers` | Accepted Lore Key hardware tiers. |
| `maxDevices` | Device binding limit. |
| `offlineLeaseDays` | Maximum offline lease. |
| `redistribution` | `forbidden`, `local-mirror-only`, `open`. |

### 4.4 `apps`

List of applications installed or configured by the bundle.

```json
[
  {
    "name": "StudyOS",
    "versionRange": ">=1.0.0 <2.0.0",
    "entrypoint": "studyos://bundle/chemistry-foundations",
    "capabilities": ["lesson_progress", "notes", "achievements"]
  }
]
```

### 4.5 `modules`

Modules are logical learning units.

| Field | Description |
|---|---|
| `moduleId` | Stable module ID. |
| `title` | Display title. |
| `type` | `lesson`, `lab`, `exam`, `project`, `simulation`, `memory-pack`. |
| `application` | Owning app. |
| `artifactRefs` | Required artifact IDs. |
| `prerequisites` | Module IDs that must be completed first. |
| `outcomes` | Competencies or skill nodes. |

### 4.6 `dependencies`

Dependencies can reference runtime packages, application versions, other bundles, operating system prerequisites, or hardware.

### 4.7 `signatures`

The signature block covers the canonical manifest excluding the signature value itself.

```json
{
  "algorithm": "ed25519",
  "keyId": "pub_lorekey_2026_01",
  "signedAt": "2026-06-02T00:00:00Z",
  "value": "base64url..."
}
```

## 5. JSON Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://schemas.lorekey.example/viabundle.v1.json",
  "type": "object",
  "required": ["schemaVersion", "bundle", "metadata", "licensing", "apps", "modules", "dependencies", "artifacts", "install", "offlinePolicy", "reputationPolicy", "signature"],
  "$id": "https://schemas.lorekey.example.com/viabundle.schema.json",
  "title": "Lore Key ViaBundle Manifest",
  "type": "object",
  "required": ["schemaVersion", "bundle", "metadata", "licensing", "apps", "modules", "artifacts", "install", "compatibility", "offlinePolicy", "signature"],
  "properties": {
    "schemaVersion": {"const": "viabundle.v1"},
    "bundle": {
      "type": "object",
      "required": ["code", "version", "channel", "publisherId"],
      "properties": {
        "code": {"type":"string", "pattern":"^[a-z0-9][a-z0-9-]{2,80}$"},
        "version": {"type":"string"},
        "channel": {"enum":["stable", "beta", "cohort", "security"]},
        "publisherId": {"type":"string"}
      },
      "additionalProperties": false
    },
    "metadata": {"type":"object", "required":["title", "domain", "language", "estimatedHours"]},
    "licensing": {"type":"object", "required":["requiresLoreKey", "allowedHardwareTiers", "offlineLeaseDays", "maxDevices"]},
    "apps": {"type":"array", "minItems":1},
    "modules": {"type":"array"},
    "dependencies": {"type":"array"},
    "artifacts": {"type":"array"},
    "install": {"type":"object", "required":["strategy", "entrypoint", "requiresAdmin"]},
    "offlinePolicy": {"type":"object", "required":["cacheable", "leaseRequired", "maxOfflineDays"]},
    "reputationPolicy": {"type":"object", "required":["requiresVerifiedEvents"]},
    "signature": {"type":"object", "required":["algorithm", "keyId", "signedAt", "value"]}
      "required": ["code", "version", "channel", "publisher", "publisherId", "createdAt"],
      "properties": {
        "code": {"type": "string", "pattern": "^[a-z0-9][a-z0-9-]{2,80}$"},
        "version": {"type": "string", "pattern": "^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:[-+][0-9A-Za-z.-]+)?$"},
        "channel": {"type": "string", "enum": ["stable", "beta", "cohort", "security"]},
        "publisher": {"type": "string", "minLength": 1},
        "publisherId": {"type": "string", "minLength": 1},
        "createdAt": {"type": "string", "format": "date-time"}
      },
      "additionalProperties": false
    },
    "metadata": {
      "type": "object",
      "required": ["title", "description", "domain", "language", "tags", "estimatedHours"],
      "properties": {
        "title": {"type": "string"},
        "description": {"type": "string"},
        "domain": {"type": "string"},
        "targetPersonas": {"type": "array", "items": {"type": "string"}},
        "language": {"type": "string"},
        "regions": {"type": "array", "items": {"type": "string"}},
        "tags": {"type": "array", "items": {"type": "string"}},
        "estimatedHours": {"type": "number", "minimum": 0},
        "supportUrl": {"type": "string", "format": "uri"}
      },
      "additionalProperties": false
    },
    "licensing": {
      "type": "object",
      "required": ["licenseId", "licenseType", "requiresLoreKey", "allowedHardwareTiers", "maxDevices", "offlineLeaseDays", "redistribution"],
      "properties": {
        "licenseId": {"type": "string"},
        "licenseType": {"type": "string", "enum": ["personal", "cohort", "institution", "open", "trial"]},
        "requiresLoreKey": {"type": "boolean"},
        "allowedHardwareTiers": {"type": "array", "items": {"type": "string"}},
        "maxDevices": {"type": "integer", "minimum": 1},
        "offlineLeaseDays": {"type": "integer", "minimum": 0, "maximum": 365},
        "redistribution": {"type": "string", "enum": ["forbidden", "local-mirror-only", "open"]}
      },
      "additionalProperties": false
    },
    "apps": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["name", "versionRange", "entrypoint", "capabilities"],
        "properties": {
          "name": {"type": "string", "enum": ["StudyOS", "PrepOS", "SkillHex", "ViaDecide", "Zayvora"]},
          "versionRange": {"type": "string"},
          "entrypoint": {"type": "string"},
          "capabilities": {"type": "array", "items": {"type": "string"}}
        },
        "additionalProperties": false
      }
    },
    "modules": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["moduleId", "title", "type", "application", "artifactRefs", "outcomes"],
        "properties": {
          "moduleId": {"type": "string"},
          "title": {"type": "string"},
          "type": {"type": "string", "enum": ["lesson", "lab", "exam", "project", "simulation", "memory-pack"]},
          "application": {"type": "string"},
          "artifactRefs": {"type": "array", "items": {"type": "string"}},
          "prerequisites": {"type": "array", "items": {"type": "string"}},
          "outcomes": {"type": "array", "items": {"type": "string"}}
        },
        "additionalProperties": false
      }
    },
    "dependencies": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["type", "name", "versionRange"],
        "properties": {
          "type": {"type": "string", "enum": ["bundle", "runtime", "application", "os", "hardware"]},
          "name": {"type": "string"},
          "versionRange": {"type": "string"},
          "optional": {"type": "boolean", "default": false}
        },
        "additionalProperties": false
      }
    },
    "artifacts": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["artifactId", "name", "uri", "sha256", "sizeBytes", "mediaType"],
        "properties": {
          "artifactId": {"type": "string"},
          "name": {"type": "string"},
          "uri": {"type": "string"},
          "sha256": {"type": "string", "pattern": "^[a-fA-F0-9]{64}$"},
          "sizeBytes": {"type": "integer", "minimum": 0},
          "mediaType": {"type": "string"},
          "encrypted": {"type": "boolean", "default": false}
        },
        "additionalProperties": false
      }
    },
    "install": {
      "type": "object",
      "required": ["strategy", "entrypoint", "requiresAdmin", "rollback"],
      "properties": {
        "strategy": {"type": "string", "enum": ["copy", "extract", "scripted", "container", "runtime-module"]},
        "entrypoint": {"type": "string"},
        "requiresAdmin": {"type": "boolean"},
        "rollback": {"type": "object"}
      }
    },
    "compatibility": {
      "type": "object",
      "required": ["platforms", "minInstallerVersion"],
      "properties": {
        "platforms": {"type": "array", "items": {"type": "string"}},
        "minInstallerVersion": {"type": "string"}
      }
    },
    "offlinePolicy": {
      "type": "object",
      "required": ["cacheable", "leaseRequired", "maxOfflineDays"],
      "properties": {
        "cacheable": {"type": "boolean"},
        "leaseRequired": {"type": "boolean"},
        "maxOfflineDays": {"type": "integer", "minimum": 0}
      }
    },
    "reputationPolicy": {
      "type": "object",
      "properties": {
        "eligibleAchievements": {"type": "array", "items": {"type": "string"}},
        "minimumTrustTier": {"type": "string"},
        "requiresReviewer": {"type": "boolean"}
      }
    },
    "signature": {
      "type": "object",
      "required": ["algorithm", "keyId", "signedAt", "value"],
      "properties": {
        "algorithm": {"const": "ed25519"},
        "keyId": {"type": "string"},
        "signedAt": {"type": "string", "format": "date-time"},
        "value": {"type": "string"}
      }
    }
  },
  "additionalProperties": false
}
```

## 4. Artifact Rule

Each artifact entry contains `artifactId`, `uri`, `sha256`, `sizeBytes`, `mediaType`, and optional `encrypted`. The installer downloads artifacts only after manifest signature verification and installs only after artifact hash verification.

## 5. Examples

### Chemistry Bundle

- App: StudyOS.
- Modules: atomic structure, bonding, stoichiometry, simulations.
- Reputation: foundation completion badge from verified lesson events.

### Embedded Systems Bundle

- Apps: SkillHex, StudyOS.
- Modules: GPIO, UART, interrupts, firmware build.
- Dependencies: toolchain runtime and optional board profile.
- Reputation: build log and firmware hash events.

### TinyML Bundle

- Apps: SkillHex, Zayvora.
- Modules: data capture, quantization, deployment, inference report.
- Reputation: model card, deployment evidence, verified result events.

### Industry 4.0 Bundle

- Apps: StudyOS, SkillHex, ViaDecide.
- Modules: PLC, sensors, OPC-UA simulation, maintenance scenario.
- Reputation: project portfolio plus decision trail.

## 6. Verification Flow

```text
download manifest -> validate schema -> canonicalize -> verify signature -> verify manifest hash
-> download artifacts -> verify artifact hashes -> install -> record manifest_sha256
```
## 6. Example: Chemistry Bundle

```json
{
  "schemaVersion": "viabundle.v1",
  "bundle": {"code":"chemistry-foundations","version":"1.0.0","channel":"stable","publisher":"Lore Key Learning","publisherId":"pub_lorekey","createdAt":"2026-06-02T00:00:00Z"},
  "metadata": {"title":"Chemistry Foundations","description":"Atomic structure, bonding, stoichiometry, and lab simulations.","domain":"chemistry","targetPersonas":["STEM Student"],"language":"en","regions":["US"],"tags":["chemistry","studyos"],"estimatedHours":30,"supportUrl":"https://support.lorekey.example.com/chemistry"},
  "licensing": {"licenseId":"lic_personal_studyos","licenseType":"personal","requiresLoreKey":true,"allowedHardwareTiers":["QR_NFC","SECURE_ELEMENT"],"maxDevices":2,"offlineLeaseDays":30,"redistribution":"local-mirror-only"},
  "apps": [{"name":"StudyOS","versionRange":">=1.0.0 <2.0.0","entrypoint":"studyos://bundle/chemistry-foundations","capabilities":["lesson_progress","notes","achievements"]}],
  "modules": [{"moduleId":"chem.atomic-structure","title":"Atomic Structure","type":"lesson","application":"StudyOS","artifactRefs":["art_atomic"],"prerequisites":[],"outcomes":["chemistry.atomic_structure"]}],
  "dependencies": [],
  "artifacts": [{"artifactId":"art_atomic","name":"atomic-structure.pack.zst","uri":"https://cdn.example.com/chemistry/atomic.zst","sha256":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","sizeBytes":1048576,"mediaType":"application/zstd","encrypted":false}],
  "install": {"strategy":"extract","entrypoint":"install.json","requiresAdmin":false,"rollback":{"strategy":"restore-checkpoint"}},
  "compatibility": {"platforms":["windows","macos","linux"],"minInstallerVersion":"1.0.0"},
  "offlinePolicy": {"cacheable":true,"leaseRequired":true,"maxOfflineDays":30},
  "reputationPolicy": {"eligibleAchievements":["chemistry_foundations_complete"],"minimumTrustTier":"standard","requiresReviewer":false},
  "signature": {"algorithm":"ed25519","keyId":"pub_lorekey_2026_01","signedAt":"2026-06-02T00:00:00Z","value":"base64url-signature"}
}
```

## 7. Example Bundle Profiles

### Embedded Systems Bundle

- Primary apps: SkillHex, StudyOS.
- Modules: C fundamentals, GPIO, UART, timers, interrupts, firmware build pipeline.
- Dependencies: toolchain runtime, board support package, optional hardware board.
- Reputation: project completion requires build log, firmware hash, and optional board evidence.

### TinyML Bundle

- Primary apps: SkillHex, Zayvora.
- Modules: sensor data collection, model training, quantization, deployment, inference telemetry.
- Dependencies: Python runtime, TinyML runtime, supported microcontroller or simulator.
- Reputation: requires model card, accuracy report, and deployment evidence.

### Industry 4.0 Bundle

- Primary apps: StudyOS, SkillHex, ViaDecide.
- Modules: PLC concepts, industrial sensors, OPC-UA simulation, predictive maintenance scenario.
- Dependencies: simulator runtime and optional hardware dock.
- Reputation: supports portfolio artifact publishing and reviewer validation.

## 8. Signing and Verification Procedure

```text
Build artifacts -> compute SHA-256 -> assemble manifest -> canonicalize manifest
       -> sign canonical manifest -> publish manifest and artifacts -> CDN cache
       -> installer downloads manifest -> verify signature -> download artifacts
       -> verify artifact hashes -> install
```

Failure rules:

- Invalid manifest schema: reject.
- Invalid signature: reject and audit.
- Unknown signing key: reject unless trust store update succeeds.
- Artifact hash mismatch: quarantine artifact and retry from alternate mirror.
- Revoked bundle version: do not install; existing installs enter update-required policy state.
