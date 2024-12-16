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
        case paused = 5        // 已暂停
        case stopped = 6       // 已停止
        
        var description: String {
            switch self {
            case .idle: return "空闲"
            case .printing: return "打印中"
            case .fileTransferring: return "文件传输中"
            case .exposureTesting: return "曝光测试"
            case .devicesTesting: return "设备自检"
            case .paused: return "已暂停"
            case .stopped: return "已停止"
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
            case .pausing: return "正在暂停"
            case .paused: return "已暂停"
            case .stopping: return "正在停止"
            case .stopped: return "已停止"
            case .complete: return "打印完成"
            case .fileChecking: return "文件检测中"
            }
        }
    }
    
    /// 设备自检状态
    struct DevicesStatus: Codable, Equatable {
        let tempSensorStatusOfUVLED: Int  // UVLED温度传感器状态,0未接入，1正常，2异常
        let lcdStatus: Int                // 曝光屏连接状态，0断开，1连接
        let sgStatus: Int                 // 应变片状态，0未接入，1正常 2校准失败
        let zMotorStatus: Int             // Z轴电机连接状态，0断开，1连接
        let rotateMotorStatus: Int        // 旋转轴电机连接状态，0断开，1连接
        let releaseFilmState: Int         // 离型膜状态，0异常，1正常
        let xMotorStatus: Int             // X轴电机连接状态，0断开，1连接
        
        // 实现 Equatable
        static func == (lhs: DevicesStatus, rhs: DevicesStatus) -> Bool {
            return lhs.tempSensorStatusOfUVLED == rhs.tempSensorStatusOfUVLED &&
                   lhs.lcdStatus == rhs.lcdStatus &&
                   lhs.sgStatus == rhs.sgStatus &&
                   lhs.zMotorStatus == rhs.zMotorStatus &&
                   lhs.rotateMotorStatus == rhs.rotateMotorStatus &&
                   lhs.releaseFilmState == rhs.releaseFilmState &&
                   lhs.xMotorStatus == rhs.xMotorStatus
        }
    }
    
    let currentStatus: MachineStatus      // 当前机器状态
    let previousStatus: MachineStatus     // 上一次机器状态
    let printScreenTime: Int              // 曝光屏使用时间（s）
    let releaseFilmCount: Int             // 离型膜次数
    let uvledTemperature: Double          // 当前UVLED温度（℃）
    let timeLapseEnabled: Bool            // 延时摄影开关状态
    let boxTemperature: Double            // 箱体当前温度（℃）
    let boxTargetTemperature: Double      // 箱体目标温度（℃）
    let printInfo: PrintInfo?             // 打印信息
    let devicesStatus: DevicesStatus?     // 设备自检状态
    
    var isPrinting: Bool {
        currentStatus == .printing
    }
    
    var isExposureTesting: Bool {
        currentStatus == .exposureTesting
    }
    
    var isDevicesTesting: Bool {
        currentStatus == .devicesTesting
    }
    
    // 实现 Equatable
    static func == (lhs: PrintStatus, rhs: PrintStatus) -> Bool {
        return lhs.currentStatus == rhs.currentStatus &&
               lhs.previousStatus == rhs.previousStatus &&
               lhs.printScreenTime == rhs.printScreenTime &&
               lhs.releaseFilmCount == rhs.releaseFilmCount &&
               lhs.uvledTemperature == rhs.uvledTemperature &&
               lhs.timeLapseEnabled == rhs.timeLapseEnabled &&
               lhs.boxTemperature == rhs.boxTemperature &&
               lhs.boxTargetTemperature == rhs.boxTargetTemperature &&
               lhs.printInfo == rhs.printInfo &&
               lhs.devicesStatus == rhs.devicesStatus
    }
} 