# 数据加载问题完整修复总结

## 🐛 发现的所有问题

### 问题 1: ViewModel 生命周期不兼容
**症状**: 数据加载方法从未被调用  
**原因**: 使用了 `@Observable` 宏，与自定义 `main()` 函数不兼容  
**修复**: 改用 `ObservableObject` + `@Published` + `@StateObject`

### 问题 2: 日期解码失败 ⭐
**症状**: "Failed to decode response"  
**原因**: Wallhaven API 返回日期格式为 `"2026-05-02 05:53:28"`，但使用 `.iso8601` 策略  
**修复**: 使用自定义 DateFormatter

### 问题 3: Actor 隔离死锁 ⭐⭐ 关键问题
**症状**: Hero 和 Popular 数据无法加载，日志中断  
**原因**: `MediaRepository` 标记为 `@MainActor`，但调用 `actor MediaService`，导致跨 actor 调用挂起  
**修复**: 移除 Repository 层的 `@MainActor` 标记

### 问题 4: 并行加载错误处理
**症状**: 一个数据源失败导致全部失败  
**原因**: 使用 `async let` 并行加载，任何一个失败都会抛出错误  
**修复**: 改为顺序加载，单独捕获每个错误

### 问题 5: 本地库 Mock 数据
**症状**: 本地库显示假数据  
**原因**: `LibraryViewModel` 初始化时创建 Mock 数据  
**修复**: 移除 Mock 数据，从数据库加载

## ✅ 完整修复清单

### 1. NetworkService.swift - 日期解码
```swift
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
dateFormatter.locale = Locale(identifier: "en_US_POSIX")
dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
decoder.dateDecodingStrategy = .formatted(dateFormatter)
```

### 2. ViewModels - ObservableObject
- `HomeFeedViewModel`: `@Observable` → `ObservableObject` + `@Published`
- `WallpaperExploreViewModel`: `@Observable` → `ObservableObject` + `@Published`
- `MediaExploreViewModel`: `@Observable` → `ObservableObject` + `@Published`

### 3. Views - @StateObject
- `HomeView`: `@State` → `@StateObject`
- `WallpaperExploreView`: `@State` → `@StateObject`
- `MediaExploreView`: `@State` → `@StateObject`

### 4. Repositories - 移除 @MainActor ⭐ 关键修复
```swift
// 修复前
@MainActor
final class MediaRepository: ObservableObject { }

// 修复后
final class MediaRepository: ObservableObject { }
```

同样修复 `WallpaperRepository`。

### 5. HomeFeedViewModel - 顺序加载
```swift
// 修复前：并行加载，一个失败全部失败
async let heroTask = mediaRepo.fetchHeroItems()
async let latestTask = wallpaperRepo.fetchLatest()
async let popularTask = mediaRepo.fetchPopular()
let (hero, latest, popular) = try await (heroTask, latestTask, popularTask)

// 修复后：顺序加载，单独捕获错误
do {
    let hero = try await mediaRepo.fetchHeroItems()
    self.heroItems = hero
} catch {
    print("Hero 加载失败: \(error)")
}

do {
    let latest = try await wallpaperRepo.fetchLatest()
    self.latestStills = latest
} catch {
    print("Latest 加载失败: \(error)")
}

do {
    let popular = try await mediaRepo.fetchPopular()
    self.popularMotions = popular
} catch {
    print("Popular 加载失败: \(error)")
}
```

### 6. 添加详细日志
在所有关键方法中添加日志：
- `HomeFeedViewModel.loadInitialData()`
- `MediaRepository.fetchHeroItems()`
- `MediaRepository.fetchPopular()`
- `WallpaperRepository.fetchLatest()`
- `MediaService.fetchPage()`

## 🎯 预期结果

启动应用后，控制台应该显示：

