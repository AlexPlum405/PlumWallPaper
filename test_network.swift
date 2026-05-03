#!/usr/bin/env swift
import Foundation

// 测试 Wallhaven API
let wallhavenURL = URL(string: "https://wallhaven.cc/api/v1/search?q=&categories=111&purity=100&sorting=date_added&page=1")!

print("Testing Wallhaven API...")
let task = URLSession.shared.dataTask(with: wallhavenURL) { data, response, error in
    if let error = error {
        print("❌ Error: \(error.localizedDescription)")
        exit(1)
    }

    if let httpResponse = response as? HTTPURLResponse {
        print("✅ Status Code: \(httpResponse.statusCode)")
    }

    if let data = data {
        print("✅ Data Size: \(data.count) bytes")
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("✅ JSON parsed successfully")
            if let meta = json["meta"] as? [String: Any],
               let total = meta["total"] as? Int {
                print("✅ Total wallpapers: \(total)")
            }
        }
    }

    exit(0)
}

task.resume()
RunLoop.main.run()
