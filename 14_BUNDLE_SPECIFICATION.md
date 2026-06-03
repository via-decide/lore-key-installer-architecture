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

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://schemas.lorekey.example/viabundle.v1.json",
  "type": "object",
  "required": ["schemaVersion", "bundle", "metadata", "licensing", "apps", "modules", "dependencies", "artifacts", "install", "offlinePolicy", "reputationPolicy", "signature"],
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
