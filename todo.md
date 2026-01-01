  功能建议列表

  1. 核心体验优化 (High Impact)
   * 搜索与筛选 (Search & Filter): 当账户数量超过 10 个时，滚动查找非常低效。建议在主页顶部增加搜索栏，支持按 Issuer 或 Account Name 过滤。
   * 账户排序 (Reorder): 支持长按拖拽排序，或者将常用账户置顶。目前只能按添加顺序排列。
   * 点击复制与隐藏 (Tap to Reveal/Copy): 为了隐私，默认应该隐藏验证码（显示 *** ***），点击后显示或直接复制到剪贴板。

  2. 视觉增强 (Visuals)
   * 品牌图标 (Brand Icons): Account 模型应增加 iconPath 或 iconUrl 字段。可以使用开源的 Simple Icons 库或者根据 Issuer 名称自动匹配首字母头像。
   * 暗黑模式切换: 虽然支持系统跟随，但有些用户喜欢强制暗黑模式。

  3. 数据安全与备份 (Security & Backup)
   * 加密备份 (Encrypted Backups): 目前的导出是明文 URI，极度危险。建议实现 AES-256 加密的 JSON 导出功能，兼容常见格式（如 Aegis）。
   * 防截屏 (Secure Window): 在 Android 上设置 FLAG_SECURE，防止恶意软件后台截屏或录屏。

  4. 高级功能 (Advanced)
   * 多算法支持: 现在的代码硬编码了 Algorithm.SHA1 和 30s 周期。虽然这是主流，但一些企业 VPN 使用 SHA256 或 60s 周期。Account 模型需要存储这些元数据。
   * 桌面端热键: 在 macOS/Windows 上，支持全局快捷键搜索并复制验证码。

  我建议优先实现：
   1. 搜索功能（代码量小，体验提升大）。
   2. 点击复制 + 隐藏逻辑（隐私保护）。
   3. 加密备份（安全底线）。

  您想先从哪一个开始？
