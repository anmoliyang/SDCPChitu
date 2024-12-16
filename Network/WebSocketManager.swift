import Foundation
import Combine

final class WebSocketManager: ObservableObject {
    static let shared = WebSocketManager()
    
    @Published private(set) var currentStatus: PrintStatus?
    @Published private(set) var isConnected = false
    @Published private(set) var videoStreamUrl: String?
    @Published private(set) var deviceId: String?
    
    private var currentDevice: PrinterDevice?
    private var webSocket: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    
    #if DEBUG
    private var debugTimer: Timer?
    #endif
    
    private let connectionStatusSubject = PassthroughSubject<ConnectionStatus, Never>()
    var connectionStatusPublisher: AnyPublisher<ConnectionStatus, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
    }
    
    private let statusSubject = PassthroughSubject<PrintStatus, Never>()
    var statusPublisher: AnyPublisher<PrintStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    private init() {
        print("Debug: WebSocketManager initialized")
    }
    
    /// 连接到打印机
    func connect(to device: PrinterDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        self.currentDevice = device
        self.deviceId = device.id
        print("Debug: Connecting to device \(device.id)")
        
        disconnect()
        
        // 检查是否有保存的状态
        if let savedStatus = DeviceManager.shared.deviceStatuses[device.id] {
            currentStatus = savedStatus
            statusSubject.send(savedStatus)
            isConnected = true
            connectionStatusSubject.send(.connected(deviceId: device.id))
            
            // 如果正在打印，启动调试定时器
            #if DEBUG
            if device.id.starts(with: "DEBUG") {
                if savedStatus.currentStatus == .printing {
                    startDebugStatusUpdates()
                }
                completion(.success(()))
                return
            }
            #endif
        }
        
        if device.id.starts(with: "DEBUG") {
            // 调试模式下的初始状态
            let initialStatus = PrintStatus(
                currentStatus: .idle,
                previousStatus: .idle,
                printScreenTime: 0,
                releaseFilmCount: 0,
                uvledTemperature: 25.0,
                timeLapseEnabled: false,
                boxTemperature: 25.0,
                boxTargetTemperature: 25.0,
                printInfo: nil,
                devicesStatus: .debugDefault
            )
            
            currentStatus = initialStatus
            statusSubject.send(initialStatus)
            isConnected = true
            connectionStatusSubject.send(.connected(deviceId: device.id))
            
            completion(.success(()))
            return
        }
        
        // 正常连接逻辑
        guard let url = URL(string: "ws://\(device.ipAddress):3000/ws") else {
            completion(.failure(ConnectionError.invalidURL))
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        
        webSocket?.resume()
        startPingTimer()
        startListening()
        
        isConnected = true
        connectionStatusSubject.send(.connected(deviceId: device.id))
        completion(.success(()))
    }
    
    func disconnect() {
        isConnected = false
        webSocket?.cancel()
        webSocket = nil
        pingTimer?.invalidate()
        pingTimer = nil
        
        #if DEBUG
        debugTimer?.invalidate()
        debugTimer = nil
        #endif
        
        if let deviceId = deviceId {
            connectionStatusSubject.send(.disconnected(deviceId: deviceId))
        }
        
        videoStreamUrl = nil
    }
    
    private func updateStatus(_ newStatus: PrintStatus) {
        DispatchQueue.main.async {
            self.currentStatus = newStatus
            self.statusSubject.send(newStatus)
            
            // 保存状态到 DeviceManager
            if let deviceId = self.deviceId {
                DeviceManager.shared.updateDeviceStatus(deviceId: deviceId, status: newStatus)
            }
        }
    }
    
    #if DEBUG
    private func startDebugStatusUpdates() {
        debugTimer?.invalidate()
        debugTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDebugPrintStatus()
        }
    }
    
    private func updateDebugPrintStatus() {
        guard let currentStatus = currentStatus,
              let printInfo = currentStatus.printInfo else { return }
        
        // 更新打印进度
        let newCurrentLayer = min(printInfo.currentLayer + 1, printInfo.totalLayer)
        let newCurrentTicks = min(printInfo.currentTicks + 1000, printInfo.totalTicks)
        let newRemainingTicks = max(printInfo.remainingTicks - 1000, 0)
        
        // 判断是否打印完成
        if newCurrentLayer >= printInfo.totalLayer {
            // 创建打印完成状态
            let completedStatus = PrintStatus(
                currentStatus: .idle,
                previousStatus: .printing,
                printScreenTime: currentStatus.printScreenTime,
                releaseFilmCount: currentStatus.releaseFilmCount,
                uvledTemperature: currentStatus.uvledTemperature,
                timeLapseEnabled: currentStatus.timeLapseEnabled,
                boxTemperature: currentStatus.boxTemperature,
                boxTargetTemperature: currentStatus.boxTargetTemperature,
                printInfo: PrintInfo(
                    status: .complete,  // 设置为完成状态
                    currentLayer: printInfo.totalLayer,
                    totalLayer: printInfo.totalLayer,
                    currentTicks: printInfo.totalTicks,
                    totalTicks: printInfo.totalTicks,
                    filename: printInfo.filename,
                    errorNumber: 0,
                    taskId: printInfo.taskId,
                    remainingTicks: 0,
                    printSpeed: printInfo.printSpeed,
                    zHeight: printInfo.zHeight
                ),
                devicesStatus: currentStatus.devicesStatus
            )
            
            updateStatus(completedStatus)
            debugTimer?.invalidate()  // 停止定时器
            return
        }
        
        // 继续打印中状态更新
        let newPrintInfo = PrintInfo(
            status: .exposuring,
            currentLayer: newCurrentLayer,
            totalLayer: printInfo.totalLayer,
            currentTicks: newCurrentTicks,
            totalTicks: printInfo.totalTicks,
            filename: printInfo.filename,
            errorNumber: printInfo.errorNumber,
            taskId: printInfo.taskId,
            remainingTicks: newRemainingTicks,
            printSpeed: printInfo.printSpeed,
            zHeight: printInfo.zHeight
        )
        
        let newStatus = PrintStatus(
            currentStatus: .printing,
            previousStatus: currentStatus.currentStatus,
            printScreenTime: currentStatus.printScreenTime + 1000,
            releaseFilmCount: currentStatus.releaseFilmCount,
            uvledTemperature: currentStatus.uvledTemperature,
            timeLapseEnabled: currentStatus.timeLapseEnabled,
            boxTemperature: currentStatus.boxTemperature,
            boxTargetTemperature: currentStatus.boxTargetTemperature,
            printInfo: newPrintInfo,
            devicesStatus: currentStatus.devicesStatus
        )
        
        updateStatus(newStatus)
    }
    
    private func handleDebugVideoStreamResponse(_ command: String) {
        guard let data = command.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let commandData = json["Data"] as? [String: Any],
              let commandDataDict = commandData["Data"] as? [String: Any],
              let enable = commandDataDict["Enable"] as? Int else {
            return
        }
        
        DispatchQueue.main.async {
            if enable == 1 {
                // 模拟视频流URL
                if let device = self.currentDevice {
                    self.videoStreamUrl = "rtsp://\(device.ipAddress):8554/live"
                }
            } else {
                self.videoStreamUrl = nil
            }
        }
    }
    
    private func handleDebugPauseCommand() {
        guard let currentStatus = currentStatus else { return }
        // 创建新的状态对象而不是修改现有的
        let newStatus = PrintStatus(
            currentStatus: .paused,
            previousStatus: .printing,
            printScreenTime: currentStatus.printScreenTime,
            releaseFilmCount: currentStatus.releaseFilmCount,
            uvledTemperature: currentStatus.uvledTemperature,
            timeLapseEnabled: currentStatus.timeLapseEnabled,
            boxTemperature: currentStatus.boxTemperature,
            boxTargetTemperature: currentStatus.boxTargetTemperature,
            printInfo: currentStatus.printInfo.map { info in
                PrintInfo(
                    status: .pausing,
                    currentLayer: info.currentLayer,
                    totalLayer: info.totalLayer,
                    currentTicks: info.currentTicks,
                    totalTicks: info.totalTicks,
                    filename: info.filename,
                    errorNumber: info.errorNumber,
                    taskId: info.taskId,
                    remainingTicks: info.remainingTicks,
                    printSpeed: info.printSpeed,
                    zHeight: info.zHeight
                )
            },
            devicesStatus: currentStatus.devicesStatus
        )
        
        updateStatus(newStatus)
        debugTimer?.invalidate()
    }
    
    private func handleDebugResumeCommand() {
        guard let currentStatus = currentStatus else { return }
        // 创建新的状态对象
        let newStatus = PrintStatus(
            currentStatus: .printing,
            previousStatus: .paused,
            printScreenTime: currentStatus.printScreenTime,
            releaseFilmCount: currentStatus.releaseFilmCount,
            uvledTemperature: currentStatus.uvledTemperature,
            timeLapseEnabled: currentStatus.timeLapseEnabled,
            boxTemperature: currentStatus.boxTemperature,
            boxTargetTemperature: currentStatus.boxTargetTemperature,
            printInfo: currentStatus.printInfo.map { info in
                PrintInfo(
                    status: .exposuring,
                    currentLayer: info.currentLayer,
                    totalLayer: info.totalLayer,
                    currentTicks: info.currentTicks,
                    totalTicks: info.totalTicks,
                    filename: info.filename,
                    errorNumber: info.errorNumber,
                    taskId: info.taskId,
                    remainingTicks: info.remainingTicks,
                    printSpeed: info.printSpeed,
                    zHeight: info.zHeight
                )
            },
            devicesStatus: currentStatus.devicesStatus
        )
        
        updateStatus(newStatus)
        startDebugStatusUpdates() // 重新启动调试定时器
    }
    
    private func handleDebugStopCommand() {
        guard let currentStatus = currentStatus else { return }
        
        // 先更新为停止中状态
        let stoppingStatus = PrintStatus(
            currentStatus: .stopped,  // 直接设置为已停止状态
            previousStatus: currentStatus.currentStatus,
            printScreenTime: currentStatus.printScreenTime,
            releaseFilmCount: currentStatus.releaseFilmCount,
            uvledTemperature: currentStatus.uvledTemperature,
            timeLapseEnabled: currentStatus.timeLapseEnabled,
            boxTemperature: currentStatus.boxTemperature,
            boxTargetTemperature: currentStatus.boxTargetTemperature,
            printInfo: currentStatus.printInfo.map { info in
                PrintInfo(
                    status: .stopped,  // 修改为已停止状态
                    currentLayer: info.currentLayer,
                    totalLayer: info.totalLayer,
                    currentTicks: info.currentTicks,
                    totalTicks: info.totalTicks,
                    filename: info.filename,
                    errorNumber: info.errorNumber,
                    taskId: info.taskId,
                    remainingTicks: info.remainingTicks,
                    printSpeed: info.printSpeed,
                    zHeight: info.zHeight
                )
            },
            devicesStatus: currentStatus.devicesStatus
        )
        
        updateStatus(stoppingStatus)
        debugTimer?.invalidate()
    }
    
    private func handleDebugCommand(_ command: String) {
        guard let data = command.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let commandData = json["Data"] as? [String: Any],
              let cmd = commandData["Cmd"] as? Int else {
            return
        }
        
        // 处理不同的命令
        switch cmd {
        case 128: // 开始打印
            handleDebugStartPrintCommand()
        case 129: // 暂停打印
            handleDebugPauseCommand()
        case 130: // 继续打印
            handleDebugResumeCommand()
        case 131: // 停止打印
            handleDebugStopCommand()
        case 133: // 回零操作
            handleDebugHomeCommand()
        case 134: // 曝光测试
            handleDebugExposureTestCommand()
        case 135: // 设备自检
            handleDebugDeviceTestCommand()
        case 386: // 视频流命令
            handleDebugVideoStreamResponse(command)
        default:
            break
        }
    }
    
    private func handleDebugStartPrintCommand() {
        guard let currentStatus = currentStatus,
              let deviceId = deviceId else { return }
        
        // 创建打印信息
        let printInfo = PrintInfo(
            status: .homing,
            currentLayer: 0,
            totalLayer: 10,
            currentTicks: 0,
            totalTicks: 10000,
            filename: "测试打印",
            errorNumber: 0,
            taskId: deviceId,
            remainingTicks: 10000,
            printSpeed: 1.0,
            zHeight: 0.0
        )
        
        let newStatus = PrintStatus(
            currentStatus: .printing,
            previousStatus: .idle,
            printScreenTime: 0,
            releaseFilmCount: currentStatus.releaseFilmCount,
            uvledTemperature: currentStatus.uvledTemperature,
            timeLapseEnabled: false,
            boxTemperature: currentStatus.boxTemperature,
            boxTargetTemperature: currentStatus.boxTargetTemperature,
            printInfo: printInfo,
            devicesStatus: currentStatus.devicesStatus
        )
        
        updateStatus(newStatus)
        startDebugStatusUpdates()
    }
    
    private func handleDebugHomeCommand() {
        guard let currentStatus = currentStatus else { return }
        
        // 创建一个安全的打印信息，避免无效的数值转换
        let printInfo = PrintInfo(
            status: .homing,
            currentLayer: 0,
            totalLayer: 1,  // 避免除以零错误
            currentTicks: 0,
            totalTicks: 10000,  // 设置一个合理的总时间
            filename: "",
            errorNumber: 0,
            taskId: deviceId ?? "DEBUG",
            remainingTicks: 10000,  // 与总时间保持一致
            printSpeed: 1.0,
            zHeight: 0.0
        )
        
        let newStatus = PrintStatus(
            currentStatus: .idle,
            previousStatus: currentStatus.currentStatus,
            printScreenTime: 0,  // 重置打印时间
            releaseFilmCount: currentStatus.releaseFilmCount,
            uvledTemperature: 25.0,  // 使用固定的温度值
            timeLapseEnabled: false,
            boxTemperature: 25.0,  // 使用固定的温度值
            boxTargetTemperature: 25.0,
            printInfo: printInfo,
            devicesStatus: currentStatus.devicesStatus
        )
        
        // 更新状态
        updateStatus(newStatus)
        
        // 模拟回零完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self,
                  let currentStatus = self.currentStatus else { return }
            
            // 回零完成后更新状态
            let completedStatus = PrintStatus(
                currentStatus: .idle,
                previousStatus: .idle,
                printScreenTime: 0,
                releaseFilmCount: currentStatus.releaseFilmCount,
                uvledTemperature: 25.0,
                timeLapseEnabled: false,
                boxTemperature: 25.0,
                boxTargetTemperature: 25.0,
                printInfo: nil,  // 清除打印信息
                devicesStatus: currentStatus.devicesStatus
            )
            
            self.updateStatus(completedStatus)
        }
    }
    
    private func handleDebugExposureTestCommand() {
        guard let currentStatus = currentStatus else { return }
        let newStatus = PrintStatus(
            currentStatus: .exposureTesting,
            previousStatus: currentStatus.currentStatus,
            printScreenTime: 0,
            releaseFilmCount: currentStatus.releaseFilmCount,
            uvledTemperature: currentStatus.uvledTemperature,
            timeLapseEnabled: currentStatus.timeLapseEnabled,
            boxTemperature: currentStatus.boxTemperature,
            boxTargetTemperature: currentStatus.boxTargetTemperature,
            printInfo: nil,
            devicesStatus: currentStatus.devicesStatus
        )
        
        updateStatus(newStatus)
    }
    
    private func handleDebugDeviceTestCommand() {
        guard let currentStatus = currentStatus else { return }
        let newStatus = PrintStatus(
            currentStatus: .devicesTesting,
            previousStatus: currentStatus.currentStatus,
            printScreenTime: currentStatus.printScreenTime,
            releaseFilmCount: currentStatus.releaseFilmCount,
            uvledTemperature: currentStatus.uvledTemperature,
            timeLapseEnabled: currentStatus.timeLapseEnabled,
            boxTemperature: currentStatus.boxTemperature,
            boxTargetTemperature: currentStatus.boxTargetTemperature,
            printInfo: nil,
            devicesStatus: currentStatus.devicesStatus
        )
        
        updateStatus(newStatus)
    }
    
    func sendCommand(_ command: String) {
        print("Debug: WebSocketManager - Sending command: \(command)")
        // 实现发送命令的逻辑
        #if DEBUG
        if let deviceId = deviceId, deviceId.starts(with: "DEBUG") {
            handleDebugCommand(command)
        }
        #endif
    }
    
    func restoreStatus(_ status: PrintStatus, for deviceId: String) {
        self.deviceId = deviceId
        currentStatus = status
        statusSubject.send(status)
    }
    
    #if DEBUG
    private func handleDebugClearPrintCommand() {
        currentStatus = nil
        debugTimer?.invalidate()
        debugTimer = nil
    }
    #endif
    #endif
    
    // 处理视频流响应
    private func handleVideoStreamResponse(_ response: SDCPResponse) {
        if response.Data.Cmd == 386 { // 视频流命令响应
            DispatchQueue.main.async {
                if let enable = response.Data.Data["Enable"] as? Int {
                    if enable == 1, let url = response.Data.Data["URL"] as? String {
                        self.videoStreamUrl = url
                    } else {
                        self.videoStreamUrl = nil
                    }
                }
            }
        }
    }
    
    private func handlePrintStatusUpdate(_ status: PrintStatus) {
        // 如果是从暂停状态恢复，需要保持原有进度
        if let currentStatus = self.currentStatus,
           currentStatus.printInfo?.status == .paused,
           status.printInfo?.status == .exposuring {
            
            // 创建新的打印信息，保持原有进度
            let updatedPrintInfo = currentStatus.printInfo.map { info in
                PrintInfo(
                    status: .exposuring,  // 更新为打印中状态
                    currentLayer: info.currentLayer,  // 保持暂停时的层数
                    totalLayer: info.totalLayer,
                    currentTicks: info.currentTicks,  // 保持暂停时的时间
                    totalTicks: info.totalTicks,
                    filename: info.filename,
                    errorNumber: info.errorNumber,
                    taskId: info.taskId,
                    remainingTicks: info.remainingTicks,  // 保持暂停时的剩余时间
                    printSpeed: info.printSpeed,
                    zHeight: info.zHeight
                )
            }
            
            // 创建新的状态对象，但保持原有的打印进度信息
            let updatedStatus = PrintStatus(
                currentStatus: .printing,  // 更新为打印状态
                previousStatus: .paused,   // 设置前一个状态为暂停
                printScreenTime: currentStatus.printScreenTime,  // 保持原有的打印时间
                releaseFilmCount: currentStatus.releaseFilmCount,
                uvledTemperature: status.uvledTemperature,  // 使用新状态的温度信息
                timeLapseEnabled: status.timeLapseEnabled,
                boxTemperature: status.boxTemperature,
                boxTargetTemperature: status.boxTargetTemperature,
                printInfo: updatedPrintInfo,
                devicesStatus: status.devicesStatus
            )
            
            updateStatus(updatedStatus)
            
            #if DEBUG
            if currentDevice?.id.starts(with: "DEBUG") ?? false {
                startDebugStatusUpdates()  // 重新启动调试定时器
            }
            #endif
        } else {
            updateStatus(status)
        }
    }
}

