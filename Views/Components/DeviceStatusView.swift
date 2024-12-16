import SwiftUI

/// 打印机状态视图组件
struct DeviceStatusView: View {
    let status: PrintStatus
    let printInfo: PrintInfo
    
    // MARK: - 子视图
    /// 设备信息行组件
    private struct StatusInfoRow: View {
        let title: String
        let value: String
        
        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 主状态显示
            HStack {
                Label(status.currentStatus.description, 
                      systemImage: getStatusIcon(status.currentStatus))
                    .foregroundColor(getStatusColor(status.currentStatus))
                Spacer()
                Text(printInfo.status.description)
                    .foregroundColor(getSubStatusColor(printInfo.status))
            }
            .font(.headline)
            
            // 详细状态信息
            VStack(spacing: 8) {
                if status.isPrinting {
                    StatusInfoRow(title: "打印文件", value: printInfo.filename)
                    StatusInfoRow(title: "当前层数", 
                                value: "\(printInfo.currentLayer)/\(printInfo.totalLayer)")
                    StatusInfoRow(title: "打印进度", 
                                value: "\(Int((Double(printInfo.currentLayer) / Double(printInfo.totalLayer)) * 100))%")
                }
                
                if status.isExposureTesting {
                    StatusInfoRow(title: "曝光时间", 
                                value: "\(status.printScreenTime)s")
                }
                
                if status.isDevicesTesting {
                    StatusInfoRow(title: "自检状态", 
                                value: getDeviceTestStatus(status))
                }
            }
        }
    }
    
    private func getStatusIcon(_ status: PrintStatus.MachineStatus) -> String {
        switch status {
        case .idle: return "printer"
        case .printing: return "printer.fill"
        case .fileTransferring: return "arrow.down.doc.fill"
        case .exposureTesting: return "rays"
        case .devicesTesting: return "gearshape.2"
        case .paused: return "pause.circle.fill"
        case .stopped: return "stop.circle.fill"
        }
    }
    
    private func getStatusColor(_ status: PrintStatus.MachineStatus) -> Color {
        switch status {
        case .idle: return .secondary
        case .printing: return .green
        case .fileTransferring: return .blue
        case .exposureTesting: return .orange
        case .devicesTesting: return .purple
        case .paused: return .yellow
        case .stopped: return .red
        }
    }
    
    private func getSubStatusColor(_ status: PrintStatus.PrintSubStatus) -> Color {
        switch status {
        case .idle: return .secondary
        case .homing: return .blue
        case .dropping, .lifting: return .orange
        case .exposuring: return .green
        case .pausing, .paused: return .yellow
        case .stopping, .stopped: return .red
        case .complete: return .green
        case .fileChecking: return .blue
        }
    }
    
    private func getDeviceTestStatus(_ status: PrintStatus) -> String {
        // 根据设备测试状态返回对应的文本
        if let devices = status.devicesStatus {
            var statusTexts = [String]()
            
            if devices.tempSensorStatusOfUVLED == 0 {
                statusTexts.append("UVLED温度传感器未接入")
            } else if devices.tempSensorStatusOfUVLED == 2 {
                statusTexts.append("UVLED温度传感器异常")
            }
            
            if devices.lcdStatus == 0 {
                statusTexts.append("曝光屏未连接")
            }
            
            if devices.sgStatus == 0 {
                statusTexts.append("应变片未接入")
            } else if devices.sgStatus == 2 {
                statusTexts.append("应变片校准失败")
            }
            
            if devices.zMotorStatus == 0 {
                statusTexts.append("Z轴电机未连接")
            }
            
            if devices.rotateMotorStatus == 0 {
                statusTexts.append("旋转轴电机未连接")
            }
            
            if devices.releaseFilmState == 0 {
                statusTexts.append("离型膜异常")
            }
            
            if devices.xMotorStatus == 0 {
                statusTexts.append("X轴电机未连接")
            }
            
            if statusTexts.isEmpty {
                return "设备自检正常"
            } else {
                return statusTexts.joined(separator: "\n")
            }
        }
        
        return "正在检测"
    }
}

#Preview {
    // 创建预览用的 PrintInfo
    let printInfoJson: [String: Any] = [
        "Status": 3,  // SDCP_PRINT_STATUS_EXPOSURING
        "CurrentLayer": 50,
        "TotalLayer": 100,
        "CurrentTicks": 3600000,
        "TotalTicks": 7200000,
        "Filename": "test.ctb",
        "ErrorNumber": 0,
        "TaskId": "TEST001"
    ]
    
    // 创建预览用的 PrintStatus
    let statusJson: [String: Any] = [
        "CurrentStatus": [1],  // [SDCP_MACHINE_STATUS_PRINTING]
        "PreviousStatus": 0,   // SDCP_MACHINE_STATUS_IDLE
        "PrintScreen": 8000,
        "ReleaseFilm": 0,
        "TempOfUVLED": 25.0,
        "TimeLapseStatus": 1,
        "TempOfBox": 25.0,
        "TempTargetBox": 28.0,
        "PrintInfo": [
            "Status": 3,
            "CurrentLayer": 50,
            "TotalLayer": 100,
            "CurrentTicks": 3600000,
            "TotalTicks": 7200000,
            "Filename": "test.ctb",
            "ErrorNumber": 0,
            "TaskId": "TEST001"
        ]
    ]
    
    // 使用 try? 处理可能的解码错误
    let previewPrintInfo = try? JSONDecoder().decode(PrintInfo.self, 
        from: JSONSerialization.data(withJSONObject: printInfoJson))
    let previewStatus = try? JSONDecoder().decode(PrintStatus.self, 
        from: JSONSerialization.data(withJSONObject: statusJson))
    
    return List {
        if let status = previewStatus, let printInfo = previewPrintInfo {
            DeviceStatusView(status: status, printInfo: printInfo)
        }
    }
} 
