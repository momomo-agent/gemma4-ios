# Gemma 4 iOS

在 iPhone 上运行 Google Gemma 4 模型，支持文字、语音、图片输入。

## 模型

| 模型 | 参数量 | 大小 | 能力 |
|------|--------|------|------|
| Gemma 4 E2B | 2.3B effective (5.1B w/ embeddings) | ~3GB | 文字 + 图片 |
| Gemma 4 E4B | 4.5B effective (8B w/ embeddings) | ~5GB | 文字 + 图片 |

首次启动自动从 Hugging Face 下载模型。

## 技术栈

- **MLX Swift**: Apple Silicon 加速推理
- **MLXVLM**: Vision-Language Model 支持（Gemma 4 架构）
- **Speech Framework**: 语音转文字
- **PhotosPicker**: 图片选择

## 构建

```bash
xcodegen generate
open Gemma4iOS.xcodeproj
# 选择真机设备构建
```

## 依赖

- mlx-swift 0.31+
- mlx-swift-lm（Gemma 4 fork，PR #180 合并后切回主仓）

## 系统要求

- iOS 17.0+
- E2B: iPhone 12+（6GB+ RAM）
- E4B: iPhone 15 Pro+（8GB+ RAM）
