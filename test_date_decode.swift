#!/usr/bin/env swift
import Foundation

// 测试 Wallhaven API 日期解码

struct TestWallpaper: Codable {
    let id: String
    let created_at: Date
}

struct TestResponse: Codable {
    let data: [TestWallpaper]
}

let jsonString = """
{
    "data": [
        {
            "id": "test123",
            "created_at": "2026-05-02 05:53:28"
        }
    ]
}
"""

let decoder = JSONDecoder()
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
dateFormatter.locale = Locale(identifier: "en_US_POSIX")
dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
decoder.dateDecodingStrategy = .formatted(dateFormatter)

do {
    let data = jsonString.data(using: .utf8)!
    let response = try decoder.decode(TestResponse.self, from: data)
    print("✅ 解码成功！")
    print("ID: \(response.data[0].id)")
    print("Date: \(response.data[0].created_at)")
} catch {
    print("❌ 解码失败: \(error)")
}
