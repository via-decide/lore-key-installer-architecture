# Formal State Machines

## 1. State Machine Principles

Lore Key is state-driven. All lifecycle changes must be explicit, auditable, and guarded. State machines prevent ambiguous behavior during offline use, recovery, suspension, and reputation publication.

## 2. Lore Key Lifecycle

### 2.1 State Diagram

```text
        manufacture
            │
            v
      ┌───────────┐   claim proof valid   ┌─────────┐   activation complete   ┌────────┐
      │ UNCLAIMED │──────────────────────>│ CLAIMED │────────────────────────>│ ACTIVE │
      └───────────┘                       └─────────┘                         └───┬────┘
            │                                  │                                   │
            │ admin revoke                     │ admin suspend                     │ admin suspend
            v                                  v                                   v
      ┌─────────┐                         ┌───────────┐<──────────────────────┌───────────┐
      │ REVOKED │<────────────────────────│ SUSPENDED │──── reinstate ───────>│  ACTIVE   │
      └─────────┘     admin revoke        └───────────┘                       └───────────┘
```

### 2.2 States

| State | Meaning |
|---|---|
| `UNCLAIMED` | Manufactured or registered but not bound to a user. |
| `CLAIMED` | Bound to a user but not fully active for environment installation. |
| `ACTIVE` | Valid for validation, bundle resolution, and offline lease issuance. |
| `SUSPENDED` | Temporarily blocked due to risk, support issue, or payment/entitlement dispute. |
| `REVOKED` | Permanently invalid for activation and validation. |

### 2.3 Transitions

| From | To | Trigger | Guards | Actions |
|---|---|---|---|---|
| `UNCLAIMED` | `CLAIMED` | Claim request | Valid key proof; not deleted; no prior claimant | Write user binding; audit claim. |
| `CLAIMED` | `ACTIVE` | Activation completion | Consent accepted; device bound; no risk hold | Issue token and lease; audit activation. |
| `ACTIVE` | `SUSPENDED` | Admin or risk event | Authorized actor; reason supplied | Deny new leases; audit suspension. |
| `SUSPENDED` | `ACTIVE` | Reinstatement | Risk resolved; actor authorized | Restore validation eligibility; audit. |
| Any non-revoked | `REVOKED` | Confirmed compromise | Authorized actor; reason supplied | Invalidate tokens; block installs; audit. |

### 2.4 Failure States

- Invalid proof: no transition.
- Duplicate claim: no transition; return conflict.
- Partial activation: remain `CLAIMED` until recovery reconciliation.
- Revoked key reactivation attempt: no transition.

### 2.5 Edge Cases

- QR code copied before sale: first activation may claim the key; anomaly detection and receipt verification are needed for disputes.
- NFC UID collision or unreliable reads: require serial fallback and proof hashing.
- Key replacement: old key moves to `REVOKED`; replacement starts `UNCLAIMED` and is administratively linked.

## 3. Environment Lifecycle

### 3.1 State Diagram

```text
┌────────┐ validate ┌────────────────┐ resolve/install ┌────────────┐ success ┌────────┐
│ LOCKED │─────────>│ AUTHENTICATING │────────────────>│ INSTALLING │───────>│ ACTIVE │
└────────┘          └───────┬────────┘                 └─────┬──────┘        └───┬────┘
    ▲                       │ auth fail                       │ failure             │ offline
    │                       v                                 v                     v
    │                  ┌────────┐                        ┌────────┐           ┌─────────┐
    └──── expired ─────│ LOCKED │<──── lease expired ────│ LOCKED │<──────────│ OFFLINE │
                       └────────┘                        └────────┘           └────┬────┘
                                                                                   │ lease expired
                                                                                   v
                                                                               ┌─────────┐
                                                                               │ EXPIRED │
                                                                               └─────────┘
```

### 3.2 States

| State | Meaning |
|---|---|
| `LOCKED` | Environment cannot run protected functions. |
| `AUTHENTICATING` | Installer/runtime is validating identity and lease. |
| `INSTALLING` | Bundle artifacts are downloading, verifying, and configuring. |
| `ACTIVE` | Environment is installed and lease-valid. |
| `OFFLINE` | Environment is running without network under a valid offline lease. |
| `EXPIRED` | Offline lease expired; protected functions locked until validation. |

