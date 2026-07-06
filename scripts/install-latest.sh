#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="${ORACLE_CONSULT_REPO_OWNER:-medraud94private}"
REPO_NAME="${ORACLE_CONSULT_REPO_NAME:-oracle-consult-skill}"
REF="${ORACLE_CONSULT_REF:-main}"
CALLER_PWD="$(pwd -P)"

usage() {
  cat <<'EOF'
Install or update Oracle Consult from the latest GitHub archive, without git clone/pull.

Run from the repository where you want repo-scoped installation:
  curl -fsSL https://raw.githubusercontent.com/medraud94private/oracle-consult-skill/main/scripts/install-latest.sh | bash

Default behavior with no arguments:
  --language auto --preset all --scope repo --repo-path "$PWD" --force --no-prompt --no-open-oracle

Installer language values: auto, ko, en, ja.
Oracle browser mode values: default, hidden, attach, visible, render.

Pass normal install.sh arguments after `bash -s --` to override:
  curl -fsSL https://raw.githubusercontent.com/medraud94private/oracle-consult-skill/main/scripts/install-latest.sh \
    | bash -s -- --language ja --preset plugins --scope repo --force --no-prompt --no-open-oracle --oracle-browser-mode attach
EOF
}

has_arg() {
  local needle="$1"
  shift || true
  local arg
  for arg in "$@"; do
    if [[ "$arg" == "$needle" || "$arg" == "$needle="* ]]; then
      return 0
    fi
  done
  return 1
}

arg_value() {
  local key="$1"
  shift || true
  local previous=""
  local arg
  for arg in "$@"; do
    if [[ "$previous" == "$key" ]]; then
      printf '%s\n' "$arg"
      return 0
    fi
    case "$arg" in
      "$key="*)
        printf '%s\n' "${arg#*=}"
        return 0
        ;;
    esac
    previous="$arg"
  done
  return 1
}

if has_arg "--help" "$@" || has_arg "-h" "$@"; then
  usage
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required for install-latest.sh" >&2
  exit 1
fi
if ! command -v tar >/dev/null 2>&1; then
  echo "tar is required for install-latest.sh" >&2
  exit 1
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/oracle-consult-latest.XXXXXX")"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

archive="$tmp_dir/source.tar.gz"
url="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${REF}.tar.gz"
echo "Downloading Oracle Consult ${REF} from ${REPO_OWNER}/${REPO_NAME}..."
curl -fsSL "$url" -o "$archive"
tar -xzf "$archive" -C "$tmp_dir"

source_dir="$(find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d -name "${REPO_NAME}-*" | head -n 1)"
if [[ -z "$source_dir" || ! -f "$source_dir/install.sh" ]]; then
  echo "Downloaded archive did not contain install.sh" >&2
  exit 1
fi

chmod +x "$source_dir/install.sh" "$source_dir/scripts/open-oracle-login.sh" 2>/dev/null || true

install_args=("$@")
if [[ "${#install_args[@]}" -eq 0 ]]; then
  install_args=(--language auto --preset all --scope repo --repo-path "$CALLER_PWD" --force --no-prompt --no-open-oracle)
else
  scope="$(arg_value "--scope" "${install_args[@]}" || true)"
  preset="$(arg_value "--preset" "${install_args[@]}" || true)"
  if [[ "$scope" != "user" && "$preset" != "oracle-login" ]] && ! has_arg "--repo-path" "${install_args[@]}"; then
    install_args+=(--repo-path "$CALLER_PWD")
  fi
fi

echo "Installing into default repo path: $CALLER_PWD"
exec "$source_dir/install.sh" "${install_args[@]}"
