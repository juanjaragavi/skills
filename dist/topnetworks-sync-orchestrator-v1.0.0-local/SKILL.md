---
name: topnetworks-sync-orchestrator
description: Coordinate parity work across topfinanzas-us-next, uk-topfinanzas-com, topfinanzas-mx-next, and budgetbee-next for shared code, SEO/GEO/LLM indexing, analytics, ads, scripts, and documentation while preserving market-specific localization.
---

# TopNetworks Sync Orchestrator

Use this skill to manage multi-repo parity across the local TopNetworks Next.js properties while preserving market-specific localization, compliance, and brand requirements.

## Core resources

- The `docs-topnetworks-co` repository (`/Users/macbookpro/GitHub/docs-topnetworks-co`) is the single source of truth for TopNetworks Inc.'s technology stack, architecture, workflows, and operational standards. Its generated context files (`public/llms-full.txt` and `public/llms.txt`) should be consulted for architectural decisions, shared component patterns, and brand guidelines.
- `repositories.json` is the source of truth for repository paths, markets, domains, languages, validation commands, and adaptation rules.
- `SYNC_RUNBOOK.md` describes the propagation workflow, task classes, guardrails, and validation expectations.
- `scripts/topnetworks-sync.mjs` provides safe deterministic commands for listing repositories, checking status, auditing file parity, and running allowlisted validation scripts.
- `scripts/topnetworks-deploy.mjs` provides the synchronized deployment-readiness workflow. It audits git/deploy scripts, runs local preflight validation, and prints deployment plans without running production deployment commands.

Read `repositories.json` before changing any target repository. Read `SYNC_RUNBOOK.md` before executing a synchronized change.

## Project skill routing map

Use the central orchestrator as the entrypoint, then route implementation work to the repository-local skill that owns deep codebase behavior.

- **TopFinanzas US skill**: `/Users/macbookpro/GitHub/topfinanzas-us-next/.agents/skills/topfinanzas-us-next-agent/SKILL.md`
  - Invoke for US-local architecture, product pages, US compliance/copy, lead/API mappings, and ad/analytics behavior in `topfinanzas-us-next`.
  - Trigger when a task touches US-only routes, US listing arrays, US integration behavior, or US deployment-readiness details.
- **TopFinanzas MX skill**: `/Users/macbookpro/GitHub/topfinanzas-mx-next/.agents/skills/topfinanzas-mx-codebase/SKILL.md`
  - Invoke for MX-local routes under `/mx`, `basePath` invariants, MX SEO/canonical rules, `ALL_POSTS` listing behavior, and MX API/integration workflows.
  - Trigger when a task affects Spanish content, MX regulatory/localization requirements, or route handling unique to `topfinanzas-mx-next`.
- **TopFinance UK skill**: `/Users/macbookpro/GitHub/uk-topfinanzas-com/.github/skills/topfinance-uk-codebase-map/SKILL.md`
  - Invoke for UK architecture mapping, FCA-compliant wording constraints, en-GB/GBP adaptation, UK SEO registry updates, and UK analytics/ad stack specifics.
  - Trigger when a task touches UK-only content, UK API workflows, UK recommender/quiz route behavior, or UK deployment/readiness flow.
- **BudgetBee skill**: `/Users/macbookpro/GitHub/budgetbee-next/.agents/skills/budgetbee-codebase-ops/SKILL.md`
  - Invoke for BudgetBee-specific catalog/listing synchronization, SEO route registry updates, UTM/analytics flows, and BudgetBee brand/audience constraints.
  - Trigger when a task modifies `budgetbee-next` content catalogs, API pipelines, analytics wiring, or deployment-readiness checks.

Routing rule:

- If scope is single-repo, invoke that repo skill first.
- If scope is multi-repo or parity-sensitive, use this orchestrator to classify and coordinate, then delegate per-repo implementation to the mapped local skill.

Routing decision table:

| Task scope            | Primary skill                   | Delegation rule                                                        |
| --------------------- | ------------------------------- | ---------------------------------------------------------------------- |
| One repository only   | Matching repo-local skill       | Keep changes local unless parity is explicitly requested               |
| Multiple repositories | `topnetworks-sync-orchestrator` | Classify shared/localized scope, then delegate per-repo implementation |
| Unclear scope         | `topnetworks-sync-orchestrator` | Run classification first, then route to repo-local skill(s)            |

