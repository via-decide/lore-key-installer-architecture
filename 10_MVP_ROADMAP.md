# 12-Month MVP Roadmap

## 1. Roadmap Overview

This roadmap sequences Lore Key from architecture through physical prototyping, identity activation, bundle installation, learning application integration, reputation, offline sync, and the Zayvora runtime layer. The plan assumes a lean cross-functional team with staged expansion.

```text
Month 1     Month 2     Month 3     Month 4     Month 5     Month 6
Phase 0 ─── Phase 1 ─── Phase 2 ─────────────── Phase 3 ───────────
Architecture Physical   Aporaksha Identity      Bundle Installer

Month 7     Month 8     Month 9     Month 10    Month 11    Month 12
Phase 4 ─── Phase 5 ─── Phase 6 ─── Phase 7 ─── Phase 8 ───────────
StudyOS     PrepOS      ViaDecide   Offline     Zayvora Runtime
```

## 2. Phase 0: Architecture

### Timeline

Month 1.

### Objectives

- Establish product, system, security, data, and API architecture.
- Define state machines, event flows, and MVP boundaries.
- Align stakeholders on physical artifact as environment installer.

### Deliverables

- Product Requirements Document.
- JTBD analysis.
- API specification.
- PostgreSQL schema.
- Event flow documentation.
- State machine documentation.
- Security model and threat matrix.
- Architecture review package.

### Dependencies

- Product leadership alignment.
- Initial assumptions about target learners and applications.
- Manufacturing feasibility inputs.

### Risks

- Over-scoping platform before validating activation and installation.
- Ambiguity between content container and environment installer.
- Security model mismatch with low-cost artifact constraints.

### Success Metrics

- Architecture review approved by product, engineering, security, and operations.
- MVP scope explicitly accepted.
- Top ten technical risks documented with owners.

### Estimated Effort

4-6 person-weeks.

### Team Composition

- Principal Architect.
- Product Manager.
- Security Architect.
- Backend Lead.
- Client/Installer Lead.
- Operations/Manufacturing Advisor.

## 3. Phase 1: Physical Lore Key Prototype

### Timeline

Months 2-3.

### Objectives

- Build physical prototypes using serialized QR, optional NFC, and 3D printable enclosure.
- Define manufacturing batch data model and QA process.
- Validate scan/tap usability across target devices.

### Deliverables

- 3D printable enclosure files.
- QR payload format specification.
- NFC payload format specification.
- Batch registration CSV/JSON format.
- Prototype run of 100-500 keys.
- Scan reliability test report.

### Dependencies

- Serial generation policy.
- Branding and packaging decisions.
- Supplier or maker-space access.

### Risks

- QR labels degrade or scan poorly.
- NFC tags vary in reliability.
- Physical artifact feels like a novelty rather than core product.
- Manufacturing metadata errors cause activation failures.

### Success Metrics

- >= 98% successful QR scans under normal lighting.
- >= 95% successful NFC reads on compatible devices.
- Batch import produces zero duplicate serials.
- Prototype BOM supports low-cost manufacturing target.

### Estimated Effort

8-10 person-weeks.

### Team Composition

- Hardware/Industrial Designer.
- Operations Lead.
- Backend Engineer for batch tooling.
- QA Engineer.
- Product Designer.

## 4. Phase 2: Aporaksha Identity Service

### Timeline

Months 3-5.

### Objectives

- Implement activation, validation, state, lease, and device binding services.
- Build audit logging and admin status controls.
- Provide SDK/client contracts for installer integration.

### Deliverables

- `POST /activate` implementation.
- `POST /validate` implementation.
- `GET /state` implementation.
- Token and offline lease issuance.
- Device binding model.
- Admin batch import, suspend, revoke, and audit views.
- Integration test suite.

### Dependencies

- Database schema baseline.
- Physical key payload format.
- Authentication provider and secret management.

### Risks

- Recovery and device binding policies become too complex for MVP.
- Activation spikes exceed early infrastructure.
- QR-only assurance is misunderstood by stakeholders.

### Success Metrics

