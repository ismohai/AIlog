# AIlog Skill

AIlog 是给 AI 助手用的操作日志技能，不是给人手动记流水账的。

它只记一类事情：AI 已经成功执行、并且确实改动了状态的操作。每发生一次，就往当前项目的 `./AIlog/YYYY-MM-DD.log` 末尾追加一行。

## 这个技能主要解决什么问题

- 对话轮次多了，或者换了工具后，不容易还原“到底做过什么”
- 项目突然出问题时，想快速定位是哪一步改动引起的
- 需要一份既能人读、又方便 AI 检索的操作轨迹

## 仓库内容

- Skill 目录：`AIlog/`
- 追加脚本：`AIlog/scripts/ailog.ps1`
- Windows 包装器（不用配 PATH）：`AIlog/scripts/ailog.cmd`
- 可分发包：`dist/AIlog.skill`

## 日志格式（单行追加）

每条日志至少包含 4 个字段：`等级`、`时间`、`事件`、`行为`，也支持追加 `键=值` 扩展字段。

示例：

```text
等级="中" 时间="2026-02-16 14:03:22" 事件="修改" 行为="修改函数functest的计算公式为xxx。" 路径="src/main.ts"
```

## AI 自动调用（示例）

这些命令是给 AI/Agent 调用的。正常情况下不需要用户手动执行。

AI 在你当前项目目录里调用时，日志会写到该目录下的 `./AIlog/`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<AIlog技能目录>\AIlog\scripts\ailog.ps1" 中 修改 "修改函数functest的计算公式为xxx。" "路径=src/main.ts"
```

Windows 下也可以用包装器：

```bat
"<AIlog技能目录>\AIlog\scripts\ailog.cmd" 中 指令 "使用npm install命令更新了项目myproject。" "命令=npm install"
```

## 记录边界

- 只记录成功操作；失败不记
- 只记录状态变化；纯读取不记
- 只追加，不改写历史日志
- 写日志这件事本身不再额外记一条

## 安全策略

- 默认脱敏敏感信息（token、secret、password、api key 等）
- 避免把明文密钥写进日志

## License

见 `LICENSE`
