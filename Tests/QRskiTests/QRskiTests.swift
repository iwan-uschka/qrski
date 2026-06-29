import XCTest
import SwiftUI
@testable import QRskiCore

// MARK: - QRCodeGenerator

final class QRCodeGeneratorTests: XCTestCase {
    // QR version n occupies (n * 4 + 17) modules per side
    private func expectedWidth(_ version: Int) -> Int { version * 4 + 17 }

    func testVersion1() throws {
        let r = try XCTUnwrap(QRCodeGenerator.generate(text: "Hi", version: 1, maskPattern: -1, ecl: ErrorCorrectionLevel.M))
        XCTAssertEqual(r.version, 1)
        XCTAssertEqual(r.matrix.width, 21)
    }

    func testVersion2() throws {
        let r = try XCTUnwrap(QRCodeGenerator.generate(text: "Hi", version: 2, maskPattern: -1, ecl: ErrorCorrectionLevel.M))
        XCTAssertEqual(r.matrix.width, 25)
    }

    func testVersion40() throws {
        let r = try XCTUnwrap(QRCodeGenerator.generate(text: "test", version: 40, maskPattern: -1, ecl: ErrorCorrectionLevel.L))
        XCTAssertEqual(r.version, 40)
        XCTAssertEqual(r.matrix.width, 177)
    }

    func testAutoVersionPicksSmallest() throws {
        // "Hi" fits in version 1 for ECL M
        let r = try XCTUnwrap(QRCodeGenerator.generate(text: "Hi", version: 0, maskPattern: -1, ecl: ErrorCorrectionLevel.M))
        XCTAssertEqual(r.version, 1)
    }

    func testWidthMatchesVersionFormula() throws {
        for v in [1, 5, 10, 20, 40] {
            let r = try XCTUnwrap(
                QRCodeGenerator.generate(text: "test", version: v, maskPattern: -1, ecl: ErrorCorrectionLevel.L),
                "version \(v)"
            )
            XCTAssertEqual(r.matrix.width, expectedWidth(v), "version \(v)")
        }
    }

    func testAllMaskPatternsProduceResults() {
        for mask in 0...7 {
            XCTAssertNotNil(
                QRCodeGenerator.generate(text: "test", version: 1, maskPattern: mask, ecl: ErrorCorrectionLevel.M),
                "mask \(mask)"
            )
        }
    }

    func testAutoMaskPattern() {
        XCTAssertNotNil(
            QRCodeGenerator.generate(text: "test", version: 0, maskPattern: -1, ecl: ErrorCorrectionLevel.M)
        )
    }

    func testAllECLevels() {
        for ecl in ErrorCorrectionLevel.allCases {
            XCTAssertNotNil(
                QRCodeGenerator.generate(text: "test", version: 0, maskPattern: -1, ecl: ecl),
                "ECL \(ecl)"
            )
        }
    }

    func testEmptyStringReturnsNil() {
        XCTAssertNil(
            QRCodeGenerator.generate(text: "", version: 0, maskPattern: -1, ecl: ErrorCorrectionLevel.M)
        )
    }

    func testURLText() throws {
        let r = try XCTUnwrap(
            QRCodeGenerator.generate(text: "https://example.com", version: 0, maskPattern: -1, ecl: ErrorCorrectionLevel.M)
        )
        XCTAssertGreaterThan(r.matrix.width, 0)
    }

    func testUTF8WithEmoji() throws {
        let r = try XCTUnwrap(
            QRCodeGenerator.generate(text: "Hello 🌍", version: 0, maskPattern: -1, ecl: ErrorCorrectionLevel.M)
        )
        XCTAssertGreaterThan(r.matrix.width, 0)
    }

    func testModuleMatrixIsSquare() throws {
        let r = try XCTUnwrap(
            QRCodeGenerator.generate(text: "test", version: 1, maskPattern: -1, ecl: ErrorCorrectionLevel.M)
        )
        XCTAssertEqual(r.matrix.modules.count, r.matrix.width)
        for row in r.matrix.modules {
            XCTAssertEqual(row.count, r.matrix.width)
        }
    }

