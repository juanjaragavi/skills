#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <target-project-path> <version-tag> [--from-local-repo <skills-repo-path>]"
  exit 1
fi

TARGET_PROJECT="$1"
VERSION_TAG="$2"
shift 2

LOCAL_REPO=""
if [[ ${1:-} == "--from-local-repo" ]]; then
  LOCAL_REPO="${2:-}"
fi

TARGET_DIR="$TARGET_PROJECT/.agents/skills/topnetworks-sync-orchestrator"
LOCK_FILE="$TARGET_PROJECT/.agents/skills-lock.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TARGET_DIR"

if [[ -n "$LOCAL_REPO" ]]; then
  REPO_DIST="$LOCAL_REPO/dist"
  ARTIFACT_PATH="$(find "$REPO_DIST" -maxdepth 1 -type f -name "topnetworks-sync-orchestrator-${VERSION_TAG}.tar.gz" | head -n1)"
  CHECKSUM_PATH="${ARTIFACT_PATH%.tar.gz}.sha256"
  if [[ -z "$ARTIFACT_PATH" || ! -f "$CHECKSUM_PATH" ]]; then
    echo "Artifact or checksum not found for version tag $VERSION_TAG in $REPO_DIST"
    exit 1
  fi
  cp "$ARTIFACT_PATH" "$TMP_DIR/artifact.tar.gz"
  cp "$CHECKSUM_PATH" "$TMP_DIR/artifact.sha256"
else
  if command -v gh >/dev/null 2>&1; then
    gh release download "$VERSION_TAG" -R topfinanzas/skills \
      -p "topnetworks-sync-orchestrator-${VERSION_TAG}.tar.gz" \
      -p "topnetworks-sync-orchestrator-${VERSION_TAG}.sha256" \
      -D "$TMP_DIR"
    mv "$TMP_DIR/topnetworks-sync-orchestrator-${VERSION_TAG}.tar.gz" "$TMP_DIR/artifact.tar.gz"
    mv "$TMP_DIR/topnetworks-sync-orchestrator-${VERSION_TAG}.sha256" "$TMP_DIR/artifact.sha256"
  else
    BASE_URL="https://github.com/topfinanzas/skills/releases/download/${VERSION_TAG}"
    curl -fsSL "$BASE_URL/topnetworks-sync-orchestrator-${VERSION_TAG}.tar.gz" -o "$TMP_DIR/artifact.tar.gz"
    curl -fsSL "$BASE_URL/topnetworks-sync-orchestrator-${VERSION_TAG}.sha256" -o "$TMP_DIR/artifact.sha256"
  fi
fi

EXPECTED_SUM="$(tr -d '[:space:]' < "$TMP_DIR/artifact.sha256")"
ACTUAL_SUM="$(shasum -a 256 "$TMP_DIR/artifact.tar.gz" | awk '{print $1}')"
if [[ "$EXPECTED_SUM" != "$ACTUAL_SUM" ]]; then
  echo "Checksum mismatch for ${VERSION_TAG}"
  echo "Expected: $EXPECTED_SUM"
  echo "Actual:   $ACTUAL_SUM"
  exit 1
fi

mkdir -p "$TMP_DIR/unpack"
tar -xzf "$TMP_DIR/artifact.tar.gz" -C "$TMP_DIR/unpack"
EXTRACTED_DIR="$(find "$TMP_DIR/unpack" -mindepth 1 -maxdepth 1 -type d | head -n1)"

cp "$EXTRACTED_DIR/SKILL.md" "$TARGET_DIR/SKILL.md"

mkdir -p "$(dirname "$LOCK_FILE")"
if [[ -f "$LOCK_FILE" ]]; then
  cp "$LOCK_FILE" "$TMP_DIR/lock.prev.json"
fi

cat > "$LOCK_FILE" <<LOCK
{
  "skills": {
    "topnetworks-sync-orchestrator": {
      "source": "topfinanzas/skills",
      "sourceType": "github-release",
      "versionTag": "${VERSION_TAG}",
      "computedHash": "${ACTUAL_SUM}",
      "targetPath": ".agents/skills/topnetworks-sync-orchestrator/SKILL.md"
    }
  }
}
LOCK

echo "Installed topnetworks-sync-orchestrator ${VERSION_TAG} into ${TARGET_PROJECT}"
