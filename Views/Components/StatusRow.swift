import SwiftUI

/// 通用状态行组件
struct StatusRow: View {
    let title: String
    let value: String
    var foregroundColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(foregroundColor)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(.systemBackground))
    }
}

#Preview {
    List {
        StatusRow(title: "测试标题", value: "测试值")
    }
} 