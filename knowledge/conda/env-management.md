# Conda 环境管理

> 仅记录个人踩坑经验和非显而易见的用法。基础命令（create/list/remove 等）不在此记录，模型可直接回答。

---

## 创建环境的非默认参数

**日期：** 原始笔记

| 参数 | 说明 |
|------|------|
| `CONDA_FORCE_32BIT=1` | 创建 32 位 Python 解释器（在命令前设置环境变量） |
| `--clone old_name` | 复制已有虚拟环境 |

```bash
CONDA_FORCE_32BIT=1 conda create -n myenv32 python=3.7
conda create -n new_env --clone old_env
```

---

## `activate` / `deactivate` 弃用时间线

> **DeprecationWarning:** `deactivate` is deprecated. Use `conda deactivate`.

| 版本 | 时间 | 变更 |
|------|------|------|
| conda 4.4.0 | 2017-12 | 引入弃用警告，推荐 `conda deactivate` / `conda activate` |
| conda 4.6 | 2019-02 | `conda activate` / `conda deactivate` 成为跨平台标准 |
| conda 24.x+ | 至今 | 旧命令仍可用但持续报 DeprecationWarning，尚未移除 |

旧版 Windows 需去掉 `conda` 前缀（`activate` / `deactivate`），新版本全平台统一用带前缀的命令。

---

## 复制/迁移虚拟环境

**日期：** 原始笔记
**场景：** 将虚拟环境文件夹复制到其他位置或机器

1. 复制虚拟环境文件夹到目标路径
2. 注册路径：
   ```bash
   conda config --add envs_dirs <目标虚拟环境路径>
   ```
3. 验证：
   ```bash
   conda env list
   ```
