#!/usr/bin/env bash
set -euo pipefail

LANGUAGE="auto"
YES=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Open Oracle's browser login/setup flow.

Usage:
  ./scripts/open-oracle-login.sh [options]

Options:
  --language ko|en|auto
  --yes                  Skip confirmation
  --dry-run              Preview Oracle command without opening browser
  -h, --help             Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --language|-l)
      LANGUAGE="${2:-}"; shift 2 ;;
    --yes|-y)
      YES=1; shift ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1 ;;
  esac
done

case "$LANGUAGE" in auto|ko|en) ;; *) echo "Invalid --language: $LANGUAGE" >&2; exit 1 ;; esac

detect_language() {
  if [[ "$LANGUAGE" != "auto" ]]; then
    printf '%s\n' "$LANGUAGE"
  elif [[ "${LC_ALL:-${LANG:-}}" == ko* ]]; then
    printf '%s\n' "ko"
  else
    printf '%s\n' "en"
  fi
}

INSTALL_LANG="$(detect_language)"

text() {
  if [[ "$INSTALL_LANG" == "ko" ]]; then
    printf '%s' "$1"
  else
    printf '%s' "$2"
  fi
}

say() {
  text "$1" "$2"
  printf '\n'
}

if ! command -v npx >/dev/null 2>&1; then
  say "npx를 찾지 못했습니다. Node.js 24+를 먼저 설치하세요." "npx was not found. Install Node.js 24+ first." >&2
  exit 1
fi

if [[ "$YES" -ne 1 && "$DRY_RUN" -ne 1 ]]; then
  echo ""
  say "이 단계는 Oracle이 제어하는 보이는 Chrome 창을 열 수 있습니다." "This step can open a visible Chrome window controlled by Oracle."
  say "ChatGPT 로그인은 자동화하지 않습니다. 브라우저가 열리면 사용자가 직접 로그인해야 합니다." "ChatGPT sign-in is not automated. When the browser opens, sign in manually."
  say "로그인 확인용으로 비밀이 없는 작은 임시 파일과 짧은 프롬프트만 보냅니다." "It sends only a small non-secret temporary file and a short setup prompt."
  read -r -p "$(text "계속할까요? [y/N]" "Continue? [y/N]") " answer
  if [[ ! "$answer" =~ ^([yY]|yes|YES|예|네|ㅇ|ㅖ)$ ]]; then
    say "Oracle 브라우저 열기를 건너뜁니다." "Skipping Oracle browser setup."
    exit 0
  fi
fi

temp_file="$(mktemp "${TMPDIR:-/tmp}/oracle-consult-login-check.XXXXXX.txt")"
cleanup() {
  rm -f "$temp_file"
}
trap cleanup EXIT

cat > "$temp_file" <<'EOF'
Oracle Consult login setup check.
This temporary file intentionally contains no project data or secrets.
EOF

oracle_args=(
  -y
  @steipete/oracle
  --engine
  browser
  --browser-manual-login
  --browser-keep-browser
  -p
  "Oracle Consult login/setup check. If this reaches ChatGPT, reply OK only."
  --file
  "$temp_file"
)

if [[ "$DRY_RUN" -eq 1 ]]; then
  oracle_args+=(--dry-run summary --files-report)
else
  say "Oracle 브라우저 설정을 시작합니다. Chrome이 열리면 ChatGPT에 로그인하세요." "Starting Oracle browser setup. If Chrome opens, sign in to ChatGPT."
fi

npx "${oracle_args[@]}"
