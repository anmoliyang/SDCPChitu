import SwiftUI

/// 设备详情视图
struct DeviceDetailView: View {
    let device: PrinterDevice
    @StateObject private var webSocketManager = WebSocketManager.shared
    @StateObject private var deviceManager = DeviceManager.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingConfirmation = false
    @State private var confirmationMessage = ""
    @State private var confirmationAction: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    private var deviceStatus: PrintStatus.DevicesStatus? {
        webSocketManager.currentStatus?.devicesStatus
    }
    
    private var printStatus: PrintStatus? {
        webSocketManager.currentStatus
    }
    
    private var printInfo: PrintInfo? {
        printStatus?.printInfo
    }
    
    private var isStoppingPrint: Bool {
        printStatus?.printInfo?.status == .stopping
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // 打印机图片
                Image("printer_thumbnail")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 150)
                
                // 打印状态部分
                if let info = printInfo,
                   let status = printStatus {
                    PrintStatusSection(status: status, info: info)
                }
                
                // 操作控制部分
                VStack(spacing: 16) {
                    VStack(spacing: 15) {
                        // 快捷操作按钮
                        HStack(spacing: 15) {
                            Button(action: { /* 打开摄像头 */ }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "web.camera")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("打开摄像")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                            }
                            .primaryButtonStyle(backgroundColor: Color(red: 248/255, green: 248/255, blue: 248/255))
                            
                            Button(action: { /* 设备设置 */ }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("设备设置")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                            }
                            .primaryButtonStyle(backgroundColor: Color(red: 248/255, green: 248/255, blue: 248/255))
                        }
                        .padding(.horizontal, 15)
                        
                        // 打印控制部分
                        if isStoppingPrint {
                            // 停止中按钮
                            Button(action: {}) {
                                HStack(spacing: 5) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("停止中...")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .primaryButtonStyle(backgroundColor: Color(red: 0.87, green: 0.16, blue: 0.16))
                            .disabled(true)
                            .padding(.horizontal, 15)
                        } else if let info = printInfo {
                            // 主要控制按钮
                            if info.status == .exposuring || 
                               info.status == .dropping ||
                               info.status == .lifting ||
                               info.status == .homing {
                                // 暂停和停止按钮并排
                                HStack(spacing: 15) {
                                    // 暂停打印按钮
                                    Button {
                                        confirmAction("确定要暂停打印吗？") {
                                            sendCommand("pause")
                                        }
                                    } label: {
                                        Text("暂停打印")
                                            .font(.system(size: 16, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                    }
                                    .primaryButtonStyle()
                                    
                                    // 停止打印按钮
                                    Button {
                                        confirmAction("确定要停止打印吗？此操作不可恢复。") {
                                            sendCommand("stop")
                                        }
                                    } label: {
                                        Text("停止打印")
                                            .font(.system(size: 16, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                    }
                                    .primaryButtonStyle(backgroundColor: Color(red: 0.87, green: 0.16, blue: 0.16))
                                }
                                .padding(.horizontal, 15)
                            } else if info.status == .paused ||
                                      info.status == .pausing {
                                // 继续和停止按钮并排
                                HStack(spacing: 15) {
                                    // 继续打印按钮
                                    Button {
                                        sendCommand("resume")
                                    } label: {
                                        Text("继续打印")
                                            .font(.system(size: 16, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                    }
                                    .primaryButtonStyle()
                                    
                                    // 停止打印按钮
                                    Button {
                                        confirmAction("确定要停止打印吗？此操作不可恢复。") {
                                            sendCommand("stop")
                                        }
                                    } label: {
                                        Text("停止打印")
                                            .font(.system(size: 16, weight: .bold))
                                            .frame(maxWidth: .infinity)
                                    }
                                    .primaryButtonStyle(backgroundColor: Color(red: 0.87, green: 0.16, blue: 0.16))
                                }
                                .padding(.horizontal, 15)
                            }
                        } else {
                            // 开始打印按钮
                            Button(action: { 
                                sendCommand("StartPrint")
                            }) {
                                Text("开始打印")
                                    .font(.system(size: 16, weight: .bold))
                                    .frame(maxWidth: .infinity)
                            }
                            .primaryButtonStyle()
                            .padding(.horizontal, 15)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 15)
                }
                
                // 设备状态列表
                VStack(alignment: .center, spacing: 0) {
                    if let status = deviceStatus {
                        StatusRow(
                            title: "UVLED 传感器",
                            value: getUVLEDStatusText(status.tempSensorStatusOfUVLED),
                            foregroundColor: getStatusColor(status.tempSensorStatusOfUVLED == 1)
                        )
                        
                        StatusRow(
                            title: "LCD 屏幕",
                            value: getLCDStatusText(status.lcdStatus),
                            foregroundColor: getStatusColor(status.lcdStatus == 1)
                        )
                        
                        StatusRow(
                            title: "光栅",
                            value: getSGStatusText(status.sgStatus),
                            foregroundColor: getStatusColor(status.sgStatus == 1)
                        )
                        
                        StatusRow(
                            title: "旋转电机",
                            value: getMotorStatusText(status.rotateMotorStatus),
                            foregroundColor: getStatusColor(status.rotateMotorStatus == 1)
                        )
                        
                        StatusRow(
                            title: "离型膜",
                            value: getReleaseFilmStatusText(status.releaseFilmState),
                            foregroundColor: getStatusColor(status.releaseFilmState == 1)
                        )
                        
                        StatusRow(
                            title: "X轴电机",
                            value: getMotorStatusText(status.xMotorStatus),
                            foregroundColor: getStatusColor(status.xMotorStatus == 1)
                        )
                        
                        StatusRow(
                            title: "Z轴电机",
                            value: getMotorStatusText(status.zMotorStatus),
                            foregroundColor: getStatusColor(status.zMotorStatus == 1)
                        )
                    } else {
                        StatusRow(title: "设备状态", value: "获取中...")
                    }
                }
                .padding(.vertical, 0)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 15)
            }
            .padding(.top, 20)
        }
        .background(Color(red: 248/255, green: 248/255, blue: 248/255).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(CustomNavigationConfigurator())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }

            ToolbarItem(placement: .principal) {
                Text(device.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
            }
        }

        .alert("确认", isPresented: $showingConfirmation) {
            Button("取消", role: .cancel) {}
            Button("确定", role: .destructive) {
                confirmationAction?()
            }
        } message: {
            Text(confirmationMessage)
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            connectToDevice()
        }
    }
    
    private func connectToDevice() {
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
    
    private func disconnectDevice() {
        webSocketManager.disconnect()
        deviceManager.disconnectDevice(device)
    }
    
    // MARK: - Helper Methods
    
    private func getStatusColor(_ isNormal: Bool) -> Color {
        isNormal ? .secondary : .red
    }
    
    private func getUVLEDStatusText(_ status: Int) -> String {
        switch status {
        case 0: return "未接入"
        case 1: return "正常"
        case 2: return "异常"
        default: return "未知"
        }
    }
    
    private func getLCDStatusText(_ status: Int) -> String {
        status == 1 ? "连接" : "未连接"
    }
    
    private func getSGStatusText(_ status: Int) -> String {
        status == 1 ? "正常" : "异常"
    }
    
    private func getMotorStatusText(_ status: Int) -> String {
        status == 1 ? "连接" : "未连接"
    }
    
    private func getReleaseFilmStatusText(_ status: Int) -> String {
        status == 1 ? "正常" : "异常"
    }
    
    private func sendCommand(_ command: String) {
        print("Debug: DeviceDetailView - Sending command: \(command)")
        
        // 构建符合 SDCP 协议的命令数据
        var commandData: [String: Any] = [:]
        
        // 根不同命令添加所需参数
        switch command {
        case "pause", "resume", "stop":
            commandData["TaskID"] = printInfo?.taskId ?? ""
        default:
            break
        }
        
        let message: [String: Any] = [
            "Topic": "sdcp/request/\(device.id)",
            "Data": [
                "MainboardID": device.id,
                "RequestID": UUID().uuidString,
                "TimeStamp": Int(Date().timeIntervalSince1970),
                "From": 3,
                "Cmd": getCommandCode(command),
                "Data": commandData
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            print("Debug: DeviceDetailView - Command JSON: \(jsonString)")
            webSocketManager.sendCommand(jsonString)
        }
    }
    
    private func getCommandCode(_ command: String) -> Int {
        switch command {
        case "StartPrint": return 128  // 开始打印
        case "pause": return 129   // 暂停打印
        case "resume": return 130  // 继续打印
        case "stop": return 131    // 停止打印
        default: return 0
        }
    }
    
    private func confirmAction(_ message: String, action: @escaping () -> Void) {
        confirmationMessage = message
        confirmationAction = action
        showingConfirmation = true
    }
}

#Preview {
    NavigationView {
        DeviceDetailView(device: PrinterDevice.preview)
    }
} 
