import Foundation

/// 打印文件模型
struct PrintFile: Identifiable, Codable {
    /// 文件ID
    let id: String
    /// 文件名
    let name: String
    /// 文件大小(字节)
    let size: Int64
    /// 文件MD5
    let md5: String
    /// 上传时间
    let uploadTime: Date
    /// 文件状态
    let status: FileStatus
    
    /// 文件状态枚举
    enum FileStatus: Int, Codable {
        case ready = 0      // 就绪
        case uploading = 1  // 上传中
        case checking = 2   // 校验中
        case error = 3      // 错误
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case size = "Size"
        case md5 = "MD5"
        case uploadTime = "UploadTime"
        case status = "Status"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        size = try container.decode(Int64.self, forKey: .size)
        md5 = try container.decode(String.self, forKey: .md5)
        
        // 将时间戳转换为Date
        let timestamp = try container.decode(TimeInterval.self, forKey: .uploadTime)
        uploadTime = Date(timeIntervalSince1970: timestamp)
        
        let statusRaw = try container.decode(Int.self, forKey: .status)
        status = FileStatus(rawValue: statusRaw) ?? .error
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(size, forKey: .size)
        try container.encode(md5, forKey: .md5)
        try container.encode(Int(uploadTime.timeIntervalSince1970), forKey: .uploadTime)
        try container.encode(status.rawValue, forKey: .status)
    }
    
    // MARK: - 初始化方法
    
    init(id: String, name: String, size: Int64, md5: String, uploadTime: Date, status: FileStatus) {
        self.id = id
        self.name = name
        self.size = size
        self.md5 = md5
        self.uploadTime = uploadTime
        self.status = status
    }
}

// MARK: - 辅助方法
extension PrintFile {
    /// 格式化文件大小
    var formattedSize: String {
        size.formatFileSize()
    }
    
    /// 格式化上传时间
    var formattedUploadTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: uploadTime)
    }
} 