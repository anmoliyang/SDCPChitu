import SwiftUI

/// 打印进度视图组件
struct PrintProgressView: View {
    let printInfo: PrintInfo
    
    private var progress: Double {
        Double(printInfo.currentLayer) / Double(printInfo.totalLayer)
    }
    
    private var timeRemaining: String {
        let seconds = printInfo.remainingTicks / 1000
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
    let previewPrintInfo = PrintInfo(
        status: .exposuring,
        currentLayer: 50,
        totalLayer: 100,
        currentTicks: 3600000,
        totalTicks: 7200000,
        filename: "test.ctb",
        errorNumber: 0,
        taskId: "TEST001",
        remainingTicks: 3600000,
        printSpeed: 1.0,
        zHeight: 50.0
    )
    
    return List {
        PrintProgressView(printInfo: previewPrintInfo)
    }
} 
