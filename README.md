# TWThreat v1.4.0
Turtle WoW 仇恨监控插件
<br>
使用条件：处于`小队`或`团队`中，攻击`精英`怪物或`Boss`。
<br>

## 安装说明

1. 下载本项目
2. 将文件夹放入 WoW 目录：`Interface\AddOns\`
3. **文件夹必须命名为 `TWThreat`**（GitHub 下载的 zip 解压后需将 `tw-threatmeter-main` 重命名）

## 更新日志

### 1.4.0 (anym 分支)

**架构重写：XML → 纯 Lua UI**
- 整个 UI 系统从 XML 帧定义重写为纯 Lua 代码（`TWThreat_UI.lua`）
- 移除对 XML 模板的依赖（`TankModeExtraFrameTemplate` 等）
- 所有帧（主窗口、设置、坦克模式、目标覆盖层、插件状态）均通过代码动态创建
- 视觉风格对齐 ShaguDPS，保持界面一致性

**完整中文本地化**
- 所有 UI 文本、设置项、提示信息、聊天消息的简繁中文翻译
- 通过 `GetLocale()` 自动检测语言

**Bug 修复**
- 修复 Lua 5.0 兼容性：将 `%` 取模运算符（Lua 5.1+ 语法）替换为 `math.mod()`，此问题导致整个插件无法加载
- 修复 `math.mod()` 负数取模行为导致 TPS 环形缓冲区回绕后始终返回 0 的问题
- 修复 `UnitClass('player')` 返回本地化职业名（如"战士"）而非英文标识符，导致非英文客户端职业颜色不匹配
- 修复仇恨条背景（`bar.bg`）的父帧为主窗口而非条本身，隐藏仇恨条后深色背景残留溢出

**新功能**
- 设置面板新增行高调节（10-30px），可在固定窗口内显示更多行数
- 设置面板新增条间距调节（0-10px）
- 设置面板新增条纹理选择器（4 种内置纹理）
- 柔和色模式开关
- 背景显隐开关
- 窗口缩放设置（50%-150%）
- 战斗/非战斗透明度设置
- OT 警告阈值滑块（65-95%）

### 1.3.0
- 修复其他插件干扰目标选择时仇恨显示丢失的问题
- 安装 SuperWoW 后可直接点击坦克模式目标进行选中
- 仇恨条更新动画更流畅

### 1.2.3 unofficial balake version
- 目标处于战斗状态时即查询仇恨，即使玩家未进入战斗或未产生仇恨
- 统一各专精的更新速度

### v1.2.3
- 适配 TW 16.0 补丁

### v1.2.2
- 条动画修复
- TankName bug 修复
- 可配置 OT 警告阈值

### v1.2.1
- 坦克模式窗口随主窗口缩放

### v1.2.0
- 仇恨 API v4，旧版本不再兼容
- [pfUI](https://github.com/shagu/pfUI) 目标头像发光和仇恨百分比集成
- 坦克模式回归
- 新 OT 警告音效
- 新按钮图标（设置/锁定/关闭）

### v1.1.0
- 仇恨 API v3，旧版本不再兼容
- 召唤生物显示正确的仇恨值
- 新增战斗/非战斗透明度设置

### v1.0.2
- 设置窗口改为分页式
- 新增窗口缩放设置
- 启用条动画
- 禁用坦克模式（仍有 bug）

### v1.0.1
- 更快的 GUID 获取方式
- 坦克模式窗口可拖动，可吸附到主窗口的上/下/左/右
- 坦克模式窗口在配置模式下显示测试数据
- 坦克模式目标颜色优化，当前目标高亮
- 治疗者的窗口标题更稳定
- 移除条动画（可能是临时的）
- 目标死亡后为治疗者清除仇恨条
- 修复 Pull Agro At 条不显示的潜在 bug
- 修复坦克不在仇恨列表首位时的 tankthreat bug

## 功能特性
- 仇恨值、OT 所需仇恨、每秒仇恨(TPS)、最大百分比、OT 百分比
- 默认目标头像和 pfUI 目标头像的仇恨发光效果
- 默认目标头像和 pfUI 目标头像的仇恨百分比显示
- 可调节行高、间距、纹理、柔和色
- 窗口缩放、战斗/非战斗透明度、背景显隐
- 高仇恨时全屏红色发光警告
- 高仇恨时 OT 警告声音
- 可自定义 TPS、仇恨值、百分比列的显隐
- 完整中文（简体/繁体）本地化
- 坦克模式

## 斜杠命令
- `/twtshow` — 显示主窗口
- `/twt show` — 显示主窗口
- `/twt toggle` — 切换窗口显示
- `/twt lock` — 切换窗口锁定
- `/twt reset` — 重置仇恨数据
- `/twt texture [1-4]` — 设置条纹理
- `/twt spacing [0-10]` — 设置条间距
- `/twt scale [50-150]` — 设置窗口缩放
- `/twt pastel` — 切换柔和色
- `/twt backdrop` — 切换背景
- `/twt tankmode` — 切换坦克模式
- `/twt debug` — 切换调试模式
- `/twt who` — 查询团队插件状态

## 设置说明

### 目标发光
在默认 UI 目标头像上显示绿/黄/红渐变光环。光环颜色基于当前仇恨百分比：
- 绿色 → 黄色：0% - 49%
- 黄色 → 红色：50% - 100%

### 全屏发光
仇恨超过 OT 阈值时屏幕边缘红色发光警告。坦克模式下自动禁用。

### OT 警告声音
仇恨达到 OT 阈值时播放警告音效。坦克模式下自动禁用。

### 仇恨百分比
在目标头像上显示仇恨百分比数值。

### 战斗显示 / 战斗隐藏
战斗开始时自动显示窗口，战斗结束后自动隐藏窗口。

### 坦克模式
显示一个额外窗口，列出你正在拉住的怪物，以及仇恨列表中下一个玩家的名字和仇恨百分比，方便快速换目标（此模式会禁用全屏发光和 OT 警告声音）。

### 标签行 / 列显隐
可单独控制 TPS、仇恨值、百分比列及标签行的显示与隐藏。


## 贡献者与测试者
[Henry](https://armory.turtle-wow.org/#!/character/Henry)、[Laughadin](https://armory.turtle-wow.org/#!/character/Laughadin)、[Faralynn](https://armory.turtle-wow.org/#!/character/Faralynn)、[Draxer](https://armory.turtle-wow.org/#!/character/Draxer) <br><br>

## 作者
[Xerron/Er](https://github.com/MarcelineVQ/TWThreat) — TWThreat 原作者<br>
v1.4.0 by anym — XML→Lua 架构重写、完整中文本地化、Bug 修复

## 支持原作者
如果你喜欢原作者的工作，可以请他喝杯咖啡！<br>
https://ko-fi.com/xerron

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/xerroner)
