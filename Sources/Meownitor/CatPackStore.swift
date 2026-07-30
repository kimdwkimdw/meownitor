import CryptoKit
import Foundation
import ImageIO

struct CatPack: Codable, Equatable {
  let id: String
  let version: Int
  let bytes: Int64
  let sha256: String
  let url: URL
}

struct CatPackCatalog: Codable, Equatable {
  let version: Int
  let packs: [CatPack]
}

enum CatPackError: LocalizedError {
  case unavailable
  case invalidResponse
  case invalidChecksum
  case invalidArchive
  case extractionFailed(String)

  var errorDescription: String? {
    switch self {
    case .unavailable:
      return "This cat is not available for download yet."
    case .invalidResponse:
      return "The cat download failed."
    case .invalidChecksum:
      return "The downloaded cat pack failed its integrity check."
    case .invalidArchive:
      return "The downloaded cat pack is incomplete or invalid."
    case .extractionFailed(let message):
      return "The cat pack could not be opened: \(message)"
    }
  }
}

final class CatPackStore {
  static let shared = CatPackStore()
  static let remoteCatalogURL = URL(
    string:
      "https://github.com/kimdwkimdw/meownitor/releases/download/cat-packs-v1/cat-packs.json"
  )!

  static let sequenceNames = [
    "00-idle.webp",
    "01-blink.webp",
    "02-breathe.webp",
    "03-look-left.webp",
    "04-look-right.webp",
    "05-look-up.webp",
    "06-look-down.webp",
    "07-ear-twitch.webp",
    "08-tail-swish.webp",
    "09-head-tilt-left.webp",
    "10-meow.webp",
    "11-yawn.webp",
    "12-paw-wave.webp",
    "13-groom.webp",
    "14-stretch.webp",
  ]

  private let fileManager: FileManager
  private let rootDirectory: URL
  private(set) var packsByID: [String: CatPack]

  init(
    fileManager: FileManager = .default,
    rootDirectory: URL? = nil,
    catalogURL: URL? = nil
  ) {
    self.fileManager = fileManager
    self.rootDirectory =
      rootDirectory
      ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Meownitor/Cats", isDirectory: true)

    let resolvedCatalogURL =
      catalogURL
      ?? Bundle.main.url(forResource: "cat-packs", withExtension: "json")
      ?? URL(fileURLWithPath: fileManager.currentDirectoryPath)
      .appendingPathComponent("Resources/CatPacks/cat-packs.json")
    let catalog = try? JSONDecoder().decode(
      CatPackCatalog.self,
      from: Data(contentsOf: resolvedCatalogURL)
    )
    let allowedIDs = Set(CatProfile.all.dropFirst().map(\.id))
    let packs = (catalog?.packs ?? []).filter {
      Self.isValid($0, allowedIDs: allowedIDs)
    }
    packsByID = Dictionary(uniqueKeysWithValues: packs.map { ($0.id, $0) })
  }

  func pack(for cat: CatProfile) -> CatPack? {
    packsByID[cat.id]
  }

  func refreshCatalog() async throws {
    let (data, response) = try await URLSession.shared.data(from: Self.remoteCatalogURL)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200,
      data.count <= 1_000_000
    else {
      throw CatPackError.invalidResponse
    }
    let catalog = try JSONDecoder().decode(CatPackCatalog.self, from: data)
    let allowedIDs = Set(CatProfile.all.dropFirst().map(\.id))
    var validated: [String: CatPack] = [:]
    for pack in catalog.packs {
      guard Self.isValid(pack, allowedIDs: allowedIDs), validated[pack.id] == nil
      else {
        throw CatPackError.invalidArchive
      }
      validated[pack.id] = pack
    }
    packsByID = validated
  }

  func isInstalled(_ cat: CatProfile) -> Bool {
    cat.id == "elsa" || sequenceURLs(for: cat).count == Self.sequenceNames.count
  }

  func sequenceURLs(for cat: CatProfile) -> [URL] {
    guard cat.id != "elsa" else { return [] }
    let directory = rootDirectory.appendingPathComponent(cat.id).appendingPathComponent("strips")
    return Self.sequenceNames.compactMap { name in
      let url = directory.appendingPathComponent(name)
      return fileManager.fileExists(atPath: url.path) ? url : nil
    }
  }

  func installedBytes(for cat: CatProfile) -> Int64 {
    sequenceURLs(for: cat).reduce(0) { total, url in
      let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
      return total + Int64(size)
    }
  }

