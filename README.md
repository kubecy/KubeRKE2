# Rke2Ops
<!-- Logo -->
<img src="https://github.com/kubecy/Rke2Ops/blob/main/pics/Rke2Ops.png?raw=true" width="220px" alt="Rke2Ops logo"/>
<!-- Rke2Ops 完整版徽章 -->
<a href="#"><img src="https://img.shields.io/badge/Project-Rke2Ops-326ce5?logo=kubernetes&logoColor=white" /></a>
<a href="#"><img src="https://img.shields.io/badge/Platform-Kubernetes-326ce5?logo=kubernetes&logoColor=white" /></a>
<a href="#"><img src="https://img.shields.io/badge/Support‑OS-RedHat%7CRocky%7COpenEuler%7CKylin%7CDebian%7CUbuntu-yellow" /></a>

Rke2Ops 是一款面向 RKE2 多环境、多版本自动化部署运维工具。内置 kube‑vip 一体化方案，零外部负载均衡依赖，一键构建稳定可靠的 Kubernetes 控制平面高可用集群，大幅简化裸金属、离线机房 Kubernetes 高可用落地流程。
<img src="https://github.com/kubecy/Rke2Ops/blob/main/pics/Kube-VIP-RKE2.png">

---
# 快速开始
``` bash
yichen@Ubuntu-Desktop:~$ git clone https://github.com/kubecy/Rke2Ops.git
yichen@Ubuntu-Desktop:~$ cd Rke2Ops/

# 配置 rke2ctl Tab 功能 
yichen@Ubuntu-Desktop:~/Rke2Ops$ ./rke2ctl bash-completion

# 创建部署环境
yichen@Ubuntu-Desktop:~/Rke2Ops$ ./rke2ctl new cq-moone
2026-08-17 12:34:59 [rke2ctl:220] INFO  已创建环境 cq-moone: /home/yichen/Rke2Ops/inventory/cq-moone
2026-08-17 12:34:59 [rke2ctl:222] INFO  正在加密 /home/yichen/Rke2Ops/inventory/cq-moone/secrets.yml (请输入两遍 vault 密码)
New Vault password:             # 输入secrets.yml文件解密密码
Confirm New Vault password:     # 确定secrets.yml文件解密密码
Encryption successful

# 目录结构
Rke2Ops/
├── rke2ctl                     # 总控脚本: 环境, 下载, 推送, 部署, 补全
├── playbooks/
│   ├── rke2-server.yml         # 部署 master
│   └── rke2-agent.yml          # 部署 worker
├── roles/
│   ├── prepare/                # 基础初始化 (用户, 目录, 离线包分发)
│   ├── rke2-server/            # 含 kube-vip.yaml.j2 (HA 清单)
│   └── rke2-agent/
├── inventory/
│   ├── sample/                 # 环境模板 (复制即得新环境)
|   |   ├── hosts               # 配置 rke2-server 和 rke2-agent
|   |   ├── secrets.yml         # 配置 sudo 密码
|   |   ├── site.yml            # 配置 kre2 参数, 包括磁盘分区、网络插件等的启用, kube-vip 设置等文件
│   └── <env>/                  # 独立环境: hosts / site.yml / secrets.yml
└── packages_rke2/cq-moone/v1.36.3+rke2r1/amd64/                                          # 离线包 (download 产物, 含 kube-vip 镜像包)
                                               ├── install.sh                             # RKE2 一键安装脚本
                                               ├── rancher-load-images.sh                 # 镜像导入辅助脚本
                                               ├── rke2.linux-amd64.tar.gz                # RKE2 核心程序包
                                               ├── sha256sum-amd64.txt                    # 全部包 SHA256 校验值
                                               ├── rke2-images-all.linux-amd64.txt        # 全量镜像清单
                                               ├── rke2-images.linux-amd64.tar.gz         # 核心组件 + 默认 CNI 镜像
                                               ├── rke2-images-cilium.linux-amd64.tar.gz  # CNI 镜像包 (按 cni 配置下载)
                                               └── kube-vip-image-v1.2.3.tar.gz           # kube-vip 镜像包

# 修改需要部署版本和 rke2 参数
yichen@Ubuntu-Desktop:~/Rke2Ops$ vim inventory/cq-moone/site.yml

# 下载 rke2 离线镜像包
yichen@Ubuntu-Desktop:~/Rke2Ops$ ./rke2ctl download cq-moone

# 打包拷贝离线环境
yichen@Ubuntu-Desktop:~/Rke2Ops$ tar -zcvf Rke2Ops.tar.gz ../Rke2Ops
```

