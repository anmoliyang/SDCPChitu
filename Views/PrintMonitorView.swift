import SwiftUI

/// 打印监控视图
struct PrintMonitorView: View {
    let device: PrinterDevice
    @StateObject private var webSocketManager = WebSocketManager.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isStreaming = false
    @State private var showingConfirmation = false
    @State private var confirmationAction: (() -> Void)?
    @State private var confirmationMessage = ""
    
    var body: some View {
        List {
            // 视频监控区域
            if device.capabilities.contains(.videoStream) {
                Section(header: Text("视频监控")) {
                    // 视频预览区域
                    ZStack {
                        Color.black
                            .aspectRatio(16/9, contentMode: .fit)
                        
                        if !isStreaming {
                            VStack(spacing: 16) {
                                Image(systemName: "video.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("未连接视频流")
                                    .foregroundColor(.gray)
                            }
                        }
                        // TODO: 添加视频预览视图
                    }
                    .cornerRadius(8)
                    
                    // 视频控制按钮
                    Button(action: toggleStream) {
                        Label(isStreaming ? "停止视频" : "开始视频", systemImage: isStreaming ? "stop.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(isStreaming ? .red : .blue)
                }
            }
            
            // 打印控制区域
            Section(header: Text("打印控制")) {
                if let status = webSocketManager.currentStatus,
                   let printInfo = status.printInfo {
                    // 打印状态显示
                    DeviceStatusRow(title: "当前状态", value: printInfo.status.description)
                    DeviceStatusRow(title: "打印文件", value: printInfo.filename)
                    
                    // 打印进度
                    PrintProgressView(printInfo: printInfo)
                    
                    // 打印控制按钮组
                    VStack(spacing: 12) {
                        // 主要控制按钮
                        HStack {
                            // 暂停/继续按钮
                            if printInfo.status == .exposuring || 
                               printInfo.status == .dropping ||
                               printInfo.status == .lifting {
                                ControlButton(title: "暂停", icon: "pause.fill") {
                                    confirmAction(message: "确定要暂停打印吗？") {
                                        sendCommand("pause")
                                    }
                                }
                            } else if printInfo.status == .paused {
                                ControlButton(title: "继续", icon: "play.fill") {
                                    sendCommand("resume")
                                }
                            }
                            
                            // 停止按钮
                            if printInfo.status != .stopped && printInfo.status != .complete {
                                ControlButton(title: "停止", icon: "stop.fill") {
                                    confirmAction(message: "确定要停止打印吗？此操作不可恢复。") {
                                        sendCommand("stop")
                                    }
                                }
                                .tint(.red)
                            }
                        }
                        
                        // 辅助控制按钮
                        HStack {
                            // 回零按钮
                            if printInfo.status == .idle || printInfo.status == .complete {
                                ControlButton(title: "回零", icon: "arrow.down.to.line") {
                                    confirmAction(message: "确定要执行回零操作吗？") {
                                        sendCommand("home")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 16) {
                        Text("未在打印")
                            .foregroundColor(.secondary)
                        
                        // 添加开始打印按钮（仅在调试模式下显示）
                        #if DEBUG
                        Button(action: {
                            sendCommand("StartPrint")
                        }) {
                            Label("开始测试打印", systemImage: "play.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
                        Button(action: {
                            sendCommand("exposureTest")
                        }) {
                            Label("曝光测试", systemImage: "rays")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        
                        Button(action: {
                            sendCommand("deviceTest")
                        }) {
                            Label("设备自检", systemImage: "gearshape.2")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                        #endif
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // 设备状态区域
            Section(header: Text("设备状态")) {
                DeviceStatusRow(title: "UVLED传感器", 
                              value: getStatusText(device.deviceStatus.uvledTempSensorStatus))
                    .foregroundColor(getStatusColor(device.deviceStatus.uvledTempSensorStatus))
                
                DeviceStatusRow(title: "LCD屏幕", 
                              value: getStatusText(device.deviceStatus.lcdStatus))
                    .foregroundColor(getStatusColor(device.deviceStatus.lcdStatus))
                
                DeviceStatusRow(title: "Z轴电机", 
                              value: getStatusText(device.deviceStatus.zMotorStatus))
                    .foregroundColor(getStatusColor(device.deviceStatus.zMotorStatus))
                
                DeviceStatusRow(title: "离型膜", 
                              value: getStatusText(device.deviceStatus.releaseFilmState))
                    .foregroundColor(getStatusColor(device.deviceStatus.releaseFilmState))
            }
        }
        .navigationTitle("打印监控")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("Debug: PrintMonitorView appeared for device \(device.id)")
            webSocketManager.connect(to: device) { result in
                switch result {
                case .success:
                    print("Debug: Successfully connected to device")
                case .failure(let error):
                    print("Debug: Connection failed - \(error)")
                    errorMessage = "连接失败：\(error.localizedDescription)"
                    showingError = true
                }
            }
        }
        .onDisappear {
            print("Debug: PrintMonitorView disappeared")
            webSocketManager.disconnect()
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("确认", isPresented: $showingConfirmation) {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) {
                confirmationAction?()
            }
        } message: {
            Text(confirmationMessage)
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
    
    private func toggleStream() {
        isStreaming.toggle()
        
        let message: [String: Any] = [
            "Topic": "sdcp/request/\(device.id)",
            "Data": [
                "MainboardID": device.id,
                "RequestID": UUID().uuidString,
                "TimeStamp": Int(Date().timeIntervalSince1970),
                "From": 3,  // APP端
                "Cmd": isStreaming ? 0x90 : 0x91,  // 0x90: 开始视频流, 0x91: 停止视频流
                "Data": [:]
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            webSocketManager.sendCommand(jsonString)
        }
    }
    
    private func sendCommand(_ command: String) {
        print("Debug: Sending command - \(command)")
        webSocketManager.sendCommand(command)
    }
    
    private func confirmAction(message: String, action: @escaping () -> Void) {
        confirmationMessage = message
        confirmationAction = action
        showingConfirmation = true
    }
} 