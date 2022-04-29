// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "HelloGtkBuilder",
    dependencies: [
        .package(url: "https://github.com/rhx/SwiftGtk.git", branch: "gtk4-monorepo"),
    ],
    targets: [
        .executableTarget(
            name: "HelloGtkBuilder", 
            dependencies: [
                .product(name: "Gtk", package: "SwiftGtk")
            ],
            resources: [ .process("Resources") ]
        ),
    ]
)
