import Foundation

/// 3D打印机设备模型
struct PrinterDevice: Identifiable, Codable, Equatable {
    /// 设备唯一标识符
    let id: String  // 对应协议中的MainboardID
    /// 设备名称
    let name: String
    /// 机型名称
    let machineName: String
    /// 品牌名称
    let brandName: String
    /// IP地址
    let ipAddress: String
    /// 协议版本
    let protocolVersion: String
    /// 固件版本
    let firmwareVersion: String
    
    /// 网络状态
    enum NetworkStatus: String, Codable {
        case wlan = "WLAN"
        case ethernet = "Ethernet"
    }
    
    /// 设备能力
    enum DeviceCapability: String, Codable {
        case fileTransfer = "FILE_TRANSFER"
        case printControl = "PRINT_CONTROL"
        case videoStream = "VIDEO_STREAM"
    }
    
    /// 分辨率
    let resolution: String?
    /// 成型尺寸
    let xyzSize: String?
    /// 网络状态
    let networkStatus: NetworkStatus?
    /// USB状态
    let usbDiskStatus: Int?
    /// 设备能力
    let capabilities: [DeviceCapability]?
    /// 支持的文件类型
    let supportFileTypes: [String]?
    
    #if DEBUG
    static let preview = PrinterDevice(
        id: "PREVIEW_001",
        name: "Preview Printer",
        machineName: "Test Model",
        brandName: "CBD",
        ipAddress: "192.168.1.100",
        protocolVersion: "V3.0.0",
        firmwareVersion: "V1.0.0",
        resolution: "7680x4320",
        xyzSize: "210x140x100",
        networkStatus: .wlan,
        usbDiskStatus: 0,
        capabilities: [.fileTransfer, .printControl, .videoStream],
        supportFileTypes: ["CTB"]
    )
    #endif
} 