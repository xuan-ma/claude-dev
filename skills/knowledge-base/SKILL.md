---
name: knowledge-base
description: >
  本地知识库检索。Use when the user asks about tools, commands, configurations,
  troubleshooting, or development workflows — anything that might be covered in
  the personal knowledge base. Covers conda, docker, git, python, and other
  development domains. Retrieval-first: search local docs before using model knowledge.
---

# Knowledge Base

## Goal

两层索引检索：先定位领域 → 再定位文档 → 先检索后兜底 → 解决后沉淀。

## Decision Tree

```
用户提问
  │
  ├─ 0. 快速分流：通用基础知识？
  │     └─ 是 → 模型直接答，跳过知识库
  │
  ├─ 1. Read ~/.claude/knowledge/INDEX.md
  │     匹配关键词 → 定位到领域子目录
  │     无匹配 → 明确告知"知识库未覆盖此领域"，模型兜底
  │
  ├─ 2. Read ~/.claude/knowledge/<domain>/index.md
  │     匹配关键词 → 定位到具体文档
  │
  ├─ 3. Read 目标文档
  │     ├─ 完全匹配 → 返回文档方案
  │     ├─ 部分匹配 → 基于文档适配
  │     └─ 无匹配 → 模型兜底
  │
  └─ 4. 解决后 → 按 references/save-protocol.md 沉淀到对应领域目录
```

## Routing Table

| 关键词 → 领域 |
|-------------|
| conda, anaconda, miniconda, 虚拟环境 → `conda/` |
| docker, 容器, 镜像, compose → `docker/` |
| git, 分支, 合并, 提交, rebase → `git/` |
| python, pip, venv, poetry → `python/` |
| ... 其余见 `~/.claude/knowledge/INDEX.md` |

## Constraints

- 始终先查 INDEX.md，不跳过直接答。
- 知识库无覆盖时明确告知用户。
- 最多同时加载 2 篇目标文档。
- 截图仅在对比排查场景才 Read，不主动加载。
- 新增知识域只需在 INDEX.md 加一行 + 创建子目录，不动 Skill。

## Validation

- 第一步必须是 Read INDEX.md。
- 解决新问题后必须按 save-protocol.md 沉淀。
- 沉淀后同步更新领域 index.md 和主 INDEX.md（如需要）。

## Resources

- `references/save-protocol.md` — 知识沉淀规范
- `references/doc-format.md` — 文档格式模板
- `~/.claude/knowledge/INDEX.md` — 领域索引
- `~/.claude/knowledge/<domain>/` — 各领域知识库