    func testHigherECLUsesLargerOrEqualVersion() throws {
        let low = try XCTUnwrap(QRCodeGenerator.generate(text: "Hello World", version: 0, maskPattern: -1, ecl: ErrorCorrectionLevel.L))
        let high = try XCTUnwrap(QRCodeGenerator.generate(text: "Hello World", version: 0, maskPattern: -1, ecl: ErrorCorrectionLevel.H))
        XCTAssertLessThanOrEqual(low.version, high.version)
    }
}

// MARK: - SVG export

final class SVGExportTests: XCTestCase {
    private let qz = ExportCore.quietZone

    private func blankMatrix(width: Int) -> QRMatrix {
        QRMatrix(width: width, modules: Array(repeating: Array(repeating: false, count: width), count: width))
    }

    private func solidMatrix(width: Int) -> QRMatrix {
        QRMatrix(width: width, modules: Array(repeating: Array(repeating: true, count: width), count: width))
    }

    func testSVGOpenAndCloseTag() {
        let svg = ExportCore.generateSVG(matrix: blankMatrix(width: 5), fg: .black, bg: .white)
        XCTAssertTrue(svg.hasPrefix("<svg "))
        XCTAssertTrue(svg.hasSuffix("</svg>"))
    }

    func testSVGViewBoxIncludesQuietZone() {
        let svg = ExportCore.generateSVG(matrix: blankMatrix(width: 5), fg: .black, bg: .white)
        let total = 5 + 2 * qz
        XCTAssertTrue(svg.contains("viewBox=\"0 0 \(total) \(total)\""))
    }

    func testSVGOpaqueBackgroundHasRect() {
        let svg = ExportCore.generateSVG(matrix: blankMatrix(width: 5), fg: .black, bg: .white)
        XCTAssertTrue(svg.contains("<rect "))
    }

    func testSVGTransparentBackgroundHasNoRect() {
        let svg = ExportCore.generateSVG(matrix: blankMatrix(width: 5), fg: .black, bg: nil)
        XCTAssertFalse(svg.contains("<rect "))
    }

    func testSVGPathPresentForDarkModules() {
        let svg = ExportCore.generateSVG(matrix: solidMatrix(width: 5), fg: .black, bg: nil)
        XCTAssertTrue(svg.contains("<path "))
    }

    func testSVGNoPathForAllLightMatrix() {
        let svg = ExportCore.generateSVG(matrix: blankMatrix(width: 5), fg: .black, bg: nil)
        XCTAssertFalse(svg.contains("<path "))
    }

    func testSVGModuleOffsetByQuietZone() {
        // Only the top-left module is dark; its path command must be offset by quietZone
        let m = QRMatrix(width: 3, modules: [
            [true,  false, false],
            [false, false, false],
            [false, false, false]
        ])
        let svg = ExportCore.generateSVG(matrix: m, fg: .black, bg: nil)
        XCTAssertTrue(svg.contains("M\(qz) \(qz)h1v1h-1z"), "Module (0,0) should map to M\(qz) \(qz)")
    }

    func testSVGBlackForeground() {
        let svg = ExportCore.generateSVG(matrix: solidMatrix(width: 3), fg: .black, bg: nil)
        XCTAssertTrue(svg.contains("fill=\"#000000\""))
    }

    func testHexStringBlack() {
        XCTAssertEqual(ExportCore.hexString(.black), "#000000")
    }

    func testHexStringWhite() {
        XCTAssertEqual(ExportCore.hexString(.white), "#FFFFFF")
    }

    func testHexStringFormat() {
        let hex = ExportCore.hexString(.red)
        XCTAssertTrue(hex.hasPrefix("#"))
        XCTAssertEqual(hex.count, 7)
    }

    func testSVGWithRealQRCode() throws {
        let r = try XCTUnwrap(
            QRCodeGenerator.generate(text: "https://example.com", version: 0, maskPattern: -1, ecl: ErrorCorrectionLevel.M)
        )
        let svg = ExportCore.generateSVG(matrix: r.matrix, fg: .black, bg: .white)
        XCTAssertTrue(svg.contains("<path "), "Real QR code must contain dark modules")
        XCTAssertTrue(svg.contains("<rect "))
    }
}

// MARK: - PNG export

