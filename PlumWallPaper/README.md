# PlumWallPaper 后端架构

## 已完成

### 数据模型（SwiftData）
- ✅ `Wallpaper.swift` - 壁纸数据模型
- ✅ `Tag.swift` - 标签数据模型
- ✅ `FilterPreset.swift` - 色彩滤镜预设模型
- ✅ `Settings.swift` - 应用设置模型

### 存储层
- ✅ `WallpaperStore.swift` - 壁纸存储管理器
  - CRUD 操作
  - 查询操作（全部、收藏、按标签、搜索、最近使用）
  - 重复检测
  - 批量操作
- ✅ `PreferencesStore.swift` - 偏好设置管理器

### 系统集成
- ✅ `DesktopBridge.swift` - macOS 桌面壁纸 API 封装

### 渲染引擎（骨架）
- ✅ `WallpaperRenderer.swift` - 渲染器协议和基础实现
  - `VideoRenderer` - 视频渲染器（待完善）
  - `HEICRenderer` - HEIC 渲染器（待完善）

## 待实现

### 核心功能
- [ ] 完善视频渲染器
  - AVPlayer 配置
  - 硬件解码
  - 循环播放
  - 桌面窗口集成
- [ ] 色彩滤镜系统
  - Core Image 滤镜链
  - AVVideoComposition 集成
  - 实时预览
- [ ] 多显示器管理
  - 显示器检测
  - 拓扑管理
  - 独立渲染
- [ ] 轮播调度器
  - 定时切换
  - 顺序/随机/收藏优先
  - 过渡效果
- [ ] 智能省电策略
  - 系统事件监听
  - 自动暂停/恢复
  - 性能监控

### 工具功能
- [ ] 文件管理
  - 导入处理
  - 缩略图生成
  - 文件哈希计算
  - 重复检测
- [ ] 缓存管理
  - 缓存清理
  - 空间监控

## 项目结构

```
PlumWallPaper/
├── Sources/
│   ├── App/                    # 应用入口（待创建）
│   ├── UI/                     # 界面层（由 Gemini 生成）
│   │   ├── Views/
│   │   └── Components/
│   ├── Core/                   # 核心业务逻辑
│   │   ├── WallpaperEngine/    # ✅ 渲染引擎骨架
│   │   ├── ColorFilter/        # 色彩滤镜（待实现）
│   │   ├── DisplayManager/     # 显示器管理（待实现）
│   │   ├── Scheduler/          # 轮播调度（待实现）
│   │   └── PowerManager/       # 省电管理（待实现）
│   ├── Storage/                # ✅ 数据持久化
│   │   ├── Models/             # ✅ 数据模型
│   │   ├── WallpaperStore.swift
│   │   └── PreferencesStore.swift
│   ├── System/                 # ✅ 系统集成
│   │   └── DesktopBridge.swift
│   └── Resources/              # 资源文件（待添加）
└── Tests/                      # 测试（待创建）
```

## 下一步

1. **等待 Gemini 生成前端 UI**
2. **完善渲染引擎**：
   - 实现完整的视频渲染逻辑
   - 集成 Core Image 滤镜
3. **实现多显示器管理**
4. **实现轮播调度器**
5. **实现智能省电策略**
6. **创建应用入口和生命周期管理**
7. **集成前后端**

## 技术要点

### 性能优化
- 使用 AVPlayer 硬件解码
- GPU 加速滤镜处理
- 独立进程渲染（XPC Service）
- 内存管理和缓存策略

### 系统集成
- NSWorkspace 桌面壁纸 API
- NSScreen 多显示器管理
- NSApplication 生命周期事件
- IOKit 电源管理

### 数据管理
- SwiftData 持久化
- 非破坏性滤镜（参数存储）
- 轻量级索引（只存路径）
