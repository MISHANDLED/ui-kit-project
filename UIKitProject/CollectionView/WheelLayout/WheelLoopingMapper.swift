import CoreGraphics

struct WheelLoopingMapper {
    let itemsPerCycle: Int
    let cycleCount: Int

    init(itemsPerCycle: Int, cycleCount: Int = 9) {
        self.itemsPerCycle = max(itemsPerCycle, 1)
        self.cycleCount = max(cycleCount, 5)
    }

    var totalItemCount: Int {
        itemsPerCycle * cycleCount
    }

    var middleCycle: Int {
        cycleCount / 2
    }

    func virtualIndex(forBaseIndex baseIndex: Int) -> Int {
        middleCycle * itemsPerCycle + normalizedBaseIndex(baseIndex)
    }

    func recenteredProgressIfNeeded(_ progress: CGFloat) -> CGFloat? {
        guard progress.isFinite else {
            return nil
        }

        let itemsPerCycle = CGFloat(itemsPerCycle)
        let currentCycle = Int(floor(progress / itemsPerCycle))
        let isNearStart = currentCycle <= 1
        let isNearEnd = currentCycle >= cycleCount - 2

        guard isNearStart || isNearEnd else {
            return nil
        }

        var progressWithinCycle = progress.truncatingRemainder(dividingBy: itemsPerCycle)
        if progressWithinCycle < 0 {
            progressWithinCycle += itemsPerCycle
        }

        return CGFloat(middleCycle * self.itemsPerCycle) + progressWithinCycle
    }

    private func normalizedBaseIndex(_ index: Int) -> Int {
        let remainder = index % itemsPerCycle
        return remainder >= 0 ? remainder : remainder + itemsPerCycle
    }
}
