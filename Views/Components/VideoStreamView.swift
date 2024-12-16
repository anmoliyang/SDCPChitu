import SwiftUI
import AVKit

/// 视频监控组件
struct VideoStreamView: View {
    let device: PrinterDevice
    @StateObject private var webSocketManager = WebSocketManager.shared
    
    private var isStreaming: Bool {
        webSocketManager.videoStreamUrl != nil
    }
    
    var body: some View {
        VStack {
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
                } else if let url = webSocketManager.videoStreamUrl {
                    if let videoURL = URL(string: url) {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .aspectRatio(16/9, contentMode: .fit)
                    } else {
                        Text("视频流地址无效")
                            .foregroundColor(.red)
                    }
                }
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
        .background(Color(red: 248/255, green: 248/255, blue: 248/255))
        .transaction { transaction in
            transaction.animation = nil
        }
    }
    
    private func toggleStream() {
        let message: [String: Any] = [
            "Topic": "sdcp/request/\(device.id)",
            "Data": [
                "MainboardID": device.id,
                "RequestID": UUID().uuidString,
                "TimeStamp": Int(Date().timeIntervalSince1970),
                "From": 3,
                "Cmd": 386,  // 打开/关闭视频流命令
                "Data": [
                    "Enable": isStreaming ? 0 : 1  // 0：关闭 1：开启
                ]
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            webSocketManager.sendCommand(jsonString)
        }
    }
} 