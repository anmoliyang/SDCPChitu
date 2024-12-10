import Foundation

/// 设备状态
struct DeviceStatus: Codable {
    /// UVLED温度传感器状态
    let uvledTempSensorStatus: Int
    /// LCD屏状态
    let lcdStatus: Int
    /// 光栅状态
    let sgStatus: Int
    /// Z轴电机状态
    let zMotorStatus: Int
    /// 旋转电机状态
    let rotateMotorStatus: Int
    /// 离型膜状态
    let releaseFilmState: Int
    /// X轴电机状态
    let xMotorStatus: Int
}

/// 网络状态
enum NetworkStatus: String, Codable {
    case wlan = "WLAN"
    case ethernet = "Ethernet"
}

/// 设备能力
enum DeviceCapability: String, Codable {
    case fileTransfer = "FileTransfer"
    case printControl = "PrintControl"
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
        
        let status = DeviceStatus(
            uvledTempSensorStatus: devicesStatus["TempSensorStatusOfUVLED"] ?? 0,
            lcdStatus: devicesStatus["LCDStatus"] ?? 0,
            sgStatus: devicesStatus["SgStatus"] ?? 0,
            zMotorStatus: devicesStatus["ZMotorStatus"] ?? 0,
            rotateMotorStatus: devicesStatus["RotateMotorStatus"] ?? 0,
            releaseFilmState: devicesStatus["RelaseFilmState"] ?? 0,
            xMotorStatus: devicesStatus["XMotorStatus"] ?? 0
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
            id: "DEBUG_PRINTER_001",
            name: "调试打印机",
            machineName: "Debug Model X1",
            brandName: "DebugBrand",
            ipAddress: "192.168.1.100",
            protocolVersion: "3.0.0",
            firmwareVersion: "1.0.0-debug",
            resolution: "4096x2560",
            xyzSize: "192x120x200",
            networkStatus: .wlan,
            capabilities: Set([.fileTransfer, .printControl, .videoStream]),
            supportedFileTypes: ["ctb", "cbddlp", "photon"],
            deviceStatus: DeviceStatus(
                uvledTempSensorStatus: 1,
                lcdStatus: 1,
                sgStatus: 1,
                zMotorStatus: 1,
                rotateMotorStatus: 1,
                releaseFilmState: 1,
                xMotorStatus: 1
            )
        )
    }
    
    /// 用于调试的打印机列表
    static var debugDevices: [PrinterDevice] {
        [
            PrinterDevice(
                id: "DEBUG_PRINTER_002",
                name: "调试打印机 2",
                machineName: "Debug Model X2",
                brandName: "DebugBrand",
                ipAddress: "192.168.1.102",
                protocolVersion: "3.0.0",
                firmwareVersion: "1.0.0-debug",
                resolution: "5760x3600",
                xyzSize: "192x120x200",
                networkStatus: .ethernet,
                capabilities: Set([.fileTransfer, .printControl]),
                supportedFileTypes: ["ctb", "cbddlp"],
                deviceStatus: DeviceStatus(
                    uvledTempSensorStatus: 2,  // 故障状态
                    lcdStatus: 1,
                    sgStatus: 1,
                    zMotorStatus: 1,
                    rotateMotorStatus: 1,
                    releaseFilmState: 1,
                    xMotorStatus: 1
                )
            ),
            PrinterDevice(
                id: "DEBUG_PRINTER_003",
                name: "调试打印机 3",
                machineName: "Debug Model X3",
                brandName: "DebugBrand",
                ipAddress: "192.168.1.103",
                protocolVersion: "3.0.0",
                firmwareVersion: "1.0.0-debug",
                resolution: "3840x2400",
                xyzSize: "192x120x200",
                networkStatus: .wlan,
                capabilities: Set([.fileTransfer, .printControl, .videoStream]),
                supportedFileTypes: ["ctb", "cbddlp"],
                deviceStatus: DeviceStatus(
                    uvledTempSensorStatus: 1,
                    lcdStatus: 2,  // LCD故障
                    sgStatus: 1,
                    zMotorStatus: 1,
                    rotateMotorStatus: 1,
                    releaseFilmState: 1,
                    xMotorStatus: 1
                )
            )
        ]
    }
} 