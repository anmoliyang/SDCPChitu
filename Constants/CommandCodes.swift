enum CommandCode: Int {
    case startPrint = 0x80    // 128 开始打印
    case pausePrint = 0x81    // 129 暂停打印
    case stopPrint = 0x82     // 130 停止打印
    case resumePrint = 0x83   // 131 恢复打印
    case homeAxis = 0x84      // 132 回零操作
    case testPrint = 0x85     // 133 测试打印
} 