import SwiftUI

/// 主按钮样式
struct PrimaryButtonStyle: ViewModifier {
    let backgroundColor: Color
    
    init(backgroundColor: Color = .black) {
        self.backgroundColor = backgroundColor
    }
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(backgroundColor)
            .cornerRadius(15)
    }
}

/// 快捷操作按钮样式
struct QuickActionButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 120, height: 80)
            .background(Color(.systemBackground))
            .cornerRadius(12)
    }
}

// 扩展 View 以便更方便地使用这些样式
extension View {
    func primaryButtonStyle(backgroundColor: Color = .black) -> some View {
        self.modifier(PrimaryButtonStyle(backgroundColor: backgroundColor))
    }
    
    func quickActionButtonStyle() -> some View {
        modifier(QuickActionButtonStyle())
    }
} 