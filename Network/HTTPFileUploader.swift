import Foundation
import CryptoKit

/// HTTP文件上传管理器
class HTTPFileUploader {
    /// 单例
    static let shared = HTTPFileUploader()
    
    /// 上传进度回调
    var progressHandler: ((Double) -> Void)?
    /// 上传完成回调
    var completionHandler: ((Result<Void, Error>) -> Void)?
    
    /// 分片大小(1MB)
    private let chunkSize = 1024 * 1024
    /// 当前上传任务
    private var currentTask: URLSessionDataTask?
    
    private init() {}
    
    /// 上传文件
    /// - Parameters:
    ///   - fileURL: 文件URL
    ///   - ipAddress: 打印机IP地址
    ///   - progress: 进度回调
    ///   - completion: 完成回调
    func uploadFile(at fileURL: URL, to ipAddress: String,
                   progress: @escaping (Double) -> Void,
                   completion: @escaping (Result<Void, Error>) -> Void) {
        progressHandler = progress
        completionHandler = completion
        
        // 读取文件数据
        guard let fileData = try? Data(contentsOf: fileURL) else {
            completion(.failure(NetworkError.invalidData))
            return
        }
        
        // 计算SHA256
        let hash = fileData.sha256String
        
        // 分片上传
        let totalChunks = Int(ceil(Double(fileData.count) / Double(chunkSize)))
        uploadChunk(fileData: fileData, hash: hash, currentChunk: 0, totalChunks: totalChunks, ipAddress: ipAddress)
    }
    
    /// 取消上传
    func cancelUpload() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    /// 上传分片
    private func uploadChunk(fileData: Data, hash: String, currentChunk: Int, totalChunks: Int, ipAddress: String) {
        // 计算当前分片范围
        let start = currentChunk * chunkSize
        let end = min(start + chunkSize, fileData.count)
        let chunkData = fileData.subdata(in: start..<end)
        
        // 创建请求
        let url = URL(string: "http://\(ipAddress):3030/uploadFile/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 生成分片UUID
        let uuid = UUID().uuidString
        
        // 创建multipart表单数据
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加哈希值
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"S-File-Hash\"\r\n\r\n")
        body.append("\(hash)\r\n")
        
        // 添加校验标志
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"Check\"\r\n\r\n")
        body.append("1\r\n")
        
        // 添加偏移量
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"Offset\"\r\n\r\n")
        body.append("\(start)\r\n")
        
        // 添加UUID
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"Uuid\"\r\n\r\n")
        body.append("\(uuid)\r\n")
        
        // 添加总大小
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"TotalSize\"\r\n\r\n")
        body.append("\(fileData.count)\r\n")
        
        // 添加文件数据
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"File\"; filename=\"chunk\"\r\n")
        body.append("Content-Type: application/octet-stream\r\n\r\n")
        body.append(chunkData)
        body.append("\r\n")
        
        // 结束标记
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        // 发送请求
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                self?.completionHandler?(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self?.completionHandler?(.failure(NetworkError.invalidResponse))
                return
            }
            
            // 检查响应状态
            guard httpResponse.statusCode == 200,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool,
                  success else {
                self?.completionHandler?(.failure(NetworkError.invalidResponse))
                return
            }
            
            // 计算进度
            let progress = Double(currentChunk + 1) / Double(totalChunks)
            DispatchQueue.main.async {
                self?.progressHandler?(progress)
            }
            
            // 检查是否还有下一个分片
            if currentChunk + 1 < totalChunks {
                self?.uploadChunk(fileData: fileData,
                                hash: hash,
                                currentChunk: currentChunk + 1,
                                totalChunks: totalChunks,
                                ipAddress: ipAddress)
            } else {
                self?.completionHandler?(.success(()))
            }
        }
        
        currentTask?.resume()
    }
}

// MARK: - Data 扩展
extension Data {
    /// 计算SHA256哈希值
    var sha256String: String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// 添加字符串
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 