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
    private let deviceStatusesKey = "DeviceStatuses"
    
    private init() {
        loadConnectedDevices()
        loadDeviceStatuses()
        
        // 监听设备状态更新
        WebSocketManager.shared.statusPublisher
            .sink { [weak self] (status: PrintStatus) in
                guard let self = self,
                      let deviceId = WebSocketManager.shared.deviceId else { return }
                self.deviceStatuses[deviceId] = status
                self.saveDeviceStatuses()
            }
            .store(in: &cancellables)
    }
    
    func updateDeviceStatus(deviceId: String, status: PrintStatus) {
        deviceStatuses[deviceId] = status
        saveDeviceStatuses()
    }
    
    private func loadDeviceStatuses() {
        if let data = userDefaults.data(forKey: deviceStatusesKey),
           let statuses = try? JSONDecoder().decode([String: PrintStatus].self, from: data) {
            deviceStatuses = statuses
        }
    }
    
    private func saveDeviceStatuses() {
        if let data = try? JSONEncoder().encode(deviceStatuses) {
            userDefaults.set(data, forKey: deviceStatusesKey)
        }
    }
    
    func reconnectDevice(_ device: PrinterDevice, completion: @escaping (Bool) -> Void = { _ in }) {
        connectingDevices.insert(device.id)
        
        // 检查设备状态
        if deviceStatuses[device.id] != nil {
            connectedWebSockets.insert(device.id)
            
            // 发送获取状态命令
            let message: [String: Any] = [
                "Topic": "sdcp/request/\(device.id)",
                "Data": [
                    "MainboardID": device.id,
                    "RequestID": UUID().uuidString,
                    "TimeStamp": Int(Date().timeIntervalSince1970),
                    "From": 3,
                    "Cmd": 385,  // 获取打印机状态命令
                    "Data": [:]
                ]
            ]
            
            if let data = try? JSONSerialization.data(withJSONObject: message),
               let jsonString = String(data: data, encoding: .utf8) {
                WebSocketManager.shared.sendCommand(jsonString)
            }
            
            completion(true)
            connectingDevices.remove(device.id)
            return
        }
        
        // 尝试重新连接
        WebSocketManager.shared.connect(to: device) { [weak self] result in
            DispatchQueue.main.async {
                self?.connectingDevices.remove(device.id)
                switch result {
                case .success:
                    self?.connectedWebSockets.insert(device.id)
                    completion(true)
                case .failure:
                    completion(false)
                }
            }
        }
    }
    
    func connectDevice(_ device: PrinterDevice) {
        if !connectedDevices.contains(device) {
            connectedDevices.append(device)
            saveConnectedDevices()
        }
    }
    
    func disconnectDevice(_ device: PrinterDevice) {
        // 不要在断开连接时删除状态，只移除连接标记
        connectedWebSockets.remove(device.id)
        connectedDevices.removeAll { $0.id == device.id }
        saveConnectedDevices()
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