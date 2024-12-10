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
    @State private var files: [PrintFile] = []
    
    var body: some View {
        List {
            // 文件上传区域
            Section {
                Button {
                    showingFilePicker = true
                } label: {
                    Label("上传文件", systemImage: "arrow.up.doc")
                }
                .disabled(isUploading)
                
                if isUploading {
                    ProgressView(value: uploadProgress) {
                        Text("上传中 \(Int(uploadProgress * 100))%")
                    }
                }
            }
            
            // 文件列表区域
            Section("文件列表") {
                if files.isEmpty {
                    ContentUnavailableView {
                        Label("暂无文件", systemImage: "doc")
                    } description: {
                        Text("点击上方按钮上传文件")
                    }
                } else {
                    ForEach(files) { file in
                        FileListItem(file: file) {
                            confirmDelete(file)
                        }
                    }
                }
            }
        }
        .navigationTitle("文件管理")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    uploadFile(url)
                }
            case .failure(let error):
                showError("选择文件失败: \(error.localizedDescription)")
            }
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            refreshFileList()
        }
    }
    
    private func uploadFile(_ url: URL) {
        isUploading = true
        uploadProgress = 0.0
        
        HTTPFileUploader.shared.uploadFile(url, to: device) { progress in
            self.uploadProgress = progress
        } completion: { result in
            DispatchQueue.main.async {
                self.isUploading = false
                switch result {
                case .success:
                    self.refreshFileList()
                case .failure(let error):
                    self.showError("上传失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func refreshFileList() {
        let message: [String: Any] = [
            "Id": UUID().uuidString,
            "Data": [
                "Cmd": 258,
                "Data": [
                    "Url": "/local/"
                ],
                "RequestID": UUID().uuidString,
                "MainboardID": device.id,
                "TimeStamp": Int(Date().timeIntervalSince1970),
                "From": 0
            ],
            "Topic": "sdcp/request/\(device.id)"
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            webSocketManager.sendCommand(jsonString)
        }
    }
    
    private func confirmDelete(_ file: PrintFile) {
        let message: [String: Any] = [
            "Id": UUID().uuidString,
            "Data": [
                "Cmd": 259,
                "Data": [
                    "FileList": [file.name],
                    "FolderList": []
                ],
                "RequestID": UUID().uuidString,
                "MainboardID": device.id,
                "TimeStamp": Int(Date().timeIntervalSince1970),
                "From": 0
            ],
            "Topic": "sdcp/request/\(device.id)"
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            webSocketManager.sendCommand(jsonString)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                refreshFileList()
            }
        }
    }
    
    private func handleFileList(_ response: [String: Any]) {
        guard let data = response["Data"] as? [String: Any],
              let fileList = data["FileList"] as? [[String: Any]] else {
            return
        }
        
        files = fileList.compactMap { fileDict in
            guard let name = fileDict["name"] as? String,
                  let type = fileDict["type"] as? Int,
                  let usedSize = fileDict["usedSize"] as? Int64 else {
                return nil
            }
            
            // 只显示文件，不显示文件夹
            guard type == 1 else { return nil }
            
            return PrintFile(
                id: UUID().uuidString, // 生成临时ID
                name: name,
                size: usedSize,
                md5: "", // 服务器没有返回MD5
                uploadTime: Date(), // 服务器没有返回上传时间
                status: .ready
            )
        }
    }
    
    /// 显示错误信息
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

struct FileListItem: View {
    let file: PrintFile
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(file.name)
                    .font(.headline)
                Text(file.size.formatFileSize())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
        }
    }
}

#Preview {
    NavigationView {
        FileManagerView(device: .preview)
    }
} 