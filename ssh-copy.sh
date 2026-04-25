#!/bin/bash

USER="admin"
PASSWORD="123456"

IPS=(
192.168.1.61
192.168.1.62
192.168.1.63
192.168.1.71
192.168.1.72
192.168.1.73
)

if ! command -v sshpass &>/dev/null; then
    echo "请先安装 sshpass"
    exit 1
fi

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "未检测到 SSH Key，自动生成..."
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

for ip in "${IPS[@]}"; do
    echo "====== $ip ======"

    sshpass -p "$PASSWORD" ssh-copy-id \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        ${USER}@${ip} &>/dev/null

    if [ $? -eq 0 ]; then
        echo "✔ 成功"
    else
        echo "✖ 失败"
    fi
done