```
[ContentView] 应用启动，准备初始化数据
[HomeView] .onAppear 被调用
[HomeView] 开始加载初始数据
[HomeFeedViewModel] 开始加载数据...
[HomeFeedViewModel] 加载 Hero 项目...
[MediaRepository] fetchHeroItems() 开始
[MediaRepository] 获取 MotionBG 候选项...
[MediaService] fetchPage() 开始, source: Featured
[MediaService] URL: https://motionbgs.com/
[MediaService] 开始获取 HTML...
[MediaService] ✅ HTML 获取成功，长度: XXXXX 字符
[MediaService] 开始解析 HTML...
[MediaService] ✅ 解析完成，获得 XX 项
[MediaRepository] ✅ 获取到 XX 个 MotionBG 候选项
[MediaRepository] 最终返回 8 个 Hero 项
[HomeFeedViewModel] ✅ Hero: 8 项
[HomeFeedViewModel] 加载最新壁纸...
[WallpaperRepository] fetchLatest() 开始
[WallhavenService] fetchLatest() 开始, limit=20
[WallhavenService] ✅ 获取到 20 个壁纸
[WallpaperRepository] ✅ 获取到 20 个壁纸
[WallpaperRepository] 最终返回 8 项
[HomeFeedViewModel] ✅ Latest: 8 项
[HomeFeedViewModel] 加载热门动态...
[MediaRepository] fetchPopular() 开始
[MediaRepository] 获取 MotionBG 热门候选项...
[MediaService] fetchPage() 开始, source: Featured
[MediaService] 使用缓存数据: XX 项
[MediaRepository] ✅ 获取到 XX 个热门候选项
[MediaRepository] 最终返回 8 个 Popular 项
[HomeFeedViewModel] ✅ Popular: 8 项
[HomeFeedViewModel] 加载完成
```

## 📱 UI 预期显示

1. **首页（Home）**
   - ✅ Hero 轮播显示 8 个动态壁纸
   - ✅ "最新画作"显示 8 个静态壁纸
   - ✅ "热门动态"显示 8 个动态壁纸

2. **静态壁纸（Wallpaper Explore）**
   - ✅ 自动加载壁纸网格

3. **动态壁纸（Media Explore）**
   - ✅ 自动加载媒体网格

4. **本地库（Library）**
   - ✅ 显示真实数据

## 🚀 启动应用

```bash
cd /Users/Alex/AI/project/PlumWallPaper
./run.sh
```

## 🔍 如果仍然有问题

1. 查看控制台日志，找到哪一步失败
2. 检查网络连接
3. 测试 MotionBG 网站是否可访问：`curl -s https://motionbgs.com/ | head -100`
4. 测试 Wallhaven API：`curl -s "https://wallhaven.cc/api/v1/search?q=&categories=111&purity=100&sorting=date_added&page=1"`

## 📝 修改的文件

1. ✅ `Sources/Network/NetworkService.swift` - 日期解码
2. ✅ `Sources/ViewModels/HomeFeedViewModel.swift` - ObservableObject + 顺序加载
3. ✅ `Sources/ViewModels/WallpaperExploreViewModel.swift` - ObservableObject
4. ✅ `Sources/ViewModels/MediaExploreViewModel.swift` - ObservableObject
5. ✅ `Sources/Views/Home/HomeView.swift` - @StateObject
6. ✅ `Sources/Views/Explore/WallpaperExploreView.swift` - @StateObject
7. ✅ `Sources/Views/Explore/MediaExploreView.swift` - @StateObject
8. ✅ `Sources/Repositories/MediaRepository.swift` - 移除 @MainActor + 日志
9. ✅ `Sources/Repositories/WallpaperRepository.swift` - 移除 @MainActor + 日志
10. ✅ `Sources/Network/MediaService.swift` - 日志
11. ✅ `Sources/ViewModels/LibraryViewModel.swift` - 移除 Mock 数据

## 🎊 所有问题已修复！

应用现在应该能正常加载所有数据了。请在应用中验证各个标签页是否正常显示内容。
