# AIlog Skill

AIlog 是一个用于记录 AI 助手“成功且确实改变状态”的操作的技能（Skill）。

它会在每次成功操作后，向当前工作目录下的 `./AIlog/YYYY-MM-DD.log` 追加一行日志，便于跨对话/跨工具定位问题来源。

## 内容

- Skill 目录：`AIlog/`
- 追加脚本：`AIlog/scripts/ailog.ps1`
- Windows 包装器（无需配置 PATH）：`AIlog/scripts/ailog.cmd`
- 可分发包：`dist/AIlog.skill`

## 日志格式（单行追加）

每条日志至少包含 4 个字段：`等级` `时间` `事件` `行为`，并允许追加 `键=值` 扩展字段。

示例：

```text
等级="中" 时间="2026-02-16 14:03:22" 事件="修改" 行为="修改函数functest的计算公式为xxx。" 路径="src/main.ts"
```

## AI 自动调用方式（示例）

下面命令是给 AI/Agent 调用的。正常使用时由 AI 在每次成功且发生状态变化后自动执行，通常不需要用户手动输入。

AI 在你正在操作的项目目录里调用时，日志会写入该目录的 `./AIlog/`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<AIlog技能目录>\AIlog\scripts\ailog.ps1" 中 修改 "修改函数functest的计算公式为xxx。" "路径=src/main.ts"
```

或在 Windows 下直接调用包装器：

```bat
"<AIlog技能目录>\AIlog\scripts\ailog.cmd" 中 指令 "使用npm install命令更新了项目myproject。" "命令=npm install"
```

## 安全

- 默认脱敏敏感信息（token/secret/password/api key 等），避免把密钥写进日志。
- 只记录成功操作；失败操作不记录。
- 只允许追加写入，不读取日志再改写。

## License

MIT
