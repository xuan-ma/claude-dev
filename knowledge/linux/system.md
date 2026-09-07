# Linux 系统操作

> 来源：思维导图 "generals" 标签页

---

## Ubuntu 版本查询

```bash
lsb_release -a
```

---

## sudo

```bash
sudo -i    # 切换到 root 账号
```

---

## vim 整行操作

| 操作 | 命令 |
|------|------|
| 复制一行 | `yy` |
| 删除一行 | `dd` |
| 粘贴 | `p` |

---

## Windows / Linux 行尾转换

Windows 和 Linux 换行符不同导致脚本执行问题。

```bash
# 批量转换为 Linux 格式
find . -name "*.sh" | xargs dos2unix

# 批量转换为 Windows 格式
find . -name "*.sh" | xargs unix2dos
```

---

## 文件路径操作

| 需求 | 方法 |
|------|------|
| 获取文件名/扩展名 | `basename` |
| 获取文件所在路径 | `dirname` |

---

## 压缩和解压缩

（笔记中标注但未展开，常见命令：`tar`、`gzip`、`zip`）

---

## ffmpeg 常用操作

笔记中标注了以下场景（具体命令待补充）：
- 图像装视频（图片序列 → 视频）
- 视频拼接
- 加文字注释
