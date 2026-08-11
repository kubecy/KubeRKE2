# rke2ctl download 子命令简化为配置驱动

日期: 2026-08-11
状态: 已批准

## 背景

`rke2ctl download` 的帮助文档、README 与 bash-completion 仍描述旧语法:

```
./rke2ctl download <版本> [架构] [环境名]
```

而 `cmd_download` 的实际实现已支持新语法:参数为 `[环境名]`(缺省 `sample`),`rke2_version` / `arch` / `cni` 全部取自该环境 `site.yml`。需要将文档与补全逻辑统一到新语法:

```
./rke2ctl download                 # 按 sample 的 rke2_version/arch/cni 下载
./rke2ctl download zxjt-k99        # 按 zxjt-k99 的 rke2_version/arch/cni 下载
```

## 改动范围

`cmd_download` 本体逻辑**不改动**。仅清理旧语法残留:

### 1. `rke2ctl` usage()(第 45、52-53 行)

- download 用法行改为:`./rke2ctl download [环境名]  按环境 site.yml 的 rke2_version/arch/cni 下载至 packages_rke2/<版本>/<架构>/`
- 示例改为:
  - `./rke2ctl download` — 按 sample 配置下载
  - `./rke2ctl download zxjt-k99` — 按 zxjt-k99 配置下载

### 2. `rke2ctl` cmd_install_completion()(第 306-319 行)

download 分支改为:
- 第 2 参数补全环境名(inventory 下所有目录, 排除 sample, 复用 setup 分支的逻辑)
- 移除第 3 参数(架构)补全分支

### 3. `rke2ctl` cmd_download 失败提示(第 480 行)

`修复后重跑: ./rke2ctl download ${version} ${arch_in} ${env_name}` 改为 `./rke2ctl download ${env_name}`(同时修复未定义变量 `${arch_in}` 的残留)。

### 4. `README.md`(第 29-30 行)

快速下载示例同步改为新语法, 并说明版本/架构/CNI 均取自指定环境(缺省 sample)的 site.yml。

## 验证

1. `./rke2ctl help` 输出新语法(无 `<版本> [架构]`)
2. 执行 `./rke2ctl bash-completion` 后, `download <Tab>` 补全出环境名列表而非架构
3. `./rke2ctl download` 无参数时解析 sample 配置: `rke2_version=v1.34.6+rke2r3 arch=amd cni=cilium`, 目标目录 `packages_rke2/v1.34.6+rke2r3/amd64/`
