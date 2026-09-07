# VNC 远程桌面

> 来源：思维导图 "VNC" 标签页

---

## 基本概念

| 角色 | 说明 |
|------|------|
| vncserver | 服务端，安装路径 `/usr/bin`，默认端口 5900 |
| vncviewer | 客户端 |
| 显示号 `:1` | 对应端口 5901 = 5900 + 1 |

**客户端下载（RealVNC）：**
https://www.realvnc.com/en/connect/download/viewer/

---

## tightvncserver（推荐，轻量常用）

### 安装
```bash
apt-get install -y tightvncserver
```

### 启动
```bash
vncserver :1 -geometry 1280x800 -depth 24
vncserver              # 首次运行提示设置密码
```

---

## x11vnc（功能更强，基于 X11）

### 启动虚拟显示器 + 桌面环境
```bash
# 安装虚拟 X 服务器
apt-get install -y xvfb

# 安装轻量级桌面
apt-get update && apt-get install -y xfce4 xfce4-goodies

# 启动虚拟显示器
Xvfb :0 -screen 0 1280x800x24 &

# 指定显示号（不指定连接后黑屏）
export DISPLAY=:0

# 启动桌面
xfce4-session &

# 启动 x11vnc
x11vnc -display :0 -forever -shared -rfbport 5900 -passwd robo@123 &
```

### x11vnc 参数说明

| 参数 | 说明 |
|------|------|
| `-display :0` | 共享 X11 显示号 :0（通常是真实桌面） |
| `-forever` | 客户端断开后不退出 |
| `-shared` | 允许多个客户端同时连接 |
| `-rfbport 5900` | VNC 端口（5900 对应 :0） |
| `-passwd <pwd>` | 设置连接密码 |

---

## 剪切板失效

```bash
vncconfig &
```

---

## 其他工具

| 工具 | 说明 |
|------|------|
| tigervnc-server | 另一 VNC 服务端实现 |
| novnc | 基于浏览器的 VNC 客户端 |
| realvnc viewer | 官方客户端 |
