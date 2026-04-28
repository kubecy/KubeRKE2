# 				**Moone-K45 容器云底座平台建设**



# 1. 服务器与网络规划

<img src="https://cdn.nlark.com/yuque/0/2026/png/35290775/1777089611925-3c8ca523-7e14-4627-9fdc-854b8f65c355.png" width="1438.7877956281839" title="" crop="0,0,1,1" id="u480b4bfc" class="ne-image">

<img src="https://cdn.nlark.com/yuque/0/2026/png/35290775/1777089401575-41bbe32a-35eb-413d-9ed5-9fe749f99d9e.png" width="1466.06052132459" title="" crop="0,0,1,1" id="u57d5b827" class="ne-image">

# 2. 离线资源准备（在外网机器执行）

🔔下载 RKE2`v1.34.6+rke2r3`版本，在可访问外网的跳板机或者自己的笔记本上执行，然后统一打包，拷贝到企业内网。

[Releases · rancher/rke2](https://github.com/rancher/rke2/releases?page=2)

1. `rke2-images.linux-amd64.tar.zst`：包含 K8s 核心组件+ 默认网络插件 Canal、Calico 等容器镜像。
2. `rke2-images-cilium.linux-amd64.tar.gz`：仅包含 Cilium 网络插件的镜像。
3. `rke2.linux-amd64.tar.gz`：RKE2 核心程序包。
4. `rke2-images-all.linux-amd64.txt`：全量镜像清单。
5. `sha256sum-amd64.txt`：记录所有包的 SHA256 哈希值，用于下载后验证文件完整性。
6. `rancher-load-images.sh`：镜像加载辅助脚本，批量导入私有镜像仓库。
7. `install.sh`：RKE2 一键安装脚本。
8. `KubeRKE2`：ansible 自动化编排高效批量部署 RKE2。[GitHub - kubecy/KubeRKE2](https://github.com/kubecy/KubeRKE2)




🔔下载完成后

将以下包上传到企业的 Harbor 服务器的`/opt/rke2-offline`目录

1. rke2-images.linux-amd64.tar.zst
2. rke2-images-cilium.linux-amd64.tar.gz
3. rke2-images-all.linux-amd64.txt
4. rancher-load-images.sh

将以下包上传到 ansible 服务器的普通用户（admin）的 app 目录，自定义即可

1. rke2-images-all.linux-amd64.txt
2. sha256sum-amd64.txt
3. rke2.linux-amd64.tar.gz
4. install.sh
5. KubeRKE2

另外 1-4 包移动到 KubeRKE2 目录下的` rke2_packages` 目录中

如下所示：

<img src="https://cdn.nlark.com/yuque/0/2026/png/35290775/1777091908097-3f5a9e61-849e-49d1-b895-ef0f6b2e607d.png" width="1212.7272026335281" title="" crop="0,0,1,1" id="u68d218ae" class="ne-image">

<img src="https://cdn.nlark.com/yuque/0/2026/png/35290775/1777093964646-3eca5422-7c83-409c-b720-d6f7cad6d39f.png" width="1145.4544792490597" title="" crop="0,0,1,1" id="u8391ec8a" class="ne-image">

# 3. 部署 HA_VIP
1. Keepalived+haproxy

```shell
listen k8s-api-ha
    bind 192.168.1.200:8443
    mode tcp
    option tcplog
    balance roundrobin
    server cq-moone-master1 192.168.1.61:6443 weight 3 check inter 5s rise 2 fall 3
    server cq-moone-master2 192.168.1.62:6443 weight 3 check inter 5s rise 2 fall 3
    server cq-moone-master3 192.168.1.63:6443 weight 3 check inter 5s rise 2 fall 3

listen rke2-register
    bind 192.168.1.200:9345
    mode tcp
    option tcplog
    balance roundrobin
    server cq-moone-master1 192.168.1.61:9345 weight 3 check inter 5s rise 2 fall 3
    server cq-moone-master2 192.168.1.62:9345 weight 3 check inter 5s rise 2 fall 3
    server cq-moone-master3 192.168.1.63:9345 weight 3 check inter 5s rise 2 fall 3
```

# 4. RKE2 离线镜像批量导入 Harbor
1. 提前创建一个 rancher 项目名称

<img src="https://cdn.nlark.com/yuque/0/2026/png/35290775/1777092115076-85c815b3-5f62-4530-b40a-3a44e30140c0.png" width="1299.999924862028" title="" crop="0,0,1,1" id="uc6d36bdc" class="ne-image">

2. 去 registry prefix。

```shell
root@jump-server /opt/rke2-offline:~ # sed -i 's#docker.io/##g' rke2-images-all.linux-amd64.txt
```

3. 上传 Cilium 网络插件的镜像

```shell
root@jump-server /opt/rke2-offline:~ # bash rancher-load-images.sh -l rke2-images-all.linux-amd64.txt \
-i rke2-images-cilium.linux-amd64.tar.zst -r harbor.kubecy.com
```

4. 上传 K8S 核心组件+ 默认网络插件 Canal、Calico 等容器镜像

```shell
root@jump-server /opt/rke2-offline:~ # bash rancher-load-images.sh -l rke2-images-all.linux-amd64.txt \
-i rke2-images.linux-amd64.tar.zst -r harbor.kubecy.com
```

5. 登录 Harbor 验证是否上传成功，一般 28 个镜像

<img src="https://cdn.nlark.com/yuque/0/2026/png/35290775/1777093326907-4240c700-1b06-4e06-ad92-0d4cfd78c941.png" width="1316.3635602798715" title="" crop="0,0,1,1" id="u8e55a102" class="ne-image">
<font style="color:#DF2A3F;">⚠️</font><font style="color:#DF2A3F;">注意事项</font>：上传完成后，一定要清理本地镜像。

<img src="https://cdn.nlark.com/yuque/0/2026/png/35290775/1777093397644-6214a3f2-79ff-4aad-8278-714e6061e8eb.png" width="1295.151440293778" title="" crop="0,0,1,1" id="uf802825d" class="ne-image">

# 5. 部署 ansible 环境
## 5.1. 所有 K8S 节点创建 admin 用户
```shell
groupadd -g 2001 admin

useradd -g admin -u 2001 admin -s /bin/bash

echo "CsYPNMnkGNjdveZ" | passwd --stdin admin

echo "admin   ALL=(ALL)    ALL"  >> /etc/sudoers
```

## 5.2. 创建提权加密文件
:::info
🔔在 ansible 主机上执行

:::

1. 在 become: true 场景下，为不同主机动态提供 sudo 密码。
2. 在 KubeRKE2 下创建 `secrets_moone.yml` 加密文件。

```shell
admin@jump-server /home/admin/app/KubeRKE2:~ $ touch secrets_moone.yml
admin@jump-server /home/admin/app/KubeRKE2:~ $ ansible-vault encrypt secrets_moone.yml
New Vault password: 
Confirm New Vault password: 
Encryption successful
```

3. 将 admin 用户密码通过 base64 编码，然后保持在加密`secrets_moone.yml`文件中，如下所示

```shell
admin@jump-server /home/admin/app/KubeRKE2:~ $ echo "CsYPNMnkGNjdveZ" | base64 
Q3NZUE5NbmtHTmpkdmVaCg==
admin@jump-server /home/admin/app/KubeRKE2:~ $ ansible-vault edit secrets_moone.yml 
Vault password: 
---
servers:
  cq-moone-master1: 
    sudopass: "Q3NZUE5NbmtHTmpkdmVaCg=="
  cq-moone-master2:
    sudopass: "Q3NZUE5NbmtHTmpkdmVaCg=="
  cq-moone-master3:
    sudopass: "Q3NZUE5NbmtHTmpkdmVaCg=="
  cq-moone-worker1:
    sudopass: "Q3NZUE5NbmtHTmpkdmVaCg=="
  cq-moone-worker2:
    sudopass: "Q3NZUE5NbmtHTmpkdmVaCg=="
  cq-moone-worker3:
    sudopass: "Q3NZUE5NbmtHTmpkdmVaCg=="
```

## 5.3. ansible 主机免密所有 K8S 主机（admin）
```shell
cat > ssh-copy.sh << 'EOF'
#!/bin/bash
USER="admin"
IPS=(
192.168.1.61
192.168.1.62
192.168.1.63
192.168.1.71
192.168.1.72
192.168.1.73
)
check_security() {
    if ! command -v sshpass &>/dev/null; then
        echo "错误: 请先安装 sshpass 工具"
        exit 1
    fi

    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        echo "信息: 未检测到 SSH Key，自动生成..."
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
        if [ $? -ne 0 ]; then
            echo "错误: SSH Key 生成失败"
            exit 1
        fi
        echo "信息: SSH Key 生成成功"
    fi

    chmod 600 ~/.ssh/id_rsa
    chmod 644 ~/.ssh/id_rsa.pub
}

main() {
    check_security
    read -s -p "请输入目标主机的密码: " PASSWORD
    echo
    for ip in "${IPS[@]}"; do
        echo "处理主机: $ip"
        sshpass -p "$PASSWORD" ssh-copy-id \
            -o StrictHostKeyChecking=accept-new \
            -o ConnectTimeout=10 \
            -o ServerAliveInterval=5 \
            -o ServerAliveCountMax=3 \
            -o PasswordAuthentication=yes \
            ${USER}@${ip} &>/dev/null

        if [ $? -eq 0 ]; then
            echo "状态: 成功"
        else
            echo "状态: 失败"
        fi
        echo
    done
    unset PASSWORD
    echo "公钥分发完成"
}
main
EOF
```

# 6. 配置主机清单
```shell
admin@jump-server /home/admin/app/KubeRKE2:~ $ cat inventory/hosts 
## control-plane, etcd节点
[kube_control_plane_node]
cq-moone-master1 ansible_host=192.168.1.61 init_master=true
cq-moone-master2 ansible_host=192.168.1.62
cq-moone-master3 ansible_host=192.168.1.63


## 工作节点
[kube_worker_node]
cq-moone-worker1 ansible_host=192.168.1.71
cq-moone-worker2 ansible_host=192.168.1.72
cq-moone-worker3 ansible_host=192.168.1.73
```

# 7. 部署 RKE2 SERVER
```shell
admin@jump-server /home/admin/app/KubeRKE2:~ $ ansible-playbook --ask-vault-pass playbooks/kube_control_plane_node.yml
Vault password: 


## 可在目录主机查看日志
journalctl -u rke2-server -f
```

# 8. 部署 RKE2 AGENT
```shell
admin@jump-server /home/admin/app/KubeRKE2:~ $ ansible-playbook --ask-vault-pass playbooks/kube_worker_node.yml 
Vault password: 


## 可在目录主机查看日志
journalctl -u rke2-agent -f
```