## Project-local orchestrator harmonization

The central orchestrator at `/Users/macbookpro/GitHub/.agents/skills/topnetworks-sync-orchestrator/SKILL.md` is authoritative and must stay synchronized with repository-local variants:

- `/Users/macbookpro/GitHub/topfinanzas-us-next/.agents/skills/topnetworks-sync-orchestrator/SKILL.md`
- `/Users/macbookpro/GitHub/topfinanzas-mx-next/.agents/skills/topnetworks-sync-orchestrator/SKILL.md`
- `/Users/macbookpro/GitHub/budgetbee-next/.agents/skills/topnetworks-sync-orchestrator/SKILL.md`
- `/Users/macbookpro/GitHub/docs-topnetworks-co/.agents/skills/topnetworks-sync-orchestrator/SKILL.md`

When reconciling variants, keep one unified interface here and preserve repo-specific requirements as conditional guidance:

- **US conditional guidance**:
  - Preserve GTM container isolation (`GTM-5568TKCX`) and do not generalize to shared GTM components.
  - Preserve approved ad activation flows (no manual `window.topAds.spa()` usage in page-level code).
- **MX conditional guidance**:
  - Preserve `basePath: "/mx"`, MX canonical/hreflang behavior, and noindex handling for funnel/test/admin paths.
  - Keep category/listing behavior aligned with `lib/data/posts.ts` (`ALL_POSTS`) and route metadata registry updates where applicable.
- **UK conditional guidance**:
  - Preserve en-GB, GBP, FCA-compliant wording, representative APR conventions, and UK-specific canonical domain handling.
  - Keep UK route-level metadata and sitemap integrity in sync with `lib/seo-route-registry.ts` and `lib/seo.ts` patterns.
- **BudgetBee conditional guidance**:
  - Preserve BudgetBee brand voice and audience framing (Gen-Z/Millennial).
  - Keep SEO route registry and duplicated listing arrays synchronized across discovery surfaces.

Cross-repo synchronization rule:

- Merge shared commands/workflows/guardrails into this central file.
- Keep repo-only implementation details inside each project skill and reference them through the routing map.

## Branch policy (Local vs. Remote)

It is CRITICAL to distinguish the local development lifecycle from the remote production lifecycle:

- **Local Development**: `dev` is the local development branch for each synchronized property. All feature work must be completed on `dev`. To prepare for deployment, the approved feature state is locally merged/synchronized with `main` (and the repository backup branch) and pushed to origin. The local working tree must always be returned to `dev` after synchronization so development can continue. The local `main` branch should ONLY be touched to push deployment updates.
- **Remote Production (Ubuntu Server)**: `main` is the production branch. The server-side deployment script (`scripts/deploy_update.sh`) operates strictly on the remote server, pulling the latest `main` changes from origin, building the app, and restarting PM2. Remote scripts do NOT handle local branch synchronization (`dev` -> `main`).

## Operating model

Follow this sequence for every sync task:

1. Establish the source of truth.
   - Consult the `docs-topnetworks-co` documentation site (`public/llms-full.txt`) for authoritative guidance on the technology stack, architecture, shared components, and operational standards.
   - Identify whether the change originates from one repository, a user instruction, or a new shared standard.
   - Inspect the current implementation in all four repositories before editing.
2. Classify the change.
   - Shared architecture: can be propagated with minimal adaptation.
   - Market-localized: requires language, currency, domain, route, disclosure, or regulatory adaptation.
   - Brand-localized: requires visual identity, voice, imagery, or audience adaptation.
   - Repo-specific: should not be propagated unless the user explicitly asks.
3. Build a propagation matrix.
   - For each repository, list target files, expected adaptation, validation command, and risk level.
   - Do not blindly copy code or text across markets.
4. Apply changes incrementally.
   - Prefer small, reviewable diffs.
   - Preserve existing local conventions and app structure.
   - Keep shared patterns aligned while leaving localized constants and copy intact.
5. Validate per repository.
   - At minimum, run the commands configured in `repositories.json` when practical.
   - For documentation-only changes, validate file existence and manifest/CLI behavior.

- If validation fails, stop propagation for the affected repository, provide a detailed error report, list corrective actions, and retry only after fixes are applied.

6. Report divergence.
   - Summarize what is now aligned.
   - Call out intentional differences, skipped repositories, and validation failures.

Use this decision shortcut to reduce ambiguity:

