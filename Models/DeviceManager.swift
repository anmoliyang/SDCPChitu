import Foundation

/// 设备管理器
class DeviceManager: ObservableObject {
    static let shared = DeviceManager()
    
    private let defaults = UserDefaults.standard
    private let connectedDevicesKey = "ConnectedDevices"
    
    private init() {}
    
    /// 获取已连接的设备列表
    @Published private(set) var connectedDevices: [PrinterDevice] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(connectedDevices) {
                defaults.set(data, forKey: connectedDevicesKey)
            }
        }
    }
    
    /// 连接设备
    func connectDevice(_ device: PrinterDevice) {
        if !connectedDevices.contains(where: { $0.id == device.id }) {
            connectedDevices.append(device)
        }
    }
    
    /// 移除设备
    func removeDevice(_ device: PrinterDevice) {
        connectedDevices.removeAll(where: { $0.id == device.id })
    }
    
    /// 检查设备是否已连接
    func isDeviceConnected(_ device: PrinterDevice) -> Bool {
        return connectedDevices.contains(where: { $0.id == device.id })
    }
    
    /// 从持久化存储加载设备列表
    func loadDevices() {
        if let data = defaults.data(forKey: connectedDevicesKey),
           let devices = try? JSONDecoder().decode([PrinterDevice].self, from: data) {
            connectedDevices = devices
        }
    }
} 