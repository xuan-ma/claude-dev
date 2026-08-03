---
name: conda-knowledge-base
description: >
  Conda/Anaconda/Miniconda 相关问题处理。
  Use when the user asks about conda — environment management, package installation,
  channel/mirror configuration, version switching, environment export/import,
  or conda error troubleshooting.
---

# Conda Knowledge Base

## Goal

检索本地知识库 → 无匹配则模型兜底 → 解决后沉淀回知识库。

## Decision Tree

```
用户提出 conda 问题
  │
  ├─ 0. 快速分流：是否为基础常识问题？
  │     │  判断标准：命令基础语法、概念定义，不涉及具体环境/版本/报错
  │     │  例："conda create 怎么用" → 基础，模型直接答，跳过知识库
  │     │  例："清华源今天超时怎么查" → 非基础，走知识库
  │     │
  │     ├─ 是 → 模型直接回答，回答后判断有无值得沉淀的新知识
  │     │
  │     └─ 否 → 继续第1步
  │
  ├─ 1. Read ~/.claude/knowledge/conda/index.md
  │     匹配关键词 → 定位到具体文档
  │
  ├─ 2. Read 匹配到的文档 + 相关截图
  │     │
  │     ├─ 完全匹配 ──▶ 返回文档中的方案
  │     ├─ 部分匹配 ──▶ 基于文档适配当前场景
  │     └─ 无匹配 ────▶ 进入第3步
  │
  ├─ 3. 明确告知："知识库暂无记录，基于通用知识解答。"
  │     使用模型知识解决问题
  │
  └─ 4. 问题解决后 → 按 references/save-protocol.md 沉淀
```

## Routing Table

| 用户关键词 | 目标文档 |
|-----------|---------|
| 安装、卸载、升级、版本选择 | `~/.claude/knowledge/conda/installation.md` |
| 环境、env、create、activate、deactivate、切换、导出、导入、克隆、删除、environment.yml | `~/.claude/knowledge/conda/env-management.md` |
| 包、package、install、uninstall、update、search、版本锁定、依赖 | `~/.claude/knowledge/conda/package-ops.md` |
| 镜像、源、channel、加速、清华、中科大、阿里云 | `~/.claude/knowledge/conda/channel-config.md` |
| 报错、错误、失败、超时、冲突、排查、bug | `~/.claude/knowledge/conda/troubleshooting.md` |

## Constraints

- 检索优先，不跳过知识库直接用模型知识。
- 知识库无匹配时，**明确告知用户**后再用模型兜底。
- 保存新内容前，评估是否值得记录（不记录 trivial one-liner）。
- 写入文件前确认目标文档路径，避免创建重复或冗余文件。
- Windows 环境注意路径分隔符和 PowerShell 语法。

## Validation

- 每次触发时，第一步必须是 Read index.md。
- 解决新问题后，必须执行 save-protocol.md 中的沉淀流程。
- 写操作后同步更新 index.md 的索引条目。

## Resources

- `references/routing-table.md` — 扩展路由规则和关键词匹配方法
- `references/save-protocol.md` — 知识沉淀的判断标准和操作规范
- `references/doc-format.md` — 知识库文档的写作模板
- `~/.claude/knowledge/conda/` — 知识库实际内容（安装、环境、包、镜像源、排障）
