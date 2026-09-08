# Linux 网络

> 来源：思维导图 "generals" 标签页

---

## iperf3 网络带宽测试

**场景：** 测试两台机器之间的真实网络带宽（如工作站 ↔ LIMO Pro 小车）

### 安装
```bash
apt update && apt install iperf3
```

### TCP 模式
```bash
# 服务端
iperf3 -s -p 5001

# 客户端
iperf3 -c <服务端IP> -p 5001 -t 60 -i 5
```

| 参数 | 说明 |
|------|------|
| `-c <IP>` | 服务端地址 |
| `-p` | 端口 |
| `-t 60` | 测试持续时间（秒） |
| `-i 5` | 每 5 秒打印一次结果 |

### UDP 模式
```bash
iperf3 -c <服务端IP> -u -b 0 -t 30
```

| 参数 | 说明 |
|------|------|
| `-u` | UDP 模式 |
| `-b 0` | 不限速 |

---

## TCP 缓冲区调优

**现象：** UDP 能跑 100+ Mbps，TCP 只有 4.28 Mbps → TCP 重传问题，源于信号差或干扰

**原因：** TCP 缓冲区太小，无法接收高速数据

### 查看当前值
```bash
cat /proc/sys/net/core/rmem_max        # 默认 212992 (212KB)
cat /proc/sys/net/core/rmem_default
```

### 推荐值
| 参数 | 推荐值 |
|------|--------|
| `rmem_max` | 134217728 (128MB) |
| `rmem_default` | 16777216 (16MB) |

### 临时生效
```bash
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.rmem_default=16777216
```

### 永久生效
写入 `/etc/sysctl.conf`：
```
net.core.rmem_max = 134217728
net.core.rmem_default = 16777216
```

---

## DNS 解析问题

**现象：** `Temporary failure resolving "archive.ubuntu.com"`

**原因：** DNS 配置问题

### 检查
```bash
cat /etc/resolv.conf
```

### 修复
编辑 `/etc/resolv.conf`，添加 nameserver：
```
nameserver 10.10.10.10
nameserver 127.0.0.53
search huawei.com
```

验证：`ping <域名>` 查看域名对应的 IP

> 如果设置之后域名解析还有问题，需要加 "IP 域名" 映射到 `/etc/hosts`

---

## 代理配置

```bash
# 查看当前代理
echo $http_proxy
echo $https_proxy

# wget 代理配置文件
cat /etc/wgetrc
```

---

## hostname 管理

```bash
hostname                              # 查看主机名
hostnamectl set-hostname <new_name>   # 设置新主机名
```

---

## /etc/hosts

```bash
# 查看 hostname 对应的 IP
cat /etc/hosts

# 添加映射
echo "<IP> <域名>" >> /etc/hosts
```

---

## 端口检查

```bash
netstat -anp | grep <端口号>
netstat -tulnp | grep <端口号>
```

---

## SSH

### 重启 SSH 服务

**场景：** 远程服务器修改 SSH 配置后，重启服务使配置生效。

**两个版本：**

| 系统版本 | 命令 |
|----------|------|
| 老版本（init.d） | `service ssh restart` |
| 新版本（systemd） | `systemctl restart sshd` |

> 服务名因发行版而异：Debian/Ubuntu 多为 `ssh`，RHEL/CentOS 多为 `sshd`。不确定时先查：`systemctl list-unit-files | grep ssh`
