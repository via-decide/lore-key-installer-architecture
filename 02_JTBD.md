# Jobs-To-Be-Done Analysis: Lore Key Product Family

## 1. Method

This analysis applies Jobs-To-Be-Done across functional, emotional, and social dimensions. Each product is evaluated by the job it is hired to perform, the circumstances that trigger adoption, the reasons users abandon it, competing alternatives, desired outcomes, and opportunity scoring.

Opportunity scoring uses the formula:

```text
Opportunity Score = Importance + max(Importance - Satisfaction, 0)
```

Scores use a 1-10 scale. Higher scores indicate stronger product opportunity.

## 2. Portfolio Context

```text
Lore Key       Physical identity and environment installer
StudyOS        Structured learning operating environment
PrepOS         Competitive exam preparation environment
SkillHex       Project and skill-building environment
ViaDecide      Decision provenance and reputation layer
Zayvora        Runtime memory and adaptive context layer
```

## 3. Lore Key

### Functional Job

When I acquire a physical learning artifact, I want it to activate my identity and install the correct local learning environment so that I can begin learning without manually assembling accounts, tools, bundles, and credentials.

### Emotional Job

I want the artifact to feel like a durable key to my learning journey, not another disposable login or coupon code.

### Social Job

I want to signal that I own a legitimate learning pathway and can prove progress without exposing all private learning data.

### Hiring Triggers

- Learner receives a kit, course package, school-issued object, maker kit, or exam preparation bundle.
- Internet access is unreliable and local operation is valuable.
- User has experienced account loss, content expiration, or fragmented tools.
- Institution wants controlled distribution without shipping content on USB drives.
- Parent, teacher, or mentor wants tangible proof that a learning environment was activated.

### Firing Triggers

- Activation fails or takes too long.
- Artifact appears to be only a gimmick with no ongoing utility.
- Offline mode unexpectedly locks the user out.
- Recovery after device loss is confusing or punitive.
- Security friction exceeds the value of possession-based identity.

### Competitive Alternatives

| Alternative | Strength | Weakness |
|---|---|---|
| Course coupon code | Cheap and simple | Easily shared, no durable identity, no environment install. |
| USB drive with content | Offline friendly | Piracy risk, stale content, malware risk. |
| LMS account | Familiar | Cloud dependent, fragmented, weak physical ownership. |
| Hardware dongle | Stronger possession proof | Higher cost, poor learner experience if treated as DRM. |
| Printed textbook code | Low cost | One-time activation, limited ongoing state. |

### User Outcomes

- Activate a legitimate identity in under three minutes.
- Install a verified environment without manually resolving dependencies.
- Continue learning offline within clear lease rules.
- Recover access after device replacement.
- Publish selected achievements with credible provenance.

### Opportunity Scoring

| Outcome | Importance | Current Satisfaction | Opportunity Score |
|---|---:|---:|---:|
| Install a complete environment quickly | 10 | 4 | 16 |
| Use learning tools offline | 9 | 3 | 15 |
| Prevent loss of learning history | 9 | 4 | 14 |
| Prove legitimate progress | 8 | 3 | 13 |
| Reduce piracy without punishing learners | 8 | 4 | 12 |

## 4. StudyOS

### Functional Job

When I start a course or topic, I want a structured learning environment that tracks lessons, notes, labs, practice, and progress so that I can move through material coherently.

### Emotional Job

I want to feel oriented, supported, and able to resume without anxiety about where I left off.

### Social Job

I want teachers, mentors, peers, or family to see credible progress without needing access to all my private notes.

### Hiring Triggers

- Beginning a semester, course, bootcamp, or self-study track.
- Feeling overwhelmed by scattered PDFs, videos, and notes.
- Needing offline study continuity.
- Wanting progress that survives across devices or cohorts.

### Firing Triggers

- StudyOS becomes another rigid LMS instead of a helpful environment.
- Progress tracking feels inaccurate or intrusive.
- Content and notes are difficult to export.
- Offline changes fail to sync reliably.

### Competitive Alternatives

| Alternative | Strength | Weakness |
|---|---|---|
| LMS modules | Institutionally accepted | Often passive, online-first, weak personal ownership. |
| Notion/Obsidian | Flexible notes | Requires manual structure and no trusted progress. |
| Video course platform | Easy consumption | Weak labs, weak offline state, fragmented identity. |
| Paper planner | Tangible | Not integrated with digital proof. |

