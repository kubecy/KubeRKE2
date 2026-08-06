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
    read -s -p "输入目标主机的密码: " PASSWORD
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
}
main
