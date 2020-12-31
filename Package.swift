// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "HelloGtkBuilder",
    dependencies: [
        .package(name: "Gtk", url: "https://github.com/rhx/SwiftGtk.git", .branch("gtk4")),
    ],
    targets: [
        .target(name: "HelloGtkBuilder", dependencies: ["Gtk"]),
    ]
)
