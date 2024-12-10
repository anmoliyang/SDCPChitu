import SwiftUI

struct DeviceScanView: View {
    @StateObject private var discoveryManager = UDPDiscoveryManager.shared
    @StateObject private var deviceManager = DeviceManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var connectingDevice: PrinterDevice?
    
    var body: some View {
        List {
            if discoveryManager.isScanning {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在扫描设备...")
                        .foregroundColor(.secondary)
                }
            } else if discoveryManager.discoveredDevices.isEmpty {
                ContentUnavailableView {
                    Label("未发现设备", systemImage: "printer.fill")
                } description: {
                    Text("请确保设备已开机并在同一网络中")
                } actions: {
                    Button(action: startScanning) {
                        Label("重新扫描", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ForEach(discoveryManager.discoveredDevices) { device in
                    DeviceListItemWithConnection(
                        device: device,
                        isConnecting: connectingDevice == device,
                        onTap: { connectDevice(device) }
                    )
                    .disabled(connectingDevice != nil)
                }
            }
        }
        .navigationTitle("扫描设备")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: startScanning) {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .disabled(discoveryManager.isScanning || connectingDevice != nil)
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
    }
    
    private func startScanning() {
        discoveryManager.startDiscovery(excludingDevices: deviceManager.connectedDevices)
    }
    
    private func connectDevice(_ device: PrinterDevice) {
        connectingDevice = device
        
        // 模拟连接延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            deviceManager.connectDevice(device)
            connectingDevice = nil
            dismiss()
        }
    }
}

struct DeviceListItemWithConnection: View {
    let device: PrinterDevice
    let isConnecting: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                Text(device.ipAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isConnecting {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("连接中")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .opacity(isConnecting ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isConnecting)
    }
} 