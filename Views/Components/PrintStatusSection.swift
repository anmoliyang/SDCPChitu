import SwiftUI

struct PrintStatusSection: View {
    let status: PrintStatus
    let info: PrintInfo
    
    var body: some View {
        Section {
            VStack(spacing: 15) {
                // 标题状态模块
                HStack(alignment: .center, spacing: 15) {
                    // 左侧缩略图
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "cube.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                    
                    // 右侧标题和状态
                    VStack(alignment: .leading, spacing: 8) {
                        Text(info.filename)
                            .font(.system(size: 18, weight: .semibold))
                            .lineLimit(1)
                        
                        // 根据打印状态显示不同的文本和颜色
                        switch info.status {
                        case .exposuring, .dropping, .lifting, .homing:
                            Text("打印中")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                        case .paused, .pausing:
                            Text("已暂停")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                        case .stopping:
                            Text("停止中")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                        case .stopped:
                            Text("已停止")
                                .foregroundColor(.red)
                                .font(.system(size: 14))
                        case .complete:
                            Text("已完成")
                                .foregroundColor(.green)
                                .font(.system(size: 14))
                        case .fileChecking:
                            Text("文件检查中")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                        case .idle:
                            Text("准备中")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Spacer()
                }
                
                // 打印信息模块
                VStack(spacing: 12) {
                    // 进度信息
                    HStack {
                        // 左侧层数进度
                        HStack(spacing: 4) {
                            Text("层数进度：")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            Text("\(info.currentLayer) / \(info.totalLayer)")
                                .font(.system(size: 14))
                        }
                        
                        Spacer()
                        
                        // 右侧百分比
                        Text("\(Int((Double(info.currentLayer) / Double(info.totalLayer)) * 100))%")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 4)
                            
                            Rectangle()
                                .fill(Color.mint)
                                .frame(width: geometry.size.width * CGFloat(info.currentLayer) / CGFloat(info.totalLayer), height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    // 时间信息
                    HStack(spacing: 20) {
                        // 已用时间
                        HStack(spacing: 4) {
                            Text("已用时间:")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            Text(formatTime(info.currentTicks))
                                .font(.system(size: 14))
                        }
                        
                        Spacer(minLength: 10)
                        
                        // 剩余时间
                        HStack(spacing: 4) {
                            Text("剩余时间:")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            Text(formatTime(info.remainingTicks))
                                .font(.system(size: 14))
                        }
                    }
                }
            }
            .padding(15)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .listRowInsets(EdgeInsets())
        .padding(.horizontal, 15)
    }
    
    // MARK: - 辅助函数
    private func formatTime(_ milliseconds: Int) -> String {
        let seconds = milliseconds / 1000
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }
}

#Preview {
    List {
        PrintStatusSection(
            status: PrintStatus(
                currentStatus: .printing,
                previousStatus: .idle,
                printScreenTime: 0,
                releaseFilmCount: 0,
                uvledTemperature: 25.0,
                timeLapseEnabled: false,
                boxTemperature: 25.0,
                boxTargetTemperature: 25.0,
                printInfo: PrintInfo(
                    status: .exposuring,
                    currentLayer: 81,
                    totalLayer: 100,
                    currentTicks: 1000,
                    totalTicks: 7200000,
                    filename: "CBD+Evolution+Model",
                    errorNumber: 0,
                    taskId: "TEST001",
                    remainingTicks: 7200000,
                    printSpeed: 1.0,
                    zHeight: 0.05
                ),
                devicesStatus: nil
            ),
            info: PrintInfo(
                status: .exposuring,
                currentLayer: 81,
                totalLayer: 100,
                currentTicks: 1000,
                totalTicks: 7200000,
                filename: "CBD+Evolution+Model",
                errorNumber: 0,
                taskId: "TEST001",
                remainingTicks: 7200000,
                printSpeed: 1.0,
                zHeight: 0.05
            )
        )
    }
    .listStyle(InsetGroupedListStyle())
} 