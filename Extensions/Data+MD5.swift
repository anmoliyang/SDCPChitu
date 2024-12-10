import Foundation
import CryptoKit

extension Data {
    /// 计算数据的MD5值并返回十六进制字符串
    var md5String: String {
        let digest = Insecure.MD5.hash(data: self)
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
} 