### User Outcomes

- Resume study at the exact next action.
- View progress by topic, competency, and time.
- Maintain notes and evidence locally.
- Sync progress safely when online.
- Export selected achievements.

### Opportunity Scoring

| Outcome | Importance | Current Satisfaction | Opportunity Score |
|---|---:|---:|---:|
| Know what to study next | 9 | 5 | 13 |
| Keep notes and progress together | 8 | 4 | 12 |
| Work offline | 8 | 3 | 13 |
| Share progress selectively | 7 | 3 | 11 |
| Avoid tool fragmentation | 9 | 4 | 14 |

## 5. PrepOS

### Functional Job

When I prepare for a competitive exam, I want an exam-specific operating environment with practice, revision schedules, analytics, and simulated tests so that I can improve readiness under realistic constraints.

### Emotional Job

I want confidence that my effort is targeted and that weak areas are visible early enough to improve.

### Social Job

I want to demonstrate disciplined preparation to parents, mentors, institutions, or sponsors without sharing embarrassing raw scores.

### Hiring Triggers

- Upcoming exam deadline.
- Poor performance in mock tests.
- Need for structured revision.
- Limited connectivity in study locations.
- Desire for verified preparation history.

### Firing Triggers

- Question bank quality is poor or stale.
- Analytics are inaccurate or demotivating.
- Offline tests are not trusted.
- Progress cannot be recovered after reinstall.

### Competitive Alternatives

| Alternative | Strength | Weakness |
|---|---|---|
| Coaching app | Rich question bank | Cloud dependency, siloed records. |
| Printed guidebooks | Offline | No adaptive analytics or reputation. |
| Spreadsheets | Customizable | Manual tracking, no validation. |
| Coaching center portal | Structured | Institution lock-in. |

### User Outcomes

- Complete timed practice offline.
- Identify weak topics and revision priorities.
- Preserve attempt history.
- Publish readiness milestones with consent.
- Recover from device changes.

### Opportunity Scoring

| Outcome | Importance | Current Satisfaction | Opportunity Score |
|---|---:|---:|---:|
| Accurate weak-area diagnosis | 10 | 5 | 15 |
| Offline mock tests | 8 | 3 | 13 |
| Trusted attempt history | 8 | 4 | 12 |
| Revision schedule adherence | 9 | 5 | 13 |
| Privacy-preserving progress sharing | 7 | 2 | 12 |

## 6. SkillHex

### Functional Job

When I want to build a skill through projects, I want a project environment that installs tools, guides tasks, captures evidence, and maps work to skills so that I can prove practical capability.

### Emotional Job

I want to feel like a builder making visible progress instead of a passive consumer of tutorials.

### Social Job

I want to show mentors, employers, peers, or communities credible evidence of completed projects.

### Hiring Triggers

- Starting a maker kit, hackathon, robotics build, electronics module, or portfolio project.
- Struggling to set up toolchains.
- Needing proof that a project was actually completed.
- Wanting skill progression beyond certificates.

### Firing Triggers

- Toolchain installation fails.
- Evidence capture feels burdensome.
- Skill mapping feels arbitrary.
- Project artifacts cannot be exported.

### Competitive Alternatives

| Alternative | Strength | Weakness |
|---|---|---|
| GitHub portfolio | Public proof | Requires skill in documentation and does not validate learning pathway. |
| Maker tutorials | Accessible | Weak state and evidence. |
| IDE extensions | Tool-integrated | Narrow scope, no reputation layer. |
| Badges | Motivating | Often weak evidence. |

### User Outcomes

- Install project dependencies reproducibly.
- Capture build logs, photos, commits, tests, and reflections.
- Map evidence to skill nodes.
- Publish verified project achievements.
- Reuse local project memory in future learning.

### Opportunity Scoring

| Outcome | Importance | Current Satisfaction | Opportunity Score |
|---|---:|---:|---:|
| Reproducible project setup | 9 | 3 | 15 |
| Evidence-backed skills | 8 | 3 | 13 |
| Exportable portfolio artifacts | 8 | 5 | 11 |
| Mentor review workflow | 7 | 4 | 10 |
| Offline project continuity | 7 | 3 | 11 |

## 7. ViaDecide

### Functional Job

When I make learning, project, or career decisions, I want to record decision context and publish verified reputation events so that others can trust selected claims about my work.

