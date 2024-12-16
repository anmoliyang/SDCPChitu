import SwiftUI

/// 打印进度视图组件
struct PrintProgressView: View {
    let printInfo: PrintInfo
    
    private var progress: Double {
        Double(printInfo.currentLayer) / Double(printInfo.totalLayer)
    }
    
    private var timeRemaining: String {
        let remainingTicks = printInfo.totalTicks - printInfo.currentTicks
        let seconds = remainingTicks / 1000
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return String(format: "%d小时%d分钟", hours, minutes)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 层数进度
            HStack {
                Text("层数进度")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(printInfo.currentLayer)/\(printInfo.totalLayer)")
            }
            
            // 进度条
            ProgressView(value: progress) {
                HStack {
                    Text("\(Int(progress * 100))%")
                    Spacer()
                    Text("剩余时间: \(timeRemaining)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .background(Color(red: 248/255, green: 248/255, blue: 248/255))
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
