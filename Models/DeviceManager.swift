import Foundation
import Combine

/// 设备管理器
class DeviceManager: ObservableObject {
    static let shared = DeviceManager()
    
    @Published private(set) var connectedDevices: [PrinterDevice] = []
    @Published private(set) var deviceStatuses: [String: PrintStatus] = [:]
    
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
    }
    
    func connectDevice(_ device: PrinterDevice) {
        if !connectedDevices.contains(device) {
            connectedDevices.append(device)
            saveConnectedDevices()
        }
    }
    
    func disconnectDevice(_ device: PrinterDevice) {
        connectedDevices.removeAll { $0.id == device.id }
        deviceStatuses.removeValue(forKey: device.id)
        saveConnectedDevices()
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