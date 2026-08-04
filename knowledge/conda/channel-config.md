# Conda 镜像源与 Channel 配置

> 国内访问 conda 官方源很慢，替换国内镜像源是最佳解决方案。
> 旧教程（2018-2021）中很多镜像源 URL 已失效，但替换方法不变。
> 本笔记的清华源 URL 经验证有效（2022.3）。

---

## 已验证的清华镜像源 URL

```bash
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/
conda config --set show_channel_urls yes
```

配置前如需恢复默认：`conda config --remove-key channels`

## 国内镜像源对照

| 来源 | 主 URL |
|------|--------|
| 清华 | `https://mirrors.tuna.tsinghua.edu.cn/anaconda/` |
| 中科大 | `https://mirrors.ustc.edu.cn/anaconda/` |
| 阿里云 | `https://mirrors.aliyun.com/anaconda/` |

常用子路径：`/pkgs/main/`、`/pkgs/free/`、`/pkgs/r/`、`/cloud/pytorch/`、`/cloud/conda-forge/`

## 如何自行验证镜像源是否有效

1. 浏览器打开镜像站主页（如 https://mirrors.tuna.tsinghua.edu.cn/anaconda/）
2. 确认路径结构存在，直接访问 URL 看是否 404

> **核心思路：** 替换方法永远不变（`conda config --add channels`），变的是 URL。学会自己找 URL 比背 URL 更重要。
