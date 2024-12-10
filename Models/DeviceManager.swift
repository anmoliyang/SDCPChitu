import Foundation
import Combine

/// 设备管理器
class DeviceManager: ObservableObject {
    static let shared = DeviceManager()
    
    @Published private(set) var connectedDevices: [PrinterDevice] = []
    @Published private(set) var deviceStatuses: [String: PrintStatus] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
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
        }
    }
    
    func disconnectDevice(_ device: PrinterDevice) {
        connectedDevices.removeAll { $0.id == device.id }
        deviceStatuses.removeValue(forKey: device.id)
    }
} 