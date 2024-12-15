// 如果有设置页面
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // ... existing code ...
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(CustomNavigationConfigurator())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }
        }
    }
} 