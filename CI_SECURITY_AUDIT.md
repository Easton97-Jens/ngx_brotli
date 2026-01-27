# CI Security Audit

## Inventory (workflows, triggers, actions)

### `.github/workflows/build_test.yml` — Build/Test
- **Purpose:** Builds and tests the module across matrix entries (currently gcc-14 on Ubuntu 24.04).
- **Triggers:**
  - `push` to `master`
  - `pull_request` on `opened`, `reopened`, `labeled`, `synchronize`
- **Actions used:**
  - `actions/checkout` (pinned SHA)

### `.github/workflows/codeql.yml` — CodeQL
- **Purpose:** Static analysis for C/C++ and SARIF upload.
- **Triggers:**
  - `push` to `master`/`main`
  - `pull_request` to `master`/`main`
  - `schedule` weekly
- **Actions used:**
  - `actions/checkout` (pinned SHA)
  - `github/codeql-action` (init/analyze pinned SHA)

### `.github/workflows/dependabot-auto-approve.yaml` — Dependabot Auto-Approve (hardened)
- **Purpose:** Triage Dependabot PRs with labels/comments; auto-approve/merge disabled.
- **Triggers:**
  - `pull_request`
- **Actions used:**
  - `dependabot/fetch-metadata` (pinned SHA)

### `.github/workflows/dependency-review.yml` — Dependency Review
- **Purpose:** Blocks PRs that introduce risky dependency changes.
- **Triggers:**
  - `pull_request` on `opened`, `reopened`, `synchronize`
- **Actions used:**
  - `actions/checkout` (pinned SHA)
  - `actions/dependency-review-action` (pinned SHA)

### `.github/workflows/sbom.yml` — SBOM
- **Purpose:** Generates CycloneDX SBOM and uploads as artifact.
- **Triggers:**
  - `push` to `master`/`main`
  - `workflow_dispatch`
- **Actions used:**
  - `actions/checkout` (pinned SHA)
  - `anchore/sbom-action` (pinned SHA)
  - `actions/upload-artifact` (pinned SHA)

### `.github/workflows/scorecard.yml` — OpenSSF Scorecard
- **Purpose:** Informational security posture checks with SARIF upload.
- **Triggers:**
  - `branch_protection_rule`
  - `push` to `master`/`main`
  - `schedule` weekly
  - `workflow_dispatch`
- **Actions used:**
  - `actions/checkout` (pinned SHA)
  - `ossf/scorecard-action` (pinned SHA)
  - `github/codeql-action/upload-sarif` (pinned SHA)
  - `actions/upload-artifact` (pinned SHA)

## Risk assessment (before hardening)
- **Overbroad permissions:** Dependabot auto-approve used `contents: write` and `pull-requests: write` for all PRs.
- **Unpinned actions:** `actions/checkout@v6` and CodeQL actions were not pinned.
- **No concurrency limits:** PR workflows could overlap and waste capacity.
- **Dependabot auto-approve risk:** Automatic approval/merge enabled without conditions.
- **Missing dependency review:** No PR-time dependency review workflow.
- **SBOM missing:** No automated SBOM generation.

## Hardening actions applied
- **Least privilege permissions:** Workflows now use minimal `contents`/`pull-requests`/`issues`/`security-events` permissions.
- **Concurrency controls:** PR workflows now cancel in-progress runs for the same ref.
- **Actions pinned:** All actions are pinned to specific commit SHAs (see list below).
- **Dependabot auto-approve disabled:** Replaced with label/comment triage, restricted to Dependabot PRs.
- **Added dependency review:** New blocking dependency review workflow on PRs.
- **Added SBOM generation:** CycloneDX SBOM artifact generated on push.
- **Added Scorecard:** Informational security checks with SARIF upload.

## Pinned action SHAs
- `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683` (v4.2.2)
- `github/codeql-action@b20883b0cd1f46c72ae0ba6d1090936928f9fa30` (v4)
- `dependabot/fetch-metadata@21025c705c08248db411dc16f3619e6b5f9ea21a`
- `actions/dependency-review-action@3c4e3dcb1aa7874d2c16be7d79418e9b7efd6261` (v4)
- `anchore/sbom-action@251a468eed47e5082b105c3ba6ee500c0e65a764` (v0.17.6)
- `actions/upload-artifact@b4b15b8c7c6ac21ea08fcf65892d2ee8f75cf882` (v4.4.3)
- `ossf/scorecard-action@dc50aa9510b46c811795eb24b2f1ba02a914e534` (v2.3.3)

## Assumptions
- SBOM generation is currently source-based (no release workflow present to attach artifacts to releases).
- Dependency Review runs on PRs only and blocks risky dependency changes before merge.
