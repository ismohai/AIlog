---
name: AIlog
description: Use when an AI assistant completes a successful, state-changing operation and must append an audit line to ./AIlog/YYYY-MM-DD.log, or when debugging user-reported issues that may have been caused by prior AI actions.
---

# AIlog

这个技能的目标很直接：把 AI 真正做过的改动留痕，方便以后排查。

使用时只做两件事：
1. 成功且发生状态变化后，立刻追加一条日志。
2. 仅在用户要求排查问题且可能由 AI 引起时，读取日志。

## 强制规则

1. 只记成功操作。失败、未执行、仅计划中的动作不记录。
2. 只记状态变化。纯读取行为不记录。
3. 每个成功动作完成后立刻记录，不做延迟汇总。
4. 只允许追加，禁止先读再改写历史日志。
5. 写日志这件事本身不再记录。
6. 日志目录固定在当前工作目录：`./AIlog/`。
7. 日志按天切分，文件名格式：`YYYY-MM-DD.log`。
8. 平时不读日志。只有用户要求排障且怀疑是 AI 导致时才读取 `AIlog`。

## 日志结构

每条日志是一行，至少包含四个字段：

- `等级`：`低` / `中` / `高`
- `时间`：`YYYY-MM-DD HH:mm:ss`（由脚本生成）
- `事件`：固定为 `移动` / `复制` / `修改` / `覆盖` / `下载/更新` / `指令` / `删除`
- `行为`：自然语言描述，直接写“做了什么”

可选扩展字段用 `键=值` 追加，例如：`路径=...`、`源路径=...`、`目标路径=...`、`命令=...`、`变量名=...`。

## 等级判定

- `低`：不改变实际内容的行为（如移动、复制）
- `中`：改变内容但通常可恢复（如修改、下载/更新、一般指令）
- `高`：不可逆或高风险行为（如覆盖、删除）

如果操作风险更高（例如系统级影响、跨项目破坏、难恢复后果），可以上调等级。

## 指令事件推断

执行终端或 PowerShell 指令后，优先推断为更具体事件：

- 能明确归类为 `删除` / `移动` / `复制` / `下载/更新` / `覆盖` / `修改` 时，使用对应事件。
- 无法明确归类时，使用 `事件=指令`。

## 脱敏规则

默认脱敏敏感信息，不记录明文：

- 密码、口令、token、secret、api key、authorization、cookie、私钥等
- 环境变量中的敏感值
- 命令参数中的敏感值

## 调用方式

优先调用脚本追加日志，不直接手写文件：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill目录>/scripts/ailog.ps1" <等级> <事件> <行为> ["键=值" ...]
```

Windows 也可直接调用包装器（无需改 PATH）：

```bat
"<skill目录>\scripts\ailog.cmd" <等级> <事件> "<行为>" "键=值"
```

示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill目录>/scripts/ailog.ps1" 中 修改 "修改函数functest的计算公式为xxx。" "路径=src/main.ts"
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill目录>/scripts/ailog.ps1" 高 删除 "删除了D:\\systemmine\\desktop\\test\\test.txt。" "路径=D:\\systemmine\\desktop\\test\\test.txt"
```

## 行为字段写法

行为必须写成完整自然语言句子，直接描述动作，不写空泛词。

推荐模板：

- `将文件<源>移动至<目标>。`
- `修改函数<函数名>的计算公式为<变更描述>。`
- `使用<命令>设置了环境变量<变量名>=<已脱敏值>。`
- `删除了<路径>。`
- `使用<命令>更新了项目<项目名>。`
- `使用<命令>下载了项目<项目名>的依赖文件。`
- `使用<命令>提交了项目到 GitHub 仓库<仓库名>。`
- `使用<命令>从 GitHub 回退了版本。`
