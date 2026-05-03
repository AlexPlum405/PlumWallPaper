# Hero 和热门动态无法加载 - 问题分析和解决方案

## 🔍 问题诊断

### 日志显示
```
[MediaRepository] ✅ 获取到 0 个 MotionBG 候选项
[MediaRepository] 最终返回 0 个 Hero 项
[HomeFeedViewModel] ✅ Hero: 0 项
[HomeFeedViewModel] ✅ Popular: 0 项
[HomeFeedViewModel] ✅ Latest: 8 项  ← 这个成功了
```

### 根本原因
**MediaService 的 HTML 解析器使用了错误的选择器**

- 当前代码使用：`div.item, article.item, div.wallpaper-item`
- MotionBG 实际使用：`a[title*='live wallpaper']`

## 📋 解决方案

### 方案 1: 使用 WaifuX 的 MediaService（推荐）

WaifuX 已经有一个完整且经过测试的 MediaService 实现，支持配置文件驱动的解析器。

**步骤**：
1. 复制 WaifuX 的 MediaService.swift
2. 复制 DataSourceProfile.json 配置文件
3. 更新 MediaItem 模型以匹配 WaifuX 的字段

**优点**：
- 已经过验证，可以正常工作
- 支持配置文件，易于维护
- 包含完整的错误处理

### 方案 2: 修复当前的 MediaService

需要修改 `parseListPage` 方法：

```swift
private func parseListPage(html: String, source: MediaRouteSource, pageURL: URL) -> MediaListPage {
    let title = parsePageTitle(html: html) ?? source.defaultTitle
    var seen = Set<String>()
    var items: [MediaItem] = []

    do {
        let document = try SwiftSoup.parse(html)
        // 使用正确的选择器
        let elements = try document.select("a[title*='live wallpaper']")

        for element in elements {
            // 提取标题
            guard let titleElement = try? element.select("span.ttl").first(),
                  let titleText = try? titleElement.text(),
                  !titleText.isEmpty else {
                continue
            }

            // 提取图片
            guard let imgElement = try? element.select("img").first(),
                  let imageSrc = try? imgElement.attr("src"),
                  !imageSrc.isEmpty else {
                continue
            }

            // 提取链接
            guard let href = try? element.attr("href"),
                  !href.isEmpty else {
                continue
            }

            // 从 href 提取 slug
            let slug = href.replacingOccurrences(of: "/media/", with: "")
                .replacingOccurrences(of: "/", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !slug.isEmpty, seen.insert(slug).inserted else {
                continue
            }

            let cleanTitle = titleText.replacingOccurrences(of: " live wallpaper", with: "", options: [.caseInsensitive])

            // 构建完整的图片 URL
            let fullImageURL: URL?
            if imageSrc.hasPrefix("http") {
                fullImageURL = URL(string: imageSrc)
            } else if imageSrc.hasPrefix("/") {
                fullImageURL = absoluteURL(for: imageSrc)
            } else {
                fullImageURL = absoluteURL(for: "/\(imageSrc)")
            }

            let item = MediaItem(
                id: slug,
                slug: slug,
                title: cleanTitle,
                thumbnailURL: fullImageURL,
                resolutionLabel: "Unknown",
                tags: [],
                authorName: nil,
                viewCount: nil,
                subscriptionCount: nil,
                favoriteCount: nil,
                createdAt: nil
            )

            items.append(item)
        }
    } catch {
        NSLog("[MediaService] parseListPage error: \(error)")
    }

    return MediaListPage(
        title: title,
        items: items,
        nextPagePath: parseNextPagePath(html: html)
    )
}
```

### 方案 3: 临时禁用 MotionBG（快速修复）

如果只想先让应用运行起来，可以临时禁用 MotionBG 数据源：

```swift
// MediaRepository.swift
func fetchHeroItems() async throws -> [MediaItem] {
    // 临时返回空数组
    return []
}

func fetchPopular() async throws -> [MediaItem] {
    // 临时返回空数组
    return []
}
```

这样至少"最新画作"部分可以正常显示。

## 🎯 推荐行动

1. **立即**: 使用方案 3 临时禁用 MotionBG，让应用可以运行
2. **短期**: 实施方案 2 修复 MediaService 的解析器
3. **长期**: 考虑方案 1，使用 WaifuX 的完整实现

## 📝 相关文件

- `/Users/Alex/AI/project/PlumWallPaper/Sources/Network/MediaService.swift` - 需要修复
- `/Users/Alex/AI/project/PlumWallPaper/Sources/Repositories/MediaRepository.swift` - 调用 MediaService
- `/Users/Alex/AI/project/WaifuX/Services/MediaService.swift` - 参考实现
- `/Users/Alex/AI/project/WaifuX/Resources/DataSourceProfile.json` - 配置文件

## 🔧 当前状态

- ✅ 日期解码已修复
- ✅ ViewModel 生命周期已修复
- ✅ Actor 隔离已修复
- ✅ 最新壁纸可以正常加载
- ❌ Hero 轮播无法加载（MediaService 解析器问题）
- ❌ 热门动态无法加载（MediaService 解析器问题）

## 💡 下一步

请选择一个方案并告诉我，我会帮你实施。
