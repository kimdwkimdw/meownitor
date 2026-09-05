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
    XCTAssertEqual(CatProfile.bundledIDs, ["elsa", "K01", "K02", "K03"])
  }

  func testCatPackCatalogAndRemoval() throws {
    let temporary = FileManager.default.temporaryDirectory
      .appendingPathComponent("MeownitorTests-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: temporary) }
    try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)

    let catalogURL = temporary.appendingPathComponent("cat-packs.json")
    let bundledPack = CatPack(
      id: "K02", version: 1, bytes: 123, sha256: String(repeating: "a", count: 64),
      url: URL(
        string:
          "https://github.com/kimdwkimdw/meownitor/releases/download/v0.3.0-alpha.1/Meownitor-Cat-K02-v1.zip"
      )!)
    let pack = CatPack(
      id: "K04",
      version: 1,
      bytes: 123,
      sha256: String(repeating: "a", count: 64),
      url: URL(
        string:
          "https://github.com/kimdwkimdw/meownitor/releases/download/v0.3.0-alpha.1/Meownitor-Cat-K04-v1.zip"
      )!
    )
    try JSONEncoder().encode(CatPackCatalog(version: 1, packs: [bundledPack, pack])).write(
      to: catalogURL)

    let root = temporary.appendingPathComponent("installed")
    let store = CatPackStore(rootDirectory: root, catalogURL: catalogURL)
    let bundledCat = CatProfile.all[2]
    let downloadableCat = CatProfile.all[4]
    XCTAssertNil(store.pack(for: bundledCat))
    XCTAssertTrue(store.isInstalled(bundledCat))
    XCTAssertEqual(store.pack(for: downloadableCat), pack)
    XCTAssertFalse(store.isInstalled(downloadableCat))

    let strips = root.appendingPathComponent("K04/strips")
    try FileManager.default.createDirectory(at: strips, withIntermediateDirectories: true)
    for name in CatPackStore.sequenceNames {
      XCTAssertTrue(
        FileManager.default.createFile(
          atPath: strips.appendingPathComponent(name).path, contents: Data()))
    }
    XCTAssertTrue(store.isInstalled(downloadableCat))
    try store.remove(downloadableCat)
    XCTAssertFalse(store.isInstalled(downloadableCat))
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

  func testPublishedCatInstallAndRemoval() async throws {
    guard ProcessInfo.processInfo.environment["MEOWNITOR_RELEASE_SMOKE"] == "1" else {
      throw XCTSkip("Set MEOWNITOR_RELEASE_SMOKE=1 to test the published alpha in temporary storage.")
    }
    let temporary = FileManager.default.temporaryDirectory
      .appendingPathComponent("MeownitorReleaseSmoke-\(UUID().uuidString)")
    defer { try? FileManager.default.removeItem(at: temporary) }
    let store = CatPackStore(rootDirectory: temporary)
    try await store.refreshCatalog()
    XCTAssertEqual(store.packsByID.count, 17)
    let cat = try XCTUnwrap(CatProfile.all.first { $0.id == "K04" })
    XCTAssertFalse(store.isInstalled(cat))
    try await store.install(cat)
    XCTAssertTrue(store.isInstalled(cat))
    XCTAssertEqual(store.sequenceURLs(for: cat).count, 15)
    XCTAssertGreaterThan(store.installedBytes(for: cat), 0)
    try store.remove(cat)
    XCTAssertFalse(store.isInstalled(cat))
  }
}
