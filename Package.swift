// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "zaraDatabaseWrapper",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "zaraDatabaseWrapper",
            targets: ["zaraDatabaseWrapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/PerfectlySoft/Perfect-PostgreSQL.git", from: "3.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", from: "3.0.0"),
        .package(url: "https://github.com/mczachurski/Swiftgger.git", from: "1.2.1"),
        .package(url: "https://github.com/AliSoftware/Dip.git", from: "7.0.0"),
        .package(url: "https://github.com/IBM-Swift/Configuration.git", from: "3.0.1"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.0.3"),
        .package(url: "https://github.com/twostraws/SwiftGD.git", from: "2.0.0"),
        .package(url: "https://github.com/idi888/Perfect-SMTP.git", .branch("master")),
        .package(url: "https://github.com/idi888/Perfect-OAuth2.git", .branch("master")),
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "0.6.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-Notifications.git", from: "3.0.0"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-WebSockets.git", from: "3.0.0"),
        
        
//        .package(url: "https://github.com/idi888/databaseWrapper", .branch("master")),
//                .package(url: "https://github.com/idi888/projectConstants", .branch("master"))
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "zaraDatabaseWrapper",
            
            dependencies: ["PerfectPostgreSQL", "PerfectHTTPServer", "Swiftgger", "Dip", "Configuration", "SwiftProtobuf", "SwiftGD", "PerfectSMTP", "OAuth2", "SwiftGRPC", "PerfectNotifications", "PerfectWebSockets"],
            path: "Sources"),
        .testTarget(
            name: "zaraDatabaseWrapperTests",
            dependencies: ["zaraDatabaseWrapper"]),
    ]
)
