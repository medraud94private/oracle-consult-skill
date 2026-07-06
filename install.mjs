#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline/promises";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const repoRoot = path.dirname(__filename);

const options = {
  language: "auto",
  preset: "interactive",
  scope: "interactive",
  repoPath: process.cwd(),
  force: false,
  openOracle: false,
  noOpenOracle: false,
  noPrompt: false,
  oracleBrowserMode: "default",
};

const presets = new Set([
  "interactive",
  "all",
  "codex",
  "claude",
  "skills",
  "plugins",
  "codex-skill",
  "codex-plugin",
  "claude-skill",
  "claude-plugin",
  "oracle-login",
]);

function usage() {
  console.log(`Oracle Consult installer for Windows/macOS/Linux.

Usage:
  node install.mjs [options]
  install.cmd [options]

Options:
  --language ko|en|ja|auto     Installer language. Default: auto
  --preset NAME                all|codex|claude|skills|plugins|codex-skill|codex-plugin|claude-skill|claude-plugin|oracle-login|interactive
  --scope repo|user|interactive
                               repo is recommended. Default: interactive
  --repo-path PATH             Target repository for repo-scoped install. Default: current directory
  --force                      Overwrite existing install targets
  --open-oracle                Open Oracle browser login setup after install
  --no-open-oracle             Do not ask to open Oracle browser login setup
  --oracle-browser-mode MODE   default|hidden|attach|visible|render. Overrides installed config
  --no-prompt                  Non-interactive mode. Defaults to --preset all --scope repo
  -h, --help                   Show this help

Examples:
  install.cmd
  install.cmd --language ko --preset all --scope repo --repo-path C:\\path\\to\\repo --force --no-prompt
  install.cmd --language ja --preset all --scope repo --repo-path C:\\path\\to\\repo --force --no-prompt
  node install.mjs --language ko --preset all --scope user --force --no-prompt
`);
}

function parseArgs(argv) {
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    switch (arg) {
      case "--language":
      case "-l":
        options.language = argv[++i] ?? "";
        break;
      case "--preset":
        options.preset = argv[++i] ?? "";
        break;
      case "--scope":
        options.scope = argv[++i] ?? "";
        break;
      case "--repo-path":
        options.repoPath = argv[++i] ?? "";
        break;
      case "--force":
        options.force = true;
        break;
      case "--open-oracle":
        options.openOracle = true;
        break;
      case "--no-open-oracle":
        options.noOpenOracle = true;
        break;
      case "--no-prompt":
        options.noPrompt = true;
        break;
      case "--oracle-browser-mode":
        options.oracleBrowserMode = argv[++i] ?? "";
        break;
      case "--help":
      case "-h":
        usage();
        process.exit(0);
      default:
        throw new Error(`Unknown option: ${arg}`);
    }
  }

  if (!["auto", "ko", "en", "ja"].includes(options.language)) {
    throw new Error(`Invalid --language: ${options.language}`);
  }
  if (!presets.has(options.preset)) {
    throw new Error(`Invalid --preset: ${options.preset}`);
  }
  if (!["interactive", "repo", "user"].includes(options.scope)) {
    throw new Error(`Invalid --scope: ${options.scope}`);
  }
  if (options.openOracle && options.noOpenOracle) {
    throw new Error("Use either --open-oracle or --no-open-oracle, not both.");
  }
  if (!["default", "hidden", "attach", "visible", "render"].includes(options.oracleBrowserMode)) {
    throw new Error(`Invalid --oracle-browser-mode: ${options.oracleBrowserMode}`);
  }
}

parseArgs(process.argv.slice(2));

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

async function ask(prompt) {
  return (await rl.question(prompt)).trim();
}

function detectLanguageNoPrompt() {
  const locale = `${process.env.LC_ALL ?? ""}${process.env.LANG ?? ""}${process.env.LANGUAGE ?? ""}`;
  const normalized = locale.toLowerCase();
  if (normalized.startsWith("ko")) return "ko";
  if (normalized.startsWith("ja")) return "ja";
  return "en";
}

async function resolveLanguage() {
  if (options.language !== "auto") return options.language;
  if (options.noPrompt) return detectLanguageNoPrompt();

  console.log("");
  console.log("Choose language / 언어를 선택하세요");
  console.log("  [1] 한국어");
  console.log("  [2] English");
  console.log("  [3] 日本語");
  const choice = await ask("1/2/3 (default: 1): ");
  return choice === "2" ? "en" : choice === "3" ? "ja" : "ko";
}

