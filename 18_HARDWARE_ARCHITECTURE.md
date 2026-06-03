# 18 — Hardware Architecture

## 1. Hardware Rule

The physical Lore Key provides a physical signal. It does not store content and does not provide trusted identity by itself.

## 2. MVP Artifact

Components:

- 3D printed shell.
- Printed QR code.
- Human-readable serial.
- Optional NFC sticker.
- Laminated label.

Recommended dimensions:

| Dimension | Target |
|---|---:|
| Length | 55 mm |
| Width | 28 mm |
| Thickness | 5-7 mm |
| Keyring hole | 4.5 mm |
| Label recess | 0.2-0.4 mm |

## 3. QR Layout

Payload:

```text
https://activate.lorekey.example/k/LK-2026-000001?c=PUBLIC-CODE&v=1
# Hardware Architecture

## 1. Purpose

This document defines the physical Lore Key system, optional dock, NFC and QR layouts, manufacturing process, 3D printing constraints, material selection, tolerance stackups, assembly procedures, and future variants. The physical artifact is an identity anchor and environment installer, not a content container.

## 2. Physical System Overview

```text
┌──────────────────────┐       optional       ┌──────────────────────┐
│ Lore Key Artifact    │<-------------------->│ Lore Key Dock        │
│ QR + Serial + NFC    │                      │ NFC reader / holder  │
│ 3D printed shell     │                      │ optional USB bridge  │
└─────────┬────────────┘                      └─────────┬────────────┘
          │ scan/tap                                      │ USB/BLE future
          v                                               v
┌────────────────────────────────────────────────────────────────────┐
│ Installer Device                                                    │
│ camera, NFC reader, browser/deep link, desktop installer             │
└────────────────────────────────────────────────────────────────────┘
```

## 3. Lore Key Artifact

### 3.1 Functional Requirements

- Provide visible serial identifier.
- Provide scannable QR payload.
- Optionally provide NFC tap activation.
- Be durable enough for daily carry.
- Be manufacturable at low cost.
- Support 3D printed enclosure variations.
- Avoid storing licensed content.

### 3.2 Recommended MVP Construction

| Layer | Material | Purpose |
|---|---|---|
| Outer shell | PLA/PETG/ABS 3D print | Mechanical protection and brand identity. |
| Label face | Laminated printed label | QR code, serial, support URL. |
| NFC insert | NTAG213/215 sticker or equivalent | Tap activation payload. |
| Adhesive | Thin double-sided adhesive | Holds NFC and label. |
| Optional insert | Metal/plastic weight | Improves perceived durability. |

### 3.3 Nominal Dimensions

| Dimension | Target | Notes |
|---|---:|---|
| Length | 55 mm | Keychain-friendly. |
| Width | 28 mm | Supports readable QR. |
| Thickness | 5-7 mm | Depends on printer/material. |
| Corner radius | 4 mm | Reduces pocket wear. |
| Keyring hole | 4.5 mm diameter | Minimum 2 mm wall around hole. |
| QR quiet zone | >= 4 modules | Required for scan reliability. |

## 4. Dock

### 4.1 Purpose

The dock is optional. It improves onboarding for classrooms, labs, and maker kits by providing a consistent place to tap or hold Lore Keys.

### 4.2 MVP Dock

- Passive 3D printed holder with alignment marks.
- No electronics required.
- Positions QR at camera-friendly angle or NFC at reader-friendly area.

### 4.3 Future Active Dock

| Component | Purpose |
|---|---|
| USB-C microcontroller | Host communication and future challenge workflows. |
| NFC reader | Reads key NFC payload. |
| Status LED | User feedback. |
| Secure element | Dock identity for classroom/lab trust. |
| Optional BLE | Mobile onboarding. |

## 5. NFC Layout

### 5.1 NFC Payload

Use NDEF URI or text record.

```text
lorekey://activate?k=LK-2026-000001&p=PUBLIC-CODE-VERSIONED
```

Rules:

- QR code includes no private secret.
- Server stores hash of public code.
- QR has high contrast and quiet zone.
- Serial text must match encoded serial.

## 4. NFC Layout

Payload:

```text
lorekey://activate?serial=LK-2026-000001&code=PUBLIC-CODE&v=1
```

Rules:

- NFC UID is not trusted identity.
- NFC payload is equivalent to QR signal unless secure element variant exists.
- Keep antenna away from metal without shielding.

## 5. Dock

MVP dock is passive: it positions the key for QR scanning or NFC reading. Future active dock can include USB-C, NFC reader, status LED, microcontroller, and secure element.

## 6. Manufacturing Process

```text
Generate serials/codes -> hash codes -> print labels -> encode NFC -> print shells
-> assemble -> scan QA -> tap QA -> batch register in Aporaksha -> package
```

## 7. 3D Printing Constraints

| Constraint | Requirement |
|---|---|
| Wall thickness | >= 1.2 mm. |
| Material | PETG preferred; PLA acceptable for prototype. |
| Overhang | Avoid unsupported >45 degrees. |
| Tolerance | +/- 0.4 mm for FDM MVP. |
| Label alignment | +/- 0.75 mm. |

## 8. Variants

| Variant | Difference |
|---|---|
| Maker | Color shell, project kit serial linking. |
| Embedded Systems | Rugged shell, optional board dock. |
| TinyML | Sensor-themed shell, optional sensor dock. |
| Secure Element | Challenge-response hardware for higher trust. |
- NFC payload must contain no raw server secret beyond the same low-assurance public activation code used by QR unless using secure element.
- Server stores only hashes of public codes.
- NFC UID alone is not sufficient identity proof.
- NFC layout must include a version byte or versioned URI parameter.

### 5.2 NFC Placement

```text
Top View
┌──────────────────────────────┐
│ QR / Label Face              │
│                              │
│        ┌────────────┐        │
│        │ NFC Coil   │        │
│        │ centered   │        │
│        └────────────┘        │
│ Serial: LK-2026-000001       │
└──────────────────────────────┘
```

Placement rules:

- Keep NFC antenna away from metal inserts unless ferrite shielding is used.
- Keep at least 1 mm cover material over NFC tag where possible.
- Test with common Android phones and external readers.

## 6. QR Layout

### 6.1 QR Payload

```text
https://activate.lorekey.example.com/k/LK-2026-000001?c=Q7K9-2M4P-88XZ&v=1
```

### 6.2 Printed Label Requirements

| Requirement | Target |
|---|---:|
| Minimum QR size | 18 mm x 18 mm for MVP payload. |
| Error correction | Level Q or H. |
| Quiet zone | >= 4 modules. |
| Contrast | Black on white or equivalent high contrast. |
| Lamination | Recommended for abrasion resistance. |
| Human serial | Printed below QR. |

### 6.3 QR Quality Checks

- Scan with at least three phone models.
- Scan under low indoor light and indirect daylight.
- Scan after light abrasion test.
- Verify serial text matches encoded serial.

## 7. Manufacturing Process

```text
Generate serials and public codes
        │
        v
