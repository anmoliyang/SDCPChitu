import SwiftUI

/// 状态信息行
struct DeviceStatusRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

#Preview {
    List {
        DeviceStatusRow(title: "测试标题", value: "测试值")
    }
} 