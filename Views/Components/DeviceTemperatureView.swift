import SwiftUI

/// 设备温度视图
struct DeviceTemperatureView: View {
    let status: PrintStatus
    
    var body: some View {
        VStack {
            DeviceStatusRow(title: "UVLED温度", 
                          value: String(format: "%.1f°C", status.uvledTemperature))
                .foregroundColor(getTemperatureColor(status.uvledTemperature))
            
            DeviceStatusRow(title: "箱体温度", 
                          value: String(format: "%.1f°C / %.1f°C", 
                                      status.boxTemperature,
                                      status.boxTargetTemperature))
                .foregroundColor(getTemperatureColor(status.boxTemperature))
        }
    }
    
    private func getTemperatureColor(_ temperature: Double) -> Color {
        if temperature > 60 {
            return .red
        } else if temperature > 45 {
            return .orange
        } else if temperature < 15 {
            return .blue
        } else {
            return .green
        }
    }
}