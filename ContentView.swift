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
        NavigationView {
            Group {
                if deviceManager.connectedDevices.isEmpty {
                    // 空状态视图
                    VStack(spacing: 20) {
                        Spacer()
                            .frame(height: 80)
                        
                        Image("empty_printer")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250, height: 250)
                        
                        VStack(spacing: 10) {
                            Text("添加一台设备")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                            
                            Text("开启你的3D打印之旅")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .padding(.top, 50)
                        
                        Spacer()
                        
                        // 搜索设备按钮 - 改为导航链接
                        NavigationLink {
                            DeviceScanView()
                        } label: {
                            HStack(alignment: .center, spacing: 5) {
                                Image(systemName: "plus")
                                    .frame(width: 18, height: 18)
                                Text("搜索设备")
                                    .font(.headline)
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
                } else {
                    // 设备列表
                    List {
                        ForEach(deviceManager.connectedDevices) { device in
                            NavigationLink {
                                DeviceDetailView(device: device)
                            } label: {
                                DeviceListItem(device: device)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .toolbar {
                if !deviceManager.connectedDevices.isEmpty {
                    NavigationLink {
                        DeviceScanView()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct DeviceListItem: View {
    let device: PrinterDevice
    @StateObject private var deviceManager = DeviceManager.shared
    
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
            if deviceManager.connectedDevices.contains(device) {
                Image(systemName: "link.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    ContentView()
}
