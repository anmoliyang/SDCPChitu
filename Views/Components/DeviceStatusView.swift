import SwiftUI

/// 打印机状态视图组件
struct DeviceStatusView: View {
    let status: PrintStatus
    let printInfo: PrintInfo
    
    // MARK: - 子视图
    /// 设备信息行组件
    private struct StatusInfoRow: View {
        let title: String
        let value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 主状态显示
            HStack {
                Label(status.currentStatus.description, 
                      systemImage: getStatusIcon(status.currentStatus))
                    .foregroundColor(getStatusColor(status.currentStatus))
                Spacer()
                Text(printInfo.status.description)
                    .foregroundColor(getSubStatusColor(printInfo.status))
            }
            .font(.headline)
            
            // 详细状态信息
            VStack(spacing: 8) {
                if status.isPrinting {
                    StatusInfoRow(title: "打印文件", value: printInfo.filename)
                    StatusInfoRow(title: "打印速度", 
                                value: String(format: "%.1fx", printInfo.printSpeed))
                    StatusInfoRow(title: "Z轴高度", 
                                value: String(format: "%.2fmm", printInfo.zHeight))
                }
                
                if status.isExposureTesting {
                    StatusInfoRow(title: "曝光时间", 
                                value: "\(status.printScreenTime)ms")
                }
                
                if status.isDevicesTesting {
                    StatusInfoRow(title: "自检次数", 
                                value: "\(status.releaseFilmCount)次")
                }
            }
        }
    }
    
    private func getStatusIcon(_ status: PrintStatus.MachineStatus) -> String {
        switch status {
        case .idle: return "printer"
        case .printing: return "printer.fill"
        case .fileTransferring: return "arrow.down.doc.fill"
        case .exposureTesting: return "rays"
        case .devicesTesting: return "gearshape.2"
        }
    }
    
    private func getStatusColor(_ status: PrintStatus.MachineStatus) -> Color {
        switch status {
        case .idle: return .secondary
        case .printing: return .green
        case .fileTransferring: return .blue
        case .exposureTesting: return .orange
        case .devicesTesting: return .purple
        }
    }
    
    private func getSubStatusColor(_ status: PrintStatus.PrintSubStatus) -> Color {
        switch status {
        case .idle: return .secondary
        case .homing: return .blue
        case .dropping, .lifting: return .orange
        case .exposuring: return .green
        case .pausing, .paused: return .yellow
        case .stopping, .stopped: return .red
        case .complete: return .green
        case .fileChecking: return .blue
        }
    }
}

#Preview {
    let previewPrintInfo = PrintInfo(
        status: .exposuring,
        currentLayer: 50,
        totalLayer: 100,
        currentTicks: 3600000,
        totalTicks: 7200000,
        filename: "test.ctb",
        errorNumber: 0,
        taskId: "TEST001",
        remainingTicks: 3600000,
        printSpeed: 1.0,
        zHeight: 50.0
    )
    
    let previewStatus = PrintStatus(
        currentStatus: .printing,
        previousStatus: .idle,
        printScreenTime: 8000,
        releaseFilmCount: 0,
        uvledTemperature: 25.0,
        timeLapseEnabled: true,
        boxTemperature: 25.0,
        boxTargetTemperature: 28.0,
        printInfo: previewPrintInfo
    )
    
    return List {
        DeviceStatusView(status: previewStatus, printInfo: previewPrintInfo)
    }
} 