const lang = await resolveLanguage();

const jaTextByEnglish = new Map([
  ["Choose what to install.", "インストールする内容を選択してください。"],
  ["  [1] Recommended: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin", "  [1] 推奨: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin"],
  ["  [2] Codex only: skill + plugin", "  [2] Codex のみ: skill + plugin"],
  ["  [3] Claude Code only: skill + plugin", "  [3] Claude Code のみ: skill + plugin"],
  ["  [4] Skills only: Codex skill + Claude Code skill", "  [4] Skills のみ: Codex skill + Claude Code skill"],
  ["  [5] Plugins only: Codex plugin + Claude Code plugin", "  [5] Plugins のみ: Codex plugin + Claude Code plugin"],
  ["  [6] Open Oracle browser login only", "  [6] Oracle ブラウザログインだけを開く"],
  ["  [7] Cancel", "  [7] キャンセル"],
  ["Choose install scope. Repository-level install is recommended.", "インストール範囲を選択してください。リポジトリ単位のインストールを推奨します。"],
  ["  [1] Recommended: install only into the current/target repository", "  [1] 推奨: 現在または指定したリポジトリにのみインストール"],
  ["  [2] Install globally for this user", "  [2] このユーザー全体にインストール"],
  ["Enter the target repository path.", "対象リポジトリのパスを入力してください。"],
  ["Prefer the actual work repository, not necessarily this installer repository.", "installer repo ではなく、実際に作業する repo を指定することを推奨します。"],
  ["Canceled.", "キャンセルしました。"],
  ["Starting Oracle Consult setup.", "Oracle Consult のセットアップを開始します。"],
  ["Install scope: global user", "インストール範囲: ユーザー全体"],
  ["Open Oracle's Chrome profile for ChatGPT login setup? You still sign in manually.", "Oracle 専用の Chrome プロファイルを開いて ChatGPT ログイン設定に進みますか? ログインは手動です。"],
  ["Setup complete.", "セットアップが完了しました。"],
  ["Only Oracle browser login setup was run.", "Oracle ブラウザログインの準備だけを実行しました。"],
  ["Open a new Codex/Claude Code session from that repository root.", "そのリポジトリルートから Codex/Claude Code を新しく開いて使ってください。"],
  ["It is available across repositories, but already-open sessions may need a new thread or restart.", "他のリポジトリでも利用できますが、既に開いているセッションは新しいスレッドまたは再起動が必要な場合があります。"],
  ["Codex skill: explicitly invoke $oracle-consult-skill.", "Codex skill: $oracle-consult-skill を明示的に呼び出します。"],
  ["Codex plugin: install Oracle Consult from /plugins, then invoke $oracle-consult in a new thread.", "Codex plugin: /plugins から Oracle Consult をインストールし、新しい thread で $oracle-consult を呼び出します。"],
  ["Claude Code skill: invoke /oracle-consult-skill.", "Claude Code skill: /oracle-consult-skill で呼び出します。"],
  ["Claude Code plugin: invoke /oracle-consult:oracle-consult.", "Claude Code plugin: /oracle-consult:oracle-consult で呼び出します。"],
]);

function text(ko, en, ja) {
  if (lang === "ko") return ko;
  if (lang === "ja") return ja ?? jaTextByEnglish.get(en) ?? en;
  return en;
}

function say(ko, en) {
  console.log(text(ko, en));
}

async function askYesNo(ko, en, defaultYes = false) {
  if (options.noPrompt) return defaultYes;
  const suffix = defaultYes ? "[Y/n]" : "[y/N]";
  const answer = await ask(`${text(ko, en)} ${suffix} `);
  if (!answer) return defaultYes;
  if (/^(y|yes|はい|ハイ)$/i.test(answer)) return true;
  return /^(y|yes|예|네|ㅇ|ㅖ)$/i.test(answer);
}

async function selectPreset() {
  if (options.preset !== "interactive") return options.preset;
  if (options.noPrompt) return "all";

  console.log("");
  say("설치할 대상을 선택하세요.", "Choose what to install.");
  say("  [1] 추천: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin", "  [1] Recommended: Codex skill + Codex plugin + Claude Code skill + Claude Code plugin");
  say("  [2] Codex만: skill + plugin", "  [2] Codex only: skill + plugin");
  say("  [3] Claude Code만: skill + plugin", "  [3] Claude Code only: skill + plugin");
  say("  [4] skill만: Codex skill + Claude Code skill", "  [4] Skills only: Codex skill + Claude Code skill");
  say("  [5] plugin만: Codex plugin + Claude Code plugin", "  [5] Plugins only: Codex plugin + Claude Code plugin");
  say("  [6] Oracle 브라우저 로그인만 열기", "  [6] Open Oracle browser login only");
  say("  [7] 취소", "  [7] Cancel");
  const choice = await ask("1-7 (default: 1): ");

  return {
    "2": "codex",
    "3": "claude",
    "4": "skills",
    "5": "plugins",
    "6": "oracle-login",
    "7": "cancel",
  }[choice] ?? "all";
}

