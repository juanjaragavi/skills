# skills

Canonical, versioned skill distribution repository.

## topnetworks-sync-orchestrator

Source files:
- `skills/topnetworks-sync-orchestrator/SKILL.md`
- `skills/topnetworks-sync-orchestrator/VERSION`
- `skills/topnetworks-sync-orchestrator/manifest.json`

Release artifact flow:
- Every push to `main` that modifies the orchestrator package triggers GitHub Actions release workflow.
- Workflow builds a tarball and checksum and publishes them as a GitHub Release with tag:
  - `v<semantic-version>-<shortsha>`

## Local build

```bash
bash scripts/build-skill-artifact.sh
```

## Install into a project (pinned)

```bash
bash scripts/install-topnetworks-sync-orchestrator.sh /absolute/project/path v1.0.0-abcdef0 --from-local-repo /Users/macbookpro/GitHub/skills
```

## Remote install from GitHub Release

```bash
bash scripts/install-topnetworks-sync-orchestrator.sh /absolute/project/path v1.0.0-abcdef0
```
