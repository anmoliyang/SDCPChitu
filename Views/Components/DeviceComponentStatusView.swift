import SwiftUI

/// 设备组件状态视图
struct DeviceComponentStatusView: View {
    let devicesStatus: PrintStatus.DevicesStatus
    
    var body: some View {
        VStack(spacing: 0) {
            StatusRow(
                title: "UVLED传感器", 
                value: getUVLEDStatusText(devicesStatus.tempSensorStatusOfUVLED),
                foregroundColor: getUVLEDStatusColor(devicesStatus.tempSensorStatusOfUVLED)
            )
            Divider().padding(.leading, 16)
            
            StatusRow(
                title: "LCD屏幕", 
                value: getLCDStatusText(devicesStatus.lcdStatus),
                foregroundColor: getLCDStatusColor(devicesStatus.lcdStatus)
            )
            Divider().padding(.leading, 16)
            
            StatusRow(
                title: "光栅", 
                value: getSGStatusText(devicesStatus.sgStatus),
                foregroundColor: getSGStatusColor(devicesStatus.sgStatus)
            )
            Divider().padding(.leading, 16)
            
            StatusRow(
                title: "Z轴电机", 
                value: getMotorStatusText(devicesStatus.zMotorStatus),
                foregroundColor: getMotorStatusColor(devicesStatus.zMotorStatus)
            )
            Divider().padding(.leading, 16)
            
            StatusRow(
                title: "旋转电机", 
                value: getMotorStatusText(devicesStatus.rotateMotorStatus),
                foregroundColor: getMotorStatusColor(devicesStatus.rotateMotorStatus)
            )
            Divider().padding(.leading, 16)
            
            StatusRow(
                title: "离型膜", 
                value: getReleaseFilmStatusText(devicesStatus.releaseFilmState),
                foregroundColor: getReleaseFilmStatusColor(devicesStatus.releaseFilmState)
            )
            Divider().padding(.leading, 16)
            
            StatusRow(
                title: "X轴电机", 
                value: getMotorStatusText(devicesStatus.xMotorStatus),
                foregroundColor: getMotorStatusColor(devicesStatus.xMotorStatus)
            )
        }
        .background(Color(.systemBackground))
    }
    
    // UVLED温度传感器状态文本
    private func getUVLEDStatusText(_ status: Int) -> String {
        switch status {
        case 0: return "未接入"
        case 1: return "正常"
        case 2: return "异常"
        default: return "未知"
        }
    }
    
    // UVLED温度传感器状态颜色
    private func getUVLEDStatusColor(_ status: Int) -> Color {
        switch status {
        case 0: return .orange
        case 1: return .green
        case 2: return .red
        default: return .secondary
        }
    }
    
    // LCD屏幕状态文本
    private func getLCDStatusText(_ status: Int) -> String {
        switch status {
        case 0: return "断开"
        case 1: return "连接"
        default: return "未知"
        }
    }
    
    // LCD屏幕状态颜色
    private func getLCDStatusColor(_ status: Int) -> Color {
        switch status {
        case 0: return .red
        case 1: return .green
        default: return .secondary
        }
    }
    
    // 应变片状态文本
    private func getSGStatusText(_ status: Int) -> String {
        switch status {
        case 0: return "未接入"
        case 1: return "正常"
        case 2: return "校准失败"
        default: return "未知"
        }
    }
    
    // 应变片状态颜色
    private func getSGStatusColor(_ status: Int) -> Color {
        switch status {
        case 0: return .orange
        case 1: return .green
        case 2: return .red
        default: return .secondary
        }
    }
    
    // 电机状态文本
    private func getMotorStatusText(_ status: Int) -> String {
        switch status {
        case 0: return "断开"
        case 1: return "连接"
        default: return "未知"
        }
    }
    
    // 电机状态颜色
    private func getMotorStatusColor(_ status: Int) -> Color {
        switch status {
        case 0: return .red
        case 1: return .green
        default: return .secondary
        }
    }
    
    // 离型膜状态文本
    private func getReleaseFilmStatusText(_ status: Int) -> String {
        switch status {
        case 0: return "异常"
        case 1: return "正常"
        default: return "未知"
        }
    }
    
    // 离型膜状态颜色
    private func getReleaseFilmStatusColor(_ status: Int) -> Color {
        switch status {
        case 0: return .red
        case 1: return .green
        default: return .secondary
        }
    }
}

// 预览
#Preview {
    let previewDevicesStatus = PrintStatus.DevicesStatus(
        tempSensorStatusOfUVLED: 1,  // 正常
        lcdStatus: 1,                // 连接
        sgStatus: 1,                 // 正常
        zMotorStatus: 1,             // 连接
        rotateMotorStatus: 1,        // 连接
        releaseFilmState: 1,         // 正常
        xMotorStatus: 1              // 连接
    )
    
    return DeviceComponentStatusView(devicesStatus: previewDevicesStatus)
}