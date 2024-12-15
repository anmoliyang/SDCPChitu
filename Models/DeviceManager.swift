import Foundation
import Combine

/// 设备管理器
class DeviceManager: ObservableObject {
    static let shared = DeviceManager()
    
    @Published private(set) var connectedDevices: [PrinterDevice] = []
    @Published private(set) var deviceStatuses: [String: PrintStatus] = [:]
    @Published private(set) var connectingDevices: Set<String> = []
    @Published private(set) var connectedWebSockets: Set<String> = []
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let connectedDevicesKey = "ConnectedDevices"
    
    private init() {
        // 从 UserDefaults 加载已保存的设备
        loadConnectedDevices()
        
        // 监听设备状态更新
        WebSocketManager.shared.statusPublisher
            .sink { [weak self] status in
                guard let deviceId = status.printInfo?.taskId else { return }
                self?.deviceStatuses[deviceId] = status
            }
            .store(in: &cancellables)
        
        // 监听WebSocket连接状态
        WebSocketManager.shared.connectionStatusPublisher
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .connected(let deviceId):
                    self.connectedWebSockets.insert(deviceId)
                case .disconnected(let deviceId):
                    self.connectedWebSockets.remove(deviceId)
                }
            }
            .store(in: &cancellables)
    }
    
    func connectDevice(_ device: PrinterDevice) {
        if !connectedDevices.contains(device) {
            connectedDevices.append(device)
            saveConnectedDevices()
        }
    }
    
    func disconnectDevice(_ device: PrinterDevice) {
        connectedWebSockets.remove(device.id)
        connectedDevices.removeAll { $0.id == device.id }
        deviceStatuses.removeValue(forKey: device.id)
        saveConnectedDevices()
    }
    
    func reconnectDevice(_ device: PrinterDevice, completion: @escaping (Bool) -> Void = { _ in }) {
        // 添加到连接中状态
        connectingDevices.insert(device.id)
        
        // 尝试重新连接
        WebSocketManager.shared.connect(to: device) { [weak self] result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // 缩短延迟时间
                self?.connectingDevices.remove(device.id)
                
                switch result {
                case .success:
                    print("Debug: Successfully reconnected to device")
                    completion(true)
                case .failure(let error):
                    print("Debug: Reconnection failed - \(error)")
                    completion(false)
                }
            }
        }
    }
    
    /// 检查设备是否已连接
    func isDeviceConnected(_ deviceId: String) -> Bool {
        connectedWebSockets.contains(deviceId)
    }
    
    // MARK: - Private Methods
    
    private func loadConnectedDevices() {
        if let data = userDefaults.data(forKey: connectedDevicesKey),
           let devices = try? JSONDecoder().decode([PrinterDevice].self, from: data) {
            connectedDevices = devices
        }
    }
    
    private func saveConnectedDevices() {
        if let data = try? JSONEncoder().encode(connectedDevices) {
            userDefaults.set(data, forKey: connectedDevicesKey)
        }
    }
} 