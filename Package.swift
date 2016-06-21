import PackageDescription

let package = Package(
    name: "HelloGtkBuilder",
    dependencies: [
        .Package(url: "https://github.com/rhx/SwiftGtk.git", majorVersion: 3)
    ]
)
