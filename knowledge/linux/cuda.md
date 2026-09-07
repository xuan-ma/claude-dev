# CUDA 安装与 NVIDIA 驱动排障

> 来源：思维导图 "CUDA" 标签页
> 核心踩坑：内核版本与驱动不匹配导致 nvidia-smi 失败

---

## 基本概念

| 组件 | 检查命令 |
|------|----------|
| NVIDIA 显卡驱动 (driver API) | `nvidia-smi` |
| CUDA Toolkit (runtime API) | `nvcc -V` |

> cuda 版本 ≤ 显卡驱动支持的 cuda 版本

---

## CUDA Toolkit 安装

### 下载
https://developer.nvidia.com/cuda-toolkit-archive

### 安装示例（11.7）
```bash
wget https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_515.43.04_linux.run
sudo sh cuda_11.7.0_515.43.04_linux.run
```

> ⚠️ 安装包内含 nvidia driver 安装选项，如果勾选会报错。建议分开安装。

### 安装路径
```
/usr/local/cuda-xx.x
```

### 环境变量
```bash
export PATH=/usr/local/cuda-11.7/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda-11.7/lib64:$LD_LIBRARY_PATH
```

参考：https://blog.csdn.net/my__blog/article/details/125720601

---

## NVIDIA 驱动安装

### 查看推荐驱动版本
```bash
ubuntu-drivers devices
```

### 下载
https://www.nvidia.cn/geforce/drivers/

### apt 安装
```bash
apt-get update && apt-get install nvidia-driver-535
```

### 检查系统架构
```bash
uname -m          # x86_64
uname -r          # 查看内核版本，如 6.8.0-87-generic
```

参考：https://blog.csdn.net/weixin_40378209/article/details/137643190

---

## 经典报错与解决

### 报错 1：nvidia-smi 无法通信

```
NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver.
Make sure that the latest NVIDIA driver is installed and running.
```

**排查步骤：**

```bash
# 1. 确认驱动是否安装
dpkg -l | grep -i nvidia-driver      # 应返回如 nvidia-driver-550

# 2. 确认驱动是否加载
lsmod | grep nvidia                  # 无返回 = 驱动未加载

# 3. 尝试手动加载
sudo modprobe nvidia                 # 报错 = 内核模块未编译

# 4. 检查 DKMS 模块目录
ls -la /lib/modules/$(uname -r)/updates/dkms/   # 目录不存在 = 驱动未为当前内核编译

# 5. 检查 DKMS 状态
sudo dkms status | grep nvidia       # 无返回 = DKMS 未注册 NVIDIA 模块
```

**根因：** 内核版本更新后，NVIDIA 内核模块未为新内核重新编译。

**解决（以 nvidia-driver-550 为例）：**

```bash
# 注册驱动源码到 DKMS
sudo dkms add -m nvidia -v 550.163.01

# 为当前内核编译
sudo dkms build nvidia/550.163.01 -k $(uname -r)

# 安装
sudo dkms install nvidia/550.163.01 -k $(uname -r)

# 验证：应显示 "installed" 而非 "added"
sudo dkms status
```

---

### 报错 2：nvcc 未找到

```
Command 'nvcc' not found
```

**原因：** CUDA Toolkit 未安装或环境变量未设置。

---

### 报错 3：驱动版本不匹配

```
Failed to initialize NVML: Driver/library version mismatch
```

**原因：** 内核模块版本与用户态库版本不一致，通常发生在驱动更新不完整时。