async function selectScope() {
  if (options.scope !== "interactive") return options.scope;
  if (options.noPrompt) return "repo";

  console.log("");
  say("설치 범위를 선택하세요. 추천은 리포지터리별 설치입니다.", "Choose install scope. Repository-level install is recommended.");
  say("  [1] 추천: 현재/지정 리포지터리에만 설치", "  [1] Recommended: install only into the current/target repository");
  say("  [2] 사용자 전체에 설치", "  [2] Install globally for this user");
  const choice = await ask("1/2 (default: 1): ");
  return choice === "2" ? "user" : "repo";
}

async function resolveTargetRepoPath(scope) {
  if (scope !== "repo") return "";

  let repoPath = options.repoPath;
  if (!options.noPrompt) {
    console.log("");
    say("설치할 대상 리포지터리 경로를 입력하세요.", "Enter the target repository path.");
    say(`기본값: ${repoPath}`, `Default: ${repoPath}`);
    say("이 installer repo가 아니라 실제 작업 repo를 넣는 것을 권장합니다.", "Prefer the actual work repository, not necessarily this installer repository.");
    const answer = await ask("Repo path: ");
    if (answer) repoPath = answer;
  }

  const resolved = path.resolve(repoPath);
  if (!fs.existsSync(resolved) || !fs.statSync(resolved).isDirectory()) {
    throw new Error(`Repository path not found: ${resolved}`);
  }
  return resolved;
}

function ensureInside(base, target) {
  fs.mkdirSync(base, { recursive: true });
  fs.mkdirSync(path.dirname(target), { recursive: true });
  const baseReal = fs.realpathSync(base);
  const parentReal = fs.realpathSync(path.dirname(target));
  const targetReal = path.join(parentReal, path.basename(target));
  const withSep = baseReal.endsWith(path.sep) ? baseReal : `${baseReal}${path.sep}`;
  if (!targetReal.startsWith(withSep)) {
    throw new Error(`Refusing to write outside target base: ${targetReal}`);
  }
}

function copyDir(source, target, base) {
  if (!fs.existsSync(source) || !fs.statSync(source).isDirectory()) {
    throw new Error(`Source not found: ${source}`);
  }
  if (fs.existsSync(target) && !options.force) {
    throw new Error(`Target already exists: ${target}. Re-run with --force to overwrite.`);
  }

  ensureInside(base, target);
  fs.rmSync(target, { recursive: true, force: true });
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.cpSync(source, target, { recursive: true });
}

function cleanupLegacyStandaloneSkill(base) {
  const legacyTarget = path.join(base, "oracle-consult");
  const legacySkill = path.join(legacyTarget, "SKILL.md");
  if (!fs.existsSync(legacyTarget)) return;
  if (!fs.existsSync(legacySkill) || !fs.statSync(legacySkill).isFile()) {
    say(
      `기존 oracle-consult 경로가 있지만 Oracle Consult standalone skill로 확인되지 않아 남겨둡니다: ${legacyTarget}`,
      `Legacy oracle-consult path exists but was not recognized as this standalone skill, so it was left in place: ${legacyTarget}`,
    );
    return;
  }

  const text = fs.readFileSync(legacySkill, "utf8");
  const isLegacy = /^name:\s*oracle-consult\s*$/m.test(text) && text.includes("steipete/oracle");
  if (!isLegacy) {
    say(
      `기존 oracle-consult 경로가 있지만 안전 마커가 맞지 않아 남겨둡니다: ${legacyTarget}`,
      `Legacy oracle-consult path exists but did not match the safety marker, so it was left in place: ${legacyTarget}`,
    );
    return;
  }

  if (!options.force) {
    say(
      `기존 standalone oracle-consult가 남아 있습니다. 이름 충돌을 없애려면 --force로 다시 설치하세요: ${legacyTarget}`,
      `Legacy standalone oracle-consult remains. Re-run with --force to remove the old conflicting name: ${legacyTarget}`,
    );
    return;
  }

  ensureInside(base, legacyTarget);
  fs.rmSync(legacyTarget, { recursive: true, force: true });
  say(
    `기존 standalone oracle-consult 설치를 정리했습니다: ${legacyTarget}`,
    `Removed legacy standalone oracle-consult install: ${legacyTarget}`,
  );
}

