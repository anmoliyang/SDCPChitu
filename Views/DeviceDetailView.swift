import SwiftUI
import Combine

struct DeviceDetailView: View {
    let device: PrinterDevice
    @StateObject private var webSocketManager = WebSocketManager.shared
    @State private var currentStatus: PrintStatus?
    @State private var showingError = false
    @State private var errorMessage = ""
    @StateObject private var subscriptionStore = SubscriptionStore()
    @Environment(\.dismiss) private var dismiss
    @State private var showingRemoveAlert = false
    
    var body: some View {
        List {
            // 基本信息区域
            Section("基本信息") {
                InfoRow(title: "设备名称", value: device.name)
                InfoRow(title: "机型", value: device.machineName)
                InfoRow(title: "品牌", value: device.brandName)
                InfoRow(title: "固件版本", value: device.firmwareVersion)
                InfoRow(title: "分辨率", value: device.resolution)
                InfoRow(title: "成型尺寸", value: device.xyzSize)
            }
            
            // 状态信息区域
            if let status = currentStatus {
                Section("运行状态") {
                    DeviceStatusRow(title: "机器状态", value: status.currentStatus.map { $0.description }.joined(separator: ", "))
                    DeviceStatusRow(title: "UVLED温度", value: "\(String(format: "%.1f", status.uvledTemperature))℃")
                    DeviceStatusRow(title: "箱体温度", value: "\(String(format: "%.1f", status.boxTemperature))℃")
                    
                    if let printInfo = status.printInfo {
                        PrintProgressView(printInfo: printInfo)
                    }
                }
            }
            
            // 控制按钮区���
            Section {
                NavigationLink {
                    PrintMonitorView(device: device)
                } label: {
                    Label("打印监控", systemImage: "printer.fill")
                }
                
                NavigationLink {
                    FileManagerView(device: device)
                } label: {
                    Label("文件管理", systemImage: "folder")
                }
                
                // 移除设备按钮
                Button(role: .destructive) {
                    showingRemoveAlert = true
                } label: {
                    Label("移除设备", systemImage: "trash")
                }
            }
        }
        .navigationTitle("设备详情")
        .navigationBarTitleDisplayMode(.inline)
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("移除设备", isPresented: $showingRemoveAlert) {
            Button("取消", role: .cancel) {}
            Button("移除", role: .destructive) {
                removeDevice()
            }
        } message: {
            Text("确定要移除该设备吗？")
        }
        .onAppear {
            connectDevice()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }
    
    private func connectDevice() {
        // 连接设备并保存状态
        DeviceManager.shared.connectDevice(device)
        setupSubscriptions()
    }
    
    private func removeDevice() {
        // 断开连接并移除设备
        webSocketManager.disconnect()
        DeviceManager.shared.removeDevice(device)
        dismiss()
    }
    
    private func setupSubscriptions() {
        // 订阅状态更新
        webSocketManager.statusPublisher
            .receive(on: RunLoop.main)
            .sink { status in
                currentStatus = status
            }
            .store(in: &subscriptionStore.cancellables)
        
        // 订阅错误信息
        webSocketManager.errorPublisher
            .receive(on: RunLoop.main)
            .sink { error in
                errorMessage = error
                showingError = true
            }
            .store(in: &subscriptionStore.cancellables)
        
        // 连接设备
        webSocketManager.connect(to: device)
    }
}

struct InfoRow: View {
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

struct StatusRow: View {
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

struct PrintProgressView: View {
    let printInfo: PrintInfo
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("打印进度")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(printInfo.progress * 100))%")
            }
            
            ProgressView(value: printInfo.progress)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("当前层/总层")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(printInfo.currentLayer)/\(printInfo.totalLayer)")
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("已用时间/总时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(printInfo.formattedCurrentTime)/\(printInfo.formattedTotalTime)")
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationView {
        DeviceDetailView(device: PrinterDevice.preview)
    }
}

class SubscriptionStore: ObservableObject {
    var cancellables = Set<AnyCancellable>()
} 
