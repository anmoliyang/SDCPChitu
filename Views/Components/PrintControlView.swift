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
            if let info = printInfo {
                // 打印控制按钮组
                PrintControlButtons(printInfo: info) { command in
                    sendCommand(command)
                } confirmAction: { message, action in
                    confirmAction(message: message, action: action)
                }
            } else {
                #if DEBUG
                // 调试模式下显示开始打印按钮
                Button(action: { sendCommand("StartPrint") }) {
                    Label("开始打印", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                #endif
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal, 15)
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
        
        // 构建符合 SDCP 协议的命令数据
        var commandData: [String: Any] = [:]
        
        // 根据不同命令添加所需参数
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
            print("Debug: PrintControlView - Command JSON: \(jsonString)")
            webSocketManager.sendCommand(jsonString)
        }
    }
    
    private func getCommandCode(_ command: String) -> Int {
        switch command {
        case "pause": return 129   // 暂停打印
        case "resume": return 130  // 继续打印
        case "stop": return 131    // 停止打印
        case "StartPrint": return 128  // 开始打印
        default: return 0
        }
    }
    
    private func confirmAction(message: String, action: @escaping () -> Void) {
        confirmationMessage = message
        confirmationAction = action
        showingConfirmation = true
    }
} 