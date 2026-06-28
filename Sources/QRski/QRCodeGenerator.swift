import CQREncode
import Foundation

struct QRMatrix {
    let width: Int
    let modules: [[Bool]]
}

struct QRCodeResult {
    let matrix: QRMatrix
    let version: Int
}

enum QRCodeGenerator {
    static func generate(text: String, version: Int, maskPattern: Int, ecl: QRecLevel) -> QRCodeResult? {
        guard let input = QRinput_new2(Int32(version), ecl) else { return nil }
        defer { QRinput_free(input) }

        let bytes = Array(text.utf8)
        let appendResult: Int32 = bytes.withUnsafeBytes { rawPtr in
            guard let ptr = rawPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return -1 }
            return QRinput_append(input, QR_MODE_8, Int32(bytes.count), ptr)
        }
        guard appendResult == 0 else { return nil }

        guard let qrcode = QRcode_encodeMask(input, Int32(maskPattern)) else { return nil }
        defer { QRcode_free(qrcode) }

        let w = Int(qrcode.pointee.width)
        let v = Int(qrcode.pointee.version)
        guard let data = qrcode.pointee.data, w > 0 else { return nil }

        var modules = [[Bool]](repeating: [Bool](repeating: false, count: w), count: w)
        for y in 0..<w {
            for x in 0..<w {
                modules[y][x] = (data[y * w + x] & 0x01) != 0
            }
        }

        return QRCodeResult(matrix: QRMatrix(width: w, modules: modules), version: v)
    }
}
