import SwiftUI
import Combine

struct DeviceDetailView: View {
    let device: PrinterDevice
    @StateObject private var webSocketManager = WebSocketManager.shared
    @State private var currentStatus: PrintStatus?
    
    var body: some View {
        List {
            // 打印监控入口
            if device.capabilities.contains(.printControl) {
                Section {
                    NavigationLink {
                        PrintMonitorView(device: device)
                    } label: {
                        HStack {
                            Image(systemName: "printer.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("打印监控")
                                    .font(.headline)
                                if let status = currentStatus?.printInfo?.status {
                                    Text(status.description)
                                        .font(.caption)
                                        .foregroundColor(getStatusColor(status))
                                }
                            }
                        }
                    }
                }
            }
            
            // 添加文件管理入口
            if device.capabilities.contains(.fileTransfer) {
                Section {
                    NavigationLink {
                        FileManagerView(device: device)
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("文件管理")
                                    .font(.headline)
                                Text("管理打印文件")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // 基本信息区域
            Section(header: Text("基本信息")) {
                DeviceStatusRow(title: "设备名称", value: device.name)
                DeviceStatusRow(title: "机型", value: device.machineName)
                DeviceStatusRow(title: "品牌", value: device.brandName)
                DeviceStatusRow(title: "IP地址", value: device.ipAddress)
                DeviceStatusRow(title: "固件版本", value: device.firmwareVersion)
                DeviceStatusRow(title: "分辨率", value: device.resolution)
                DeviceStatusRow(title: "成型尺寸", value: device.xyzSize)
            }
            
            // 状态信息区域
            Section(header: Text("运行状态")) {
                if let status = currentStatus {
                    DeviceStatusRow(title: "机器状态", value: status.currentStatus.description)
                    
                    DeviceStatusRow(title: "LCD屏", value: getStatusText(device.deviceStatus.lcdStatus))
                        .foregroundColor(getStatusColor(device.deviceStatus.lcdStatus))
                    DeviceStatusRow(title: "Z轴电机", value: getStatusText(device.deviceStatus.zMotorStatus))
                        .foregroundColor(getStatusColor(device.deviceStatus.zMotorStatus))
                    DeviceStatusRow(title: "离型膜", value: getStatusText(device.deviceStatus.releaseFilmState))
                        .foregroundColor(getStatusColor(device.deviceStatus.releaseFilmState))
                    
                    DeviceStatusRow(title: "UVLED温度", value: "\(String(format: "%.1f", status.uvledTemperature))℃")
                    DeviceStatusRow(title: "箱体温度", value: "\(String(format: "%.1f", status.boxTemperature))℃")
                    
                    if let printInfo = status.printInfo {
                        PrintProgressView(printInfo: printInfo)
                    }
                } else {
                    HStack {
                        Spacer()
                        ProgressView()
                        Text("正在获取状态...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(device.name)
        .onAppear {
            webSocketManager.connect(to: device) { _ in }
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
        .onReceive(webSocketManager.$currentStatus) { status in
            currentStatus = status
        }
    }
    
    // MARK: - 辅助方法
    
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
        case .unknown: return .gray
        }
    }
    
    // 获取打印状态颜色
    private func getStatusColor(_ status: PrintStatus.PrintSubStatus) -> Color {
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
    NavigationView {
        DeviceDetailView(device: PrinterDevice.preview)
    }
} 
