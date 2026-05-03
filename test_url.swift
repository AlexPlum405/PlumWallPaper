import Foundation

let path = "/Users/Alex/Library/Caches/PlumWallPaper/Thumbnails/test.jpg"
let url1 = URL(string: path)
let url2 = URL(fileURLWithPath: path)

print("URL(string:): \(String(describing: url1))")
if let url1 = url1 {
    print("  isFileURL: \(url1.isFileURL)")
}

print("URL(fileURLWithPath:): \(url2)")
print("  isFileURL: \(url2.isFileURL)")

