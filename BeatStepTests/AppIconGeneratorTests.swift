import XCTest
import UIKit

final class AppIconGeneratorTests: XCTestCase {

    func testGenerateAppIcon() throws {
        let size = CGSize(width: 1024, height: 1024)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        let image = renderer.image { context in
            let cgContext = context.cgContext
            let w = size.width
            let h = size.height

            // Background: near-black (surfaceBase)
            UIColor(white: 0.067, alpha: 1.0).setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))

            // ECG pulse path in #FF4545
            let strokeColor = UIColor(red: 1.0, green: 0.271, blue: 0.271, alpha: 1.0)
            strokeColor.setStroke()

            let path = UIBezierPath()
            let strokeWidth: CGFloat = w * 0.035 // ~36pt at 1024
            path.lineWidth = strokeWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            let centerY = h * 0.5

            // Flat baseline left: 15% to 35%
            path.move(to: CGPoint(x: w * 0.15, y: centerY))
            path.addLine(to: CGPoint(x: w * 0.35, y: centerY))

            // Small P-wave bump
            path.addLine(to: CGPoint(x: w * 0.38, y: centerY - h * 0.04))
            path.addLine(to: CGPoint(x: w * 0.40, y: centerY))

            // Sharp R-wave spike upward (30% above center)
            path.addLine(to: CGPoint(x: w * 0.44, y: centerY + h * 0.06))
            path.addLine(to: CGPoint(x: w * 0.48, y: centerY - h * 0.30))

            // S-wave trough (12% below center)
            path.addLine(to: CGPoint(x: w * 0.52, y: centerY + h * 0.12))

            // Return to baseline
            path.addLine(to: CGPoint(x: w * 0.55, y: centerY))

            // Small T-wave bump
            path.addLine(to: CGPoint(x: w * 0.60, y: centerY - h * 0.05))
            path.addLine(to: CGPoint(x: w * 0.65, y: centerY))

            // Flat baseline right: 65% to 85%
            path.addLine(to: CGPoint(x: w * 0.85, y: centerY))

            path.stroke()
        }

        // Validate image
        XCTAssertEqual(image.size.width, 1024, "Icon width must be 1024")
        XCTAssertEqual(image.size.height, 1024, "Icon height must be 1024")

        let pngData = try XCTUnwrap(image.pngData(), "Failed to create PNG data")
        XCTAssertGreaterThan(pngData.count, 0, "PNG data must not be empty")

        // Write to Asset Catalog path
        let outputPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // BeatStepTests/
            .deletingLastPathComponent()  // project root
            .appendingPathComponent("BeatStep/Resources/Assets.xcassets/AppIcon.appiconset/appicon-1024.png")

        try pngData.write(to: outputPath)

        // Verify written file
        let writtenData = try Data(contentsOf: outputPath)
        XCTAssertEqual(writtenData.count, pngData.count, "Written file must match generated data")
    }
}
