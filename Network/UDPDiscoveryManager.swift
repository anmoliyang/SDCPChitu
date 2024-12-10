import Foundation
import Network
import Combine

/// UDP设备发现管理器
class UDPDiscoveryManager: ObservableObject {
    /// 单例
    static let shared = UDPDiscoveryManager()
    
    /// 发现的设备列表
    @Published private(set) var discoveredDevices: [PrinterDevice] = []
    /// 是否正在扫描
    @Published private(set) var isScanning = false
    
    /// UDP连接
    private var connection: NWConnection?
    /// 发现超时定时器
    private var discoveryTimer: Timer?
    /// 设备缓存
    private var deviceCache = Set<String>()
    
    private let udpQueue = DispatchQueue(label: "com.sdcp.udp")
    private let port: NWEndpoint.Port = 3000
    
    private init() {}
    
    /// 开始设备发现
    func startDiscovery(completion: (() -> Void)? = nil) {
        guard !isScanning else { return }
        
        isScanning = true
        deviceCache.removeAll()
        discoveredDevices.removeAll()
        
        // 创建UDP广播端点
        let endpoint = NWEndpoint.hostPort(host: .init("255.255.255.255"), port: port)
        
        // 创建UDP连接参数
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        // 设置广播选项
        if let options = parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            options.version = .v4
            options.hopLimit = 1
        }
        
        // 创建UDP连接
        connection = NWConnection(to: endpoint, using: parameters)
        
        // 设置接收处理
        setupReceive()
        
        // 启动连接
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                // 发送M99999字符串，符合SDCP协议规范
                self?.sendDiscoveryMessage()
            case .failed(let error):
                print("UDP连接失败: \(error)")
                self?.stopDiscovery()
            case .cancelled:
                self?.stopDiscovery()
            default:
                break
            }
        }
        
        connection?.start(queue: udpQueue)
        
        // 设置超时定时器
        discoveryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.stopDiscovery()
            completion?()
        }
    }
    
    /// 停止设备发现
    func stopDiscovery() {
        connection?.cancel()
        connection = nil
        discoveryTimer?.invalidate()
        discoveryTimer = nil
        isScanning = false
    }
    
    /// 设置接收处理
    private func setupReceive() {
        receiveNextMessage()
    }
    
    /// 接收下一条消息
    private func receiveNextMessage() {
        connection?.receiveMessage { [weak self] content, context, isComplete, error in
            if let error = error {
                print("接收消息错误: \(error)")
                return
            }
            
            if let content = content,
               let response = try? JSONSerialization.jsonObject(with: content, options: []) as? [String: Any] {
                self?.handleDiscoveryResponse(response)
            }
            
            // 继续接收下一条消息
            if !isComplete {
                self?.receiveNextMessage()
            }
        }
    }
    
    /// 发送发现消息
    private func sendDiscoveryMessage() {
        // 按照SDCP协议规范，发送"M99999"字符串
        guard let data = "M99999".data(using: .utf8) else { return }
        
        connection?.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("发送发现消息失败: \(error)")
                self?.stopDiscovery()
            }
        })
    }
    
    /// 处理发现响应
    private func handleDiscoveryResponse(_ response: [String: Any]) {
        guard let data = response["Data"] as? [String: Any],
              let device = PrinterDevice.from(data) else {
            return
        }
        
        // 检查设备是否已存在
        if !deviceCache.contains(device.id) {
            deviceCache.insert(device.id)
            DispatchQueue.main.async { [weak self] in
                self?.discoveredDevices.append(device)
            }
        }
    }
} 