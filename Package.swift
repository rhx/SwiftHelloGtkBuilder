// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "HelloGtkBuilder",
    dependencies: [
        .package(name: "Gtk", url: "https://github.com/rhx/SwiftGtk.git", .branch("main")),
    ],
    targets: [
        .target(name: "HelloGtkBuilder", dependencies: ["Gtk"]),
    ]
)
