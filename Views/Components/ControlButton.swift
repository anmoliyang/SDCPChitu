import SwiftUI

/// 控制按钮组件
struct ControlButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

#Preview {
    HStack {
        ControlButton(title: "暂停", icon: "pause.fill") {}
        ControlButton(title: "停止", icon: "stop.fill") {}
            .tint(.red)
        ControlButton(title: "回零", icon: "arrow.down.to.line") {}
            .tint(.blue)
    }
    .padding()
} 