# 抓住小宝贝 (CatchMe)

一个适合爸爸和女儿一起玩的 iOS 方格追逐游戏,SwiftUI 原生实现,无第三方依赖。

## 玩法

- 10x10 方格棋盘,爸爸 👨 从左上角出发,女儿 👧 从右下角出发
- 回合制:女儿先走、爸爸后走,每次只能走相邻一格(上/下/左/右)
- 爸爸走进女儿所在的格子 → **爸爸获胜**
- 女儿撑满限定回合数(可选 20 / 30 / 40)没被抓住 → **女儿获胜**

## 游戏模式

| 模式 | 说明 |
|---|---|
| 双人对战 | 同一台设备轮流走棋 |
| 我当爸爸 | AI 控制女儿逃跑(拉开距离 + 保住安全区域) |
| 我当女儿 | AI 控制爸爸追捕(逼角策略,模拟验证 100% 能在 30 回合内抓住) |

## 环境要求

- Xcode 26+(iOS 17.0+ 部署目标)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)(`brew install xcodegen`)

## 构建运行

```bash
xcodegen generate          # 由 project.yml 生成 CatchMe.xcodeproj
open CatchMe.xcodeproj     # 在 Xcode 中打开,选模拟器或真机运行
```

## 项目结构

```
CatchMe/
├── CatchMeApp.swift          # 入口
├── Models/
│   ├── GameState.swift       # 棋盘、回合、胜负判定(纯逻辑)
│   └── AIPlayer.swift        # 追捕 / 逃跑 AI
└── Views/
    ├── MenuView.swift        # 主菜单(模式 + 回合数)
    ├── BoardView.swift       # 棋盘渲染与点击走棋
    └── GameView.swift        # 对局界面、状态栏、胜负弹窗
```
# Catch Me
