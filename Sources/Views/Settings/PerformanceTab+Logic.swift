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
        viewModel.settings?.pauseOnBattery = enabled
        viewModel.save()
    }

    func setPauseOnFullscreen(_ enabled: Bool) {
        viewModel.settings?.pauseOnFullscreen = enabled
        viewModel.save()
    }

    func setPauseOnLowBattery(_ enabled: Bool) {
        viewModel.settings?.pauseOnLowBattery = enabled
        viewModel.save()
    }

    func setLowBatteryThreshold(_ threshold: Int) {
        viewModel.settings?.lowBatteryThreshold = threshold
        viewModel.save()
    }

    func setPauseOnScreenSharing(_ enabled: Bool) {
        viewModel.settings?.pauseOnScreenSharing = enabled
        viewModel.save()
    }

    func setPauseOnHighLoad(_ enabled: Bool) {
        viewModel.settings?.pauseOnHighLoad = enabled
        viewModel.save()
    }

    func setPauseOnLostFocus(_ enabled: Bool) {
        viewModel.settings?.pauseOnLostFocus = enabled
        viewModel.save()
    }

    func setPauseOnLidClosed(_ enabled: Bool) {
        viewModel.settings?.pauseOnLidClosed = enabled
        viewModel.save()
    }

    func setPauseBeforeSleep(_ enabled: Bool) {
        viewModel.settings?.pauseBeforeSleep = enabled
        viewModel.save()
    }

    func setPauseOnOcclusion(_ enabled: Bool) {
        viewModel.settings?.pauseOnOcclusion = enabled
        viewModel.save()
    }
}
