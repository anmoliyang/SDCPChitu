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
    // 调试模式下的模拟定
    private var debugTimer: Timer?
    #endif
    
    private var device: PrinterDevice?  // 添加设备引用
    
    private override init() {
        super.init()
        print("Debug: WebSocketManager initialized")
    }
    
    /// 连接到打印机
    /// - Parameters:
    ///   - device: 打印机设备
    ///   - completion: 连接结果回调
    func connect(to device: PrinterDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        self.device = device  // 保存设备引用
        print("Debug: Connecting to device \(device.id)")
        
        // 如果已经连接，先断开
        disconnect()
        
        // 保存设备ID
        deviceId = device.id
        
        #if DEBUG
        // 调试模式下模拟连接
        DispatchQueue.main.async { [weak self] in
            print("Debug: Debug mode connection")
            self?.isConnected = true
            self?.startDebugStatusUpdates()
            completion(.success(()))
        }
        #else
        // 实际WebSocket连接逻辑保持不变
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
        }
    }
    
    /// 接收消息
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // 在主线程处理消息
                        DispatchQueue.main.async {
                            self?.handleMessage(json)
                        }
                    }
                case .data(let data):
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // 在主线程处理消息
                        DispatchQueue.main.async {
                            self?.handleMessage(json)
                        }
                    }
                @unknown default:
                    break
                }
                
                // 继续接收下一条消息
                self?.receiveMessage()
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.errorSubject.send("接收消息失败: \(error.localizedDescription)")
                    self?.disconnect()
                }
            }
        }
    }
    
    /// 处理接收到的消息
    private func handleMessage(_ json: [String: Any]) {
        // 解析打印机状态
        if let data = try? JSONSerialization.data(withJSONObject: json),
           let status = try? JSONDecoder().decode(PrintStatus.self, from: data) {
            DispatchQueue.main.async {
                self.currentStatus = status
            }
        }
        
        // 继续接收下一条消息
        receiveMessage()
    }
    
    /// 发送命令
    func sendCommand(_ command: String) {
        #if DEBUG
        handleDebugCommand(command)
        #else
        guard let data = command.data(using: .utf8) else {
            errorSubject.send("无效的命令格式")
            return
        }
        
        webSocket?.send(.data(data)) { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.errorSubject.send("发送命令失败: \(error.localizedDescription)")
                }
            }
        }
        #endif
    }
    
    // MARK: - URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket连接成功")
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = true
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket连接关闭: \(closeCode)")
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.currentStatus = nil
            if let reason = reason,
               let message = String(data: reason, encoding: .utf8) {
                self?.errorSubject.send("连接已关闭: \(message)")
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("WebSocket错误: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.errorSubject.send("连接错误: \(error.localizedDescription)")
            }
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        guard let deviceId = deviceId else { return }  // 确保设备ID存在
        
        let message: [String: Any] = [
            "Topic": "sdcp/heartbeat/\(deviceId)",
            "Data": [
                "MainboardID": deviceId,
                "TimeStamp": Int(Date().timeIntervalSince1970),
                "From": 3  // APP端
            ]
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            sendCommand(jsonString)
        }
    }
    
    #if DEBUG
    private func startDebugStatusUpdates() {
        print("Debug: Starting debug status updates")
        
        // 立即生成一个初始状态
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
                taskId: device?.id ?? "DEBUG_TASK_001",  // 使用设备ID
                remainingTicks: 7200000,
                printSpeed: 1.0,
                zHeight: 0.0
            )
        )
        
        // 确保在主线程更新状态
        DispatchQueue.main.async { [weak self] in
            print("Debug: Setting initial status")
            self?.currentStatus = initialStatus
        }
        
        // 启动定时器进行状态更新
        debugTimer?.invalidate() // 确保之前的定时��被清理
        debugTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let currentStatus = self.currentStatus ?? initialStatus
            var newPrintInfo: PrintInfo?
            
            switch currentStatus.currentStatus {
            case .printing:
                // 模拟打印过程中的状态变化
                if let oldPrintInfo = currentStatus.printInfo {
                    let newCurrentLayer = min(oldPrintInfo.currentLayer + 1, oldPrintInfo.totalLayer)
                    let newCurrentTicks = min(oldPrintInfo.currentTicks + 1000, oldPrintInfo.totalTicks)
                    let newRemainingTicks = max(oldPrintInfo.totalTicks - newCurrentTicks, 0)
                    
                    newPrintInfo = PrintInfo(
                        status: .exposuring,
                        currentLayer: newCurrentLayer,
                        totalLayer: oldPrintInfo.totalLayer,
                        currentTicks: newCurrentTicks,
                        totalTicks: oldPrintInfo.totalTicks,
                        filename: oldPrintInfo.filename,
                        errorNumber: 0,
                        taskId: oldPrintInfo.taskId,
                        remainingTicks: newRemainingTicks,
                        printSpeed: 1.0,
                        zHeight: Double(newCurrentLayer) * 0.05 // 每层0.05mm
                    )
                }
                
            case .fileTransferring:
                newPrintInfo = PrintInfo(
                    status: .fileChecking,
                    currentLayer: 0,
                    totalLayer: 100,
                    currentTicks: 0,
                    totalTicks: 7200000,
                    filename: "debug_print.ctb",
                    errorNumber: 0,
                    taskId: "DEBUG_TASK_001",
                    remainingTicks: 7200000,
                    printSpeed: 1.0,
                    zHeight: 0.0
                )
                
            case .exposureTesting:
                newPrintInfo = PrintInfo(
                    status: .exposuring,
                    currentLayer: 1,
                    totalLayer: 1,
                    currentTicks: 5000,
                    totalTicks: 8000,
                    filename: "exposure_test.ctb",
                    errorNumber: 0,
                    taskId: "DEBUG_TEST_001",
                    remainingTicks: 3000,
                    printSpeed: 1.0,
                    zHeight: 0.05
                )
                
            default:
                newPrintInfo = PrintInfo(
                    status: .idle,
                    currentLayer: 0,
                    totalLayer: 100,
                    currentTicks: 0,
                    totalTicks: 7200000,
                    filename: "debug_print.ctb",
                    errorNumber: 0,
                    taskId: "DEBUG_TASK_001",
                    remainingTicks: 7200000,
                    printSpeed: 1.0,
                    zHeight: 0.0
                )
            }
            
            let status = PrintStatus(
                currentStatus: currentStatus.currentStatus,
                previousStatus: currentStatus.previousStatus,
                printScreenTime: currentStatus.printScreenTime + 1,
                releaseFilmCount: currentStatus.releaseFilmCount,
                uvledTemperature: Double.random(in: 24.5...25.5),
                timeLapseEnabled: currentStatus.timeLapseEnabled,
                boxTemperature: Double.random(in: 24.0...26.0),
                boxTargetTemperature: currentStatus.boxTargetTemperature,
                printInfo: newPrintInfo
            )
            
            DispatchQueue.main.async {
                print("Debug: Updating status - \(status.currentStatus.description)")
                self.currentStatus = status
            }
        }
        
        // 确保定时器在主运行循环中运行
        RunLoop.main.add(debugTimer!, forMode: .common)
    }
    
    // 添加调试命令处理方法
    private func handleDebugCommand(_ command: String) {
        let currentStatus: PrintStatus.MachineStatus
        
        switch command {
        case "print":
            currentStatus = .printing
            let newPrintInfo = PrintInfo(
                status: .exposuring,
                currentLayer: 1,
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
            updateStatus(currentStatus: currentStatus, printInfo: newPrintInfo)
            
        case "pause":
            var newPrintInfo = currentStatus.printInfo
            newPrintInfo?.status = .paused
            updateStatus(currentStatus: currentStatus, printInfo: newPrintInfo)
            
        case "resume":
            var newPrintInfo = currentStatus.printInfo
            newPrintInfo?.status = .exposuring
            updateStatus(currentStatus: currentStatus, printInfo: newPrintInfo)
            
        case "stop":
            var newPrintInfo = currentStatus.printInfo
            newPrintInfo?.status = .stopped
            updateStatus(currentStatus: .idle, printInfo: newPrintInfo)
            
        case "home":
            var newPrintInfo = currentStatus.printInfo
            newPrintInfo?.status = .homing
            updateStatus(currentStatus: currentStatus, printInfo: newPrintInfo)
            
        case "exposureTest":
            let newPrintInfo = PrintInfo(
                status: .exposuring,
                currentLayer: 1,
                totalLayer: 1,
                currentTicks: 0,
                totalTicks: 8000,
                filename: "exposure_test.ctb",
                errorNumber: 0,
                taskId: device?.id ?? "DEBUG_TEST_001",
                remainingTicks: 8000,
                printSpeed: 1.0,
                zHeight: 0.05
            )
            updateStatus(currentStatus: .exposureTesting, printInfo: newPrintInfo)
            
        case "deviceTest":
            let newPrintInfo = PrintInfo(
                status: .idle,
                currentLayer: 0,
                totalLayer: 0,
                currentTicks: 0,
                totalTicks: 0,
                filename: "",
                errorNumber: 0,
                taskId: device?.id ?? "DEBUG_TEST_002",
                remainingTicks: 0,
                printSpeed: 1.0,
                zHeight: 0.0
            )
            updateStatus(currentStatus: .devicesTesting, printInfo: newPrintInfo)
            
        case "fileTransfer":
            let newPrintInfo = PrintInfo(
                status: .fileChecking,
                currentLayer: 0,
                totalLayer: 0,
                currentTicks: 0,
                totalTicks: 0,
                filename: "transfer.ctb",
                errorNumber: 0,
                taskId: device?.id ?? "DEBUG_TRANSFER_001",
                remainingTicks: 0,
                printSpeed: 1.0,
                zHeight: 0.0
            )
            updateStatus(currentStatus: .fileTransferring, printInfo: newPrintInfo)
            
        default:
            print("Debug: Unknown command - \(command)")
        }
    }
    
    // 辅助方法：更新状态
    private func updateStatus(currentStatus: PrintStatus.MachineStatus, printInfo: PrintInfo?) {
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
            print("Debug: Updating status - \(currentStatus.description)")
            self.currentStatus = newStatus
        }
    }
    #endif
} 

