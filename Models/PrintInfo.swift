import Foundation

/// 打印信息
struct PrintInfo: Codable, Equatable {
    /// 打印子状态
    let status: PrintStatus.PrintSubStatus
    /// 当前打印层数
    let currentLayer: Int
    /// 打印任务总层数
    let totalLayer: Int
    /// 当前已打印时间(ms)
    let currentTicks: Int
    /// 总打印时间(ms)
    let totalTicks: Int
    /// 打印文件名称
    let filename: String
    /// 错误码
    let errorNumber: Int
    /// 当前任务ID
    let taskId: String
    /// 剩余打印时间(ms)
    let remainingTicks: Int
    /// 打印速度倍率
    let printSpeed: Double
    /// 当前Z轴高度(mm)
    let zHeight: Double
    
    /// 错误状态原因
    enum ErrorStatusReason: Int, Codable {
        case ok = 0                    // 正常
        case tempError = 1             // 温度过高
        case calibrateFailed = 2       // 力学传感器校准失败
        case resinLack = 3             // 检测到树脂不足
        case resinOver = 4             // 模型所需树脂体积超过料槽最大容积
        case probeFail = 5             // 未检测到树脂
        case foreignBody = 6           // 检测到有异物
        case levelFailed = 7           // 自动调平失败
        case releaseFailed = 8         // 检测到模型脱落
        case sgOffline = 9             // 力学传感器未接入
        case lcdDetFailed = 10         // LCD屏幕连接异常
        case releaseOvercount = 11     // 累计离型次数达到最大值
        case udiskRemove = 12          // U盘拔出
        case homeFailedX = 13          // X轴电机异常
        case homeFailedZ = 14          // Z轴电机异常
        case resinAbnormalHigh = 15    // 树脂超出最大值
        case resinAbnormalLow = 16     // 树脂过少
        case homeFailed = 17           // 归零失败
        case platFailed = 18           // 平台有模型附着
        case error = 19                // 打印异常
        case moveAbnormal = 20         // 电机运动异常
        case aicModelNone = 21         // 未探测到模型
        case aicModelWarp = 22         // 检测到模型翘边
        case homeFailedY = 23          // Y轴电机异常
        case fileError = 24            // 错误文件
        case cameraError = 25          // 摄像头错误
        case networkError = 26         // 网络连接错误
        case serverConnectFailed = 27  // 服务器连接失败
        case disconnectApp = 28        // 未绑定APP
        case checkAutoResinFeeder = 29 // 自动注料机安装异常
        case containerResinLow = 30    // 容器树脂不足
        case bottleDisconnect = 31     // 自动注料机未连接
        case feedTimeout = 32          // 自动注料超时
        case tankTempSensorOffline = 33 // 料槽温度传感器未接入
        case tankTempSensorError = 34  // 料槽温度传感器温度过高
    }
    
    // 实现 Equatable
    static func == (lhs: PrintInfo, rhs: PrintInfo) -> Bool {
        return lhs.status == rhs.status &&
               lhs.currentLayer == rhs.currentLayer &&
               lhs.totalLayer == rhs.totalLayer &&
               lhs.currentTicks == rhs.currentTicks &&
               lhs.totalTicks == rhs.totalTicks &&
               lhs.filename == rhs.filename &&
               lhs.errorNumber == rhs.errorNumber &&
               lhs.taskId == rhs.taskId &&
               lhs.remainingTicks == rhs.remainingTicks &&
               lhs.printSpeed == rhs.printSpeed &&
               lhs.zHeight == rhs.zHeight
    }
} 