- If the task changes shared architecture, propagate to all four repos with localized constants and copy preserved.
- If the task changes market or brand behavior, apply only the localized adaptation for each target repo.
- If the task is repo-specific, do not propagate unless the user explicitly requests parity.

## Deployment readiness model

Use `scripts/topnetworks-deploy.mjs` for synchronized deployment preparation. Existing repo-local `scripts/deploy_update.sh` files are low-level server commands, not the agent's default deployment interface.

Before any deployment request:

1. Run `audit-scripts` to inspect the four repositories for interactive prompts, unsafe merge handling, missing validation gates, and server-only commands.
2. Run `preflight --execute` for every repository intended for deployment.
3. If preflight prints `AGENT_ACTION_REQUIRED`, fix the affected codebase before deployment.
4. Only produce or run a deployment command after explicit user natural-language authorization.
5. Ensure the approved **local** deployment preparation process synchronizes `dev`, `main`, and the repository backup branch, pushes to origin, and then returns the working tree to `dev`.
6. Only instruct or provide the remote `deploy_update.sh` command to update the production server _after_ local synchronization is pushed to origin.
7. Never answer shell `Y/N` prompts on the user's behalf. Prefer flag-driven or orchestrator-scoped commands.
8. If deployment partially fails, stop further deployment steps, report the exact failed repo and command, keep unaffected repos unchanged, and provide a rollback/recovery plan that restores the failed repo to the last known good `main` state before retry.

## Safety rules

- Validation rules:
  - Validation-only checks (`audit-scripts`, `preflight`) are allowed without explicit instruction.
  - If validation or synchronization fails, stop for the affected repository, report exact failing command/output, propose corrective actions, and do not continue deployment steps for that repository.
  - Do not run deployment scripts when validation fails. Deployment is blocked until lint, formatting checks, and build checks pass or the user explicitly narrows the requested scope.
- Deployment rules:
  - Do not commit, push, deploy, or run production deployment scripts unless the user explicitly asks.
  - Do not run `scripts/git-workflow.sh`, `scripts/deploy_update.sh`, or `scripts/sync-branches.sh` as part of ordinary sync implementation.
  - Use repository-specific git workflow scripts only when the user explicitly requests commit/push operations.
  - Do not leave a synchronized repository checked out on `main` or a backup branch after deployment; return it to `dev`.
- Execution rules:
  - Do not edit `.env`, `.env.local`, `.env.production`, secrets, credentials, or generated build output.
  - Always execute local git workflows using `cd /Users/macbookpro/GitHub/{top-networks-inc-site} && bash ./scripts/git-workflow.sh "$(cat lib/documents/commit-message.txt)"` when commit/push execution is explicitly requested. Ensure `lib/documents/commit-message.txt` is written beforehand so the workflow remains non-interactive and does not require shell prompt answers.
  - Keep all filesystem operations scoped to repositories listed in `repositories.json`.

## CLI quick reference

Run from the workspace root or from the skill directory:

```bash
node .agents/skills/topnetworks-sync-orchestrator/scripts/topnetworks-sync.mjs list
node .agents/skills/topnetworks-sync-orchestrator/scripts/topnetworks-sync.mjs status
node .agents/skills/topnetworks-sync-orchestrator/scripts/topnetworks-sync.mjs parity
node .agents/skills/topnetworks-sync-orchestrator/scripts/topnetworks-sync.mjs validate --dry-run
node .agents/skills/topnetworks-sync-orchestrator/scripts/topnetworks-sync.mjs run lint --dry-run
node .agents/skills/topnetworks-sync-orchestrator/scripts/topnetworks-deploy.mjs audit-scripts
node .agents/skills/topnetworks-sync-orchestrator/scripts/topnetworks-deploy.mjs preflight --dry-run
node .agents/skills/topnetworks-sync-orchestrator/scripts/topnetworks-deploy.mjs deployment-plan
```

Use `--execute` only after reviewing what will run.

Repository-local preflight wrappers (useful when validating one repository with its local integration context):

```bash
cd /Users/macbookpro/GitHub/topfinanzas-mx-next && node scripts/topnetworks-predeploy.mjs preflight --dry-run
cd /Users/macbookpro/GitHub/uk-topfinanzas-com && node scripts/topnetworks-predeploy.mjs preflight --dry-run
cd /Users/macbookpro/GitHub/budgetbee-next && node scripts/topnetworks-predeploy.mjs preflight --dry-run
```

