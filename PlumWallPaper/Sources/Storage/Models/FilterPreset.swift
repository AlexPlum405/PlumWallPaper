//
//  FilterPreset.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import Foundation
import SwiftData

/// 色彩滤镜预设数据模型
@Model
final class FilterPreset {
    /// 唯一标识符
    var id: UUID

    /// 预设名称
    var name: String

    /// 曝光度（0-200，100 为默认）
    var exposure: Double

    /// 对比度（0-200，100 为默认）
    var contrast: Double

    /// 饱和度（0-200，100 为默认）
    var saturation: Double

    /// 色调（-180 到 180）
    var hue: Double

    /// 模糊（0-20 px）
    var blur: Double

    /// 颗粒感（0-100）
    var grain: Double

    /// 暗角（0-100）
    var vignette: Double

    /// 灰度（0-100%）
    var grayscale: Double

    /// 反转（0-100%）
    var invert: Double

    init(
        id: UUID = UUID(),
        name: String,
        exposure: Double = 100,
        contrast: Double = 100,
        saturation: Double = 100,
        hue: Double = 0,
        blur: Double = 0,
        grain: Double = 0,
        vignette: Double = 0,
        grayscale: Double = 0,
        invert: Double = 0
    ) {
        self.id = id
        self.name = name
        self.exposure = exposure
        self.contrast = contrast
        self.saturation = saturation
        self.hue = hue
        self.blur = blur
        self.grain = grain
        self.vignette = vignette
        self.grayscale = grayscale
        self.invert = invert
    }
}

// MARK: - Preset Factory
extension FilterPreset {
    static let film = FilterPreset(
        name: "胶片",
        exposure: 105,
        contrast: 120,
        saturation: 90,
        grain: 25,
        vignette: 15
    )

    static let midnight = FilterPreset(
        name: "深夜",
        exposure: 80,
        contrast: 140,
        saturation: 110,
        hue: -10,
        vignette: 20
    )

    static let vintage = FilterPreset(
        name: "复古",
        exposure: 95,
        contrast: 110,
        saturation: 85,
        hue: 15,
        grain: 20,
        vignette: 10
    )
}
