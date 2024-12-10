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
    
    private var availableDevices: [PrinterDevice] {
        discoveryManager.discoveredDevices.filter { device in
            !deviceManager.connectedDevices.contains(device)
        }
    }
    
    var body: some View {
        List {
            if isScanning {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("正在扫描设备...")
                        .foregroundColor(.secondary)
                }
            } else if availableDevices.isEmpty {
                ContentUnavailableView {
                    Label("未发现可用设备", systemImage: "printer.fill")
                } description: {
                    Text("请确保设备已开机并在同一网络中")
                } actions: {
                    Button(action: startScanning) {
                        Label("重新扫描", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ForEach(availableDevices) { device in
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
                .disabled(isScanning || connectingDevice != nil)
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