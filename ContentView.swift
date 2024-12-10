//
//  ContentView.swift
//  SDCPChitu
//
//  Created by 杨俊文 on 2024/12/9.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var deviceManager = DeviceManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                if deviceManager.connectedDevices.isEmpty {
                    ContentUnavailableView {
                        Label("未连接设备", systemImage: "printer.fill")
                    } description: {
                        Text("点击右上角扫描按钮添加设备")
                    }
                } else {
                    ForEach(deviceManager.connectedDevices) { device in
                        NavigationLink {
                            DeviceDetailView(device: device)
                        } label: {
                            DeviceListItem(device: device)
                        }
                    }
                }
            }
            .navigationTitle("我的设备")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        DeviceScanView()
                    } label: {
                        Label("扫描", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                deviceManager.loadDevices()
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct DeviceListItem: View {
    let device: PrinterDevice
    @ObservedObject private var deviceManager = DeviceManager.shared
    
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
            
            // 连接状态指示器
            if deviceManager.isDeviceConnected(device) {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

struct StatusIndicator: View {
    let status: DeviceStatus
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
    }
    
    private var statusColor: Color {
        if status.uvledTempSensorStatus == 1 &&
           status.lcdStatus == 1 &&
           status.zMotorStatus == 1 {
            return .green
        } else if status.uvledTempSensorStatus == 2 ||
                  status.lcdStatus == 2 ||
                  status.zMotorStatus == 2 {
            return .red
        } else {
            return .yellow
        }
    }
}

#Preview {
    ContentView()
}
