#!/usr/bin/env bash
set -euo pipefail

LANGUAGE="auto"
PRESET="interactive"
SCOPE="interactive"
REPO_PATH="$PWD"
FORCE=0
OPEN_ORACLE=0
NO_OPEN_ORACLE=0
NO_PROMPT=0

usage() {
  cat <<'EOF'
Oracle Consult installer for macOS/Linux.

Usage:
  ./install.sh [options]

Options:
  --language ko|en|ja|auto     Installer language. Default: auto
  --preset NAME                all|codex|claude|skills|plugins|codex-skill|codex-plugin|claude-skill|claude-plugin|oracle-login|interactive
  --scope repo|user|interactive
                               repo is recommended. Default: interactive
  --repo-path PATH             Target repository for repo-scoped install. Default: current directory
  --force                      Overwrite existing install targets
  --open-oracle                Open Oracle browser login setup after install
  --no-open-oracle             Do not ask to open Oracle browser login setup
  --no-prompt                  Non-interactive mode. Defaults to --preset all --scope repo
  -h, --help                   Show this help

Examples:
  ./install.sh
  ./install.sh --language ko --preset all --scope repo --repo-path /path/to/repo --force --no-prompt
  ./install.sh --language ja --preset all --scope repo --repo-path /path/to/repo --force --no-prompt
  ./install.sh --language ko --preset all --scope user --force --no-prompt
  ./install.sh --language ko --preset all --scope repo --repo-path /path/to/repo --force --no-prompt --open-oracle
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --language|-l)
      LANGUAGE="${2:-}"; shift 2 ;;
    --preset)
      PRESET="${2:-}"; shift 2 ;;
    --scope)
      SCOPE="${2:-}"; shift 2 ;;
    --repo-path)
      REPO_PATH="${2:-}"; shift 2 ;;
    --force)
      FORCE=1; shift ;;
    --open-oracle)
      OPEN_ORACLE=1; shift ;;
    --no-open-oracle)
      NO_OPEN_ORACLE=1; shift ;;
    --no-prompt)
      NO_PROMPT=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1 ;;
  esac
done

case "$LANGUAGE" in auto|ko|en|ja) ;; *) echo "Invalid --language: $LANGUAGE" >&2; exit 1 ;; esac
case "$PRESET" in interactive|all|codex|claude|skills|plugins|codex-skill|codex-plugin|claude-skill|claude-plugin|oracle-login) ;; *) echo "Invalid --preset: $PRESET" >&2; exit 1 ;; esac
case "$SCOPE" in interactive|repo|user) ;; *) echo "Invalid --scope: $SCOPE" >&2; exit 1 ;; esac
if [[ "$OPEN_ORACLE" -eq 1 && "$NO_OPEN_ORACLE" -eq 1 ]]; then
  echo "Use either --open-oracle or --no-open-oracle, not both." >&2
  exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

detect_language() {
  if [[ "$LANGUAGE" != "auto" ]]; then
    printf '%s\n' "$LANGUAGE"
    return
  fi

  if [[ "$NO_PROMPT" -eq 0 ]]; then
    echo "" >&2
    echo "Choose language / 언어를 선택하세요" >&2
    echo "  [1] 한국어" >&2
    echo "  [2] English" >&2
    echo "  [3] 日本語" >&2
    read -r -p "1/2/3 (default: 1): " choice
    if [[ "$choice" == "2" ]]; then
      printf '%s\n' "en"
    elif [[ "$choice" == "3" ]]; then
      printf '%s\n' "ja"
    else
      printf '%s\n' "ko"
    fi
    return
  fi

  if [[ "${LC_ALL:-${LANG:-}}" == ko* ]]; then
    printf '%s\n' "ko"
  elif [[ "${LC_ALL:-${LANG:-}}" == ja* ]]; then
    printf '%s\n' "ja"
  else
    printf '%s\n' "en"
  fi
}

INSTALL_LANG="$(detect_language)"

