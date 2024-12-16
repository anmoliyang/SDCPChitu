import SwiftUI

struct PrintStatusSection: View {
    let status: PrintStatus
    let info: PrintInfo
    @State private var showingCloseAlert = false
    let onClose: () -> Void
    
    var body: some View {
        Section {
            VStack(spacing: 15) {
                // 标题状态模块
                HStack(alignment: .top, spacing: 15) {
                    // 左侧缩略图
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 70, height: 70)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "cube.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                    
                    // 右侧标题和状态
                    VStack(alignment: .leading, spacing: 0) {
                        // 标题行
                        HStack(spacing: 0) {
                            Text(info.filename)
                                .font(.system(size: 18, weight: .semibold))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // 完成状态或停止状态时显示关闭按钮
                            if info.status == .complete || info.status == .stopped {
                                Button(action: {
                                    showingCloseAlert = true
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.black)
                                        .font(.system(size: 16))
                                        .frame(width: 32, height: 32)
                                        .background(Color(red: 248/255, green: 248/255, blue: 248/255))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .frame(height: 32)
                        .frame(maxWidth: .infinity)
                        
                        Spacer()
                        
                        // 状态显示部分
                        let statusView = switch info.status {
                        case .exposuring, .lifting, .dropping, .homing:
                            HStack(spacing: 5) {
                                Text("打印中")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                            .background(Color.blue.opacity(0.10))
                            .cornerRadius(5)
                        case .pausing, .paused:  // 合并暂停相关状态
                            HStack(spacing: 5) {
                                Text("已暂停")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                            .background(Color.orange.opacity(0.10))
                            .cornerRadius(5)
                        case .stopping, .stopped:  // 合并停止相关状态
                            HStack(spacing: 5) {
                                Text("已停止")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.red)
                            }
                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                            .background(Color.red.opacity(0.10))
                            .cornerRadius(5)
                        case .complete:  // 保持完成状态
                            HStack(spacing: 5) {
                                Text("已完成")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                            .background(Color.green.opacity(0.10))
                            .cornerRadius(5)
                        default:  // 其他状态（包括 idle, fileChecking 等）显示为准备中
                            HStack(spacing: 5) {
                                Text("准备中")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                            .background(Color.gray.opacity(0.10))
                            .cornerRadius(5)
                        }
                        
                        // 显示状态视图
                        statusView
                            .padding(.bottom, 0)
                            .onChange(of: info.status) { oldValue, newValue in
                                print("Debug: Print status changed from \(oldValue) to \(newValue)")
                            }
                    }
                    .frame(height: 70)
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
            .listRowInsets(EdgeInsets())
            .padding(.horizontal, 15)
            .alert("确认关闭", isPresented: $showingCloseAlert) {
                Button("取消", role: .cancel) { }
                Button("确认", role: .destructive) {
                    onClose()
                }
            } message: {
                Text("是否确认关闭当前打印任务？")
            }
        }
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
                    status: .complete,
                    currentLayer: 10,
                    totalLayer: 10,
                    currentTicks: 7200000,
                    totalTicks: 7200000,
                    filename: "CBD+Evolution+Model",
                    errorNumber: 0,
                    taskId: "TEST001",
                    remainingTicks: 0,
                    printSpeed: 1.0,
                    zHeight: 0.05
                ),
                devicesStatus: nil
            ),
            info: PrintInfo(
                status: .complete,
                currentLayer: 10,
                totalLayer: 10,
                currentTicks: 7200000,
                totalTicks: 7200000,
                filename: "CBD+Evolution+Model",
                errorNumber: 0,
                taskId: "TEST001",
                remainingTicks: 0,
                printSpeed: 1.0,
                zHeight: 0.05
            ),
            onClose: {}
        )
    }
    .listStyle(InsetGroupedListStyle())
} 