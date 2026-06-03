# ViaDecide Reputation Model

## 1. Purpose

ViaDecide is the reputation architecture for Lore Key. It converts verified learning activity, project evidence, decision trails, and reviewer attestations into consented, signed reputation events. It must reward real work while resisting fraud, preserving privacy, and explaining trust.

## 2. Reputation Inputs

```text
Progress Signals ─┐
Achievements ─────┤
Portfolio Artifacts├── Evidence Graph ── Verification ── Reputation Events
Proof-of-Work ────┤                         │
Reviewer Signals ─┘                         v
                                      Trust Scores + Badges
```

## 3. Achievements

### 3.1 Achievement Types

| Type | Source | Example |
|---|---|---|
| Completion | StudyOS | Chemistry foundations complete. |
| Assessment | PrepOS | 20 timed mock tests completed. |
| Project | SkillHex | Built line-following robot. |
| Decision | ViaDecide | Published design tradeoff decision trail. |
| Memory | Zayvora | Demonstrated long-term learning continuity. |
| Reviewer | Mentor/admin | Mentor verified project artifact. |

### 3.2 Achievement Quality Levels

| Level | Evidence Requirement | Reputation Eligibility |
|---|---|---|
| Local | Local-only unsigned or unsynced evidence. | Private/local only. |
| Device-Signed | Signed by device under active lease. | Low-trust badges. |
| Server-Verified | Accepted sync evidence. | Standard badges and events. |
| Reviewed | Server-verified plus reviewer attestation. | High-trust portfolio claims. |
| Hardware-Verified | Secure element or hardware artifact evidence. | Specialized technical badges. |

## 4. Progress Signals

Progress signals are low-level events that may contribute to reputation but are not reputation by themselves.

| Signal | Weight | Fraud Risk | Notes |
|---|---:|---:|---|
| Lesson completion | Low | Medium | Easy to automate; useful for continuity. |
| Timed attempt | Medium | Medium | Requires timing and item integrity. |
| Project build log | High | Medium | Stronger if includes reproducible outputs. |
| Firmware hash | High | Low/Medium | Strong for embedded artifacts. |
| Peer review | Medium | Medium/High | Requires reviewer trust. |
| Mentor attestation | High | Low/Medium | Strong if mentor identity trusted. |
| Decision trail | Medium | Medium | Shows reasoning provenance. |

## 5. Verification Model

### 5.1 Verification Pipeline

```text
Reputation Draft
      │
      v
Consent Check
      │
      v
Evidence Resolution
      │
      v
Signature Verification
      │
      v
Policy Evaluation
      │
      v
Fraud Scoring
      │
      v
Accept / Reject / Needs Review
```

### 5.2 Verification Requirements

- Source events must be accepted or explicitly marked low-trust.
- Evidence hashes must match stored event payloads or artifact digests.
- Device signatures must validate against active or historically valid device binding.
- Achievement must not be revoked.
- Claim fields must match the source achievement and cannot inflate scope.
- Privacy policy must permit selected disclosure.

## 6. Proof-of-Work

Proof-of-Work in ViaDecide means evidence of meaningful learner work, not cryptocurrency-style computation.

### 6.1 Proof Types

| Proof Type | Evidence | Example |
|---|---|---|
| Time-bound practice | Attempt timestamps and duration | PrepOS timed mock test. |
| Build artifact | File hash, firmware hash, build log | Embedded firmware compiled and flashed. |
| Portfolio artifact | Photo, video, commit, notebook, CAD | Maker project demonstration. |
| Decision provenance | Alternatives, tradeoffs, chosen path | Engineering design decision. |
| Simulation result | Input, output, seed, runtime version | TinyML inference report. |
| Reviewer attestation | Signed review statement | Mentor validates project. |

### 6.2 Proof Rules

- Proofs must be referenced by hash or signed URL, not embedded wholesale in public reputation events.
- Private proofs require explicit sharing scope.
- Proofs can expire or be revoked if integrity is invalidated.
- Proof quality affects trust score and badge tier.

## 7. Portfolio Artifacts

### 7.1 Artifact Types

| Artifact | Stored Locally | Shareable | Verification |
|---|---:|---:|---|
| Build log | Yes | Yes | Hash and timestamp. |
| Source code reference | Optional | Yes | Git commit hash or archive hash. |
| Photo/video | Yes | Selective | Hash and optional reviewer. |
| Notebook/report | Yes | Yes | Hash and bundle context. |
| Firmware binary | Yes | Selective | Hash and toolchain version. |
| Decision record | Yes | Yes | ViaDecide signature. |

### 7.2 Artifact Privacy

- Artifacts are private by default.
- Public reputation events include references and summaries, not raw private files.
- Sharing scopes: `private`, `mentor`, `cohort`, `public`, `verification-link`.
- Revoking a public link does not delete the internal evidence trail.

## 8. Trust Scores

### 8.1 Purpose

