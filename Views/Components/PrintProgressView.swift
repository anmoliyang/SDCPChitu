import SwiftUI

/// 打印进度视图组件
struct PrintProgressView: View {
    let printInfo: PrintInfo
    
    var body: some View {
        VStack(spacing: 12) {
            // 文件名和状态
            HStack {
                Text(printInfo.filename)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(printInfo.status.description)
                    .foregroundColor(getStatusColor(printInfo.status))
            }
            
            // 进度条
            ProgressView(value: Double(printInfo.currentLayer), total: Double(printInfo.totalLayer)) {
                HStack {
                    Text("层数: \(printInfo.currentLayer)/\(printInfo.totalLayer)")
                    Spacer()
                    Text("\(Int((Double(printInfo.currentLayer) / Double(printInfo.totalLayer)) * 100))%")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // 时间信息
            HStack {
                VStack(alignment: .leading) {
                    Label {
                        Text("已打印: \(formatTime(printInfo.currentTicks))")
                    } icon: {
                        Image(systemName: "clock")
                    }
                    
                    Label {
                        Text("剩余: \(formatTime(printInfo.remainingTicks))")
                    } icon: {
                        Image(systemName: "timer")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
                
                // 打印速度和Z轴高度
                VStack(alignment: .trailing) {
                    Label {
                        Text(String(format: "%.1f%%", printInfo.printSpeed * 100))
                    } icon: {
                        Image(systemName: "speedometer")
                    }
                    
                    Label {
                        Text(String(format: "%.2f mm", printInfo.zHeight))
                    } icon: {
                        Image(systemName: "arrow.up.and.down")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // 错误信息显示
            if printInfo.errorNumber != 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("错误代码: \(printInfo.errorNumber)")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
    
    // 格式化时间（毫秒转为可读格式）
    private func formatTime(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }
    
    private func getStatusColor(_ status: PrintStatus.PrintSubStatus) -> Color {
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
}

#Preview {
    PrintProgressView(printInfo: .init(
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
    ))
    .padding()
} 
