# Docker（Linux）

> 来源：思维导图 "Docker" 标签页

---

## 容器内 DNS 解析失败

**现象：**
```
Temporary failure resolving "archive.ubuntu.com"
```

**原因：** Docker 容器内的 DNS 解析问题。

**解决：** 修改 Docker 守护进程配置 `/etc/docker/daemon.json`：

```json
{
  "dns": ["8.8.8.8", "114.114.114.114", "10.0.0.1"],
  "dns-search": ["huawei.com"]
}
```

修改后重启 Docker 服务。
