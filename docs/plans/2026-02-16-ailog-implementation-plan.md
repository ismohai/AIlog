# AIlog Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an AIlog skill and PowerShell append script that writes one structured log line for each successful state-changing AI action.

**Architecture:** Keep policy in `SKILL.md` and deterministic write behavior in `scripts/ailog.ps1`. The assistant calls the script after each successful state-changing action. The script appends one line to `./AIlog/YYYY-MM-DD.log` and never rewrites or reads log history.

**Tech Stack:** Markdown skill instructions, PowerShell script, UTF-8 log files.

---

### Task 1: Create Skill Policy File

**Files:**
- Create: `SKILL.md`

**Step 1: Write the failing behavior checklist**

Create a checklist of baseline failures without this skill:
- Missing logs after successful changes
- Inconsistent event naming
- Secrets leaked in log values
- Reading logs during normal execution

**Step 2: Define minimal policy in SKILL.md**

Include:
- Trigger conditions
- Strict write/read rules
- Fixed event list
- Level mapping
- Redaction rule
- Command usage examples

**Step 3: Verify policy file exists and is readable**

Run: `powershell -NoProfile -Command "Test-Path .\\SKILL.md"`
Expected: `True`

### Task 2: Build Append Script

**Files:**
- Create: `scripts/ailog.ps1`

**Step 1: Write script interface**

Add positional args:
- level
- event
- action
- extra key=value pairs

**Step 2: Implement validation and redaction**

Validate level/event against fixed sets. Redact sensitive fields and command fragments.

**Step 3: Implement append-only writer**

Write one line to `./AIlog/YYYY-MM-DD.log` with generated `YYYY-MM-DD HH:mm:ss` timestamp.

**Step 4: Run syntax check**

Run:
`powershell -NoProfile -Command "$null=$t=$e=$null; [System.Management.Automation.Language.Parser]::ParseFile('.\\scripts\\ailog.ps1',[ref]$t,[ref]$e) > $null; if($e.Count -eq 0){'OK'}else{$e | % Message}"`

Expected: `OK`

### Task 3: Smoke Test End-to-End Logging

**Files:**
- Modify: `AIlog/YYYY-MM-DD.log` (generated)

**Step 1: Write a normal log line**

Run:
`powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\ailog.ps1 中 修改 "修改函数functest的计算公式为xxx。" "路径=src/main.ts"`

Expected: A new line appended to today log file.

**Step 2: Write a sensitive log line**

Run:
`powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\ailog.ps1 中 指令 "使用setx命令设置了环境变量TOKEN=abc123。" "命令=setx TOKEN abc123" "变量值=abc123"`

Expected: sensitive values are replaced with `<已脱敏>`.

**Step 3: Validate unsupported event fails**

Run:
`powershell -NoProfile -ExecutionPolicy Bypass -File .\\scripts\\ailog.ps1 中 创建 "测试"`

Expected: script exits with error `Invalid event`.
