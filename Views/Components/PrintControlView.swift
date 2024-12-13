import SwiftUI

/// 打印控制组件
struct PrintControlView: View {
    let device: PrinterDevice
    @StateObject private var webSocketManager = WebSocketManager.shared
    @State private var showingConfirmation = false
    @State private var confirmationAction: (() -> Void)?
    @State private var confirmationMessage = ""
    
    private var printStatus: PrintStatus? {
        webSocketManager.currentStatus
    }
    
    private var printInfo: PrintInfo? {
        printStatus?.printInfo
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let status = printStatus,
               let info = printInfo {
                // 打印状态显示
                DeviceStatusView(status: status, printInfo: info)
                
                // 打印进度
                PrintProgressView(printInfo: info)
                
                // 打印控制按钮组
                PrintControlButtons(printInfo: info) { command in
                    sendCommand(command)
                } confirmAction: { message, action in
                    confirmAction(message: message, action: action)
                }
                .padding(.vertical, 8)
            } else {
                NonPrintingView { command in
                    sendCommand(command)
                }
                .padding(.vertical, 8)
            }
        }
        .transaction { transaction in
            // 禁用所有隐式动画
            transaction.animation = nil
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
    
    private func sendCommand(_ command: String) {
        print("Debug: PrintControlView - Sending command: \(command)")
        print("Debug: PrintControlView - WebSocket connected: \(webSocketManager.isConnected)")
        print("Debug: PrintControlView - Current status: \(String(describing: printStatus))")
        
        let message: [String: Any] = [
            "Topic": "sdcp/request/\(device.id)",
            "Data": [
                "MainboardID": device.id,
                "RequestID": UUID().uuidString,
                "TimeStamp": Int(Date().timeIntervalSince1970),
                "From": 3,
                "Cmd": getCommandCode(command),
                "Data": [:] as [String: Any]
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            print("Debug: PrintControlView - Command JSON: \(jsonString)")
            webSocketManager.sendCommand(jsonString)
        } else {
            print("Error: PrintControlView - Failed to serialize command")
        }
    }
    
    private func getCommandCode(_ command: String) -> Int {
        switch command {
            case "pause": return 0x82   // 暂停打印
            case "resume": return 0x83  // 继续打印
            case "stop": return 0x84    // 停止打印
            case "home": return 0x85    // 回零操作
            case "StartPrint": return 0x81  // 开始打印
            case "exposureTest": return 0x86  // 曝光测试
            case "deviceTest": return 0x87   // 设备自检
            default: return 0
        }
    }
    
    private func confirmAction(message: String, action: @escaping () -> Void) {
        confirmationMessage = message
        confirmationAction = action
        showingConfirmation = true
    }
}

// MARK: - 子视图
private struct PrintControlButtons: View {
    let printInfo: PrintInfo
    let onCommand: (String) -> Void
    let confirmAction: (String, @escaping () -> Void) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // 主要控制按钮
            HStack {
                // 暂停/继续按钮
                if printInfo.status == .exposuring || 
                   printInfo.status == .dropping ||
                   printInfo.status == .lifting {
                    ControlButton(title: "暂停", icon: "pause.fill") {
                        confirmAction("确定要暂停打印吗？") {
                            onCommand("pause")
                        }
                    }
                } else if printInfo.status == .paused {
                    ControlButton(title: "继续", icon: "play.fill") {
                        onCommand("resume")
                    }
                }
                
                // 停止按钮
                if printInfo.status != .idle &&
                   printInfo.status != .stopped &&
                   printInfo.status != .complete {
                    ControlButton(title: "停止", icon: "stop.fill") {
                        confirmAction("确定要停止打印吗？此操作不可恢复。") {
                            onCommand("stop")
                        }
                    }
                    .tint(.red)
                }
            }
            
            // 辅助控制按钮
            HStack {
                // 回零按钮
                if printInfo.status == .idle ||
                   printInfo.status == .stopped ||
                   printInfo.status == .complete {
                    ControlButton(title: "回零", icon: "arrow.down.to.line") {
                        confirmAction("确定要执行回零操作吗？") {
                            onCommand("home")
                        }
                    }
                }
            }
            
            // 调试按钮
            #if DEBUG
            if printInfo.status == .idle ||
               printInfo.status == .stopped ||
               printInfo.status == .complete {
                Button(action: { onCommand("StartPrint") }) {
                    Label("开始测试打印", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                Button(action: { onCommand("exposureTest") }) {
                    Label("曝光测试", systemImage: "rays")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button(action: { onCommand("deviceTest") }) {
                    Label("设备自检", systemImage: "gearshape.2")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            }
            #endif
        }
    }
}

private struct NonPrintingView: View {
    let onCommand: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("未在打印")
                .foregroundColor(.secondary)
            
            #if DEBUG
            // 调试按钮
            Button(action: { onCommand("StartPrint") }) {
                Label("开始测试打印", systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            
            Button(action: { onCommand("exposureTest") }) {
                Label("曝光测试", systemImage: "rays")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            
            Button(action: { onCommand("deviceTest") }) {
                Label("设备自检", systemImage: "gearshape.2")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.green)
            #endif
        }
    }
} 