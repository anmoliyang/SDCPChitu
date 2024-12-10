import Foundation

/// HTTP文件上传管理器
class HTTPFileUploader {
    /// 单例
    static let shared = HTTPFileUploader()
    
    /// 上传进度回调
    var progressHandler: ((Double) -> Void)?
    /// 上传完成回调
    var completionHandler: ((Result<Void, Error>) -> Void)?
    
    private init() {}
    
    /// 上传文件
    /// - Parameters:
    ///   - fileURL: 文件URL
    ///   - device: 打印机设备
    ///   - progress: 进度回调
    ///   - completion: 完成回调
    func uploadFile(_ fileURL: URL, to device: PrinterDevice, 
                   progress: @escaping (Double) -> Void,
                   completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let fileData = try? Data(contentsOf: fileURL) else {
            completion(.failure(NetworkError.uploadFailed("文件读取失败")))
            return
        }
        
        let md5 = fileData.md5String
        let uuid = UUID().uuidString
        let chunkSize = 1024 * 1024 // 1MB
        let totalSize = fileData.count
        
        var currentOffset = 0
        
        func uploadNextChunk() {
            let remainingSize = totalSize - currentOffset
            let currentChunkSize = min(chunkSize, remainingSize)
            let chunk = fileData[currentOffset..<(currentOffset + currentChunkSize)]
            
            guard let url = URL(string: "http://\(device.ipAddress):3030/uploadFile/upload") else {
                completion(.failure(NetworkError.invalidURL))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue(md5, forHTTPHeaderField: "S-File-MD5")
            request.setValue("1", forHTTPHeaderField: "Check")
            request.setValue("\(currentOffset)", forHTTPHeaderField: "Offset")
            request.setValue(uuid, forHTTPHeaderField: "Uuid")
            request.setValue("\(totalSize)", forHTTPHeaderField: "TotalSize")
            
            var body = Data()
            // Add file data
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"File\"; filename=\"\(fileURL.lastPathComponent)\"\r\n")
            body.append("Content-Type: application/octet-stream\r\n\r\n")
            body.append(chunk)
            body.append("\r\n")
            body.append("--\(boundary)--\r\n")
            
            request.httpBody = body
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(NetworkError.connectionFailed(error.localizedDescription)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                
                // 解析SDCP响应
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    if let code = json["code"] as? String {
                        if code == "000000" {
                            currentOffset += currentChunkSize
                            let progressValue = Double(currentOffset) / Double(totalSize)
                            DispatchQueue.main.async {
                                progress(progressValue)
                            }
                            
                            if currentOffset < totalSize {
                                uploadNextChunk()
                            } else {
                                completion(.success(()))
                            }
                        } else {
                            // 处理SDCP错误
                            if let messages = json["messages"] as? [[String: Any]],
                               let firstError = messages.first,
                               let field = firstError["field"] as? String,
                               let message = firstError["message"] {
                                let errorMessage = "\(field): \(message)"
                                completion(.failure(NetworkError.uploadFailed(errorMessage)))
                            } else {
                                completion(.failure(NetworkError.uploadFailed("未知错误: \(code)")))
                            }
                        }
                    } else {
                        completion(.failure(NetworkError.invalidData))
                    }
                } else {
                    completion(.failure(NetworkError.invalidData))
                }
            }
            task.resume()
        }
        
        uploadNextChunk()
    }
}

// MARK: - Data 扩展
extension Data {
    /// 添加字符串
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 