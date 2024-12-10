import Foundation

/// 打印机状态
struct PrintStatus: Codable, Equatable {
    /// 机器状态
    enum MachineStatus: Int, Codable {
        case idle = 0          // 空闲
        case printing = 1      // 打印中
        case fileTransferring = 2  // 文件传输中
        case exposureTesting = 3   // 曝光测试
        case devicesTesting = 4    // 设备自检
        
        var description: String {
            switch self {
            case .idle: return "空闲"
            case .printing: return "打印中"
            case .fileTransferring: return "文件传输中"
            case .exposureTesting: return "曝光测试"
            case .devicesTesting: return "设备自检"
            }
        }
    }
    
    /// 打印子状态
    enum PrintSubStatus: Int, Codable {
        case idle = 0          // 空闲
        case homing = 1        // 归零中
        case dropping = 2      // 下降中
        case exposuring = 3    // 曝光中
        case lifting = 4       // 抬升中
        case pausing = 5       // 正在执行暂停动作中
        case paused = 6        // 已暂停
        case stopping = 7      // 正在执行停止动作中
        case stopped = 8       // 已停止
        case complete = 9      // 打印完成
        case fileChecking = 10 // 文件检测中
        
        var description: String {
            switch self {
            case .idle: return "空闲"
            case .homing: return "归零中"
            case .dropping: return "下降中"
            case .exposuring: return "曝光中"
            case .lifting: return "抬升中"
            case .pausing: return "暂停中"
            case .paused: return "已暂停"
            case .stopping: return "停止中"
            case .stopped: return "已停止"
            case .complete: return "已完成"
            case .fileChecking: return "文件检测中"
            }
        }
    }
    
    /// 当前机器状态
    let currentStatus: MachineStatus
    /// 前一个状态
    let previousStatus: MachineStatus
    /// 曝光时间(ms)
    let printScreenTime: Int
    /// 离型次数
    let releaseFilmCount: Int
    /// UVLED温度
    let uvledTemperature: Double
    /// 延时摄影启用状态
    let timeLapseEnabled: Bool
    /// 打印仓温度
    let boxTemperature: Double
    /// 打印仓目标温度
    let boxTargetTemperature: Double
    /// 打印信息
    let printInfo: PrintInfo?
    
    private enum CodingKeys: String, CodingKey {
        case status = "Status"
        case currentStatus = "CurrentStatus"
        case previousStatus = "PreviousStatus"
        case printScreenTime = "PrintScreen"
        case releaseFilmCount = "ReleaseFilm"
        case uvledTemperature = "TempOfUVLED"
        case timeLapseEnabled = "TimeLapseStatus"
        case boxTemperature = "TempOfBox"
        case boxTargetTemperature = "TempTargetBox"
        case printInfo = "PrintInfo"
    }
    
    // MARK: - Encodable
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(currentStatus.rawValue, forKey: .currentStatus)
        try container.encode(previousStatus.rawValue, forKey: .previousStatus)
        try container.encode(printScreenTime, forKey: .printScreenTime)
        try container.encode(releaseFilmCount, forKey: .releaseFilmCount)
        try container.encode(uvledTemperature, forKey: .uvledTemperature)
        try container.encode(timeLapseEnabled ? 1 : 0, forKey: .timeLapseEnabled)
        try container.encode(boxTemperature, forKey: .boxTemperature)
        try container.encode(boxTargetTemperature, forKey: .boxTargetTemperature)
        try container.encodeIfPresent(printInfo, forKey: .printInfo)
    }
    
    // MARK: - Decodable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 解析当前状态（可能是数组或单个值）
        if let statusArray = try? container.decode([Int].self, forKey: .currentStatus) {
            currentStatus = MachineStatus(rawValue: statusArray[0]) ?? .idle
        } else if let statusValue = try? container.decode(Int.self, forKey: .currentStatus) {
            currentStatus = MachineStatus(rawValue: statusValue) ?? .idle
        } else {
            currentStatus = .idle
        }
        
        previousStatus = try container.decode(MachineStatus.self, forKey: .previousStatus)
        printScreenTime = try container.decode(Int.self, forKey: .printScreenTime)
        releaseFilmCount = try container.decode(Int.self, forKey: .releaseFilmCount)
        uvledTemperature = try container.decode(Double.self, forKey: .uvledTemperature)
        timeLapseEnabled = try container.decode(Int.self, forKey: .timeLapseEnabled) == 1
        boxTemperature = try container.decode(Double.self, forKey: .boxTemperature)
        boxTargetTemperature = try container.decode(Double.self, forKey: .boxTargetTemperature)
        printInfo = try container.decodeIfPresent(PrintInfo.self, forKey: .printInfo)
    }
    
    // MARK: - 初始化方法
    
    init(currentStatus: MachineStatus,
         previousStatus: MachineStatus,
         printScreenTime: Int,
         releaseFilmCount: Int,
         uvledTemperature: Double,
         timeLapseEnabled: Bool,
         boxTemperature: Double,
         boxTargetTemperature: Double,
         printInfo: PrintInfo?) {
        self.currentStatus = currentStatus
        self.previousStatus = previousStatus
        self.printScreenTime = printScreenTime
        self.releaseFilmCount = releaseFilmCount
        self.uvledTemperature = uvledTemperature
        self.timeLapseEnabled = timeLapseEnabled
        self.boxTemperature = boxTemperature
        self.boxTargetTemperature = boxTargetTemperature
        self.printInfo = printInfo
    }
}

// MARK: - 辅助方法
extension PrintStatus {
    var isIdle: Bool { currentStatus == .idle }
    var isPrinting: Bool { currentStatus == .printing }
    var isFileTransferring: Bool { currentStatus == .fileTransferring }
    var isExposureTesting: Bool { currentStatus == .exposureTesting }
    var isDevicesTesting: Bool { currentStatus == .devicesTesting }
} 