#!/usr/bin/env swift
import Foundation

@MainActor
class TestRunner {
    func runTests() async {
        print("=== 开始测试网络服务 ===\n")

        // 测试 1: 直接 HTTP 请求
        print("测试 1: 直接 HTTP 请求 Wallhaven API")
        await testDirectHTTP()

        print("\n测试完成")
        exit(0)
    }

    func testDirectHTTP() async {
        let url = URL(string: "https://wallhaven.cc/api/v1/search?q=&categories=111&purity=100&sorting=date_added&page=1")!

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                print("✅ HTTP Status: \(httpResponse.statusCode)")
            }

            print("✅ Data Size: \(data.count) bytes")

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataArray = json["data"] as? [[String: Any]] {
                print("✅ Wallpapers Count: \(dataArray.count)")

                if let first = dataArray.first {
                    print("✅ First wallpaper ID: \(first["id"] ?? "unknown")")
                }
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }
}

Task { @MainActor in
    let runner = TestRunner()
    await runner.runTests()
}

RunLoop.main.run()