ja_text() {
  case "$1" in
    "Choose what to install.") printf '%s' "インストールする内容を選択してください。" ;;
    "  [1] Recommended: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin") printf '%s' "  [1] 推奨: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin" ;;
    "  [2] Codex only: skill + plugin") printf '%s' "  [2] Codex のみ: skill + plugin" ;;
    "  [3] Claude Code only: skill + plugin") printf '%s' "  [3] Claude Code のみ: skill + plugin" ;;
    "  [4] Skills only: Codex skill + Claude Code skill") printf '%s' "  [4] Skills のみ: Codex skill + Claude Code skill" ;;
    "  [5] Plugins only: Codex plugin + Claude Code plugin") printf '%s' "  [5] Plugins のみ: Codex plugin + Claude Code plugin" ;;
    "  [6] Open Oracle browser login only") printf '%s' "  [6] Oracle ブラウザログインだけを開く" ;;
    "  [7] Cancel") printf '%s' "  [7] キャンセル" ;;
    "Choose install scope. Repository-level install is recommended.") printf '%s' "インストール範囲を選択してください。リポジトリ単位のインストールを推奨します。" ;;
    "  [1] Recommended: install only into the current/target repository") printf '%s' "  [1] 推奨: 現在または指定したリポジトリにのみインストール" ;;
    "  [2] Install globally for this user") printf '%s' "  [2] このユーザー全体にインストール" ;;
    "Enter the target repository path.") printf '%s' "対象リポジトリのパスを入力してください。" ;;
    "Prefer the actual work repository, not necessarily this installer repository.") printf '%s' "installer repo ではなく、実際に作業する repo を指定することを推奨します。" ;;
    "Canceled.") printf '%s' "キャンセルしました。" ;;
    "Starting Oracle Consult setup.") printf '%s' "Oracle Consult のセットアップを開始します。" ;;
    "Install scope: global user") printf '%s' "インストール範囲: ユーザー全体" ;;
    "Open Oracle's Chrome profile for ChatGPT login setup? You still sign in manually.") printf '%s' "Oracle 専用の Chrome プロファイルを開いて ChatGPT ログイン設定に進みますか? ログインは手動です。" ;;
    "Setup complete.") printf '%s' "セットアップが完了しました。" ;;
    "Only Oracle browser login setup was run.") printf '%s' "Oracle ブラウザログインの準備だけを実行しました。" ;;
    "Open a new Codex/Claude Code session from that repository root.") printf '%s' "そのリポジトリルートから Codex/Claude Code を新しく開いて使ってください。" ;;
    "It is available across repositories, but already-open sessions may need a new thread or restart.") printf '%s' "他のリポジトリでも利用できますが、既に開いているセッションは新しいスレッドまたは再起動が必要な場合があります。" ;;
    "Codex skill: explicitly invoke \$oracle-consult-skill.") printf '%s' "Codex skill: \$oracle-consult-skill を明示的に呼び出します。" ;;
    "Codex plugin: install Oracle Consult from /plugins, then invoke \$oracle-consult in a new thread.") printf '%s' "Codex plugin: /plugins から Oracle Consult をインストールし、新しい thread で \$oracle-consult を呼び出します。" ;;
    "Claude Code skill: invoke /oracle-consult-skill.") printf '%s' "Claude Code skill: /oracle-consult-skill で呼び出します。" ;;
    "Claude Code plugin: invoke /oracle-consult:oracle-consult.") printf '%s' "Claude Code plugin: /oracle-consult:oracle-consult で呼び出します。" ;;
    *) printf '%s' "$1" ;;
  esac
}

text() {
  if [[ "$INSTALL_LANG" == "ko" ]]; then
    printf '%s' "$1"
  elif [[ "$INSTALL_LANG" == "ja" ]]; then
    ja_text "$2"
  else
    printf '%s' "$2"
  fi
}

say() {
  text "$1" "$2"
  printf '\n'
}

say_err() {
  text "$1" "$2" >&2
  printf '\n' >&2
}

ask_yes_no() {
  local ko="$1"
  local en="$2"
  local default_yes="${3:-0}"
  local suffix answer

  if [[ "$NO_PROMPT" -eq 1 ]]; then
    [[ "$default_yes" -eq 1 ]]
    return
  fi

  if [[ "$default_yes" -eq 1 ]]; then
    suffix="[Y/n]"
  else
    suffix="[y/N]"
  fi

  read -r -p "$(text "$ko" "$en") $suffix " answer
  if [[ -z "$answer" ]]; then
    [[ "$default_yes" -eq 1 ]]
    return
  fi
  if [[ "$answer" =~ ^([yY]|yes|YES|はい|ハイ)$ ]]; then
    return 0
  fi
  [[ "$answer" =~ ^([yY]|yes|YES|예|네|ㅇ|ㅖ)$ ]]
}

