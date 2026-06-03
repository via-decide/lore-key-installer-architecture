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
