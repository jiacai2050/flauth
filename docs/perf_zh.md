# Flauth 性能设计文档

Flauth 旨在成为一个高性能、省电的隐私优先型 TOTP 验证器。本文档解释了为了确保在 100ms 高频全局心跳下依然保持流畅 UI 体验的关键架构决策。

## 1. 带有细粒度更新的全局心跳

应用程序使用一个中央 `AccountProvider`，其中包含一个每 **100ms** 运行一次的 `Timer.periodic`。

- **为什么是 100ms？** 这提供了 10Hz 的刷新率，这是 `LinearProgressIndicator`（进度条）的“黄金平衡点”。它确保进度条在 30 秒的 TOTP 窗口内平滑移动，而不会显得卡顿或跳帧。
- **为什么是持久运行？** 无论账号列表大小如何，计时器都会持续运行。这简化了状态机逻辑，并确保只要添加或显示账号，UI 就能立即显示正确的进度。

## 2. 重绘优化 (context.select)

最关键的优化在于单个 `AccountTile` 组件消费数据的方式。

### 问题所在
如果每个 `AccountTile` 都使用 `Provider.of<AccountProvider>(context)`，那么每秒钟每个卡片都会重绘 **10 次**。因为 Provider 每 100ms 就会为了更新顶部的进度条而通知所有监听者。

### 解决方案：选择器模式 (Selector Pattern)
我们在 `AccountTile` 内部使用 `context.select<AccountProvider, int>((p) => p.remainingSeconds)`。

- **过滤通知**：当 `notifyListeners()` 被调用时，`select` 会执行选择器函数，并将返回的 `int` 值与上一次的值进行对比。
- **延迟重绘**：由于 `remainingSeconds` 每 1000ms 才会改变一次，`AccountTile` 组件会自动忽略掉 10 次通知中的 9 次。
- **结果**：即使有 100 多个账号，UI 线程在大部分时间内也处于空闲状态，每个特定的卡片每秒仅更新一次。

## 3. 高效的 TOTP 生成

TOTP 验证码使用 `otp` 库生成，该库执行 HMAC-SHA1 计算。

- **按需计算**：验证码不会预先计算或存储在 Provider 的状态中。相反，它们是在 `AccountTile` 的 `build` 阶段实时计算的。
- **性能表现**：HMAC-SHA1 是一种非常轻量级的加密操作。现代移动 CPU 每秒可以执行数千次此类计算，因此在组件每秒一次的重绘过程中进行计算是绝对安全的。

## 4. 解耦的服务层

- **StorageService**：使用 `flutter_secure_storage`，将敏感数据处理交给操作系统（iOS 的 Keychain 或 Android 的 Keystore）。这是一个异步操作，不会阻塞 UI 线程。
- **WebDavService**：所有的网络 I/O 和路径规格化逻辑都封装在一个静态服务中。这保持了 `AccountProvider` 的简洁，使其仅专注于状态管理。

## 5. UI 刷新率总结

| 组件 | 刷新频率 | 优化策略 |
| :--- | :--- | :--- |
| **全局计时器** | 100ms (10Hz) | `Timer.periodic` |
| **进度条** | 100ms (10Hz) | 在 `HomeScreen` 中直接消费 |
| **账号卡片** | 1000ms (1Hz) | `context.select` 局部刷新优化 |
| **WebDAV 同步** | 按需触发 | 手动触发 |

通过将高频全局心跳与低频局部消费相结合，Flauth 在保持极低电池消耗的同时，实现了“丝般顺滑”的交互体验。
