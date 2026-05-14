#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_DIR="$ROOT_DIR/skills/topnetworks-sync-orchestrator"
OUTPUT_DIR="$ROOT_DIR/dist"

mkdir -p "$OUTPUT_DIR"

VERSION="$(tr -d '[:space:]' < "$SKILL_DIR/VERSION")"
SHORT_SHA="${GITHUB_SHA:-local}"
SHORT_SHA="${SHORT_SHA:0:7}"
TAG_VERSION="v${VERSION}-${SHORT_SHA}"
ARTIFACT_BASENAME="topnetworks-sync-orchestrator-${TAG_VERSION}"
ARTIFACT_DIR="$OUTPUT_DIR/$ARTIFACT_BASENAME"

rm -rf "$ARTIFACT_DIR"
mkdir -p "$ARTIFACT_DIR"

cp "$SKILL_DIR/SKILL.md" "$ARTIFACT_DIR/SKILL.md"
cp "$SKILL_DIR/manifest.json" "$ARTIFACT_DIR/manifest.json"
printf '%s\n' "$TAG_VERSION" > "$ARTIFACT_DIR/TAG_VERSION"

( cd "$OUTPUT_DIR" && tar -czf "${ARTIFACT_BASENAME}.tar.gz" "$ARTIFACT_BASENAME" )

( cd "$OUTPUT_DIR" && shasum -a 256 "${ARTIFACT_BASENAME}.tar.gz" | awk '{print $1}' > "${ARTIFACT_BASENAME}.sha256" )

cat <<REPORT
ARTIFACT_NAME=${ARTIFACT_BASENAME}.tar.gz
CHECKSUM_NAME=${ARTIFACT_BASENAME}.sha256
TAG_VERSION=${TAG_VERSION}
VERSION=${VERSION}
REPORT
