#if DEBUG
    /// 调试模式下模拟连接
    func connect(to device: PrinterDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        if device.id.starts(with: "DEBUG") {
            // 模拟成功连接
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.currentStatus = PrintStatus(
                    currentStatus: .printing,
                    previousStatus: .idle,
                    printScreenTime: 0,
                    releaseFilmCount: 0,
                    uvledTemperature: 25.0,
                    timeLapseEnabled: false,
                    boxTemperature: 25.0,
                    boxTargetTemperature: 25.0,
                    printInfo: nil,
                    devicesStatus: .debugDefault
                )
                completion(.success(()))
            }
            return
        }
        // 正常连接逻辑...
    }
#endif 