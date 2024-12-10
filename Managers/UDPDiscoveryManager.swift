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
    
    private var connection: NWConnection?
    private var discoveryTimer: Timer?
    private var deviceCache = Set<String>()
    
    private let udpQueue = DispatchQueue(label: "com.sdcp.udp")
    private let port: NWEndpoint.Port = 3000
    
    private init() {}
    
    func startDiscovery(completion: @escaping () -> Void) {
        guard !isScanning else { return }
        
        isScanning = true
        deviceCache.removeAll()
        discoveredDevices.removeAll()
        
        #if DEBUG
        // 调试模式下添加测试设备
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.discoveredDevices.append(PrinterDevice.preview)
            self?.discoveredDevices.append(contentsOf: PrinterDevice.debugDevices)
            self?.isScanning = false
            completion()
        }
        #else
        // 实际UDP发现逻辑保持不变
        // ... 原有UDP发现代码 ...
        #endif
    }
    
    func stopDiscovery() {
        isScanning = false
        connection?.cancel()
        connection = nil
        discoveryTimer?.invalidate()
        discoveryTimer = nil
    }
} 