final class PNGExportTests: XCTestCase {
    private static let pngMagic: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    private func solidMatrix(width: Int) -> QRMatrix {
        QRMatrix(width: width, modules: Array(repeating: Array(repeating: true, count: width), count: width))
    }

    func testPNGReturnsData() {
        XCTAssertNotNil(
            ExportCore.generatePNG(matrix: solidMatrix(width: 5), moduleSize: 10, fg: .black, bg: .white)
        )
    }

    func testPNGStartsWithMagicBytes() throws {
        let data = try XCTUnwrap(
            ExportCore.generatePNG(matrix: solidMatrix(width: 5), moduleSize: 10, fg: .black, bg: .white)
        )
        XCTAssertEqual([UInt8](data.prefix(8)), Self.pngMagic)
    }

    func testPNGTransparentBackgroundReturnsData() throws {
        let data = try XCTUnwrap(
            ExportCore.generatePNG(matrix: solidMatrix(width: 5), moduleSize: 10, fg: .black, bg: nil)
        )
        XCTAssertEqual([UInt8](data.prefix(8)), Self.pngMagic)
    }

    func testPNGWithRealQRCode() throws {
        let r = try XCTUnwrap(
            QRCodeGenerator.generate(text: "test", version: 1, maskPattern: -1, ecl: ErrorCorrectionLevel.M)
        )
        let data = try XCTUnwrap(
            ExportCore.generatePNG(matrix: r.matrix, moduleSize: 8, fg: .black, bg: .white)
        )
        XCTAssertEqual([UInt8](data.prefix(8)), Self.pngMagic)
    }
}

// MARK: - ErrorCorrectionLevel

final class ErrorCorrectionLevelTests: XCTestCase {
    func testFourCases() {
        XCTAssertEqual(ErrorCorrectionLevel.allCases.count, 4)
    }

    func testRawValues() {
        XCTAssertEqual(ErrorCorrectionLevel.L.rawValue, 0)
        XCTAssertEqual(ErrorCorrectionLevel.M.rawValue, 1)
        XCTAssertEqual(ErrorCorrectionLevel.Q.rawValue, 2)
        XCTAssertEqual(ErrorCorrectionLevel.H.rawValue, 3)
    }

    func testLabels() {
        XCTAssertTrue(ErrorCorrectionLevel.L.label.contains("Low"))
        XCTAssertTrue(ErrorCorrectionLevel.M.label.contains("Medium"))
        XCTAssertTrue(ErrorCorrectionLevel.Q.label.contains("Quartile"))
        XCTAssertTrue(ErrorCorrectionLevel.H.label.contains("High"))
    }

    func testRoundTrip() {
        for ecl in ErrorCorrectionLevel.allCases {
            XCTAssertEqual(ErrorCorrectionLevel(rawValue: ecl.rawValue), ecl)
        }
    }
}

// MARK: - isVersionNewer

final class VersionComparisonTests: XCTestCase {
    func testPatchBump() {
        XCTAssertTrue(isVersionNewer("1.0.1", than: "1.0.0"))
    }

    func testMinorBump() {
        XCTAssertTrue(isVersionNewer("1.1.0", than: "1.0.0"))
    }

    func testMajorBump() {
        XCTAssertTrue(isVersionNewer("2.0.0", than: "1.9.9"))
    }

    func testMinorDoesNotWrapAround() {
        XCTAssertTrue(isVersionNewer("1.10.0", than: "1.9.0"))
    }

    func testEqualVersions() {
        XCTAssertFalse(isVersionNewer("1.0.0", than: "1.0.0"))
    }

    func testOlderRemote() {
        XCTAssertFalse(isVersionNewer("1.0.0", than: "1.0.1"))
    }

    func testVPrefixStripped() {
        XCTAssertTrue(isVersionNewer("v1.1.0", than: "1.0.0"))
    }

    func testTwoComponentVsThree() {
        XCTAssertFalse(isVersionNewer("1.0.0", than: "1.0"))
    }

    func testTwoComponentNewer() {
        XCTAssertTrue(isVersionNewer("1.1", than: "1.0.0"))
    }

    func testZeroVersions() {
        XCTAssertFalse(isVersionNewer("0.0.0", than: "0.0.0"))
    }
}