- Activation p95 under 5 seconds in staging.
- 10,000 activation simulation completes without data corruption.
- Revoked keys fail validation 100% of the time.
- Audit log coverage for all write endpoints.

### Estimated Effort

18-24 person-weeks.

### Team Composition

- Backend Lead.
- Backend Engineer.
- Security Engineer.
- QA Automation Engineer.
- DevOps Engineer.
- Product Manager.

## 5. Phase 3: Bundle Installer

### Timeline

Months 5-6.

### Objectives

- Build local installer capable of resolving, downloading, verifying, and installing signed bundles.
- Implement local state store and basic diagnostics.
- Prove that the key installs environments rather than storing content.

### Deliverables

- Desktop installer MVP.
- Bundle manifest schema.
- Signature and hash verification library.
- Resumable download manager.
- Local encrypted state store.
- Install checkpoint and rollback mechanism.
- Installer diagnostics report.

### Dependencies

- Aporaksha validation endpoint.
- Bundle Resolver manifest endpoint.
- Code signing and release pipeline.

### Risks

- Device diversity causes installation failures.
- Local encryption fallback is inconsistent across OSes.
- Download size creates poor experience in low-bandwidth environments.

### Success Metrics

- >= 85% successful install rate in pilot devices.
- 100% tampered manifest rejection in test suite.
- Interrupted downloads resume successfully in test scenarios.
- Install failure diagnostics identify root cause category >= 90% of the time.

### Estimated Effort

20-28 person-weeks.

### Team Composition

- Client/Installer Lead.
- Client Engineer.
- Backend Engineer.
- Security Engineer.
- QA Engineer.
- DevOps/Release Engineer.

## 6. Phase 4: StudyOS Integration

### Timeline

Month 7.

### Objectives

- Integrate StudyOS as the first installable learning environment.
- Capture lesson progress and basic achievements.
- Validate local-first StudyOS operation.

### Deliverables

- StudyOS bundle manifest and signed artifacts.
- Local runtime SDK integration.
- Lesson progress event schema.
- StudyOS environment state registration.
- Basic achievement generation.
- Pilot content bundle.

### Dependencies

- Installer MVP.
- Local event store.
- StudyOS application readiness.

### Risks

- StudyOS event model does not match platform state model.
- Offline UX is unclear.
- Progress analytics are too shallow to demonstrate value.

### Success Metrics

- StudyOS launches from installer successfully on pilot devices.
- Lesson completion events persist offline and sync later.
- Learners can resume last activity accurately.
- >= 30% of pilot learners complete at least one offline session.

### Estimated Effort

10-14 person-weeks.

### Team Composition

- StudyOS Engineer.
- Client Runtime Engineer.
- Backend Engineer.
- Product Designer.
- QA Engineer.

## 7. Phase 5: PrepOS Integration

### Timeline

Month 8.

### Objectives

- Integrate exam preparation workflows with offline attempts, section analytics, and revision state.
- Validate that competitive exam learners receive measurable value.

### Deliverables

- PrepOS bundle manifest.
- Question bank packaging policy.
- Attempt event schema.
- Topic weakness analytics.
- Offline mock test mode.
- Sync reconciliation for attempts.

### Dependencies

- Bundle installer.
- Local event and sync primitives.
- Licensed or internally produced question bank.

### Risks

- Question quality is insufficient.
- Offline question bank increases piracy risk.
- Learners distrust analytics.

### Success Metrics

- Offline mock tests complete without network dependency.
- Attempt events sync idempotently.
- Weak-topic report generated from accepted events.
- Pilot learners report improved clarity on revision priorities.

### Estimated Effort

12-16 person-weeks.

### Team Composition

- PrepOS Product Lead.
- Application Engineer.
- Backend Engineer.
- Assessment Content Specialist.
- QA Engineer.

## 8. Phase 6: ViaDecide Reputation

### Timeline

Month 9.

### Objectives

- Publish narrow, evidence-backed reputation events with learner consent.
- Establish reputation verification and revocation foundations.

### Deliverables

