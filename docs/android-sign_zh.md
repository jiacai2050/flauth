# Android 签名指南

本文档介绍了如何为 Flauth 配置 Android 应用签名，包括本地开发环境和基于 GitHub Actions 的自动化 CI/CD 流程。

## 1. 本地开发配置

若要在本地构建已签名的 Release APK，请遵循以下步骤：

### 第一步：创建密钥库 (Keystore)
如果您还没有密钥库，可以使用以下命令生成：
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 第二步：配置 key.properties
在 `android/` 目录下创建一个名为 `key.properties` 的文件（此文件已被 Git 忽略）：
```properties
storePassword=您的存储密码
keyPassword=您的密钥密码
keyAlias=upload
storeFile=upload-keystore.jks
```

### 第三步：执行构建
运行以下构建命令：
```bash
flutter build apk --release
```
构建系统会自动检测 `key.properties` 并使用您的 JKS 文件进行签名。如果文件缺失，系统将自动回退到 debug 签名模式。

## 3. 验证签名信息

构建完成后，您可以使用 `apksigner` 工具（Android SDK Build Tools 的一部分）来验证 APK 的签名是否正确。

在 **macOS** 上，该工具通常位于：
`~/Library/Android/sdk/build-tools/<版本号>/apksigner`

示例命令：
```bash
~/Library/Android/sdk/build-tools/34.0.0/apksigner verify --print-certs --verbose build/app/outputs/flutter-apk/app-release.apk
```

观察输出结果中的 **Signer #1 certificate DN** 和 **SHA-256 digest**，确认它们是否与您的密钥库信息一致。

---

## 4. F-Droid 与第三方构建说明

我们的 `android/app/build.gradle.kts` 采用了环境无关的设计：
- 如果签名密钥存在，则产出正式签名的 Release 包。
- 如果密钥缺失（例如在 F-Droid 的构建服务器上），系统会**自动回退到 debug 签名**。这确保了任何人在没有私钥的情况下都能顺利编译源码。
