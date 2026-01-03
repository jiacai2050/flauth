# 从 Aegis Authenticator 导入账号

Aegis 是一款流行的 Android 开源双重认证管理器。从 Aegis 迁移到 Flauth 非常简单且高效。

## 推荐方法：URI 列表批量导入

此方法允许您利用 Flauth 的本地导入功能，一次性迁移所有账号。

### 第一步：从 Aegis 导出
1.  在 Android 设备上打开 **Aegis**。
2.  点击 **设置**（齿轮图标）或右上角的三个点菜单。
3.  进入 **导入 / 导出 (Import / Export)**。
4.  选择 **导出 (Export)**。
5.  选择 **明文 JSON (Plain-text JSON)** 或 **明文 URI 列表 (Plain-text URI list)**。
    *   *提示：Flauth 对 URI 列表有原生支持，兼容性最好。*
6.  点击 **导出到文件 (Export to file)** 并保存到您的设备。

### 第二步：准备文件
Flauth 识别以 `.flauth` 结尾的文件。
1.  找到您刚刚导出的文件（通常名为 `aegis-export-....txt` 或 `.json`）。
2.  将文件后缀重命名为 `.flauth`。例如：`otpauth-backup.flauth`。

### 第三步：导入 Flauth
1.  打开 **Flauth**。
2.  在主屏幕菜单中进入 **备份与恢复 (Backup & Restore)**。
3.  切换到 **本地文件 (Local File)** 标签页。
4.  点击 **从文件导入 (Import from File)**。
5.  选择您准备好的 `.flauth` 文件。
6.  Flauth 将显示成功导入的新账号数量。

---

## 备选方法：二维码（逐个导入）

如果您只有少量账号，可以逐个扫码：
1.  在 Aegis 中，长按某个账号并选择 **显示二维码 (Show QR code)**。
2.  在 Flauth 中，点击主屏幕右下角的 **[+]** 按钮。
3.  选择 **扫描二维码 (Scan QR Code)** 并对准 Aegis 显示的屏幕。

## ⚠️ 安全提示
导入成功后，请**立即且彻底删除**从 Aegis 导出的明文文件，因为它包含了您所有未加密的 2FA 密钥。
