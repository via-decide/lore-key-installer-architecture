# 02 — Jobs-To-Be-Done Analysis

## 1. Method

This document converts research into buildable Jobs-To-Be-Done. Each product is specified by functional, emotional, and social jobs plus hiring triggers, firing triggers, competitive alternatives, user outcomes, and opportunity score.

Opportunity score:

```text
Opportunity = Importance + max(Importance - Current Satisfaction, 0)
```

Scores use 1-10. MVP prioritizes outcomes scoring 13 or higher.

## 2. Portfolio Map

```text
Lore Key     -> Environment Installer and ownership activation artifact
StudyOS      -> Structured learning environment
PrepOS       -> Exam preparation environment
SkillHex     -> Project skill environment
ViaDecide    -> Reputation and decision provenance layer
Zayvora      -> Permissioned memory projection layer
```

## 3. Lore Key

| Dimension | Specification |
|---|---|
| Functional Job | When I receive a physical learning artifact, I want it to activate ownership and install my local environment so I can start learning without manual setup. |
| Emotional Job | I want the key to feel like durable ownership of my learning path. |
| Social Job | I want others to know my environment and achievements are legitimate without exposing private data. |
| Hiring Triggers | Kit purchase, classroom issue, low connectivity, fragmented tools, need for recovery. |
| Firing Triggers | Activation failure, unexpected lockout, no offline use, confusing recovery, artifact feels cosmetic. |
| Alternatives | Coupon codes, LMS accounts, USB content, printed access codes, dongles. |
| User Outcomes | Activated identity, bound device, offline lease, verified install, event-backed reputation. |

### Opportunity Scores

| Outcome | Importance | Satisfaction | Opportunity |
|---|---:|---:|---:|
| Install a complete environment | 10 | 4 | 16 |
| Use offline after valid activation | 9 | 3 | 15 |
| Own portable learning history | 9 | 4 | 14 |
| Prove progress credibly | 8 | 3 | 13 |
| Avoid content-on-key piracy | 8 | 4 | 12 |

## 4. StudyOS

| Dimension | Specification |
|---|---|
| Functional Job | When I study a topic, I want lessons, notes, progress, and achievements in one offline-capable environment. |
| Emotional Job | I want clarity about what to do next. |
| Social Job | I want to share verified progress selectively. |
| Hiring Triggers | New course, scattered notes, unreliable internet, need to resume. |
| Firing Triggers | Rigid workflow, lost progress, poor export, online-only behavior. |
| Alternatives | LMS, Notion, Obsidian, video course apps, paper planners. |
| User Outcomes | Resume next action, record events, sync progress, earn event-backed achievements. |

### Opportunity Scores

| Outcome | Importance | Satisfaction | Opportunity |
|---|---:|---:|---:|
| Know next learning step | 9 | 5 | 13 |
| Keep progress and notes together | 8 | 4 | 12 |
| Work offline | 8 | 3 | 13 |
| Share progress selectively | 7 | 3 | 11 |
| Avoid tool fragmentation | 9 | 4 | 14 |

## 5. PrepOS

| Dimension | Specification |
|---|---|
| Functional Job | When I prepare for an exam, I want timed practice, analytics, revision planning, and offline attempts. |
| Emotional Job | I want confidence that my preparation is improving. |
| Social Job | I want to show disciplined preparation without exposing raw scores. |
| Hiring Triggers | Exam deadline, weak mock scores, coaching gaps, intermittent connectivity. |
| Firing Triggers | Stale questions, bad analytics, untrusted offline attempts, unrecoverable history. |
| Alternatives | Coaching apps, books, spreadsheets, coaching portals. |
| User Outcomes | Attempt events, topic weakness signals, readiness achievements, private reputation summary. |

### Opportunity Scores