# 配置
``` bash
# 上传镜像至 harbor 镜像仓库
yichen@Ubuntu-Desktop:~/Rke2Ops$ ./rke2ctl pull cq-moone

# 修改 hosts 
yichen@Ubuntu-Desktop:~/Rke2Ops$ vim inventory/cq-moone/hosts
[rke2_server]
cq-moone-master1 ansible_host=192.168.1.61 init_master=true
cq-moone-master2 ansible_host=192.168.1.62
cq-moone-master3 ansible_host=192.168.1.63

[rke2_agent]
cq-moone-worker1 ansible_host=192.168.1.71
cq-moone-worker2 ansible_host=192.168.1.72
cq-moone-worker3 ansible_host=192.168.1.73
cq-moone-worker4 ansible_host=192.168.1.74
cq-moone-worker5 ansible_host=192.168.1.75

# 配置密码
yichen@Ubuntu-Desktop:~/Rke2Ops$ ansible-vault edit inventory/cq-moone/secrets.yml
---
servers:
  cq-moone-master1:
    sudopass: "MTIzCg=="
  cq-moone-master2:
    sudopass: "MTIzCg=="
  cq-moone-master3:
    sudopass: "MTIzCg=="

  cq-moone-worker1:
    sudopass: "MTIzCg=="
  cq-moone-worker2:
    sudopass: "MTIzCg=="
  cq-moone-worker3:
    sudopass: "MTIzCg=="
  cq-moone-worker4:
    sudopass: "MTIzCg=="
  cq-moone-worker5:
    sudopass: "MTIzCg=="
```

# 部署
``` bash
# 分发公钥
yichen@Ubuntu-Desktop:~/Rke2Ops$ ./rke2ctl setup cq-moone ssh-copy

# 部署 rke2-server
yichen@Ubuntu-Desktop:~/Rke2Ops$ ./rke2ctl setup cq-moone rke2-server

# 部署rke2-agent
yichen@Ubuntu-Desktop:~/Rke2Ops$ ./rke2ctl setup cq-moone rke2-agent

# 一键部署
yichen@Ubuntu-Desktop:~/Rke2Ops$ ./rke2ctl setup cq-moone all
```












---









---

## 6. 部署

### 6.1 创建环境（首次）

```shell
./rke2ctl new cq-moone-k45        # 复制 sample 模板 + 加密 secrets.yml + 建 packages_rke2 目录
./rke2ctl list                    # 查看全部环境
```

### 6.2 配置三件套

**① hosts — 主机清单**（`inventory/<环境名>/hosts`）：

```ini

```

**② site.yml — 环境变量**（关键项）：

| 配置项 | 说明 |
| ------ | ---- |
| `rke2_version` / `arch` | 安装包版本与架构，download 依赖 |
| `ssh_user` | SSH 远程用户（节点需提前创建并授权 sudo） |
| `global.token` | 集群共享 token，master/worker 一致 |
| `global.docker_repo.*` | Harbor 地址 / 账号 / 密码，pull 与节点拉取依赖 |
| `global.kube_vip*` | VIP 三段配置（见 1.3） |
| `rke2_server.tls_san[0]` | 必须为 `{{ global.kube_vip }}`（HA_VIP，第一行） |
| `rke2_server.cni` | 网络插件：none / calico / canal / cilium（download 按此下载镜像包） |

> 配置了 `global.kube_vip_version` 但缺少 `kube_vip` / `kube_vip_interface` 时，playbook 会**校验失败**并给出提示，防止错配。

**③ secrets.yml — sudo 密码**（vault 加密，键名必须与 hosts 主机名完全一致）：

```shell
ansible-vault edit inventory/cq-moone-k45/secrets.yml
echo "你的sudo密码" | base64        # 密码需 base64 编码填入
```

```yaml
servers:
  cq-moone-master1:
    sudopass: "xxxbase64xxx"
```

### 6.3 分发 SSH 公钥

```shell
./rke2ctl setup cq-moone-k45 ssh-copy     # sshpass 自动解析 hosts/site.yml 并分发
```

### 6.4 （推荐）

```shell
./rke2ctl setup cq-moone-k45 all
```

内部按序执行 `playbooks/rke2-server.yml` → `playbooks/rke2-agent.yml`，**任一步失败立即停止**并返回可读退出码（1=执行错误 2=主机不可达 3=解析错误 99=中断）。

分步部署（等价命令，需在仓库根目录、`env_dir` 传**绝对路径**）：

```shell
./rke2ctl setup cq-moone-k45 rke2-server
./rke2ctl setup cq-moone-k45 rke2-agent

# 或直接调 ansible-playbook:
ansible-playbook -i inventory/cq-moone-k45/hosts --ask-vault-pass \
    -e env_dir=$PWD/inventory/cq-moone-k45 playbooks/rke2-server.yml
```

### 6.5 部署机制（HA 关键路径）

```
master1 (init_master=true):  安装 RKE2 → 写入 kube-vip 清单至
                             /var/lib/rancher/rke2/server/manifests/
                             → 启动后 k3s deploy controller 自动 apply
                             → kube-vip 抢占 VIP (等待任务, 上限 7.5 分钟)
master2/3:                   server: https://<VIP>:9345 加入集群
worker:                      server: https://<VIP>:9345 加入集群
```

