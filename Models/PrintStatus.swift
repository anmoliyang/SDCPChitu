import Foundation

/// 打印机状态模型
struct PrintStatus {
    /// 当前机器状态
    var currentStatus: [MachineStatus]
    /// 上一次机器状态
    var previousStatus: MachineStatus
    /// 曝光屏使用时间(秒)
    var printScreenTime: Int
    /// 离型膜次数
    var releaseFilmCount: Int
    /// 当前UVLED温度(℃)
    var uvledTemperature: Double
    /// 延时摄影开关状态
    var timeLapseEnabled: Bool
    /// 箱体当前温度(℃)
    var boxTemperature: Double
    /// 箱体目标温度(℃)
    var boxTargetTemperature: Double
    /// 打印信息
    var printInfo: PrintInfo?
    
    /// 机器状态枚举
    enum MachineStatus: Int, CustomStringConvertible {
        case idle = 0
        case printing = 1
        case fileTransferring = 2
        case exposureTesting = 3
        case devicesTesting = 4
        
        var description: String {
            switch self {
            case .idle:
                return "空闲"
            case .printing:
                return "打印中"
            case .fileTransferring:
                return "文件传输中"
            case .exposureTesting:
                return "曝光测试中"
            case .devicesTesting:
                return "设备自检中"
            }
        }
    }
    
    /// 打印子状态枚举
    enum PrintSubStatus: Int, CustomStringConvertible {
        case idle = 0
        case homing = 1
        case dropping = 2
        case exposuring = 3
        case lifting = 4
        case pausing = 5
        case paused = 6
        case stopping = 7
        case stopped = 8
        case complete = 9
        case fileChecking = 10
        
        var description: String {
            switch self {
            case .idle:
                return "空闲"
            case .homing:
                return "回零中"
            case .dropping:
                return "下降中"
            case .exposuring:
                return "曝光中"
            case .lifting:
                return "抬升中"
            case .pausing:
                return "暂停中"
            case .paused:
                return "已暂停"
            case .stopping:
                return "停止中"
            case .stopped:
                return "已停止"
            case .complete:
                return "已完成"
            case .fileChecking:
                return "文件检查中"
            }
        }
    }
}

/// 打印信息
struct PrintInfo {
    /// 打印子状态
    var status: PrintStatus.PrintSubStatus
    /// 当前打印层数
    var currentLayer: Int
    /// 打印任务总层数
    var totalLayer: Int
    /// 当前已打印时间(ms)
    var currentTicks: Int
    /// 总打印时间(ms)
    var totalTicks: Int
    /// 打印文件名称
    var filename: String
    /// 错误码
    var errorNumber: Int
    /// 当前任务ID
    var taskId: String
    
    /// 计算打印进度
    var progress: Double {
        guard totalLayer > 0 else { return 0 }
        return Double(currentLayer) / Double(totalLayer)
    }
    
    /// 格式化已打印时间
    var formattedCurrentTime: String {
        formatTime(milliseconds: currentTicks)
    }
    
    /// 格式化总时间
    var formattedTotalTime: String {
        formatTime(milliseconds: totalTicks)
    }
    
    /// 将毫秒转换为时分秒格式
    private func formatTime(milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
}

// MARK: - JSON解析扩展
extension PrintStatus {
    /// 从JSON数据创建打印状态实例
    static func from(_ json: [String: Any]) -> PrintStatus? {
        guard let status = json["Status"] as? [String: Any] else { return nil }
        
        let currentStatusArray = status["CurrentStatus"] as? [Int] ?? []
        let currentStatus = currentStatusArray.compactMap { MachineStatus(rawValue: $0) }
        let previousStatus = MachineStatus(rawValue: status["PreviousStatus"] as? Int ?? 0) ?? .idle
        
        var printInfo: PrintInfo?
        if let printInfoDict = status["PrintInfo"] as? [String: Any] {
            printInfo = PrintInfo(
                status: PrintSubStatus(rawValue: printInfoDict["Status"] as? Int ?? 0) ?? .idle,
                currentLayer: printInfoDict["CurrentLayer"] as? Int ?? 0,
                totalLayer: printInfoDict["TotalLayer"] as? Int ?? 0,
                currentTicks: printInfoDict["CurrentTicks"] as? Int ?? 0,
                totalTicks: printInfoDict["TotalTicks"] as? Int ?? 0,
                filename: printInfoDict["Filename"] as? String ?? "",
                errorNumber: printInfoDict["ErrorNumber"] as? Int ?? 0,
                taskId: printInfoDict["TaskId"] as? String ?? ""
            )
        }
        
        return PrintStatus(
            currentStatus: currentStatus,
            previousStatus: previousStatus,
            printScreenTime: status["PrintScreen"] as? Int ?? 0,
            releaseFilmCount: status["ReleaseFilm"] as? Int ?? 0,
            uvledTemperature: status["TempOfUVLED"] as? Double ?? 0,
            timeLapseEnabled: (status["TimeLapseStatus"] as? Int ?? 0) == 1,
            boxTemperature: status["TempOfBox"] as? Double ?? 0,
            boxTargetTemperature: status["TempTargetBox"] as? Double ?? 0,
            printInfo: printInfo
        )
    }
} 