function validateFile(file) {
  if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
    throw new Error(`Missing expected file: ${file}`);
  }
}

function applyOracleBrowserMode(skillRoot) {
  if (options.oracleBrowserMode === "default") return;
  const configPath = path.join(skillRoot, "oracle-consult.config.json");
  validateFile(configPath);
  const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
  config.browserMode = options.oracleBrowserMode;
  fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`, "utf8");
  say(
    `Oracle browser mode 설정: ${options.oracleBrowserMode} (${configPath})`,
    `Oracle browser mode configured: ${options.oracleBrowserMode} (${configPath})`,
  );
}

function writeCodexMarketplace(marketplacePath, name, displayName) {
  const data = {
    name,
    interface: { displayName },
    plugins: [
      {
        name: "oracle-consult",
        source: { source: "local", path: "./plugins/oracle-consult" },
        policy: { installation: "AVAILABLE", authentication: "ON_INSTALL" },
        category: "Productivity",
      },
    ],
  };
  fs.mkdirSync(path.dirname(marketplacePath), { recursive: true });
  fs.writeFileSync(marketplacePath, `${JSON.stringify(data, null, 2)}\n`, "utf8");
}

function installCodexSkill(scope, targetRepoPath) {
  const base = scope === "repo" ? path.join(targetRepoPath, ".agents", "skills") : path.join(os.homedir(), ".agents", "skills");
  const target = path.join(base, "oracle-consult-skill");
  cleanupLegacyStandaloneSkill(base);
  copyDir(path.join(repoRoot, "skills", "oracle-consult-skill"), target, base);
  validateFile(path.join(target, "SKILL.md"));
  applyOracleBrowserMode(target);
  say(`Codex skill 설치 완료: ${target}`, `Installed Codex skill: ${target}`);
}

function installCodexPlugin(scope, targetRepoPath) {
  const base = scope === "repo" ? path.join(targetRepoPath, ".agents", "plugins") : path.join(os.homedir(), ".agents", "plugins");
  const target = path.join(base, "plugins", "oracle-consult");
  copyDir(path.join(repoRoot, "plugins", "oracle-consult"), target, base);
  writeCodexMarketplace(
    path.join(base, "marketplace.json"),
    scope === "repo" ? "repo-local" : "personal",
    scope === "repo" ? "Repository Local" : "Personal",
  );
  validateFile(path.join(target, ".codex-plugin", "plugin.json"));
  applyOracleBrowserMode(path.join(target, "skills", "oracle-consult"));
  say(`Codex plugin 등록 완료: ${target}`, `Registered Codex plugin: ${target}`);
}

function installClaudeSkill(scope, targetRepoPath) {
  const base = scope === "repo" ? path.join(targetRepoPath, ".claude", "skills") : path.join(os.homedir(), ".claude", "skills");
  const target = path.join(base, "oracle-consult-skill");
  cleanupLegacyStandaloneSkill(base);
  copyDir(path.join(repoRoot, "claude", "skills", "oracle-consult-skill"), target, base);
  validateFile(path.join(target, "SKILL.md"));
  applyOracleBrowserMode(target);
  say(`Claude Code skill 설치 완료: ${target}`, `Installed Claude Code skill: ${target}`);
}

function installClaudePlugin(scope, targetRepoPath) {
  const base = scope === "repo" ? path.join(targetRepoPath, ".claude", "skills") : path.join(os.homedir(), ".claude", "skills");
  const target = path.join(base, "oracle-consult-plugin");
  copyDir(path.join(repoRoot, "claude", "plugins", "oracle-consult"), target, base);
  validateFile(path.join(target, ".claude-plugin", "plugin.json"));
  validateFile(path.join(target, "skills", "oracle-consult", "SKILL.md"));
  applyOracleBrowserMode(path.join(target, "skills", "oracle-consult"));
  say(`Claude Code plugin 설치 완료: ${target}`, `Installed Claude Code plugin: ${target}`);
}

function runOracleLogin() {
  const script = path.join(repoRoot, "scripts", "open-oracle-login.mjs");
  const result = spawnSync(process.execPath, [script, "--language", lang, "--yes"], {
    stdio: "inherit",
    shell: false,
  });
  if (result.status !== 0) process.exit(result.status ?? 1);
}

const selectedPreset = await selectPreset();
if (selectedPreset === "cancel") {
  say("취소했습니다.", "Canceled.");
  rl.close();
  process.exit(0);
}

const scope = selectedPreset === "oracle-login" ? "user" : await selectScope();
const targetRepoPath = selectedPreset === "oracle-login" ? "" : await resolveTargetRepoPath(scope);

say("Oracle Consult 설치를 시작합니다.", "Starting Oracle Consult setup.");
if (selectedPreset !== "oracle-login") {
  if (scope === "repo") {
    say(`설치 범위: 리포지터리별 (${targetRepoPath})`, `Install scope: repository-level (${targetRepoPath})`);
  } else {
    say("설치 범위: 사용자 전체", "Install scope: global user");
  }
}

switch (selectedPreset) {
  case "all":
    installCodexSkill(scope, targetRepoPath);
    installCodexPlugin(scope, targetRepoPath);
    installClaudeSkill(scope, targetRepoPath);
    installClaudePlugin(scope, targetRepoPath);
    break;
  case "codex":
    installCodexSkill(scope, targetRepoPath);
    installCodexPlugin(scope, targetRepoPath);
    break;
  case "claude":
    installClaudeSkill(scope, targetRepoPath);
    installClaudePlugin(scope, targetRepoPath);
    break;
  case "skills":
    installCodexSkill(scope, targetRepoPath);
    installClaudeSkill(scope, targetRepoPath);
    break;
  case "plugins":
    installCodexPlugin(scope, targetRepoPath);
    installClaudePlugin(scope, targetRepoPath);
    break;
  case "codex-skill":
    installCodexSkill(scope, targetRepoPath);
    break;
  case "codex-plugin":
    installCodexPlugin(scope, targetRepoPath);
    break;
  case "claude-skill":
    installClaudeSkill(scope, targetRepoPath);
    break;
  case "claude-plugin":
    installClaudePlugin(scope, targetRepoPath);
    break;
  case "oracle-login":
    options.openOracle = !options.noOpenOracle;
    break;
  default:
    throw new Error(`Unhandled preset: ${selectedPreset}`);
}

if (options.openOracle) {
  runOracleLogin();
} else if (!options.noOpenOracle) {
  const shouldOpenOracle = await askYesNo(
    "Oracle 전용 Chrome을 열어 ChatGPT 로그인 단계까지 진행할까요? 로그인은 직접 해야 합니다.",
    "Open Oracle's Chrome profile for ChatGPT login setup? You still sign in manually.",
    false,
  );
  if (shouldOpenOracle) runOracleLogin();
}

console.log("");
say("설치가 끝났습니다.", "Setup complete.");
if (selectedPreset === "oracle-login") {
  say("Oracle 브라우저 로그인 준비만 실행했습니다.", "Only Oracle browser login setup was run.");
} else if (scope === "repo") {
  say("해당 리포지터리 루트에서 Codex/Claude Code를 새로 열어 사용하세요.", "Open a new Codex/Claude Code session from that repository root.");
} else {
  say("다른 리포지터리에서도 보이지만, 이미 열린 세션은 새로 열거나 재시작해야 할 수 있습니다.", "It is available across repositories, but already-open sessions may need a new thread or restart.");
}
if (selectedPreset !== "oracle-login") {
  if (["all", "codex", "skills", "codex-skill"].includes(selectedPreset)) {
    say("Codex skill: $oracle-consult-skill 를 명시적으로 호출합니다.", "Codex skill: explicitly invoke $oracle-consult-skill.");
  }
  if (["all", "codex", "plugins", "codex-plugin"].includes(selectedPreset)) {
    say("Codex plugin: /plugins에서 Oracle Consult를 설치한 뒤 새 thread에서 $oracle-consult 를 호출합니다.", "Codex plugin: install Oracle Consult from /plugins, then invoke $oracle-consult in a new thread.");
  }
  if (["all", "claude", "skills", "claude-skill"].includes(selectedPreset)) {
    say("Claude Code skill: /oracle-consult-skill 로 호출합니다.", "Claude Code skill: invoke /oracle-consult-skill.");
  }
  if (["all", "claude", "plugins", "claude-plugin"].includes(selectedPreset)) {
    say("Claude Code plugin: /oracle-consult:oracle-consult 로 호출합니다.", "Claude Code plugin: invoke /oracle-consult:oracle-consult.");
  }
}

rl.close();