// MARK: - Private Methods
private extension WebSocketManager {
    func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.ping()
        }
    }
    
    func ping() {
        webSocket?.sendPing { error in
            if let error = error {
                print("Debug: Ping failed: \(error)")
            }
        }
    }
    
    func startListening() {
        receiveMessage()
    }
    
    func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
            case .failure(let error):
                print("Debug: Receive error: \(error)")
            }
            self?.receiveMessage()
        }
    }
    
    func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        // 根据 SDCP 协议处理消息
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            handleBinaryMessage(data)
        @unknown default:
            break
        }
    }
    
    func handleTextMessage(_ text: String) {
        // 处理文本消息
        guard let data = text.data(using: .utf8),
              let response = try? JSONDecoder().decode(SDCPResponse.self, from: data) else {
            return
        }
        // 更新状态
        DispatchQueue.main.async {
            self.updateStatus(with: response)
        }
    }
    
    func handleBinaryMessage(_ data: Data) {
        // 处理二进制消息
    }
    
    func updateStatus(with response: SDCPResponse) {
        // 更新打印机状态
    }
}

// MARK: - Types
extension WebSocketManager {
    enum ConnectionError: Error {
        case invalidURL
        case connectionFailed
    }
    
    enum ConnectionStatus {
        case connected(deviceId: String)
        case disconnected(deviceId: String)
    }
    
    struct SDCPResponse: Codable {
        let Topic: String
        let Data: ResponseData
        
        struct ResponseData: Codable {
            let MainboardID: String
            let RequestID: String
            let TimeStamp: Int
            let From: Int
            let Cmd: Int
            let Data: ResponseDataContent
            let Result: Int?
            let Message: String?
        }
        
        struct ResponseDataContent: Codable {
            private var storage: [String: AnyCodable]
            
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                storage = try container.decode([String: AnyCodable].self)
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(storage)
            }
            
            subscript(key: String) -> Any? {
                storage[key]?.value
            }
        }
    }
}

// MARK: - AnyCodable
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map(AnyCodable.init))
        case let dict as [String: Any]:
            try container.encode(dict.mapValues(AnyCodable.init))
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "AnyCodable value cannot be encoded"
            ))
        }
    }
}

