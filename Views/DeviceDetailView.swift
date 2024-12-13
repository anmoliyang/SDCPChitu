import SwiftUI

/// 设备详情视图
struct DeviceDetailView: View {
    let device: PrinterDevice
    @StateObject private var webSocketManager = WebSocketManager.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            // 视频监控区域
            if device.capabilities.contains(.videoStream) {
                Section(header: Text("视频监控")) {
                    VideoStreamView(device: device)
                }
            }
            
            // 打印控制区域
            Section(header: Text("打印控制")) {
                PrintControlView(device: device)
            }
            
            // 设备状态区域
            Section(header: Text("设备状态")) {
                DeviceComponentStatusView(deviceStatus: device.deviceStatus)
                if let status = webSocketManager.currentStatus {
                    DeviceTemperatureView(status: status)
                }
            }
        }
        .navigationTitle(device.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            connectToDevice()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
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
}

#Preview {
    NavigationView {
        DeviceDetailView(device: PrinterDevice.preview)
    }
} 
