import SwiftUI

/// 文件管理视图
struct FileManagerView: View {
    let device: PrinterDevice
    @StateObject private var webSocketManager = WebSocketManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isUploading = false
    @State private var uploadProgress = 0.0
    @State private var showingFilePicker = false
    
    var body: some View {
        List {
            // 文件上传区域
            Section {
                Button(action: { showingFilePicker = true }) {
                    Label("上传文件", systemImage: "arrow.up.doc")
                }
                .disabled(isUploading)
                
                if isUploading {
                    VStack(spacing: 8) {
                        ProgressView(value: uploadProgress) {
                            Text("上传中... \(Int(uploadProgress * 100))%")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // TODO: 添加文��列表显示
        }
        .navigationTitle("文件管理")
        .navigationBarTitleDisplayMode(.inline)
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    uploadFile(from: url)
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func uploadFile(from url: URL) {
        isUploading = true
        uploadProgress = 0
        
        HTTPFileUploader.shared.uploadFile(
            at: url,
            to: device.ipAddress,
            progress: { progress in
                uploadProgress = progress
            },
            completion: { result in
                isUploading = false
                switch result {
                case .success:
                    // TODO: 刷新文件列表
                    break
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        )
    }
}

#Preview {
    NavigationView {
        FileManagerView(device: .preview)
    }
} 