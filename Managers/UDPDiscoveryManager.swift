import Foundation
import Network

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
    private let port: NWEndpoint.Port = 3000  // SDCP协议规定的UDP端口
    
    private init() {}
    
    func startDiscovery(completion: @escaping () -> Void) {
        guard !isScanning else { return }
        
        isScanning = true
        deviceCache.removeAll()
        discoveredDevices.removeAll()
        
        #if DEBUG
        // 调试模式下添加测试设备
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.discoveredDevices = PrinterDevice.debugDevices
            self?.isScanning = false
            completion()
        }
        #else
        // 创建UDP连接
        let endpoint = NWEndpoint.hostPort(host: .init("255.255.255.255"), port: port)
        connection = NWConnection(to: endpoint, using: .udp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.startBroadcast()
            case .failed(let error):
                print("Error: UDPDiscoveryManager - Connection failed: \(error)")
                self?.stopDiscovery()
            case .waiting(let error):
                print("Warning: UDPDiscoveryManager - Connection waiting: \(error)")
            default:
                break
            }
        }
        
        connection?.start(queue: udpQueue)
        #endif
    }
    
    func stopDiscovery() {
        isScanning = false
        connection?.cancel()
        connection = nil
        discoveryTimer?.invalidate()
        discoveryTimer = nil
    }
    
    private func startBroadcast() {
        // 按照SDCP协议发送广播命令
        let discoveryMessage = "M99999"
        guard let data = discoveryMessage.data(using: .utf8) else { return }
        
        connection?.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("Error: UDPDiscoveryManager - Failed to send broadcast: \(error)")
                self?.stopDiscovery()
            }
        })
        
        // 开始接收响应
        self.receiveResponse()
        
        // 设置定时重发
        discoveryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.connection?.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("Error: UDPDiscoveryManager - Failed to send broadcast: \(error)")
                    self?.stopDiscovery()
                }
            })
        }
    }
    
    private func receiveResponse() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65535) { [weak self] content, _, isComplete, error in
            if let error = error {
                print("Error: UDPDiscoveryManager - Failed to receive response: \(error)")
                self?.stopDiscovery()
                return
            }
            
            if let data = content,
               let jsonString = String(data: data, encoding: .utf8),
               let jsonData = jsonString.data(using: .utf8) {
                do {
                    let device = try JSONDecoder().decode(PrinterDevice.self, from: jsonData)
                    DispatchQueue.main.async {
                        if !(self?.deviceCache.contains(device.id) ?? true) {
                            self?.deviceCache.insert(device.id)
                            self?.discoveredDevices.append(device)
                        }
                    }
                } catch {
                    print("Error: UDPDiscoveryManager - Failed to decode device: \(error)")
                }
            }
            
            if !isComplete {
                self?.receiveResponse()
            }
        }
    }
}

// MARK: - Debug Helpers
#if DEBUG
extension PrinterDevice {
    /// 调试用设备列表
    static var debugDevices: [PrinterDevice] = [
        PrinterDevice(
            id: "DEBUG_001",
            name: "调试打印机1",
            machineName: "CBD-01",
            brandName: "CBD",
            ipAddress: "192.168.1.101",
            protocolVersion: "V3.0.0",
            firmwareVersion: "V1.0.0",
            resolution: "3840x2160",
            xyzSize: "192x120x200",
            networkStatus: .wlan,
            usbDiskStatus: 1,
            capabilities: [.fileTransfer, .printControl, .videoStream],
            supportFileTypes: ["CTB"]
        ),
        PrinterDevice(
            id: "DEBUG_002",
            name: "调试打印机2",
            machineName: "CBD-02",
            brandName: "CBD",
            ipAddress: "192.168.1.102",
            protocolVersion: "V3.0.0",
            firmwareVersion: "V1.0.0",
            resolution: "7680x4320",
            xyzSize: "192x120x200",
            networkStatus: .ethernet,
            usbDiskStatus: 0,
            capabilities: [.fileTransfer, .printControl],
            supportFileTypes: ["CTB"]
        )
    ]
}
#endif 