select_preset() {
  if [[ "$PRESET" != "interactive" ]]; then
    printf '%s\n' "$PRESET"
    return
  fi
  if [[ "$NO_PROMPT" -eq 1 ]]; then
    printf '%s\n' "all"
    return
  fi

  echo "" >&2
  say_err "설치할 대상을 선택하세요." "Choose what to install."
  say_err "  [1] 추천: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin" "  [1] Recommended: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin"
  say_err "  [2] Codex만: skill + plugin" "  [2] Codex only: skill + plugin"
  say_err "  [3] Claude Code만: skill + plugin" "  [3] Claude Code only: skill + plugin"
  say_err "  [4] skill만: Codex skill + Claude Code skill" "  [4] Skills only: Codex skill + Claude Code skill"
  say_err "  [5] plugin만: Codex plugin + Claude Code plugin" "  [5] Plugins only: Codex plugin + Claude Code plugin"
  say_err "  [6] Oracle 브라우저 로그인만 열기" "  [6] Open Oracle browser login only"
  say_err "  [7] 취소" "  [7] Cancel"
  read -r -p "1-7 (default: 1): " choice
  case "$choice" in
    2) printf '%s\n' "codex" ;;
    3) printf '%s\n' "claude" ;;
    4) printf '%s\n' "skills" ;;
    5) printf '%s\n' "plugins" ;;
    6) printf '%s\n' "oracle-login" ;;
    7) printf '%s\n' "cancel" ;;
    *) printf '%s\n' "all" ;;
  esac
}

select_scope() {
  if [[ "$SCOPE" != "interactive" ]]; then
    printf '%s\n' "$SCOPE"
    return
  fi
  if [[ "$NO_PROMPT" -eq 1 ]]; then
    printf '%s\n' "repo"
    return
  fi

  echo "" >&2
  say_err "설치 범위를 선택하세요. 추천은 리포지터리별 설치입니다." "Choose install scope. Repository-level install is recommended."
  say_err "  [1] 추천: 현재/지정 리포지터리에만 설치" "  [1] Recommended: install only into the current/target repository"
  say_err "  [2] 사용자 전체에 설치" "  [2] Install globally for this user"
  read -r -p "1/2 (default: 1): " choice
  if [[ "$choice" == "2" ]]; then
    printf '%s\n' "user"
  else
    printf '%s\n' "repo"
  fi
}

resolve_repo_path() {
  local path="$REPO_PATH"
  if [[ "$INSTALL_SCOPE" != "repo" ]]; then
    printf '%s\n' ""
    return
  fi

  if [[ "$NO_PROMPT" -eq 0 ]]; then
    echo "" >&2
    say_err "설치할 대상 리포지터리 경로를 입력하세요." "Enter the target repository path."
    say_err "기본값: $REPO_PATH" "Default: $REPO_PATH"
    say_err "이 installer repo가 아니라 실제 작업 repo를 넣는 것을 권장합니다." "Prefer the actual work repository, not necessarily this installer repository."
    read -r -p "Repo path: " input_path
    if [[ -n "$input_path" ]]; then
      path="$input_path"
    fi
  fi

  if [[ ! -d "$path" ]]; then
    echo "Repository path not found: $path" >&2
    exit 1
  fi
  (cd "$path" && pwd -P)
}