- 所有节点从 Harbor 拉取镜像（`system-default-registry` + `disable-default-registry-endpoint`）
- master 注册时带 `node-role.kubernetes.io/control-plane=true:NoSchedule` 污点，kube-vip DaemonSet 通过 toleration 调度
- 查看节点日志：`journalctl -u rke2-server -f` / `journalctl -u rke2-agent -f`

### 6.6 tab 补全（可选）

```shell
./rke2ctl bash-completion     # 安装后重开 shell, 环境名/部署类型均可 tab 补全
```

---

## 7. 部署验证

在 Ansible 主机上（`export KUBECONFIG=/etc/rancher/rke2/rke2.yaml`，或 `scp` 回本地）：

### 7.1 节点与组件

```shell
kubectl get nodes -o wide                    # 全部 Ready; master 带 control-plane 角色
kubectl get pods -n kube-system -o wide      # coredns/etcd/kube-vip-ds 均 Running
kubectl get ds -n kube-system kube-vip-ds    # DESIRED = master 数, 仅 control-plane 节点
```

### 7.2 VIP 接管

```shell
# 在任一 master 上执行 (仅持有 VIP 的 Leader 节点可见):
ip -4 addr show | grep 192.168.1.110
# 或查看 kube-vip 日志确认选主结果:
kubectl logs -n kube-system -l app.kubernetes.io/name=kube-vip-ds | grep -i leader
```

### 7.3 控制面 API 可达

```shell
curl -k https://192.168.1.110:6443/version     # 返回 k8s 版本 JSON 即 HA 生效
curl -k -sS -o /dev/null -w '%{http_code}\n' https://192.168.1.110:9345
# 注册端口返回非 000 状态码 (401/404 属正常) 即由 kube-vip 承载
```

### 7.4 故障转移演练

```shell
# 在持有 VIP 的 master 上:
systemctl stop rke2-server
# 观察 (租约 15s, 可到另台 master 执行):
ip -4 addr show | grep 192.168.1.110           # VIP 已漂移至此节点
curl -k https://192.168.1.110:6443/version     # 集群 API 持续可用
# 恢复: systemctl start rke2-server, kube-vip 自动重新加入选主
```

---

## 8. 常见问题（FAQ）

| 现象 | 原因 | 处理 |
| ---- | ---- | ---- |
| kube-vip 等待任务重试 90 次超时 | 接口名不符或 nodeSelector 不匹配 | `ip -4 addr` 核对网卡并修正 `kube_vip_interface`；确认节点 label 为 `node-role.kubernetes.io/control-plane=true` |
| `kubectl get ds` 显示 DESIRED=0 | kube-vip DaemonSet nodeSelector 与节点 label 不匹配 | 检查 manifest 中 `node-role.kubernetes.io/control-plane: "true"`（RKE2 为 `true`，非 kubeadm 的空值） |
| pull 出现 "No such image" 刷屏 | 清单含未下载的 CNI 镜像（如 cni 改用 cilium） | 已自动按本地已加载镜像过滤，忽略即可；确认 download 的 cni 与 site.yml 一致 |
| `docker login` 失败 | Harbor 账号或项目配置错误 | 检查 `global.docker_repo.user/password`；确认 Harbor 已建 `rancher` 项目 |
| master2/3 报 `Could not find the requested service` | 旧版 systemd 服务名 `rke2_server` 遗留 | 升级 rke2ctl/playbooks 后重跑，服务名统一为 `rke2-server` |
| download 下载慢/失败 | GitHub 直连受限 | 配置 `download_proxy` 多个加速镜像，空格分隔依次重试 |
| 修改 `tls_san` 后证书不生效 | 证书 SAN 未刷新 | 修改后需重启全部 server 节点，动态监听器会重建证书 |

---

## 9. rke2ctl 命令速查

| 命令 | 说明 |
| ---- | ---- |
| `rke2ctl help` | 显示帮助 |
| `rke2ctl list` | 列出全部环境 |
| `rke2ctl new <环境名>` | 创建环境（复制模板 + 加密 secrets） |
| `rke2ctl del <环境名>` | 删除环境（inventory/ 与 packages_rke2/ 同名目录） |
| `rke2ctl download <环境名>` | 离线下载安装包 + kube-vip 镜像包（外网） |
| `rke2ctl pull <环境名> [registry]` | 镜像导入私有仓库（内网） |
| `rke2ctl setup <环境名> <all\|ssh-copy\|rke2-server\|rke2-agent>` | 分发公钥 / 部署 master / 部署 worker / 全量部署 |
| `rke2ctl bash-completion` | 启用 tab 补全 |

---

## 10. 参考

- [RKE2 官方文档](https://docs.rke2.io/)
- [kube-vip 项目](https://kube-vip.io/)
- [rancher-load-images.sh](https://github.com/rancher/rancher/releases)
