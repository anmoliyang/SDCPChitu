import Foundation

/// 打印信息
struct PrintInfo: Codable, Equatable {
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
    /// 剩余时间(ms)
    var remainingTicks: Int
    /// 打印速度
    var printSpeed: Double
    /// Z轴高度
    var zHeight: Double
} 