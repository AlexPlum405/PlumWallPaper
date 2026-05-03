import SwiftUI

extension PerformanceTab {
    // MARK: - 业务逻辑

    func setFPSLimit(_ limit: Int) {
        viewModel.setFPSLimit(limit)
    }

    func setVSyncEnabled(_ enabled: Bool) {
        viewModel.settings?.vSyncEnabled = enabled
        viewModel.save()
    }

    func setPauseOnBattery(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnBattery, enabled)
    }

    func setPauseOnFullscreen(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnFullscreen, enabled)
    }

    func setPauseOnLowBattery(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnLowBattery, enabled)
    }

    func setLowBatteryThreshold(_ threshold: Int) {
        viewModel.settings?.lowBatteryThreshold = threshold
        viewModel.save()
        PauseStrategyManager.shared.reevaluate()
    }

    func setPauseOnScreenSharing(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnScreenSharing, enabled)
    }

    func setPauseOnHighLoad(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnHighLoad, enabled)
    }

    func setPauseOnLostFocus(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnLostFocus, enabled)
    }

    func setPauseOnLidClosed(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnLidClosed, enabled)
    }

    func setPauseBeforeSleep(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseBeforeSleep, enabled)
    }

    func setPauseOnOcclusion(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnOcclusion, enabled)
    }
}
