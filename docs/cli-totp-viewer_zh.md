# CLI TOTP 查看工具

读取 Flauth 备份文件，并在终端中输出当前 TOTP 验证码。

## 构建

```bash
make build-cli
```

产物：

```bash
build/flauth-cli
```

## 环境变量

- `FLAUTH_BACKUP_FILE`：必填，`.flauth` 备份文件路径
- `FLAUTH_BACKUP_PASSWORD`：仅加密备份需要

## 用法

显示所有账号：

```bash
FLAUTH_BACKUP_FILE=./backup.flauth ./build/flauth-cli
```

按关键字过滤：

```bash
FLAUTH_BACKUP_FILE=./backup.flauth ./build/flauth-cli github
```

读取加密备份：

```bash
FLAUTH_BACKUP_FILE=./backup.flauth \
FLAUTH_BACKUP_PASSWORD='your-password' \
./build/flauth-cli
```

可选位置参数是过滤条件，会对 `issuer` 和 `name` 做忽略大小写的 `contains` 匹配。

## 输出

```text
GitHub  alice@example.com  123456
Google  bob@gmail.com      654321
```

验证码中间不插空格，便于直接复制。

## 常见错误

- `Backup file is required via FLAUTH_BACKUP_FILE.`
- `Encrypted backup requires FLAUTH_BACKUP_PASSWORD.`
- `Backup file does not exist`
- `No valid accounts found in backup file.`

## 说明

- 支持 Flauth 明文和加密备份
- 只读取备份文件，不会修改文件
- 过滤逻辑只检查 `issuer` 和 `name`