Hash public codes into registration file
        │
        v
Print QR/serial labels
        │
        v
Encode NFC tags
        │
        v
3D print shells
        │
        v
Assemble NFC + label + shell
        │
        v
QA scan/tap test
        │
        v
Batch register in Aporaksha
        │
        v
Package and distribute
```

## 8. 3D Printing Constraints

| Constraint | Requirement |
|---|---|
| Minimum wall thickness | >= 1.2 mm for FDM. |
| Layer height | 0.16-0.24 mm recommended. |
| Overhangs | Avoid unsupported overhangs > 45 degrees. |
| Label recess | 0.2-0.4 mm recess for label protection. |
| NFC cavity | Allow tag thickness + adhesive tolerance. |
| Warping | Prefer PETG/PLA for MVP; ABS requires controlled enclosure. |
| Post-processing | Avoid solvents that damage labels or NFC. |

## 9. Material Selection

| Material | Pros | Cons | Recommendation |
|---|---|---|---|
| PLA | Cheap, easy print, good detail | Heat sensitivity | Good prototype. |
| PETG | Durable, less brittle | Stringing, moderate detail | Preferred MVP. |
| ABS/ASA | Heat resistant | Warping, fumes | Use for rugged variants. |
| Resin | High detail | Brittle, post-cure | Premium visual prototypes only. |
| Nylon | Strong | Moisture and print complexity | Future rugged edition. |

## 10. Tolerance Stackups

### 10.1 Critical Stack

```text
Shell recess depth
 + adhesive thickness
 + NFC tag thickness
 + label thickness
 + printer dimensional error
 = final surface offset
```

Targets:

- Label should sit flush or recessed by 0.1-0.3 mm.
- NFC tag should not bulge label.
- Keyring hole wall should remain >= 2 mm after print variation.
- Overall thickness variation target: +/- 0.4 mm for FDM MVP.

### 10.2 QA Gauge Checks

- Overall length/width with calipers.
- Keyring hole diameter.
- Label alignment tolerance +/- 0.75 mm.
- NFC read success through shell.

## 11. Assembly Procedures

1. Verify printed shell revision and batch.
2. Clean label recess surface.
3. Place NFC tag in cavity with antenna centered.
4. Apply label over recess without covering keyring hole.
5. Scan QR and compare serial.
6. Tap NFC and compare serial.
7. Record QA result in manufacturing batch file.
8. Package key with activation instructions.

## 12. Future Variants

### 12.1 Embedded Systems Variant

- Rugged enclosure with board-themed design.
- Optional dock that also holds microcontroller board.
- NFC tag includes variant metadata.
- Bundle defaults to Embedded Systems `.viabundle`.
- Optional secure element for professional labs.

### 12.2 TinyML Variant

- Includes sensor-themed visual identity.
- Optional dock with sensor module reference or storage slot.
- Bundle defaults to TinyML runtime and sample datasets.
- Future active dock may collect simple sensor identity metadata.

### 12.3 Maker Variant

- Larger keychain form with customizable color plates.
- QR label protected by replaceable transparent insert.
- Supports project kit serial linking.
- Encourages portfolio evidence capture through SkillHex.

### 12.4 Secure Element Variant

- Adds challenge-response chip.
- Requires electrical contact or NFC secure element.
- Supports higher-trust activation and reputation.
- Higher BOM and manufacturing QA requirements.

## 13. Hardware Security Notes

- Static QR and NFC are low-assurance and cloneable.
- Secure element variant is required for high-stakes credentials.
- Physical tamper evidence is helpful but not sufficient security.
- Do not place private cryptographic secrets in printed codes or static NFC payloads.
- Lost keys can be suspended or revoked but local user data should remain recoverable.
