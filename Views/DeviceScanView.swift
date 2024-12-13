import SwiftUI

struct DeviceScanView: View {
    @StateObject private var discoveryManager = UDPDiscoveryManager.shared
    @StateObject private var deviceManager = DeviceManager.shared
    @StateObject private var webSocketManager = WebSocketManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var connectingDevice: PrinterDevice?
    @State private var isScanning = false
    @State private var isAnimating = false
    
    private var availableDevices: [PrinterDevice] {
        discoveryManager.discoveredDevices.filter { device in
            !deviceManager.connectedDevices.contains(device)
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.97, blue: 0.97)
                .ignoresSafeArea()
            
            VStack {
                if isScanning {
                    GeometryReader { geometry in
                        VStack {
                            VStack(spacing: 15) {
                                Text("正在扫描打印机...")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text("请确保打印机处于同一局域网")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color.black.opacity(0.5))
                            }
                            .padding(.top, 30)
                            
                            Spacer()
                            
                            // 扫描动画
                            ZStack {
                                // 波纹动画1
                                Circle()
                                    .fill(Color.black.opacity(0.05))
                                    .frame(width: 210, height: 210)
                                    .scaleEffect(isAnimating ? 1 : 60/210)
                                    .opacity(isAnimating ? 0 : 1)
                                    .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                                
                                // 波纹动画2
                                Circle()
                                    .fill(Color.black.opacity(0.05))
                                    .frame(width: 210, height: 210)
                                    .scaleEffect(isAnimating ? 1 : 60/210)
                                    .opacity(isAnimating ? 0 : 1)
                                    .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false).delay(0.6), value: isAnimating)
                                
                                // 波纹动画3
                                Circle()
                                    .fill(Color.black.opacity(0.05))
                                    .frame(width: 210, height: 210)
                                    .scaleEffect(isAnimating ? 1 : 60/210)
                                    .opacity(isAnimating ? 0 : 1)
                                    .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false).delay(1.2), value: isAnimating)
                                
                                // 中心圆和图标
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .frame(width: geometry.size.width)
                            
                            Spacer()
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .onAppear {
                        isAnimating = true
                    }
                    .onChange(of: isScanning) { _, scanning in
                        if scanning {
                            isAnimating = true
                        }
                    }
                    
                    Spacer()
                } else {
                    // 设备列表
                    ScrollView {
                        if availableDevices.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "printer.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("未发现可用设备")
                                    .font(.headline)
                                Text("请确保设备已开机并在同一网络中")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 15) {
                                ForEach(Array(availableDevices.enumerated()), id: \.element.id) { index, device in
                                    DeviceRow(
                                        device: device,
                                        isConnecting: connectingDevice == device,
                                        isFirstItem: index == 0
                                    )
                                    .onTapGesture {
                                        connectDevice(device)
                                    }
                                }
                            }
                            .padding(.top, 30)
                        }
                    }
                    
                    // 底部刷新按钮
                    Button(action: {
                        startScanning()
                    }) {
                        HStack(alignment: .center, spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .frame(width: 18, height: 18)
                            Text("重新搜索")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .padding(.horizontal, 50)
                        .padding(.vertical, 20)
                        .frame(maxWidth: min(UIScreen.main.bounds.width - 40, 400), alignment: .center)
                        .background(.black)
                        .foregroundColor(.white)
                        .cornerRadius(100)
                    }
                    .disabled(connectingDevice != nil)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 20)
                }
            }
        }
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
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            startScanning()
        }
        .onDisappear {
            stopScanning()
        }
    }
    
    private func startScanning() {
        isScanning = true
        isAnimating = false // 重置动画状态
        discoveryManager.startDiscovery {
            DispatchQueue.main.async {
                isScanning = false
            }
        }
    }
    
    private func stopScanning() {
        discoveryManager.stopDiscovery()
        isScanning = false
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func connectDevice(_ device: PrinterDevice) {
        connectingDevice = device
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            webSocketManager.connect(to: device) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        deviceManager.connectDevice(device)
                        connectingDevice = nil
                        dismiss()
                    case .failure(let error):
                        showError(error.localizedDescription)
                        connectingDevice = nil
                    }
                }
            }
        }
    }
}

// 设备行视图
struct DeviceRow: View {
    let device: PrinterDevice
    let isConnecting: Bool
    let isFirstItem: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // 设备图片
            Image("printer_thumbnail")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(device.machineName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Text(device.brandName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("IP: \(device.ipAddress)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isConnecting {
                ProgressView()
                    .controlSize(.regular)
                    .padding(.trailing, 20)
            }
        }
        .padding(.leading, 20)
        .padding([.top, .bottom, .trailing], 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
        )
        .cornerRadius(15)
        .opacity(isConnecting ? 0.6 : 1.0)
        .padding(.horizontal, 20)
    }
}

// 用于十六进制颜色的扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 