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
    /// 排除的设备列表
    private var excludedDevices: [PrinterDevice] = []
    
    private init() {}
    
    /// 开始设备发现
    func startDiscovery(excludingDevices: [PrinterDevice] = []) {
        guard !isScanning else { return }
        
        isScanning = true
        deviceCache.removeAll()
        discoveredDevices.removeAll()
        excludedDevices = excludingDevices
        
        #if DEBUG
        // 在调试模式下添加测试设备
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            let newDevices = PrinterDevice.debugDevices.filter { device in
                !self.excludedDevices.contains { $0.id == device.id }
            }
            self.discoveredDevices.append(contentsOf: newDevices)
            self.stopDiscovery()
        }
        #else
        setupConnection()
        setupDiscoveryTimer()
        sendDiscoveryRequest()
        #endif
    }
    
    /// 添加发现的设备
    func addDiscoveredDevice(_ device: PrinterDevice) {
        // 检查设备是否已经在排除列表中
        guard !excludedDevices.contains(where: { $0.id == device.id }) else {
            return
        }
        
        // 检查设备是否已经在发现列表中
        guard !deviceCache.contains(device.id) else {
            return
        }
        
        deviceCache.insert(device.id)
        discoveredDevices.append(device)
    }
    
    /// 停止设备发现
    func stopDiscovery() {
        connection?.cancel()
        connection = nil
        discoveryTimer?.invalidate()
        discoveryTimer = nil
        isScanning = false
    }
    
    /// 发送发现消息
    private func sendDiscoveryMessage() {
        guard let data = "M99999".data(using: .utf8) else { return }
        
        connection?.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("发送发现消息失败: \(error)")
                self?.stopDiscovery()
            }
        })
    }
    
    /// 接收响应
    private func receiveResponse() {
        connection?.receiveMessage { [weak self] content, _, isComplete, error in
            if let error = error {
                print("接收响应失败: \(error)")
                self?.stopDiscovery()
                return
            }
            
            if let content = content,
               let json = try? JSONSerialization.jsonObject(with: content) as? [String: Any],
               let device = PrinterDevice.from(json) {
                DispatchQueue.main.async {
                    // 修复设备去重逻辑
                    if let deviceCache = self?.deviceCache,
                       !deviceCache.contains(device.id) {
                        self?.deviceCache.insert(device.id)
                        self?.discoveredDevices.append(device)
                    }
                }
            }
            
            if !isComplete {
                self?.receiveResponse()
            }
        }
    }
} 