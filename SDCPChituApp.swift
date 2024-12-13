//
//  SDCPChituApp.swift
//  SDCPChitu
//
//  Created by 杨俊文 on 2024/12/9.
//

import SwiftUI

@main
struct SDCPChituApp: App {
    init() {
        // 统一设置导航栏样式
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1.0)
        appearance.shadowColor = .clear
        
        // 应用到所有导航栏
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
