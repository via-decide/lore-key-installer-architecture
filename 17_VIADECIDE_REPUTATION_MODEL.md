# 17 — ViaDecide Reputation Model

## 1. Rule

Verified reputation is generated from verified events, not manual claims. A user may draft a claim manually, but the system can sign it only if evidence events verify.

## 2. Inputs

- Accepted progress events.
- Achievements derived from accepted events.
- Portfolio artifact hashes.
- Reviewer attestations tied to accepted events.
- Aporaksha identity assertion.
- User consent.

## 3. Verification Pipeline

```text
Draft -> Consent -> Aporaksha Assertion -> Evidence Event Resolution
-> Fraud Checks -> Trust Score -> Server Signature -> Publish/Share
```

## 4. Proof-of-Work

Proof-of-work means learning evidence:

| Proof | Evidence |
|---|---|
| Lesson completion | accepted StudyOS events. |
| Exam attempt | accepted PrepOS attempt events. |
| Project build | SkillHex build log hash and artifact hash events. |
| Decision trail | ViaDecide signed decision events. |
| Model deployment | TinyML result and model card events. |
| Mentor review | signed reviewer attestation. |

## 5. Trust Scores

Dimensions: identity assurance, evidence strength, recency, consistency, reviewer trust, tamper resistance, revocation history.

Bands: `UNVERIFIED`, `BASIC`, `STANDARD`, `STRONG`, `EXCEPTIONAL`.

Scores are explainable and recalculated from evidence and policy version.

## 6. Badge System

Badge criteria are deterministic and reference event types. Example badges:

- `studyos.foundations.complete`
- `prepos.consistent.practice`
- `skillhex.embedded.builder`
- `viadecide.decision.publisher`
- `zayvora.context.curator`

## 7. Anti-Fraud

| Signal | Action |
|---|---|
| Impossible completion velocity | hold or lower trust. |
| Replayed event IDs | reject and audit. |
| Evidence after lease expiry | reject protected claim. |
| Artifact hash mismatch | reject claim. |
| Device churn | request additional verification. |
| Reviewer collusion | hold for review. |

## 8. Privacy

Public verification shows claim, issuer, status, trust band, evidence summary, and signature. It does not show private notes, raw exam items, email, or unselected artifacts.
