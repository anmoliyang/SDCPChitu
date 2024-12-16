import SwiftUI

struct DeviceStatusSection: View {
    let device: PrinterDevice
    let webSocketManager: WebSocketManager
    
    var body: some View {
        Section(header: Text("设备状态")) {
            if let status = webSocketManager.currentStatus {
                // 调试模式下提供默认的设备状态
                #if DEBUG
                if device.id.starts(with: "DEBUG") {
                    DeviceComponentStatusView(devicesStatus: .debugDefault)
                } else if let devicesStatus = status.devicesStatus {
                    DeviceComponentStatusView(devicesStatus: devicesStatus)
                } else {
                    Text("获取设备状态中...")
                        .foregroundColor(.secondary)
                }
                #else
                if let devicesStatus = status.devicesStatus {
                    DeviceComponentStatusView(devicesStatus: devicesStatus)
                } else {
                    Text("获取设备状态中...")
                        .foregroundColor(.secondary)
                }
                #endif
            } else {
                Text("获取设备状态中...")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#if DEBUG
extension PrintStatus.DevicesStatus {
    /// 调试模式下的默认设备状态
    static let debugDefault = PrintStatus.DevicesStatus(
        tempSensorStatusOfUVLED: 1,  // 正常
        lcdStatus: 1,                // 连接
        sgStatus: 1,                 // 正常
        zMotorStatus: 1,             // 连接
        rotateMotorStatus: 1,        // 连接
        releaseFilmState: 1,         // 正常
        xMotorStatus: 1              // 连接
    )
}
#endif 