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
    
    private override init() {
        super.init()
    }
    
    /// 连接到打印机
    /// - Parameter device: 打印机设备
    func connect(to device: PrinterDevice) {
        // 如果已经连接，先断开
        disconnect()
        
        #if DEBUG
        // 调试模式下使用模拟数据
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = true
            // 创建模拟状态
            let status = PrintStatus(
                currentStatus: [.idle],
                previousStatus: .idle,
                printScreenTime: 0,
                releaseFilmCount: 0,
                uvledTemperature: 25.0,
                timeLapseEnabled: false,
                boxTemperature: 28.0,
                boxTargetTemperature: 28.0,
                printInfo: nil
            )
            self?.currentStatus = status
        }
        #else
        // 创建WebSocket URL
        guard let url = URL(string: "ws://\(device.ipAddress):3030/websocket") else {
            DispatchQueue.main.async {
                self.errorSubject.send("无效的设备地址")
            }
            return
        }
        
        print("正在连接WebSocket: \(url.absoluteString)")
        
        // 创建WebSocket会话
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        
        // 开始接收消息
        receiveMessage()
        #endif
    }
    
    /// 断开连接
    func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
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
                
                // 继续接收下一条���息
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
        if let status = PrintStatus.from(json) {
            self.currentStatus = status
        }
        
        // 继续接收下一条消息
        receiveMessage()
    }
    
    /// 发送命令
    func sendCommand(_ command: String) {
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
            print("WebSocket���误: \(error.localizedDescription)")
            DispatchQueue.main.async { [weak self] in
                self?.errorSubject.send("连接错误: \(error.localizedDescription)")
            }
        }
    }
} 