### Emotional Job

I want my effort to be recognized fairly and not reduced to a single score or certificate.

### Social Job

I want to build a reputation that is credible to peers, mentors, institutions, and employers.

### Hiring Triggers

- Completing meaningful learning milestones.
- Applying to internships, cohorts, scholarships, or jobs.
- Seeking mentor feedback.
- Wanting to distinguish verified work from self-promotion.

### Firing Triggers

- Reputation events are too easy to fake.
- Publication exposes private data.
- External viewers do not trust the format.
- Review workflows are slow or opaque.

### Competitive Alternatives

| Alternative | Strength | Weakness |
|---|---|---|
| LinkedIn posts | Broad audience | Weak verification. |
| Certificates | Familiar | Often low evidence depth. |
| GitHub activity | Technical evidence | Not suitable for all learning and weak identity linkage. |
| Digital badges | Portable | Quality varies widely. |

### User Outcomes

- Publish signed achievements derived from verified activity.
- Attach evidence references without leaking private records.
- Maintain revocation and correction history.
- Build cumulative reputation across products.

### Opportunity Scoring

| Outcome | Importance | Current Satisfaction | Opportunity Score |
|---|---:|---:|---:|
| Credible reputation proof | 9 | 3 | 15 |
| Selective disclosure | 8 | 2 | 14 |
| Evidence-linked achievements | 9 | 4 | 14 |
| Correction and revocation | 7 | 2 | 12 |
| Cross-product reputation | 8 | 3 | 13 |

## 8. Zayvora

### Functional Job

When I learn across time and applications, I want a runtime memory layer that remembers context, goals, prior progress, and evidence so that each environment can adapt intelligently.

### Emotional Job

I want the system to feel like it knows my learning journey without trapping me in a proprietary black box.

### Social Job

I want to be seen as a learner with a coherent history, not a collection of disconnected scores.

### Hiring Triggers

- Learner returns after a long gap.
- Multiple learning apps need shared context.
- User wants adaptive recommendations based on real progress.
- Mentor needs concise historical context.

### Firing Triggers

- Memory feels creepy, inaccurate, or non-transparent.
- Users cannot inspect, correct, or delete memory.
- Memory increases lock-in.
- Performance degrades local usage.

### Competitive Alternatives

| Alternative | Strength | Weakness |
|---|---|---|
| App-specific recommendation engines | Optimized in-product | Siloed and often opaque. |
| Personal notes | User-owned | Manual and not machine-actionable. |
| AI chat history | Conversational | Weak provenance and portability. |
| LMS analytics | Institution-visible | Not learner-owned. |

### User Outcomes

- Resume learning with historical context.
- Inspect and correct memory records.
- Receive adaptive prompts based on verified progress.
- Keep memory local by default.
- Share selected memory-derived summaries with consent.

### Opportunity Scoring

| Outcome | Importance | Current Satisfaction | Opportunity Score |
|---|---:|---:|---:|
| Coherent long-term memory | 9 | 2 | 16 |
| Inspectable and correctable memory | 8 | 2 | 14 |
| Adaptive recommendations | 8 | 5 | 11 |
| Local-first privacy | 9 | 3 | 15 |
| Cross-app continuity | 9 | 3 | 15 |

## 9. Portfolio Opportunity Prioritization

| Product | Highest Opportunity | Score | MVP Priority |
|---|---|---:|---|
| Lore Key | Install a complete environment quickly | 16 | P0 |
| Zayvora | Coherent long-term memory | 16 | P2 for full feature; P1 for data hooks |
| SkillHex | Reproducible project setup | 15 | P2 |
| PrepOS | Accurate weak-area diagnosis | 15 | P1 |
| ViaDecide | Credible reputation proof | 15 | P1 |
| StudyOS | Avoid tool fragmentation | 14 | P0 |

## 10. Strategic Implications

1. The MVP should prioritize activation, local installation, StudyOS state, and sync foundations because these unlock the rest of the product family.
2. Reputation should launch with narrow, high-integrity event types rather than broad claims.
3. Zayvora should begin as a local state and memory schema before adding advanced adaptive intelligence.
4. PrepOS and SkillHex require domain-quality bundles; platform readiness alone is insufficient.
5. The physical artifact must be positioned as an installer and identity anchor, not as a DRM storage device.
