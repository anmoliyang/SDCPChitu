import SwiftUI

/// 设备详情视图
struct DeviceDetailView: View {
    let device: PrinterDevice
    @StateObject private var webSocketManager = WebSocketManager.shared
    @StateObject private var deviceManager = DeviceManager.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 248/255, green: 248/255, blue: 248/255)
                .ignoresSafeArea()
            
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
                
                // 添加移除设备按钮
                Section {
                    Button(action: {
                        disconnectDevice()
                        dismiss()
                    }) {
                        HStack(alignment: .center, spacing: 5) {
                            Image(systemName: "minus.circle")
                                .frame(width: 18, height: 18)
                            Text("移除打印机")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .padding(.horizontal, 50)
                        .padding(.vertical, 20)
                        .frame(maxWidth: min(UIScreen.main.bounds.width - 40, 400), alignment: .center)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(Color.black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 100)
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Color(red: 248/255, green: 248/255, blue: 248/255))
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(device.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }
        }
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
    
    private func disconnectDevice() {
        webSocketManager.disconnect()
        deviceManager.disconnectDevice(device)
    }
}

#Preview {
    NavigationView {
        DeviceDetailView(device: PrinterDevice.preview)
    }
} 
