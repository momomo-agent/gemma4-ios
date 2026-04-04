// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Gemma4iOS",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Gemma4iOS", targets: ["Gemma4iOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.31.0"),
        // Local fork with Gemma 4 support (patched from PR #180)
        .package(path: "/tmp/mlx-swift-lm-gemma4")
    ],
    targets: [
        .target(
            name: "Gemma4iOS",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-lm-gemma4"),
                .product(name: "MLXVLM", package: "mlx-swift-lm-gemma4"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm-gemma4")
            ]
        )
    ]
)