  func install(_ cat: CatProfile) async throws {
    let allowedIDs = Set(CatProfile.all.dropFirst().map(\.id))
    guard let pack = pack(for: cat), Self.isValid(pack, allowedIDs: allowedIDs) else {
      throw CatPackError.unavailable
    }
    let (archive, response) = try await URLSession.shared.download(from: pack.url)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      throw CatPackError.invalidResponse
    }
    let fileManager = fileManager
    let rootDirectory = rootDirectory
    try await Task.detached(priority: .userInitiated) {
      guard try Self.sha256(of: archive) == pack.sha256.lowercased() else {
        throw CatPackError.invalidChecksum
      }
      let downloadedBytes =
        (try archive.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
        ?? -1
      guard downloadedBytes == pack.bytes else {
        throw CatPackError.invalidArchive
      }
      try Self.validateArchiveEntries(archive, catID: cat.id)

      let extraction = fileManager.temporaryDirectory
        .appendingPathComponent("Meownitor-\(UUID().uuidString)", isDirectory: true)
      defer { try? fileManager.removeItem(at: extraction) }
      try fileManager.createDirectory(at: extraction, withIntermediateDirectories: true)
      try Self.extract(archive, to: extraction)

      let extractedStrips = extraction.appendingPathComponent(cat.id).appendingPathComponent(
        "strips")
      try Self.validateStrips(at: extractedStrips, fileManager: fileManager)

      let staged = rootDirectory.appendingPathComponent(".\(cat.id)-\(UUID().uuidString)")
      let stagedStrips = staged.appendingPathComponent("strips")
      try fileManager.createDirectory(at: stagedStrips, withIntermediateDirectories: true)
      do {
        for name in Self.sequenceNames {
          try fileManager.copyItem(
            at: extractedStrips.appendingPathComponent(name),
            to: stagedStrips.appendingPathComponent(name)
          )
        }
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let destination = rootDirectory.appendingPathComponent(cat.id)
        if fileManager.fileExists(atPath: destination.path) {
          try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: staged, to: destination)
      } catch {
        try? fileManager.removeItem(at: staged)
        throw error
      }
    }.value
  }

  func remove(_ cat: CatProfile) throws {
    guard cat.id != "elsa" else { return }
    let directory = rootDirectory.appendingPathComponent(cat.id)
    if fileManager.fileExists(atPath: directory.path) {
      try fileManager.removeItem(at: directory)
    }
  }

  private static func sha256(of url: URL) throws -> String {
    let data = try Data(contentsOf: url, options: .mappedIfSafe)
    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
  }

  private static func isValid(_ pack: CatPack, allowedIDs: Set<String>) -> Bool {
    allowedIDs.contains(pack.id)
      && pack.version > 0
      && pack.bytes > 0
      && pack.bytes <= 500_000_000
      && pack.sha256.count == 64
      && pack.sha256.allSatisfy(\.isHexDigit)
      && pack.url.scheme == "https"
      && pack.url.host == "github.com"
      && pack.url.path.hasPrefix(
        "/kimdwkimdw/meownitor/releases/download/cat-packs-v1/"
      )
  }

  private static func validateArchiveEntries(_ archive: URL, catID: String) throws {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    process.arguments = ["-Z1", archive.path]
    process.standardOutput = output
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0,
      let listing = String(
        data: output.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8
      )
    else {
      throw CatPackError.invalidArchive
    }

    let entries = listing.split(whereSeparator: \.isNewline).map(String.init)
    guard archiveEntriesAreValid(entries, catID: catID) else {
      throw CatPackError.invalidArchive
    }
  }

  static func archiveEntriesAreValid(_ entries: [String], catID: String) -> Bool {
    let prefix = "\(catID)/"
    guard
      entries.allSatisfy({
        $0.hasPrefix(prefix)
          && !$0.hasPrefix("/")
          && !$0.contains("..")
          && !$0.contains("\\")
      })
    else {
      return false
    }
    let files = Set(entries.filter { !$0.hasSuffix("/") })
    let expected = Set(sequenceNames.map { "\(catID)/strips/\($0)" })
    return files == expected
  }

  private static func extract(_ archive: URL, to directory: URL) throws {
    let process = Process()
    let errors = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
    process.arguments = ["-x", "-k", archive.path, directory.path]
    process.standardError = errors
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      let data = errors.fileHandleForReading.readDataToEndOfFile()
      throw CatPackError.extractionFailed(
        String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
          ?? "Unknown error"
      )
    }
  }

  private static func validateStrips(at directory: URL, fileManager: FileManager) throws {
    let files = try fileManager.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles]
    )
    guard Set(files.map(\.lastPathComponent)) == Set(sequenceNames) else {
      throw CatPackError.invalidArchive
    }
    for file in files {
      let values = try file.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
      guard
        values.isRegularFile == true,
        values.isSymbolicLink != true,
        let source = CGImageSourceCreateWithURL(file as CFURL, nil),
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
          as? [CFString: Any],
        properties[kCGImagePropertyPixelWidth] as? Int == 8778,
        properties[kCGImagePropertyPixelHeight] as? Int == 1254
      else {
        throw CatPackError.invalidArchive
      }
    }
  }
}
