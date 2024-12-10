import Foundation

/// 网络错误类型
enum NetworkError: LocalizedError {
    /// 无效的响应
    case invalidResponse
    /// 无效的数据
    case invalidData
    /// 连接失败
    case connectionFailed(String)
    /// 上传失败
    case uploadFailed(String)
    /// 未知错误
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "无效的响应"
        case .invalidData:
            return "无效的数据"
        case .connectionFailed(let message):
            return "连接失败: \(message)"
        case .uploadFailed(let message):
            return "上传失败: \(message)"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}
