import Foundation

/// 设备状态
struct DeviceStatus: Codable {
    /// 设备状态值定义
    enum Status: Int, Codable {
        case normal = 0     // 正常
        case abnormal = 1   // 异常
        case unknown = 2    // 未知
    }
    
    /// UVLED温度传感器状态
    let uvledTempSensorStatus: Status
    /// LCD屏状态
    let lcdStatus: Status
    /// 光栅状态
    let sgStatus: Status
    /// Z轴电机状态
    let zMotorStatus: Status
    /// 旋转电机状态
    let rotateMotorStatus: Status
    /// 离型膜状态
    let releaseFilmState: Status
    /// X轴电机状态
    let xMotorStatus: Status
}

/// 网络状态
enum NetworkStatus: String, Codable {
    case wlan = "WLAN"
    case ethernet = "Ethernet"
}

/// 设备能力
enum DeviceCapability: String, Codable {
    /// 文件传输
    case fileTransfer = "FileTransfer"
    /// 打印控制
    case printControl = "PrintControl"
    /// 视频流
    case videoStream = "VideoStream"
}

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
    /// 分辨率
    let resolution: String
    /// 成型尺寸
    let xyzSize: String
    /// 网络状态
    let networkStatus: NetworkStatus
    /// 设备能力
    let capabilities: Set<DeviceCapability>
    /// 支持的文件类型
    let supportedFileTypes: [String]
    /// 设备状态
    let deviceStatus: DeviceStatus
    
    /// 从JSON数据创建打印机设备实例
    static func from(_ json: [String: Any]) -> PrinterDevice? {
        guard let id = json["MainboardID"] as? String,
              let attributes = json["Attributes"] as? [String: Any],
              let name = attributes["Name"] as? String,
              let machineName = attributes["MachineName"] as? String,
              let brandName = attributes["BrandName"] as? String,
              let ipAddress = attributes["MainboardIP"] as? String,
              let protocolVersion = attributes["ProtocolVersion"] as? String,
              let firmwareVersion = attributes["FirmwareVersion"] as? String,
              let resolution = attributes["Resolution"] as? String,
              let xyzSize = attributes["XYZsize"] as? String,
              let networkStatusStr = attributes["NetworkStatus"] as? String,
              let capabilities = attributes["Capabilities"] as? [String],
              let supportedFileTypes = attributes["SupportFileType"] as? [String],
              let devicesStatus = attributes["DevicesStatus"] as? [String: Int]
        else {
            return nil
        }
        
        let networkStatus = NetworkStatus(rawValue: networkStatusStr) ?? .wlan
        let deviceCapabilities = capabilities.compactMap { DeviceCapability(rawValue: $0) }
        
        // 将Int值转换为DeviceStatus.Status枚举
        let status = DeviceStatus(
            uvledTempSensorStatus: DeviceStatus.Status(rawValue: devicesStatus["TempSensorStatusOfUVLED"] ?? 2) ?? .unknown,
            lcdStatus: DeviceStatus.Status(rawValue: devicesStatus["LCDStatus"] ?? 2) ?? .unknown,
            sgStatus: DeviceStatus.Status(rawValue: devicesStatus["SgStatus"] ?? 2) ?? .unknown,
            zMotorStatus: DeviceStatus.Status(rawValue: devicesStatus["ZMotorStatus"] ?? 2) ?? .unknown,
            rotateMotorStatus: DeviceStatus.Status(rawValue: devicesStatus["RotateMotorStatus"] ?? 2) ?? .unknown,
            releaseFilmState: DeviceStatus.Status(rawValue: devicesStatus["RelaseFilmState"] ?? 2) ?? .unknown,
            xMotorStatus: DeviceStatus.Status(rawValue: devicesStatus["XMotorStatus"] ?? 2) ?? .unknown
        )
        
        return PrinterDevice(
            id: id,
            name: name,
            machineName: machineName,
            brandName: brandName,
            ipAddress: ipAddress,
            protocolVersion: protocolVersion,
            firmwareVersion: firmwareVersion,
            resolution: resolution,
            xyzSize: xyzSize,
            networkStatus: networkStatus,
            capabilities: Set(deviceCapabilities),
            supportedFileTypes: supportedFileTypes,
            deviceStatus: status
        )
    }
    
    static func == (lhs: PrinterDevice, rhs: PrinterDevice) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - 预览辅助
