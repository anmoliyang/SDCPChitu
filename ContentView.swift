//
//  ContentView.swift
//  SDCPChitu
//
//  Created by 杨俊文 on 2024/12/9.
//

import SwiftUI

// 创建一个自定义的导航配置视图修饰符
struct CustomNavigationConfigurator: UIViewControllerRepresentable {
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: CustomNavigationConfigurator
        
        init(_ parent: CustomNavigationConfigurator) {
            self.parent = parent
            super.init()
        }
        
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if let navigationController = uiViewController.navigationController {
                navigationController.interactivePopGestureRecognizer?.delegate = context.coordinator
                navigationController.interactivePopGestureRecognizer?.isEnabled = true
            }
        }
    }
}

// 添加 View 扩展，使所有视图都可以方便地启用侧滑返回
extension View {
    func enableSwipeBack() -> some View {
        self.background(CustomNavigationConfigurator())
    }
}

struct ContentView: View {
    @StateObject private var deviceManager = DeviceManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 248/255, green: 248/255, blue: 248/255)
                    .ignoresSafeArea()
                
                Group {
                    if deviceManager.connectedDevices.isEmpty {
                        // 空状态视图
                        EmptyDeviceView()
                    } else {
                        // 设备列表
                        DeviceListView()
                    }
                }
            }
            .toolbar {
                if !deviceManager.connectedDevices.isEmpty {
                    ToolbarItem(placement: .principal) {
                        Text("设备列表")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            DeviceScanView()
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(CustomNavigationConfigurator())
        }
    }
}

// 已连接设备行视图
struct ConnectedDeviceRow: View {
    let device: PrinterDevice
    @ObservedObject private var webSocketManager = WebSocketManager.shared
    @ObservedObject private var deviceManager = DeviceManager.shared
    @State private var showingToast = false
    @State private var shouldNavigate = false
    
    // 判断设备是否在连接中
    private var isConnecting: Bool {
        deviceManager.connectingDevices.contains(device.id)
    }
    
    // 判断设备是否离线
    private var isOffline: Bool {
        !deviceManager.isDeviceConnected(device.id)
    }
    
    var connectionStatusText: String {
        if isConnecting {
            return "连接中..."
        } else if isOffline {
            return "离线"
        } else if let status = deviceManager.deviceStatuses[device.id],
                  status.currentStatus == .printing {
            return "打印中"
        }
        return "已连接"
    }
    
    var statusColor: Color {
        if isConnecting {
            return .blue
        } else if isOffline {
            return .gray
        } else if let status = deviceManager.deviceStatuses[device.id],
                  status.currentStatus == .printing {
            return .blue
        }
        return Color(red: 0.19, green: 0.80, blue: 0.62)
    }
    
    var body: some View {
        Button(action: handleDeviceClick) {
            HStack(alignment: .bottom, spacing: 30) {
                VStack(alignment: .leading, spacing: 49) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(device.brandName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(device.machineName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, minHeight: 47, maxHeight: 47)
                    
                    HStack(spacing: 5) {
                        HStack(spacing: 5) {
                            Text(connectionStatusText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(statusColor)
                        }
                        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                        .background(statusColor.opacity(0.10))
                        .cornerRadius(5)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 设备图片
                Image("printer_thumbnail")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .background(Color.white)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(.white)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .opacity(isOffline ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isConnecting)
        .navigationDestination(isPresented: $shouldNavigate) {
            DeviceDetailView(device: device)
                .onDisappear {
                    // 当详情页面消失时，确保 Toast 也被隐藏
                    showingToast = false
                }
        }
        .toast(isPresented: $showingToast, message: "正在连接设备...")
    }
    
    private func handleDeviceClick() {
        if isOffline {
            showingToast = true
            reconnectDevice()
        } else {
            shouldNavigate = true
        }
    }
    
    private func reconnectDevice() {
        deviceManager.reconnectDevice(device) { success in
            if success {
                // 在导航之前确保 Toast 消失
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showingToast = false
                    shouldNavigate = true
                }
            } else {
                // 连接失败时也要隐藏 Toast
                showingToast = false
            }
        }
    }
}

// 将空状态视图抽取为单独的组件
private struct EmptyDeviceView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 80)
            
            Image("empty_printer")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 250)
            
            VStack(spacing: 10) {
                Text("添加一台设备")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Text("开启你的3D打印之旅")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.top, 50)
            
            Spacer()
            
            NavigationLink {
                DeviceScanView()
            } label: {
                HStack(alignment: .center, spacing: 5) {
                    Image(systemName: "plus")
                        .frame(width: 18, height: 18)
                    Text("搜索设备")
                        .font(.system(size: 17, weight: .bold))
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
                .frame(maxWidth: min(UIScreen.main.bounds.width - 40, 400), alignment: .center)
                .background(.black)
                .foregroundColor(.white)
                .cornerRadius(100)
            }
        }
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
    }
}

// 将设备列表视图抽取为单独的组件
private struct DeviceListView: View {
    @ObservedObject private var deviceManager = DeviceManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(deviceManager.connectedDevices) { device in
                    ConnectedDeviceRow(device: device)
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 15)
        }
    }
}

#Preview {
    ContentView()
}
