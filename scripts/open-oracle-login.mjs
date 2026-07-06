#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline/promises";
import { spawnSync } from "node:child_process";

const options = {
  language: "auto",
  yes: false,
  dryRun: false,
};

function usage() {
  console.log(`Open Oracle's browser login/setup flow.

Usage:
  node scripts/open-oracle-login.mjs [options]
  scripts\\open-oracle-login.cmd [options]

Options:
  --language ko|en|ja|auto
  --yes                  Skip confirmation
  --dry-run              Preview Oracle command without opening browser
  -h, --help             Show help
`);
}

for (let i = 0; i < process.argv.slice(2).length; i += 1) {
  const argv = process.argv.slice(2);
  const arg = argv[i];
  switch (arg) {
    case "--language":
    case "-l":
      options.language = argv[++i] ?? "";
      break;
    case "--yes":
    case "-y":
      options.yes = true;
      break;
    case "--dry-run":
      options.dryRun = true;
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

function detectLanguage() {
  if (options.language !== "auto") return options.language;
  const locale = `${process.env.LC_ALL ?? ""}${process.env.LANG ?? ""}${process.env.LANGUAGE ?? ""}`;
  const normalized = locale.toLowerCase();
  if (normalized.startsWith("ko")) return "ko";
  if (normalized.startsWith("ja")) return "ja";
  return "en";
}

const lang = detectLanguage();
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

const jaTextByEnglish = new Map([
  ["This step can open a visible Chrome window controlled by Oracle.", "この手順では、Oracle が制御する表示状態の Chrome ウィンドウを開く場合があります。"],
  ["ChatGPT sign-in is not automated. When the browser opens, sign in manually.", "ChatGPT へのログインは自動化しません。ブラウザが開いたら手動でログインしてください。"],
  ["It sends only a small non-secret temporary file and a short setup prompt.", "送信するのは、秘密情報を含まない小さな一時ファイルと短いセットアップ用プロンプトだけです。"],
  ["Continue? [y/N]", "続行しますか? [y/N]"],
  ["Skipping Oracle browser setup.", "Oracle ブラウザ設定をスキップします。"],
  ["Starting Oracle browser setup. If Chrome opens, sign in to ChatGPT.", "Oracle ブラウザ設定を開始します。Chrome が開いたら ChatGPT にログインしてください。"],
]);

function text(ko, en, ja) {
  if (lang === "ko") return ko;
  if (lang === "ja") return ja ?? jaTextByEnglish.get(en) ?? en;
  return en;
}

function say(ko, en) {
  console.log(text(ko, en));
}

async function ask(prompt) {
  return (await rl.question(prompt)).trim();
}

if (!options.yes && !options.dryRun) {
  console.log("");
  say("이 단계는 Oracle이 제어하는 보이는 Chrome 창을 열 수 있습니다.", "This step can open a visible Chrome window controlled by Oracle.");
  say("ChatGPT 로그인은 자동화하지 않습니다. 브라우저가 열리면 사용자가 직접 로그인해야 합니다.", "ChatGPT sign-in is not automated. When the browser opens, sign in manually.");
  say("로그인 확인용으로 비밀이 없는 작은 임시 파일과 짧은 프롬프트만 보냅니다.", "It sends only a small non-secret temporary file and a short setup prompt.");
  const answer = await ask(`${text("계속할까요? [y/N]", "Continue? [y/N]")} `);
  if (!/^(y|yes|예|네|ㅇ|ㅖ|はい|ハイ)$/i.test(answer)) {
    say("Oracle 브라우저 열기를 건너뜁니다.", "Skipping Oracle browser setup.");
    rl.close();
    process.exit(0);
  }
}

const tempFile = path.join(os.tmpdir(), `oracle-consult-login-check-${process.pid}.txt`);
fs.writeFileSync(
  tempFile,
  "Oracle Consult login setup check.\nThis temporary file intentionally contains no project data or secrets.\n",
  "utf8",
);

const oracleArgs = [
  "-y",
  "@steipete/oracle",
  "--engine",
  "browser",
  "--browser-manual-login",
  "--browser-keep-browser",
  "-p",
  "HI",
  "--file",
  tempFile,
];

if (options.dryRun) {
  oracleArgs.push("--dry-run", "summary", "--files-report");
} else {
  say("Oracle 브라우저 설정을 시작합니다. Chrome이 열리면 ChatGPT에 로그인하세요.", "Starting Oracle browser setup. If Chrome opens, sign in to ChatGPT.");
}

try {
  let result;
  if (process.platform === "win32") {
    const quoteCmdArg = (value) => {
      const textValue = String(value);
      if (/^[A-Za-z0-9@._:\/\\-]+$/.test(textValue)) return textValue;
      return `"${textValue.replace(/(["^&|<>])/g, "^$1")}"`;
    };
    const npmExecArgs = ["exec", "--yes", "--package", "@steipete/oracle", "--", "oracle", ...oracleArgs.slice(2)];
    const commandLine = `npm ${npmExecArgs.map(quoteCmdArg).join(" ")}`;
    result = spawnSync(process.env.ComSpec || "cmd.exe", ["/d", "/c", commandLine], {
      stdio: "inherit",
      shell: false,
    });
  } else {
    result = spawnSync("npx", oracleArgs, {
      stdio: "inherit",
      shell: false,
    });
  }
  if (result.error) {
    throw result.error;
  }
  if (result.status !== 0) process.exit(result.status ?? 1);
} finally {
  fs.rmSync(tempFile, { force: true });
  rl.close();
}