| Outcome | Importance | Satisfaction | Opportunity |
|---|---:|---:|---:|
| Weak-area diagnosis | 10 | 5 | 15 |
| Offline mock tests | 8 | 3 | 13 |
| Trusted attempt history | 8 | 4 | 12 |
| Revision adherence | 9 | 5 | 13 |
| Privacy-preserving progress share | 7 | 2 | 12 |

## 6. SkillHex

| Dimension | Specification |
|---|---|
| Functional Job | When I build a project, I want tools, tasks, evidence capture, and skill mapping in one environment. |
| Emotional Job | I want to feel like a builder, not a passive learner. |
| Social Job | I want credible portfolio evidence. |
| Hiring Triggers | Maker kit, lab, hackathon, embedded project, portfolio need. |
| Firing Triggers | Toolchain failure, burdensome evidence, arbitrary skills, no export. |
| Alternatives | GitHub, tutorials, IDE extensions, badges. |
| User Outcomes | Reproducible setup, build evidence, skill achievements, reputation events. |

### Opportunity Scores

| Outcome | Importance | Satisfaction | Opportunity |
|---|---:|---:|---:|
| Reproducible setup | 9 | 3 | 15 |
| Evidence-backed skills | 8 | 3 | 13 |
| Exportable artifacts | 8 | 5 | 11 |
| Mentor review | 7 | 4 | 10 |
| Offline continuity | 7 | 3 | 11 |

## 7. ViaDecide

| Dimension | Specification |
|---|---|
| Functional Job | When I complete meaningful work, I want verified reputation events generated from evidence. |
| Emotional Job | I want my effort recognized fairly. |
| Social Job | I want trusted signals for mentors, schools, and employers. |
| Hiring Triggers | Achievement completion, internship application, mentor review, portfolio publishing. |
| Firing Triggers | Fakeable claims, privacy exposure, untrusted format, slow review. |
| Alternatives | LinkedIn, certificates, GitHub, digital badges. |
| User Outcomes | Consent flow, verified evidence, signed reputation event, revocation support. |

### Opportunity Scores

| Outcome | Importance | Satisfaction | Opportunity |
|---|---:|---:|---:|
| Credible proof | 9 | 3 | 15 |
| Selective disclosure | 8 | 2 | 14 |
| Evidence-linked achievements | 9 | 4 | 14 |
| Revocation/correction | 7 | 2 | 12 |
| Cross-product reputation | 8 | 3 | 13 |

## 8. Zayvora

| Dimension | Specification |
|---|---|
| Functional Job | When I learn across time, I want permissioned memory/context projected from verified activity. |
| Emotional Job | I want continuity without a creepy black box. |
| Social Job | I want to be understood as a learner with history, not only scores. |
| Hiring Triggers | Returning after a gap, cross-app learning, mentor summary, adaptive prompts. |
| Firing Triggers | Opaque memory, no correction, surprise sharing, performance overhead. |
| Alternatives | App recommendations, notes, AI chat history, LMS analytics. |
| User Outcomes | Inspectable memory, correction, permissioned projection, local-first storage. |

### Opportunity Scores

| Outcome | Importance | Satisfaction | Opportunity |
|---|---:|---:|---:|
| Coherent long-term memory | 9 | 2 | 16 |
| Inspectable/correctable memory | 8 | 2 | 14 |
| Adaptive context | 8 | 5 | 11 |
| Local-first privacy | 9 | 3 | 15 |
| Cross-app continuity | 9 | 3 | 15 |

## 9. MVP Prioritization

| Rank | Opportunity | Product | MVP Decision |
|---:|---|---|---|
| 1 | Environment installation | Lore Key | Build first. |
| 2 | Offline learning continuity | Lore Key/StudyOS | Build with IndexedDB and leases. |
| 3 | Event-backed progress | StudyOS/PrepOS | Build canonical event SDK. |
| 4 | Verified reputation | ViaDecide | Build from accepted events only. |
| 5 | Permissioned memory | Zayvora | Build projection contract, not full AI runtime. |
