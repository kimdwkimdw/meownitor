import AppKit
import XCTest

@testable import Meownitor

final class SpriteAssetTests: XCTestCase {
  func testEscapeNeedsTwoPressesWithinTwoSeconds() {
    var state = EscapeDismissalState()

    XCTAssertEqual(state.press(at: 10), .showHint)
    XCTAssertEqual(state.press(at: 10.01), .ignore)
    XCTAssertEqual(state.press(at: 12.1), .showHint)
    XCTAssertEqual(state.press(at: 13), .dismiss)
  }

  func testOverlaysUseOnlyTheBuiltInDisplay() {
    XCTAssertEqual(
      OverlayController.targetScreenIndex(for: [false, true, false]),
      1
    )
    XCTAssertEqual(
      OverlayController.targetScreenIndex(for: [true, false]),
      0
    )
    XCTAssertNil(
      OverlayController.targetScreenIndex(for: [false, false])
    )
  }

  func testSpriteSupportsSevenFrameHorizontalStrips() throws {
    let context = try XCTUnwrap(
      CGContext(
        data: nil,
        width: 700,
        height: 100,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    )
    let frames = SpriteView.frames(from: try XCTUnwrap(context.makeImage()))

    XCTAssertEqual(frames.count, 7)
    XCTAssertTrue(frames.allSatisfy { $0.width == 100 && $0.height == 100 })
  }

  func testBundledElsaContainsFifteenSevenFrameStrips() throws {
    let directory = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("Resources/ElsaHD/runtime")
    guard FileManager.default.fileExists(atPath: directory.path) else {
      throw XCTSkip("Runtime artwork is distributed as a GitHub Release asset.")
    }
    let urls = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil
    ).filter { $0.pathExtension == "webp" }

    XCTAssertEqual(urls.count, 15)
    for url in urls {
      let image = try XCTUnwrap(NSImage(contentsOf: url))
      let atlas = try XCTUnwrap(
        image.cgImage(forProposedRect: nil, context: nil, hints: nil)
      )
      XCTAssertEqual(atlas.width, 8778)
      XCTAssertEqual(atlas.height, 1254)
      let frames = SpriteView.frames(from: atlas)
      XCTAssertEqual(frames.count, 7)
      for frame in frames {
        XCTAssertEqual(frame.width, 1254)
        XCTAssertEqual(frame.height, 1254)
        XCTAssertTrue(hasVisiblePixel(frame))
        XCTAssertEqual(alpha(frame, x: 0, y: 0), 0)
        XCTAssertEqual(alpha(frame, x: frame.width - 1, y: 0), 0)
        XCTAssertEqual(alpha(frame, x: 0, y: frame.height - 1), 0)
        XCTAssertEqual(alpha(frame, x: frame.width - 1, y: frame.height - 1), 0)
      }
    }
  }

  private func hasVisiblePixel(_ image: CGImage) -> Bool {
    let bitmap = NSBitmapImageRep(cgImage: image)
    return stride(from: 0, to: image.height, by: 20).contains { y in
      stride(from: 0, to: image.width, by: 20).contains { x in
        alpha(bitmap, x: x, y: y) > 0.5
      }
    }
  }

  private func alpha(_ image: CGImage, x: Int, y: Int) -> CGFloat {
    alpha(NSBitmapImageRep(cgImage: image), x: x, y: y)
  }

  private func alpha(_ bitmap: NSBitmapImageRep, x: Int, y: Int) -> CGFloat {
    bitmap.colorAt(x: x, y: y)?.alphaComponent ?? 0
  }
}