Trust scores summarize evidence quality and abuse risk for a specific claim, user, or domain. They are not moral judgments or universal scores.

### 8.2 Trust Score Dimensions

| Dimension | Description |
|---|---|
| Identity assurance | QR/NFC/secure-element tier and account verification. |
| Evidence strength | Number and quality of source events/artifacts. |
| Recency | How recent the evidence is. |
| Consistency | Whether progress patterns are plausible. |
| Reviewer trust | Reviewer identity and history. |
| Tamper resistance | Device signatures, secure element, immutable logs. |
| Revocation history | Prior rejected or revoked claims. |

### 8.3 Score Bands

| Band | Score | Meaning |
|---|---:|---|
| Unverified | 0-24 | Draft/local-only or insufficient evidence. |
| Basic | 25-49 | Device-signed, limited evidence. |
| Standard | 50-74 | Server-verified evidence. |
| Strong | 75-89 | Multiple evidence types and/or reviewer. |
| Exceptional | 90-100 | Strong identity, evidence, review, and reproducibility. |

### 8.4 Score Constraints

- Scores must be explainable by dimensions.
- Scores must be recalculable from evidence and policy version.
- Scores cannot be permanently cached without policy version metadata.
- Users must see why a claim is low trust where possible.

## 9. Badge System

### 9.1 Badge Model

| Field | Description |
|---|---|
| `badgeCode` | Stable badge code. |
| `title` | Public title. |
| `domain` | Skill or learning domain. |
| `tier` | `bronze`, `silver`, `gold`, `verified`, `reviewed`. |
| `criteria` | Machine-readable criteria. |
| `evidencePolicy` | Required proof types. |
| `revocationPolicy` | Conditions that invalidate badge. |

### 9.2 Badge Examples

| Badge | Criteria |
|---|---|
| StudyOS Chemistry Foundations | Complete required modules with accepted progress. |
| PrepOS Consistent Practice | Complete 20 timed attempts across 30 days. |
| SkillHex Embedded Builder | Submit firmware hash, build log, and project evidence. |
| ViaDecide Decision Publisher | Publish three verified decision trails. |
| Zayvora Continuity Learner | Demonstrate progress across two learning periods with memory inspection. |

## 10. Reputation Events

### 10.1 Event Types

| Event Type | Trigger |
|---|---|
| `ACHIEVEMENT_AWARDED` | Achievement accepted. |
| `BADGE_EARNED` | Badge criteria met. |
| `PROJECT_PUBLISHED` | Portfolio artifact shared. |
| `TRUST_SCORE_UPDATED` | Trust score materially changes. |
| `REVIEW_ATTESTED` | Reviewer signs attestation. |
| `CLAIM_REVOKED` | Prior claim revoked. |
| `CLAIM_SUPERSEDED` | Claim replaced by corrected claim. |

### 10.2 Event Envelope

```json
{
  "event_id": "rep_01HX",
  "event_type": "BADGE_EARNED",
  "subject_user_id": "usr_01HX",
  "claim": {
    "badge_code": "skillhex.embedded_builder.silver",
    "title": "Embedded Builder - Silver",
    "trust_band": "Strong"
  },
  "evidence_refs": [
    {"type": "achievement", "id": "ach_01HX", "hash": "sha256:..."},
    {"type": "artifact", "id": "art_01HX", "hash": "sha256:..."}
  ],
  "policy_version": "reputation-policy-2026-06",
  "issued_at": "2026-06-02T00:00:00Z",
  "server_signature": "base64url..."
}
```

## 11. Anti-Fraud Logic

### 11.1 Fraud Signals

| Signal | Severity |
|---|---:|
| Replayed event IDs across devices | High |
| Events after lease expiry claiming protected activity | High |
| Impossible completion velocity | Medium/High |
| Frequent local database resets | Medium |
| Device binding churn | Medium |
| Reviewer collusion pattern | High |
| Hash mismatch for portfolio artifact | High |
| QR key activated in distant geographies in short window | Medium/High |

### 11.2 Actions

| Risk Level | Action |
|---|---|
| Low | Accept and monitor. |
| Medium | Accept with lower trust score or require additional evidence. |
| High | Hold for review and block public publishing. |
| Critical | Reject, audit, and optionally suspend key/user capability. |

### 11.3 Fraud Decision Flow

```text
Verified Evidence
      │
      v
Risk Signal Extraction
      │
      v
Fraud Score
      │
      ├── low -> accept
      ├── medium -> accept with lower trust / request evidence
      ├── high -> manual review
      └── critical -> reject + audit + possible suspension
```

## 12. Public Verification

Public verification pages must show:

- Claim title.
- Issuer.
- Issued date.
- Current status: accepted, revoked, superseded.
- Trust band and explanation.
- Evidence summary.
- Signature verification result.
- Privacy-safe user display name or pseudonym.

They must not show:

- Raw private notes.
- Raw exam item details.
- Personal email or recovery identifiers.
- Unselected portfolio files.
