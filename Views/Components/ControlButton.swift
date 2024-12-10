import SwiftUI

/// 控制按钮
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
        ControlButton(title: "测试", icon: "play.fill") {}
        ControlButton(title: "停止", icon: "stop.fill") {}
            .tint(.red)
    }
    .padding()
} 