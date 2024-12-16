import SwiftUI

struct VideoStreamSection: View {
    let device: PrinterDevice
    
    var body: some View {
        if let capabilities = device.capabilities,
           capabilities.contains(.videoStream) {
            Section(header: Text("视频监控")) {
                VideoStreamView(device: device)
            }
        }
    }
} 