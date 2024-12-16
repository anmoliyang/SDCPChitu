import SwiftUI

struct RemoveDeviceSection: View {
    let onDisconnect: () -> Void
    let dismiss: DismissAction
    
    var body: some View {
        Section {
            Button(role: .destructive) {
                onDisconnect()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("移除设备")
                }
            }
        }
    }
} 