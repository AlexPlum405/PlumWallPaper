import SwiftUI

extension EnhancementTab {
    func setSuperResolutionEnabled(_ enabled: Bool) {
        viewModel.setSuperResolutionEnabled(enabled)
    }

    func setSuperResolutionScale(_ scale: Int) {
        viewModel.setSuperResolutionScale(scale)
    }

    func setVideoEnhancementEnabled(_ enabled: Bool) {
        viewModel.setVideoEnhancementEnabled(enabled)
    }

    func setStatusBarShowFPS(_ enabled: Bool) {
        viewModel.setStatusBarShowFPS(enabled)
    }

    func setStatusBarShowMemory(_ enabled: Bool) {
        viewModel.setStatusBarShowMemory(enabled)
    }

    func setStatusBarShowGPU(_ enabled: Bool) {
        viewModel.setStatusBarShowGPU(enabled)
    }
}
