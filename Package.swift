// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "Meownitor",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "Meownitor", targets: ["Meownitor"])
  ],
  targets: [
    .executableTarget(name: "Meownitor"),
    .testTarget(name: "MeownitorTests", dependencies: ["Meownitor"]),
  ]
)
