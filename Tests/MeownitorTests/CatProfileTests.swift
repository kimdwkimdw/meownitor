import ImageIO
import XCTest

@testable import Meownitor

final class CatProfileTests: XCTestCase {
  func testCatalogContainsElsaAndTwentyNamedCats() {
    XCTAssertEqual(CatProfile.all.count, 21)
    XCTAssertEqual(CatProfile.all.first?.id, "elsa")
    XCTAssertEqual(Set(CatProfile.all.map(\.id)).count, 21)
    XCTAssertEqual(Set(CatProfile.all.map(\.nameKo)).count, 21)
    XCTAssertEqual(Set(CatProfile.all.map(\.nameEn)).count, 21)
    XCTAssertEqual(CatProfile.all.filter { $0.id.hasPrefix("K") }.count, 10)
    XCTAssertEqual(CatProfile.all.filter { $0.id.hasPrefix("U") }.count, 10)
  }

  func testCatPackCatalogAndRemoval() throws {
    let temporary = FileManager.default.temporaryDirectory
      .appendingPathComponent("MeownitorTests-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: temporary) }
    try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)

    let catalogURL = temporary.appendingPathComponent("cat-packs.json")
    let pack = CatPack(
      id: "K02",
      version: 1,
      bytes: 123,
      sha256: String(repeating: "a", count: 64),
      url: URL(
        string:
          "https://github.com/kimdwkimdw/meownitor/releases/download/cat-packs-v1/Meownitor-Cat-K02-v1.zip"
      )!
    )
    try JSONEncoder().encode(CatPackCatalog(version: 1, packs: [pack])).write(to: catalogURL)

    let root = temporary.appendingPathComponent("installed")
    let store = CatPackStore(rootDirectory: root, catalogURL: catalogURL)
    XCTAssertEqual(store.pack(for: CatProfile.all[2]), pack)
    XCTAssertFalse(store.isInstalled(CatProfile.all[2]))

    let strips = root.appendingPathComponent("K02/strips")
    try FileManager.default.createDirectory(at: strips, withIntermediateDirectories: true)
    for name in CatPackStore.sequenceNames {
      XCTAssertTrue(
        FileManager.default.createFile(
          atPath: strips.appendingPathComponent(name).path, contents: Data()))
    }
    XCTAssertTrue(store.isInstalled(CatProfile.all[2]))
    try store.remove(CatProfile.all[2])
    XCTAssertFalse(store.isInstalled(CatProfile.all[2]))
  }

  func testCatPackArchiveRejectsUnexpectedAndTraversingEntries() {
    let valid =
      ["K02/", "K02/strips/"]
      + CatPackStore.sequenceNames.map { "K02/strips/\($0)" }
    XCTAssertTrue(CatPackStore.archiveEntriesAreValid(valid, catID: "K02"))
    XCTAssertFalse(
      CatPackStore.archiveEntriesAreValid(
        valid + ["K02/strips/extra.webp"],
        catID: "K02"
      )
    )
    XCTAssertFalse(
      CatPackStore.archiveEntriesAreValid(
        valid + ["K02/../escape.webp"],
        catID: "K02"
      )
    )
  }
}
