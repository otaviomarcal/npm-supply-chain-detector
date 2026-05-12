#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const os = require("os");
const { spawnSync } = require("child_process");

const repoRoot = path.resolve(__dirname, "..");
const launcherPath = path.join(repoRoot, "nsc-scan.sh");

function candidateBashPaths() {
  const candidates = [];

  if (process.env.NSC_BASH_PATH) {
    candidates.push(process.env.NSC_BASH_PATH);
  }

  if (process.platform === "win32") {
    candidates.push("bash.exe");

    const programFiles = [
      process.env["ProgramFiles"],
      process.env["ProgramFiles(x86)"],
      process.env.LocalAppData
    ].filter(Boolean);

    for (const base of programFiles) {
      candidates.push(path.join(base, "Git", "bin", "bash.exe"));
      candidates.push(path.join(base, "Git", "usr", "bin", "bash.exe"));
      candidates.push(path.join(base, "Microsoft", "WindowsApps", "bash.exe"));
    }
  } else {
    candidates.push("bash");
    candidates.push("/usr/bin/bash");
    candidates.push("/bin/bash");
    candidates.push("/opt/homebrew/bin/bash");
    candidates.push("/usr/local/bin/bash");
  }

  return [...new Set(candidates)];
}

function canExecute(command) {
  if (!command) {
    return false;
  }

  if (command.includes(path.sep) || (process.platform === "win32" && command.includes("\\"))) {
    return fs.existsSync(command);
  }

  const probe = spawnSync(command, ["--version"], {
    stdio: "ignore",
    windowsHide: true
  });

  return !probe.error;
}

function findBash() {
  for (const candidate of candidateBashPaths()) {
    if (canExecute(candidate)) {
      return candidate;
    }
  }

  return null;
}

const bash = findBash();

if (!bash) {
  const guidance =
    process.platform === "win32"
      ? [
          "No compatible bash runtime was found.",
          "Install WSL or Git Bash, or set NSC_BASH_PATH to your bash executable.",
          "Example: set NSC_BASH_PATH=C:\\\\Program Files\\\\Git\\\\bin\\\\bash.exe"
        ]
      : [
          "No compatible bash runtime was found.",
          "Install Bash 5+ and try again.",
          "You can also set NSC_BASH_PATH to the bash executable."
        ];

  console.error(guidance.join(os.EOL));
  process.exit(1);
}

const result = spawnSync(bash, [launcherPath, ...process.argv.slice(2)], {
  stdio: "inherit",
  windowsHide: false
});

if (result.error) {
  console.error(`Failed to start bash runtime: ${result.error.message}`);
  process.exit(1);
}

process.exit(result.status ?? 1);