## Typical user requests that should trigger this skill

- “Propagate this SEO refactor to the other TopFinanzas repos.”
- “Keep BudgetBee, UK, MX, and US in sync for metadata and llms.txt.”
- “Compare the shared component architecture across all properties.”
- “Run validation across the TopNetworks Next.js sites.”
- “Create a cross-repo workflow for synchronized changes.”

## Google Tag Manager (GTM) Architecture

To prevent cross-market container ID contamination and ensure strict adherence to Google's required DOM placement, GTM is implemented via hardcoded inline snippets rather than abstracted React components.
When working with analytics, layout, or head modifications, ensure the following rules are strictly maintained:

1. **Container IDs**:
   - TopFinance UK (`uk-topfinanzas-com`): `GTM-MR76NXR3`
   - TopFinanzas US (`topfinanzas-us-next`): `GTM-5568TKCX`
   - TopFinanzas MX (`topfinanzas-mx-next`): `GTM-K753GNBZ`
   - BudgetBee (`budgetbee-next`): `GTM-MP4CPT97`
2. **Placement**:
   - The primary GTM `<script>` MUST be hardcoded at the very top of the `<head>` in `app/layout.tsx` using `dangerouslySetInnerHTML`.
   - The fallback `<noscript>` iframe MUST be placed immediately after the opening `<body>` tag.
3. **No Abstractions**: Do NOT use `<GoogleTagManager />` components or third-party wrappers (like `@next/third-parties/google` or Partytown proxy components) for the core GTM snippet.
4. **Data Layer**: The data layer must exclusively be named `"dataLayer"`.

## Remote Deployment & Directory Mapping

When orchestrating deployments from local environments to the production server (`topfinanzas-com` via `gcloud compute ssh`), note the directory mappings:

- **TopFinanzas US**: Local `topfinanzas-us-next` -> Remote `/var/www/html/topfinanzas-us-next`
- **TopFinanzas UK**: Local `uk-topfinanzas-com` -> Remote `/var/www/html/uk`
- **TopFinanzas MX**: Local `topfinanzas-mx-next` -> Remote `/var/www/html/topfinanzas-mx-next`
- **BudgetBee**: Local `budgetbee-next` -> Remote `/var/www/html/budgetbee-next`

_Note: Ensure remote commands use `sudo git reset --hard HEAD` and `sudo git clean -fd` if the remote directory has unsaved changes blocking `git pull` from main._

## Agentic AI Deployment Prompts

You can use the following reusable prompts to instruct the orchestrator agent:

### 1. End-to-End Deployment (All Sites)

> "@SyncOrchestrator Please execute an end-to-end deployment for all TopNetworks properties (US, UK, MX, BudgetBee). For each property: 1. Write the commit message to `lib/documents/commit-message.txt`, then push local `dev` to origin `main` via `bash ./scripts/git-workflow.sh "$(cat lib/documents/commit-message.txt)"`. 2. SSH into the remote host. 3. Navigate to the correctly mapped remote directory in `/var/www/html/`. 4. Hard reset remote changes if necessary. 5. Run `sudo bash ./scripts/deploy_update.sh`. Report the build status for each site."

### 2. Single-Site Deployment

> "@SyncOrchestrator I have made changes to the `{{project_local_name}}` codebase. Please execute an end-to-end deployment. Write the commit message to `lib/documents/commit-message.txt` first. Ensure local changes are merged to main and pushed to origin using `bash ./scripts/git-workflow.sh "$(cat lib/documents/commit-message.txt)"`. Then SSH into the remote server, navigate to `{{project_remote_path}}`, resolve any dirty working tree states, and trigger `sudo bash ./scripts/deploy_update.sh`. Verify the Next.js compilation succeeds."

### 3. Batch Deployment (Subset of Sites)

> "@SyncOrchestrator We need to deploy updates to the following subset of sites: {{site_1_local}}, {{site_2_local}}, {{site_3_local}}. For each provided site: write the commit message to `lib/documents/commit-message.txt` and synchronize the local `dev` branch to `main` by running `bash ./scripts/git-workflow.sh "$(cat lib/documents/commit-message.txt)"`, push to origin, connect to the server via SSH, map the local name to its remote `/var/www/html/` directory, clear remote changes, and execute the deploy script. Summarize the deployment outputs."
