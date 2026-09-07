# Python on Ubuntu

> 来源：思维导图 "python" 标签页

---

## Ubuntu 版本与默认 Python

| Ubuntu 版本 | 默认 Python |
|-------------|-------------|
| 桌面版 | 自带 Python 解释器 |
| 镜像版 (Server) | 较纯净，不预装 Python |
| 20.04 | 默认 python3.8 |

---

## 版本检查

```bash
python --version
python3 --version
```

---

## 安装

```bash
apt-get update && \
apt-get install -y \
  python3 \
  python3-pip \
  python3-dev \
  build-essential \
&& rm -rf /var/lib/apt/lists/*
```

### 创建软链接

```dockerfile
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN ln -s /usr/bin/pip3 /usr/bin/pip
```

---

## 安装 conda

参见 `knowledge/conda/` 领域。
