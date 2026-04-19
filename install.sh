#!/usr/bin/env bash
set -euo pipefail

DEST_DIR="${HOME}/.claude/skills"
REPO_URL="https://github.com/Paerrin/hermes-CCC"

# When piped via curl, BASH_SOURCE[0] is unset — clone the repo to a temp dir
if [[ -z "${BASH_SOURCE[0]:-}" || ! -f "${BASH_SOURCE[0]}" ]]; then
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"' EXIT
  echo "Cloning ${REPO_URL} ..."
  git clone --depth 1 "${REPO_URL}" "${TMP_DIR}/hermes-CCC"
  SOURCE_DIR="${TMP_DIR}/hermes-CCC/skills"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  SOURCE_DIR="${SCRIPT_DIR}/skills"
fi

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "skills directory not found: ${SOURCE_DIR}" >&2
  exit 1
fi

mkdir -p "${DEST_DIR}"

installed=0

for skill_dir in "${SOURCE_DIR}"/*; do
  [[ -d "${skill_dir}" ]] || continue
  skill_name="$(basename "${skill_dir}")"
  target_dir="${DEST_DIR}/${skill_name}"
  rm -rf "${target_dir}"
  cp -R "${skill_dir}" "${target_dir}"
  installed=$((installed + 1))
  echo "Installed ${skill_name} -> ${target_dir}"
done

echo "Installed ${installed} skills into ${DEST_DIR}"