extension PrinterDevice {
    /// 预览用的测试打印机
    static var preview: PrinterDevice {
        PrinterDevice(
            id: "SDCP_TEST_001",
            name: "SDCP测试打印机",
            machineName: "SDCP-X1",
            brandName: "ChiTu",
            ipAddress: "192.168.1.100",
            protocolVersion: "3.0.0",
            firmwareVersion: "V3.0.0",
            resolution: "4096x2560",
            xyzSize: "192x120x200",
            networkStatus: .wlan,
            capabilities: Set([.fileTransfer, .printControl, .videoStream]),
            supportedFileTypes: ["ctb", "cbddlp", "photon"],
            deviceStatus: DeviceStatus(
                uvledTempSensorStatus: .normal,
                lcdStatus: .normal,
                sgStatus: .normal,
                zMotorStatus: .normal,
                rotateMotorStatus: .normal,
                releaseFilmState: .normal,
                xMotorStatus: .normal
            )
        )
    }
    
    /// 用于调试打印机列表
    static var debugDevices: [PrinterDevice] {
        [
            // 正在打印的设备
            PrinterDevice(
                id: "SDCP_TEST_002",
                name: "打印中设备",
                machineName: "SDCP-X2 Pro",
                brandName: "ChiTu",
                ipAddress: "192.168.1.101",
                protocolVersion: "3.0.0",
                firmwareVersion: "V3.0.0",
                resolution: "5760x3600",
                xyzSize: "192x120x200",
                networkStatus: .ethernet,
                capabilities: Set([.fileTransfer, .printControl, .videoStream]),
                supportedFileTypes: ["ctb", "cbddlp", "photon"],
                deviceStatus: DeviceStatus(
                    uvledTempSensorStatus: .normal,
                    lcdStatus: .normal,
                    sgStatus: .normal,
                    zMotorStatus: .normal,
                    rotateMotorStatus: .normal,
                    releaseFilmState: .normal,
                    xMotorStatus: .normal
                )
            ),
            
            // 异常状态设备
            PrinterDevice(
                id: "SDCP_TEST_003",
                name: "异常状态设备",
                machineName: "SDCP-X3",
                brandName: "ChiTu",
                ipAddress: "192.168.1.102",
                protocolVersion: "3.0.0",
                firmwareVersion: "V3.0.0",
                resolution: "3840x2400",
                xyzSize: "192x120x200",
                networkStatus: .wlan,
                capabilities: Set([.fileTransfer, .printControl]),
                supportedFileTypes: ["ctb"],
                deviceStatus: DeviceStatus(
                    uvledTempSensorStatus: .abnormal,  // UVLED温度传感器异常
                    lcdStatus: .normal,
                    sgStatus: .abnormal,  // 光栅异常
                    zMotorStatus: .abnormal,  // Z轴电机异常
                    rotateMotorStatus: .normal,
                    releaseFilmState: .normal,
                    xMotorStatus: .normal
                )
            ),
            
            // 离线设备
            PrinterDevice(
                id: "SDCP_TEST_004",
                name: "离线设备",
                machineName: "SDCP-X1 Lite",
                brandName: "ChiTu",
                ipAddress: "192.168.1.103",
                protocolVersion: "3.0.0",
                firmwareVersion: "V3.0.0",
                resolution: "2560x1600",
                xyzSize: "130x80x160",
                networkStatus: .wlan,
                capabilities: Set([.fileTransfer, .printControl]),
                supportedFileTypes: ["ctb"],
                deviceStatus: DeviceStatus(
                    uvledTempSensorStatus: .unknown,
                    lcdStatus: .unknown,
                    sgStatus: .unknown,
                    zMotorStatus: .unknown,
                    rotateMotorStatus: .unknown,
                    releaseFilmState: .unknown,
                    xMotorStatus: .unknown
                )
            )
        ]
    }
} 