ensure_inside() {
  local base="$1"
  local target="$2"
  local base_real parent_real target_real
  mkdir -p "$base"
  base_real="$(cd "$base" && pwd -P)"
  mkdir -p "$(dirname "$target")"
  parent_real="$(cd "$(dirname "$target")" && pwd -P)"
  target_real="$parent_real/$(basename "$target")"
  case "$target_real/" in
    "$base_real"/*) ;;
    *) echo "Refusing to write outside target base: $target_real" >&2; exit 1 ;;
  esac
}

copy_dir() {
  local source="$1"
  local target="$2"
  local base="$3"

  if [[ ! -d "$source" ]]; then
    echo "Source not found: $source" >&2
    exit 1
  fi
  if [[ -e "$target" && "$FORCE" -ne 1 ]]; then
    echo "Target already exists: $target. Re-run with --force to overwrite." >&2
    exit 1
  fi

  ensure_inside "$base" "$target"
  if [[ -e "$target" ]]; then
    rm -rf "$target"
  fi
  mkdir -p "$(dirname "$target")"
  cp -R "$source" "$target"
}

cleanup_legacy_standalone_skill() {
  local base="$1"
  local legacy_target="$base/oracle-consult"
  local legacy_skill="$legacy_target/SKILL.md"

  if [[ ! -e "$legacy_target" ]]; then
    return
  fi
  if [[ ! -f "$legacy_skill" ]]; then
    say "기존 oracle-consult 경로가 있지만 Oracle Consult standalone skill로 확인되지 않아 남겨둡니다: $legacy_target" "Legacy oracle-consult path exists but was not recognized as this standalone skill, so it was left in place: $legacy_target"
    return
  fi
  if ! grep -Eq '^name:[[:space:]]*oracle-consult[[:space:]]*$' "$legacy_skill" || ! grep -q 'steipete/oracle' "$legacy_skill"; then
    say "기존 oracle-consult 경로가 있지만 안전 마커가 맞지 않아 남겨둡니다: $legacy_target" "Legacy oracle-consult path exists but did not match the safety marker, so it was left in place: $legacy_target"
    return
  fi
  if [[ "$FORCE" -ne 1 ]]; then
    say "기존 standalone oracle-consult가 남아 있습니다. 이름 충돌을 없애려면 --force로 다시 설치하세요: $legacy_target" "Legacy standalone oracle-consult remains. Re-run with --force to remove the old conflicting name: $legacy_target"
    return
  fi

  ensure_inside "$base" "$legacy_target"
  rm -rf "$legacy_target"
  say "기존 standalone oracle-consult 설치를 정리했습니다: $legacy_target" "Removed legacy standalone oracle-consult install: $legacy_target"
}

write_codex_marketplace() {
  local marketplace_path="$1"
  local marketplace_name="$2"
  local display_name="$3"
  mkdir -p "$(dirname "$marketplace_path")"
  cat > "$marketplace_path" <<EOF
{
  "name": "$marketplace_name",
  "interface": {
    "displayName": "$display_name"
  },
  "plugins": [
    {
      "name": "oracle-consult",
      "source": {
        "source": "local",
        "path": "./plugins/oracle-consult"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
EOF
}

validate_basic_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "Missing expected file: $file" >&2
    exit 1
  fi
}

install_codex_skill() {
  local base target source
  source="$SCRIPT_DIR/skills/oracle-consult-skill"
  if [[ "$INSTALL_SCOPE" == "repo" ]]; then
    base="$TARGET_REPO_PATH/.agents/skills"
  else
    base="$HOME/.agents/skills"
  fi
  target="$base/oracle-consult-skill"
  cleanup_legacy_standalone_skill "$base"
  copy_dir "$source" "$target" "$base"
  validate_basic_file "$target/SKILL.md"
  say "Codex skill 설치 완료: $target" "Installed Codex skill: $target"
}

install_codex_plugin() {
  local base target marketplace source name display
  source="$SCRIPT_DIR/plugins/oracle-consult"
  if [[ "$INSTALL_SCOPE" == "repo" ]]; then
    base="$TARGET_REPO_PATH/.agents/plugins"
    name="repo-local"
    display="Repository Local"
  else
    base="$HOME/.agents/plugins"
    name="personal"
    display="Personal"
  fi
  target="$base/plugins/oracle-consult"
  marketplace="$base/marketplace.json"
  copy_dir "$source" "$target" "$base"
  write_codex_marketplace "$marketplace" "$name" "$display"
  validate_basic_file "$target/.codex-plugin/plugin.json"
  validate_basic_file "$marketplace"
  say "Codex plugin 등록 완료: $target" "Registered Codex plugin: $target"
}

install_claude_skill() {
  local base target source
  source="$SCRIPT_DIR/claude/skills/oracle-consult-skill"
  if [[ "$INSTALL_SCOPE" == "repo" ]]; then
    base="$TARGET_REPO_PATH/.claude/skills"
  else
    base="$HOME/.claude/skills"
  fi
  target="$base/oracle-consult-skill"
  cleanup_legacy_standalone_skill "$base"
  copy_dir "$source" "$target" "$base"
  validate_basic_file "$target/SKILL.md"
  say "Claude Code skill 설치 완료: $target" "Installed Claude Code skill: $target"
}

install_claude_plugin() {
  local base target source
  source="$SCRIPT_DIR/claude/plugins/oracle-consult"
  if [[ "$INSTALL_SCOPE" == "repo" ]]; then
    base="$TARGET_REPO_PATH/.claude/skills"
  else
    base="$HOME/.claude/skills"
  fi
  target="$base/oracle-consult-plugin"
  copy_dir "$source" "$target" "$base"
  validate_basic_file "$target/.claude-plugin/plugin.json"
  validate_basic_file "$target/skills/oracle-consult/SKILL.md"
  say "Claude Code plugin 설치 완료: $target" "Installed Claude Code plugin: $target"
}

open_oracle_login() {
  local script="$SCRIPT_DIR/scripts/open-oracle-login.sh"
  if [[ ! -x "$script" ]]; then
    chmod +x "$script" 2>/dev/null || true
  fi
  "$script" --language "$INSTALL_LANG" --yes
}

SELECTED_PRESET="$(select_preset)"
if [[ "$SELECTED_PRESET" == "cancel" ]]; then
  say "취소했습니다." "Canceled."
  exit 0
fi

INSTALL_SCOPE="user"
TARGET_REPO_PATH=""
if [[ "$SELECTED_PRESET" != "oracle-login" ]]; then
  INSTALL_SCOPE="$(select_scope)"
  TARGET_REPO_PATH="$(resolve_repo_path)"
fi

say "Oracle Consult 설치를 시작합니다." "Starting Oracle Consult setup."
if [[ "$SELECTED_PRESET" != "oracle-login" ]]; then
  if [[ "$INSTALL_SCOPE" == "repo" ]]; then
    say "설치 범위: 리포지터리별 ($TARGET_REPO_PATH)" "Install scope: repository-level ($TARGET_REPO_PATH)"
  else
    say "설치 범위: 사용자 전체" "Install scope: global user"
  fi
fi

case "$SELECTED_PRESET" in
  all)
    install_codex_skill
    install_codex_plugin
    install_claude_skill
    install_claude_plugin ;;
  codex)
    install_codex_skill
    install_codex_plugin ;;
  claude)
    install_claude_skill
    install_claude_plugin ;;
  skills)
    install_codex_skill
    install_claude_skill ;;
  plugins)
    install_codex_plugin
    install_claude_plugin ;;
  codex-skill)
    install_codex_skill ;;
  codex-plugin)
    install_codex_plugin ;;
  claude-skill)
    install_claude_skill ;;
  claude-plugin)
    install_claude_plugin ;;
  oracle-login)
    if [[ "$NO_OPEN_ORACLE" -eq 0 ]]; then
      OPEN_ORACLE=1
    fi ;;
esac

if [[ "$OPEN_ORACLE" -eq 1 ]]; then
  open_oracle_login
elif [[ "$NO_OPEN_ORACLE" -eq 0 ]]; then
  if ask_yes_no "Oracle 전용 Chrome을 열어 ChatGPT 로그인 단계까지 진행할까요? 로그인은 직접 해야 합니다." "Open Oracle's Chrome profile for ChatGPT login setup? You still sign in manually." 0; then
    open_oracle_login
  fi
fi

echo ""
say "설치가 끝났습니다." "Setup complete."
if [[ "$SELECTED_PRESET" == "oracle-login" ]]; then
  say "Oracle 브라우저 로그인 준비만 실행했습니다." "Only Oracle browser login setup was run."
elif [[ "$INSTALL_SCOPE" == "repo" ]]; then
  say "해당 리포지터리 루트에서 Codex/Claude Code를 새로 열어 사용하세요." "Open a new Codex/Claude Code session from that repository root."
else
  say "다른 리포지터리에서도 보이지만, 이미 열린 세션은 새로 열거나 재시작해야 할 수 있습니다." "It is available across repositories, but already-open sessions may need a new thread or restart."
fi
if [[ "$SELECTED_PRESET" != "oracle-login" ]]; then
  case "$SELECTED_PRESET" in
    all|codex|skills|codex-skill)
      say "Codex skill: \$oracle-consult-skill 를 명시적으로 호출합니다." "Codex skill: explicitly invoke \$oracle-consult-skill." ;;
  esac
  case "$SELECTED_PRESET" in
    all|codex|plugins|codex-plugin)
      say "Codex plugin: /plugins에서 Oracle Consult를 설치한 뒤 새 thread에서 \$oracle-consult 를 호출합니다." "Codex plugin: install Oracle Consult from /plugins, then invoke \$oracle-consult in a new thread." ;;
  esac
  case "$SELECTED_PRESET" in
    all|claude|skills|claude-skill)
      say "Claude Code skill: /oracle-consult-skill 로 호출합니다." "Claude Code skill: invoke /oracle-consult-skill." ;;
  esac
  case "$SELECTED_PRESET" in
    all|claude|plugins|claude-plugin)
      say "Claude Code plugin: /oracle-consult:oracle-consult 로 호출합니다." "Claude Code plugin: invoke /oracle-consult:oracle-consult." ;;
  esac
fi
