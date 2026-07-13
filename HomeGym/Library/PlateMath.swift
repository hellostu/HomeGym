import Foundation

/// Works out which plates to slide onto each side of a loaded bar.
///
/// A barbell / EZ bar total load is the empty bar plus an equal stack of plates on both
/// ends, so `(total − baseWeight) / 2` is what goes on one side. We break that into the
/// standard home-gym plate denominations, largest first — greedy is exact here because
/// every plate is a whole multiple of the next-smallest one.
enum PlateMath {

    /// Plate sizes available in the gym (kg), largest first.
    static let availablePlates: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    /// A plate size and how many of it go on each side of the bar.
    struct PlateCount: Identifiable, Equatable {
        let weight: Double
        let count: Int
        var id: Double { weight }
    }

    /// Breaks the per-side load into plates, largest first. Returns nil when the
    /// equipment isn't a loadable bar, and an empty array when it's just the empty bar.
    static func perSidePlates(total: Double, equipment: Equipment) -> [PlateCount]? {
        guard equipment == .barbell || equipment == .ezBar else { return nil }
        var perSide = (total - equipment.baseWeight) / 2
        guard perSide > 0.01 else { return [] }
        var result: [PlateCount] = []
        for plate in availablePlates {
            let count = Int((perSide / plate + 1e-6).rounded(.down))
            if count > 0 {
                result.append(PlateCount(weight: plate, count: count))
                perSide -= Double(count) * plate
            }
        }
        return result
    }

    /// Human-readable per-side loading, e.g. "20 + 5 + 2.5" or "2×20 + 5".
    /// nil when the equipment isn't a bar; nil when it's just the empty bar.
    static func perSideDescription(total: Double, equipment: Equipment) -> String? {
        guard let plates = perSidePlates(total: total, equipment: equipment), !plates.isEmpty else {
            return nil
        }
        return plates.map { plate in
            plate.count > 1
                ? "\(plate.count)×\(ProgressionEngine.format(plate.weight))"
                : ProgressionEngine.format(plate.weight)
        }
        .joined(separator: " + ")
    }
}
