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
        }
    }
}

// 已连接设备行视图
struct ConnectedDeviceRow: View {
    let device: PrinterDevice
    
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 连接状态指示器
            Image(systemName: "link")
                .foregroundColor(.green)
                .padding(.trailing, 20)
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
                    NavigationLink {
                        DeviceDetailView(device: device)
                    } label: {
                        ConnectedDeviceRow(device: device)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    ContentView()
}
