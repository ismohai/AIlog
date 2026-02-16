# AIlog Design

## Goal

Create a reusable skill that records successful, state-changing AI actions as append-only daily logs to help cross-session and cross-tool troubleshooting.

## Confirmed Requirements

1. Store logs under current working directory in `./AIlog/`.
2. Rotate by day with file name `YYYY-MM-DD.log`.
3. Write one log entry immediately after each successful state-changing action.
4. Do not log failed actions.
5. Do not log pure read-only actions.
6. Do not log the act of writing logs itself.
7. Do not read logs during normal work; read only when user asks to debug and issue may be AI-caused.
8. Required fields per entry: `等级` `时间` `事件` `行为`.
9. Time format in entry: `YYYY-MM-DD HH:mm:ss`.
10. Event set is fixed: `移动` `复制` `修改` `覆盖` `下载/更新` `指令` `删除`.
11. For command executions, infer specific event first; fallback to `指令` only if unclear.
12. Level policy:
    - `低`: no actual content change (move/copy)
    - `中`: content change but usually recoverable (modify/download-update/most commands)
    - `高`: irreversible or destructive (overwrite/delete)
13. Keep schema localized (Chinese keys and event values).
14. Allow extra structured fields in `key=value` form.
15. Redact sensitive values by default.
16. Skill and script are stored together in one directory outside project roots.
17. Script is invoked directly (no global PATH requirement).

## Format Design

Each log entry is one line, append-only:

`等级="中" 时间="2026-02-16 14:03:22" 事件="修改" 行为="修改函数functest的计算公式为xxx。" 路径="src/main.ts"`

Rationale:
- Human-readable sentence in `行为`.
- Structured key/value for reliable AI parsing and filtering.
- Single-line record simplifies grep and diffs.

## Architecture

1. `SKILL.md` defines policy and usage rules.
2. `scripts/ailog.ps1` appends validated entries to the daily file.
3. Calling agent decides *when* to log (only after successful state change).
4. Script decides *how* to log (timestamp, path, append, escaping, redaction).

## Safety Rules

1. Sensitive keys and command fragments are redacted (`<已脱敏>`).
2. Script never edits existing lines and never reads log files.
3. Reserved keys (`等级/时间/事件/行为`) cannot be overridden by extras.

## Out of Scope (v1)

1. Global multi-project aggregation.
2. Automatic command interception at shell layer.
3. File locking across separate processes.
