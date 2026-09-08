#!/usr/bin/env bash
# Generate a human-browsable README.md for the knowledge base
# Triggered after any Write/Edit to knowledge/ files

set -euo pipefail

KNOWLEDGE_DIR="$HOME/.claude/knowledge"
OUTPUT="$KNOWLEDGE_DIR/README.md"

NOW=$(date "+%Y-%m-%d %H:%M")
cat > "$OUTPUT" << HEADER
# 📚 个人知识库

> 🤖 Agent 检索入口，👤 人工复习手册
> 自动生成于 $NOW

---

## 🗂️ 领域导航

HEADER

# Iterate each domain directory
for domain_dir in "$KNOWLEDGE_DIR"/*/; do
    domain=$(basename "$domain_dir")
    index_file="$domain_dir/index.md"

    # Skip if no index
    [ -f "$index_file" ] || continue

    # Extract domain description from index.md (first line after #)
    desc=$(head -3 "$index_file" | grep -v "^$" | grep -v "^#" | head -1 | sed 's/^> //' | sed 's/^ //')
    [ -z "$desc" ] && desc="$domain 相关知识"

    echo "### 📁 $domain" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "$desc" >> "$OUTPUT"
    echo "" >> "$OUTPUT"

    # List all .md files except index.md
    echo "| 文档 | 行数 | 主题 |" >> "$OUTPUT"
    echo "|------|------|------|" >> "$OUTPUT"

    for doc in "$domain_dir"/*.md; do
        doc_name=$(basename "$doc")
        [ "$doc_name" = "index.md" ] && continue

        lines=$(wc -l < "$doc")

        # Extract "## " section headings as a topic outline
        topics=$(grep -E '^## ' "$doc" | sed 's/^## //' | awk '{printf (NR==1 ? "" : " / ") $0} END {print ""}')
        [ -z "$topics" ] && topics="—"

        echo "| [$doc_name]($domain/$doc_name) | ${lines} 行 | $topics |" >> "$OUTPUT"
    done

    echo "" >> "$OUTPUT"
done

cat >> "$OUTPUT" << 'FOOTER'
---

## 🔍 使用说明

- **Agent 检索：** 提问时 Agent 自动按索引查找
- **人工浏览：** 点击上方链接，或在 VS Code / Obsidian 中打开本目录
- **GitHub 阅读：** [github.com/xuan-ma/claude-dev](https://github.com/xuan-ma/claude-dev)

## 📊 统计

FOOTER

# Stats
total_domains=$(find "$KNOWLEDGE_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
total_docs=$(find "$KNOWLEDGE_DIR" -name "*.md" ! -name "README.md" | wc -l)
total_lines=$(find "$KNOWLEDGE_DIR" -name "*.md" ! -name "README.md" -exec cat {} + | wc -l)

echo "- **领域数：** $total_domains" >> "$OUTPUT"
echo "- **文档数：** $total_docs" >> "$OUTPUT"
echo "- **总行数：** $total_lines" >> "$OUTPUT"

echo "README generated: $OUTPUT ($total_domains domains, $total_docs docs)"
