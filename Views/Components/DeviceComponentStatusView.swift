import SwiftUI

/// 设备组件状态视图
struct DeviceComponentStatusView: View {
    let deviceStatus: DeviceStatus
    
    var body: some View {
        VStack {
            DeviceStatusRow(title: "UVLED传感器", 
                          value: getStatusText(deviceStatus.uvledTempSensorStatus))
                .foregroundColor(getStatusColor(deviceStatus.uvledTempSensorStatus))
            
            DeviceStatusRow(title: "LCD屏幕", 
                          value: getStatusText(deviceStatus.lcdStatus))
                .foregroundColor(getStatusColor(deviceStatus.lcdStatus))
            
            DeviceStatusRow(title: "光栅", 
                          value: getStatusText(deviceStatus.sgStatus))
                .foregroundColor(getStatusColor(deviceStatus.sgStatus))
            
            DeviceStatusRow(title: "Z轴电机", 
                          value: getStatusText(deviceStatus.zMotorStatus))
                .foregroundColor(getStatusColor(deviceStatus.zMotorStatus))
            
            DeviceStatusRow(title: "旋转电机", 
                          value: getStatusText(deviceStatus.rotateMotorStatus))
                .foregroundColor(getStatusColor(deviceStatus.rotateMotorStatus))
            
            DeviceStatusRow(title: "离型膜", 
                          value: getStatusText(deviceStatus.releaseFilmState))
                .foregroundColor(getStatusColor(deviceStatus.releaseFilmState))
            
            DeviceStatusRow(title: "X轴电机", 
                          value: getStatusText(deviceStatus.xMotorStatus))
                .foregroundColor(getStatusColor(deviceStatus.xMotorStatus))
        }
    }
    
    private func getStatusText(_ status: DeviceStatus.Status) -> String {
        switch status {
        case .normal: return "正常"
        case .abnormal: return "异常"
        case .unknown: return "未知"
        }
    }
    
    private func getStatusColor(_ status: DeviceStatus.Status) -> Color {
        switch status {
        case .normal: return .green
        case .abnormal: return .red
        case .unknown: return .secondary
        }
    }
}