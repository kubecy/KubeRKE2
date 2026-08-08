#!/bin/bash
## 自动从同目录 hosts 解析目标主机、从 site.yml 解析 SSH 用户, 无需修改任何配置
## 用法: bash inventory/<环境名>/ssh-copy.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_FILE="${SCRIPT_DIR}/hosts"
SITE_FILE="${SCRIPT_DIR}/site.yml"

# 从 site.yml 提取 ssh_user (去行内注释), 取不到则默认 admin
SSH_USER="$(sed -n 's/^ssh_user:[[:space:]]*\([^ #]*\).*/\1/p' "${SITE_FILE}" | head -1)"
[ -z "${SSH_USER}" ] && SSH_USER="admin"

# 提取全部 ansible_host IP: 排除注释行, 去重排序
IPS=($(grep -E '^[[:space:]]*[^#]' "${HOSTS_FILE}" \
      | grep -oE 'ansible_host=[0-9.]+' | cut -d= -f2 | sort -u))

if [ "${#IPS[@]}" -eq 0 ]; then
    echo "错误: 未在 ${HOSTS_FILE} 中解析到任何主机"
    exit 1
fi
echo "SSH 用户: ${SSH_USER}"
echo "将向 ${#IPS[@]} 台主机分发公钥: ${IPS[*]}"

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
            ${SSH_USER}@${ip} &>/dev/null

        if [ $? -eq 0 ]; then
            echo "状态: 成功"
        else
            echo "状态: 失败"
        fi
        echo
    done
    unset PASSWORD
}
main
