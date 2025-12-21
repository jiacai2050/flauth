# Flauth 🔐

Flauth 是一款使用 Flutter 开发的开源 TOTP（基于时间的一次性密码）身份验证器。它旨在提供一个简洁、安全且轻量级的 2FA（双重身份验证）管理方案。

## ✨ 功能特性

- **动态验证码**：生成标准的 6 位 TOTP 验证码，每 30 秒自动刷新。
- **扫码添加**：支持扫描 `otpauth://` 标准二维码快速添加账号。
- **手动添加**：支持手动输入密钥信息。
- **安全存储**：使用 `flutter_secure_storage` 将密钥加密存储在设备的 Secure Enclave (iOS/macOS) 或 Keystore (Android) 中。
- **实时进度条**：直观展示验证码剩余有效时间。
- **便捷操作**：
  - **点击复制**：点击验证码即可快速复制。
  - **滑动删除**：支持左滑删除账号并带有二次确认。
- **主题适配**：完美适配系统的深色/浅色模式。

## 🛠️ 技术栈

- **Flutter & Dart**
- **[Provider](https://pub.dev/packages/provider)**: 状态管理。
- **[OTP](https://pub.dev/packages/otp)**: 核心算法实现。
- **[Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)**: 安全数据持久化。
- **[Mobile Scanner](https://pub.dev/packages/mobile_scanner)**: 二维码识别。

## 🚀 快速开始

### 前置条件
- 已安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)
- 对应的开发环境 (Android Studio / Xcode)

### 安装步骤

1. 克隆并进入项目目录：
   ```bash
   git clone <repository-url>
   cd flauth
   ```

2. 安装依赖：
   ```bash
   flutter pub get
   ```

3. 运行应用：
   ```bash
   flutter run
   ```

## 📸 应用截图
*(这里可以放置应用运行时的截图)*

## 🛡️ 权限说明

- **相机**：用于扫描二维码添加账号。
- **存储**：用于加密保存您的账号密钥。

## 📄 开源协议

本项目采用 MIT 协议。