### 3.3 Transitions

| From | To | Trigger | Guards | Actions |
|---|---|---|---|---|
| `LOCKED` | `AUTHENTICATING` | User launches or installs | Local identity present | Submit validation or inspect offline lease. |
| `AUTHENTICATING` | `INSTALLING` | Validation success and install requested | Active key; entitled bundle | Resolve manifest; begin install. |
| `INSTALLING` | `ACTIVE` | Installation success | All signatures and hashes valid | Register environment; create local state. |
| `ACTIVE` | `OFFLINE` | Network unavailable | Lease unexpired | Switch to offline mode; queue events. |
| `OFFLINE` | `ACTIVE` | Network restored | Validation succeeds | Sync events; renew lease. |
| `OFFLINE` | `EXPIRED` | Lease expiry | No valid renewal | Lock protected features. |
| `EXPIRED` | `AUTHENTICATING` | User reconnects | Credentials available | Validate and renew. |
| Any | `LOCKED` | Revocation or critical failure | Revoked key or tampered install | Disable protected features; audit. |

### 3.4 Guards

- Bundle signature must validate before `INSTALLING` can complete.
- Offline lease expiry must be checked against monotonic and wall-clock time where possible.
- Device binding must match local device key.
- Suspended keys may allow read-only access but not new installs.

### 3.5 Failure States and Edge Cases

- Clock rollback: shorten lease and require online validation.
- Install interrupted: remain `INSTALLING` with checkpoint metadata.
- Local database corruption: enter recovery mode and avoid writing further events.
- Revocation while offline: enforcement occurs at next sync/validation; reputation events during abusive window may be rejected.

## 4. User Lifecycle

### 4.1 State Diagram

```text
┌─────┐ activation ┌───────────┐ meaningful use ┌─────────┐ verified contributions ┌─────────────┐
│ NEW │──────────>│ ACTIVATED │───────────────>│ ENGAGED │───────────────────────>│ CONTRIBUTOR │
└─────┘           └───────────┘                └────┬────┘                         └──────┬──────┘
                                                    │ long-term completion                 │ program end
                                                    v                                      v
                                               ┌────────┐<────────────────────────────┌────────┐
                                               │ ALUMNI │        graduation/end        │ ALUMNI │
                                               └────────┘                             └────────┘
```

### 4.2 States

| State | Meaning |
|---|---|
| `NEW` | User record exists but no completed activation. |
| `ACTIVATED` | User has at least one active Lore Key and device binding. |
| `ENGAGED` | User has recorded learning activity beyond installation. |
| `CONTRIBUTOR` | User has verified achievements, projects, reviews, or reputation events. |
| `ALUMNI` | User completed a pathway, aged out of a cohort, or is primarily maintaining history. |

### 4.3 Transitions

| From | To | Trigger | Guards | Actions |
|---|---|---|---|---|
| `NEW` | `ACTIVATED` | Lore Key activated | Valid key and consent | Initialize profile and state store. |
| `ACTIVATED` | `ENGAGED` | Progress event accepted | Event passes validation | Update progress analytics. |
| `ENGAGED` | `CONTRIBUTOR` | Reputation event accepted | Evidence verified | Update reputation status. |
| `ENGAGED` | `ALUMNI` | Program completed | Completion criteria met | Archive active pathway; preserve records. |
| `CONTRIBUTOR` | `ALUMNI` | Program ended | User not active in current pathway | Preserve reputation and memory. |

### 4.4 Failure States

- User deletion request: mark `deleted_at` and pseudonymize nonessential identifiers; lifecycle is no longer used for active access.
- Fraud hold: user may remain in current lifecycle but capabilities are restricted by policy.
- Recovery hold: user status remains unchanged while device access is limited.

### 4.5 Edge Cases

- Multiple keys for one user: lifecycle should reflect highest valid engagement, not key count.
- Multiple users attempting same key: only one valid claim unless admin transfer occurs.
- Alumni reactivation: alumni can return to `ENGAGED` when a new pathway records activity.
