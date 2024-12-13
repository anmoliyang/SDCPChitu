import Foundation
import Combine

/// WebSocket连接管理器
class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    /// 单例
    static let shared = WebSocketManager()
    
    /// 当前状态
    @Published private(set) var currentStatus: PrintStatus?
    /// 连接状态
    @Published private(set) var isConnected = false
    /// 错误信息
    @Published private(set) var lastError: String?
    /// 视频流URL
    @Published private(set) var videoStreamUrl: String?
    
    /// WebSocket会话
    private var webSocket: URLSessionWebSocketTask?
    /// 错误信息发布者
    private let errorSubject = PassthroughSubject<String, Never>()
    
    /// 状态发布者
    var statusPublisher: AnyPublisher<PrintStatus, Never> {
        $currentStatus.compactMap { $0 }.eraseToAnyPublisher()
    }
    
    /// 错误发布者
    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    private var heartbeatTimer: Timer?
    private let heartbeatInterval: TimeInterval = 30  // 30秒发送一次心跳
    private var deviceId: String?  // 添加设备ID属性
    
    #if DEBUG
    // 调试模式下的定时器
    private var debugTimer: Timer?
    #endif
    
    private var device: PrinterDevice?  // 添加设备引用
    
    private override init() {
        super.init()
        print("Debug: WebSocketManager initialized")
    }
    
    /// 连接到打印机
    func connect(to device: PrinterDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        self.device = device
        print("Debug: Connecting to device \(device.id)")
        
        disconnect()
        deviceId = device.id
        
        #if DEBUG
        DispatchQueue.main.async { [weak self] in
            print("Debug: Debug mode connection")
            self?.isConnected = true
            self?.startDebugStatusUpdates()
            completion(.success(()))
        }
        #else
        guard let url = URL(string: "ws://\(device.ipAddress):3030/websocket") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        receiveMessage()
        startHeartbeat()
        
        DispatchQueue.main.async {
            self.isConnected = true
            completion(.success(()))
        }
        #endif
    }
    
    /// 断开连接
    func disconnect() {
        print("Debug: Disconnecting")
        #if DEBUG
        debugTimer?.invalidate()
        debugTimer = nil
        #else
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        #endif
        
        deviceId = nil
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.currentStatus = nil
            self?.videoStreamUrl = nil
        }
    }
    
    /// 发送命令
    func sendCommand(_ command: String) {
        print("Debug: WebSocketManager - Sending command: \(command)")
        print("Debug: WebSocketManager - Connection status: \(isConnected)")
        
        #if DEBUG
        handleDebugCommand(command)
        #else
        guard let data = command.data(using: .utf8) else {
            print("Error: WebSocketManager - Invalid command format")
            errorSubject.send("无效的命令格式")
            return
        }
        
        webSocket?.send(.data(data)) { [weak self] error in
            if let error = error {
                print("Error: WebSocketManager - Failed to send command: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.errorSubject.send("发送命令失败: \(error.localizedDescription)")
                }
            } else {
                print("Debug: WebSocketManager - Command sent successfully")
            }
        }
        #endif
    }
    
    #if DEBUG
    private func startDebugStatusUpdates() {
        print("Debug: Starting debug status updates")
        
        let initialStatus = PrintStatus(
            currentStatus: .idle,
            previousStatus: .idle,
            printScreenTime: 8000,
            releaseFilmCount: 0,
            uvledTemperature: 25.0,
            timeLapseEnabled: true,
            boxTemperature: 25.0,
            boxTargetTemperature: 28.0,
            printInfo: PrintInfo(
                status: .idle,
                currentLayer: 0,
                totalLayer: 100,
                currentTicks: 0,
                totalTicks: 7200000,
                filename: "debug_print.ctb",
                errorNumber: 0,
                taskId: device?.id ?? "DEBUG_TASK_001",
                remainingTicks: 7200000,
                printSpeed: 1.0,
                zHeight: 0.0
            )
        )
        
        DispatchQueue.main.async { [weak self] in
            print("Debug: Setting initial status")
            self?.currentStatus = initialStatus
        }
        
        // 启动定时器进行状态更新
        debugTimer?.invalidate()
        debugTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updatePrintingStatus()
        }
        RunLoop.main.add(debugTimer!, forMode: .common)
    }
    
    private func updatePrintingStatus() {
        guard let status = currentStatus else { return }
        
        if status.currentStatus == .printing,
           let info = status.printInfo {
            var newSubStatus: PrintStatus.PrintSubStatus
            var newCurrentLayer = info.currentLayer
            var newCurrentTicks = info.currentTicks
            
            // 根据当前子状态决定下一个状态
            switch info.status {
            case .exposuring:
                // 曝光完成后进入抬升状态
                newSubStatus = .lifting
                newCurrentTicks += 2000
                
            case .lifting:
                // 抬升完成后进入下降状态
                newSubStatus = .dropping
                newCurrentTicks += 1000
                
            case .dropping:
                // 下降完成后进入曝光状态，并增加层数
                newSubStatus = .exposuring
                newCurrentLayer += 1
                newCurrentTicks += 1000
                
            default:
                // 其他状态（如暂停、停止等）保持不变
                return
            }
            
            // 检查是否完成所有层数
            if newCurrentLayer >= info.totalLayer {
                updateDebugStatus(currentStatus: .idle, printSubStatus: .complete)
                return
            }
            
            // 更新打印状态
            let newPrintInfo = PrintInfo(
                status: newSubStatus,
                currentLayer: newCurrentLayer,
                totalLayer: info.totalLayer,
                currentTicks: newCurrentTicks,
                totalTicks: info.totalTicks,
                filename: info.filename,
                errorNumber: 0,
                taskId: info.taskId,
                remainingTicks: max(0, info.totalTicks - newCurrentTicks),
                printSpeed: info.printSpeed,
                zHeight: Double(newCurrentLayer) * 0.05 // 每层0.05mm
            )
            
            let newStatus = PrintStatus(
                currentStatus: .printing,
                previousStatus: status.currentStatus,
                printScreenTime: status.printScreenTime + 2,
                releaseFilmCount: status.releaseFilmCount + (newSubStatus == .lifting ? 1 : 0),
                uvledTemperature: Double.random(in: 24.5...25.5),
                timeLapseEnabled: status.timeLapseEnabled,
                boxTemperature: Double.random(in: 24.0...26.0),
                boxTargetTemperature: status.boxTargetTemperature,
                printInfo: newPrintInfo
            )
            
            DispatchQueue.main.async {
                print("Debug: Updating printing status - Layer: \(newCurrentLayer)/\(info.totalLayer), Status: \(newSubStatus)")
                self.currentStatus = newStatus
            }
        }
    }
    
    private func handleDebugCommand(_ command: String) {
        print("Debug: WebSocketManager - Handling command: \(command)")
        
        // 解析命令
        if let data = command.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let commandData = json["Data"] as? [String: Any],
           let cmd = commandData["Cmd"] as? Int {
            
            switch cmd {
            case 386: // 视频流控制命令
                if let data = commandData["Data"] as? [String: Any],
                   let enable = data["Enable"] as? Int {
                    if enable == 1 {
                        // 模拟返回RTSP地址
                        DispatchQueue.main.async {
                            self.videoStreamUrl = "rtsp://\(self.device?.ipAddress ?? "localhost"):8554/video"
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.videoStreamUrl = nil
                        }
                    }
                }
                
            case 0x81: // 开始打印
                updateDebugStatus(currentStatus: .printing, printSubStatus: .exposuring)
                
            case 0x82: // 暂停打印
                updateDebugStatus(currentStatus: .printing, printSubStatus: .paused)
                
            case 0x83: // 继续打印
                updateDebugStatus(currentStatus: .printing, printSubStatus: .exposuring)
                
            case 0x84: // 停止打印
                updateDebugStatus(currentStatus: .idle, printSubStatus: .stopped)
                
            case 0x85: // 回零操作
                updateDebugStatus(currentStatus: .idle, printSubStatus: .homing)
                
            case 0x86: // 曝光测试
                updateDebugStatus(currentStatus: .exposureTesting, printSubStatus: .exposuring)
                
            case 0x87: // 设备自检
                updateDebugStatus(currentStatus: .devicesTesting, printSubStatus: .idle)
                
            default:
                break
            }
        } else {
            // 处理字符串命令（用于兼容性）
            switch command {
            case "StartPrint":
                updateDebugStatus(currentStatus: .printing, printSubStatus: .exposuring)
            case "pause":
                updateDebugStatus(currentStatus: .printing, printSubStatus: .paused)
            case "resume":
                updateDebugStatus(currentStatus: .printing, printSubStatus: .exposuring)
            case "stop":
                updateDebugStatus(currentStatus: .idle, printSubStatus: .stopped)
            case "home":
                updateDebugStatus(currentStatus: .idle, printSubStatus: .homing)
            case "exposureTest":
                updateDebugStatus(currentStatus: .exposureTesting, printSubStatus: .exposuring)
            case "deviceTest":
                updateDebugStatus(currentStatus: .devicesTesting, printSubStatus: .idle)
            default:
                break
            }
        }
    }
    
    private func updateDebugStatus(currentStatus: PrintStatus.MachineStatus, printSubStatus: PrintStatus.PrintSubStatus) {
        print("Debug: WebSocketManager - Updating status to \(currentStatus) with sub-status \(printSubStatus)")
        
        let printInfo = PrintInfo(
            status: printSubStatus,
            currentLayer: self.currentStatus?.printInfo?.currentLayer ?? 0,
            totalLayer: self.currentStatus?.printInfo?.totalLayer ?? 100,
            currentTicks: self.currentStatus?.printInfo?.currentTicks ?? 0,
            totalTicks: self.currentStatus?.printInfo?.totalTicks ?? 7200000,
            filename: self.currentStatus?.printInfo?.filename ?? "debug_print.ctb",
            errorNumber: 0,
            taskId: device?.id ?? "DEBUG_TASK_001",
            remainingTicks: self.currentStatus?.printInfo?.remainingTicks ?? 7200000,
            printSpeed: self.currentStatus?.printInfo?.printSpeed ?? 1.0,
            zHeight: self.currentStatus?.printInfo?.zHeight ?? 0.0
        )
        
        let newStatus = PrintStatus(
            currentStatus: currentStatus,
            previousStatus: self.currentStatus?.currentStatus ?? .idle,
            printScreenTime: self.currentStatus?.printScreenTime ?? 8000,
            releaseFilmCount: self.currentStatus?.releaseFilmCount ?? 0,
            uvledTemperature: Double.random(in: 24.5...25.5),
            timeLapseEnabled: self.currentStatus?.timeLapseEnabled ?? true,
            boxTemperature: Double.random(in: 24.0...26.0),
            boxTargetTemperature: self.currentStatus?.boxTargetTemperature ?? 28.0,
            printInfo: printInfo
        )
        
        DispatchQueue.main.async {
            print("Debug: WebSocketManager - Status updated")
            self.currentStatus = newStatus
        }
    }
    #endif
    
    #if !DEBUG
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        DispatchQueue.main.async {
                            self?.handleMessage(json)
                        }
                    }
                case .data(let data):
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        DispatchQueue.main.async {
                            self?.handleMessage(json)
                        }
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage()
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.errorSubject.send("接收消息失败: \(error.localizedDescription)")
                    self?.disconnect()
                }
            }
        }
    }
    
    private func handleMessage(_ json: [String: Any]) {
        // 解析消息类型
        if let topic = json["Topic"] as? String {
            if topic.contains("sdcp/response/") {
                // 处理响应消息
                if let data = json["Data"] as? [String: Any],
                   let cmd = data["Cmd"] as? Int {
                    switch cmd {
                    case 386: // 视频流控制响应
                        if let responseData = data["Data"] as? [String: Any],
                           let ack = responseData["Ack"] as? Int,
                           let videoUrl = responseData["VideoUrl"] as? String {
                            if ack == 0 {
                                DispatchQueue.main.async {
                                    self.videoStreamUrl = videoUrl
                                }
                            } else {
                                let errorMessage: String
                                switch ack {
                                case 1: errorMessage = "超过最大同时拉流限制"
                                case 2: errorMessage = "摄像头不存在"
                                default: errorMessage = "未知错误"
                                }
                                errorSubject.send("视频流错误: \(errorMessage)")
                            }
                        }
                    default:
                        break
                    }
                }
            } else if topic.contains("sdcp/status/") {
                // 处理状态消息
                if let data = try? JSONSerialization.data(withJSONObject: json),
                   let status = try? JSONDecoder().decode(PrintStatus.self, from: data) {
                    DispatchQueue.main.async {
                        self.currentStatus = status
                    }
                }
            }
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        guard let deviceId = deviceId else { return }
        
        let message: [String: Any] = [
            "Topic": "sdcp/heartbeat/\(deviceId)",
            "Data": [
                "MainboardID": deviceId,
                "TimeStamp": Int(Date().timeIntervalSince1970),
                "From": 3
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            sendCommand(jsonString)
        }
    }
    #endif
}

