import SwiftUI

/// 打印监控视图
struct PrintMonitorView: View {
    let device: PrinterDevice
    @StateObject private var webSocketManager = WebSocketManager.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isStreaming = false
    
    var body: some View {
        List {
            // 视频监控区域
            if device.capabilities.contains(.videoStream) {
                Section {
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
                } header: {
                    Text("视频监控")
                }
            }
            
            // 打印控制区域
            Section {
                if let status = webSocketManager.currentStatus,
                   let printInfo = status.printInfo {
                    // 打印状态显示
                    DeviceStatusRow(title: "当前状态", value: printInfo.status.description)
                    
                    // 打印进度
                    PrintProgressView(printInfo: printInfo)
                    
                    // 打印控制按钮
                    HStack {
                        // 暂停/继续按钮
                        if printInfo.status == .exposuring || 
                           printInfo.status == .dropping ||
                           printInfo.status == .lifting {
                            ControlButton(title: "暂停", icon: "pause.fill") {
                                sendCommand("pause")
                            }
                        } else if printInfo.status == .paused {
                            ControlButton(title: "继续", icon: "play.fill") {
                                sendCommand("resume")
                            }
                        }
                        
                        // 停止按钮
                        if printInfo.status != .stopped && printInfo.status != .complete {
                            ControlButton(title: "停止", icon: "stop.fill") {
                                sendCommand("stop")
                            }
                            .tint(.red)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Text("未在打印")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("打印控制")
            }
        }
        .navigationTitle("打印监控")
        .navigationBarTitleDisplayMode(.inline)
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    /// 发送控制命令
    private func sendCommand(_ command: String) {
        webSocketManager.sendCommand(command)
    }
    
    private func toggleStream() {
        isStreaming.toggle()
        // TODO: 实现视频流切换逻辑
    }
} 