- Reputation event API.
- ViaDecide consent and preview UI.
- Evidence reference schema.
- Server signature for accepted events.
- Private sharing link or verifier endpoint.
- Revocation event model.

### Dependencies

- Achievement records from StudyOS or PrepOS.
- Sync acceptance for evidence events.
- Security review of public verification format.

### Risks

- Reputation claims are too broad for reliable verification.
- Privacy concerns reduce adoption.
- External verifiers do not understand trust levels.

### Success Metrics

- Accepted reputation events cite verified evidence 100% of the time.
- Users preview shared fields before publishing.
- Revocation status is visible to verifiers.
- No private notes appear in public/shared events by default.

### Estimated Effort

12-18 person-weeks.

### Team Composition

- Backend Engineer.
- ViaDecide Engineer.
- Security Engineer.
- Product Designer.
- Legal/Privacy Advisor.
- QA Engineer.

## 9. Phase 7: Offline Sync

### Timeline

Month 10.

### Objectives

- Harden offline event queueing, batch sync, conflict handling, and lease renewal.
- Support classroom and low-connectivity pilots.

### Deliverables

- Sync batch ingestion service.
- Local sync scheduler.
- Idempotent event processing.
- Conflict metadata model.
- Offline lease renewal flow.
- Backpressure and retry policies.
- Sync observability dashboard.

### Dependencies

- Local event store.
- Environment Service.
- Application event schemas.

### Risks

- Conflict rules are hard to explain to users.
- Large offline queues strain APIs when cohorts reconnect.
- Clock manipulation affects lease integrity.

### Success Metrics

- >= 95% sync success after 7-day offline pilot.
- Duplicate event submissions do not alter final state.
- Server backpressure is respected by clients.
- Lease expiry behavior is understandable in user testing.

### Estimated Effort

16-22 person-weeks.

### Team Composition

- Backend Lead.
- Client Runtime Engineer.
- Data Engineer.
- QA Automation Engineer.
- DevOps Engineer.

## 10. Phase 8: Zayvora Runtime Layer

### Timeline

Months 11-12.

### Objectives

- Introduce a local-first memory layer that connects identity, progress, achievements, and learning context.
- Provide inspectable, correctable memory records for future adaptive experiences.

### Deliverables

- Zayvora memory schema.
- Local memory store and source-event provenance.
- Memory inspection UI.
- Correction and supersession workflow.
- StudyOS and PrepOS memory adapters.
- Privacy controls for memory-derived sharing.

### Dependencies

- Stable local state model.
- Accepted progress and achievement events.
- Product policy for memory retention and deletion.

### Risks

- Memory feels opaque or invasive.
- Derived records are inaccurate.
- Local performance suffers if memory indexing is inefficient.
- Future AI expectations exceed MVP capabilities.

### Success Metrics

- Users can inspect memory records and source events.
- Users can correct memory without destroying provenance.
- StudyOS can resume with memory-informed context.
- No memory-derived summaries are shared without explicit consent.

### Estimated Effort

18-26 person-weeks.

### Team Composition

- Runtime/Local Data Engineer.
- Application Engineer.
- Product Designer.
- Privacy/Security Engineer.
- QA Engineer.
- Product Manager.

## 11. Cross-Phase Governance

| Governance Area | Cadence | Output |
|---|---|---|
| Architecture review | Monthly | Decision records and risk updates. |
| Security review | At each phase exit | Threat model deltas and penetration test findings. |
| Product review | Biweekly | Scope decisions and pilot feedback. |
| Manufacturing review | Phase 1 and launch gates | Batch QA and artifact readiness. |
| Data review | Before sync and reputation launches | Schema stability and privacy assessment. |

## 12. MVP Launch Criteria

- Physical key prototype has reliable scan/tap behavior.
- Aporaksha activation and validation are production-ready.
- Installer installs at least StudyOS using signed bundles.
- Local progress works offline and syncs later.
- Basic reputation event publishing is consented and evidence-linked.
- Admin tools can suspend, revoke, audit, and support recovery.
- Security controls pass launch review for the selected assurance tier.
