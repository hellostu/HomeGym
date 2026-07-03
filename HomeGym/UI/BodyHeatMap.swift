import SwiftUI

/// Maps a set count to a heat colour: grey when untrained, then blue → red as the
/// weekly volume for that muscle group rises relative to the most-trained group.
enum HeatColor {
    static func color(sets: Int, max: Int) -> Color {
        guard sets > 0 else { return Color.gray.opacity(0.22) }
        let intensity = max > 0 ? Double(sets) / Double(max) : 0
        return Color(hue: 0.6 * (1 - intensity), saturation: 0.85, brightness: 0.9)
    }
}

/// A simple front + back figure whose regions are tinted by how much each muscle group
/// has been trained this week. Stylised (capsules/rounded rects), not anatomical.
struct BodyHeatMap: View {
    let stats: WeeklyStats

    var body: some View {
        HStack(spacing: 28) {
            figure(front: true)
            figure(front: false)
        }
    }

    private let neutral = Color.gray.opacity(0.22)

    private func color(for group: MuscleGroup?) -> Color {
        guard let group else { return neutral }
        return HeatColor.color(sets: stats.sets(for: group), max: stats.maxGroupSets)
    }

    private func figure(front: Bool) -> some View {
        ZStack {
            // Head + lower limbs are neutral (not tracked groups).
            Circle().fill(neutral).frame(width: 34, height: 34).position(x: 70, y: 24)

            // Shoulders (shown on both views).
            Capsule().fill(color(for: .shoulders)).frame(width: 30, height: 16).position(x: 44, y: 52)
            Capsule().fill(color(for: .shoulders)).frame(width: 30, height: 16).position(x: 96, y: 52)

            // Upper arms: biceps on the front, triceps on the back.
            let armGroup: MuscleGroup = front ? .biceps : .triceps
            Capsule().fill(color(for: armGroup)).frame(width: 16, height: 54).position(x: 30, y: 92)
            Capsule().fill(color(for: armGroup)).frame(width: 16, height: 54).position(x: 110, y: 92)

            // Forearms neutral.
            Capsule().fill(neutral).frame(width: 14, height: 48).position(x: 26, y: 150)
            Capsule().fill(neutral).frame(width: 14, height: 48).position(x: 114, y: 150)

            // Torso: chest + core on the front; back covers the whole torso on the back.
            RoundedRectangle(cornerRadius: 12)
                .fill(color(for: front ? .chest : .back))
                .frame(width: 58, height: 46).position(x: 70, y: 80)
            RoundedRectangle(cornerRadius: 12)
                .fill(color(for: front ? .core : .back))
                .frame(width: 50, height: 42).position(x: 70, y: 120)

            // Thighs (legs, shown on both).
            Capsule().fill(color(for: .legs)).frame(width: 24, height: 64).position(x: 56, y: 178)
            Capsule().fill(color(for: .legs)).frame(width: 24, height: 64).position(x: 84, y: 178)

            // Shins neutral.
            Capsule().fill(neutral).frame(width: 20, height: 54).position(x: 56, y: 238)
            Capsule().fill(neutral).frame(width: 20, height: 54).position(x: 84, y: 238)
        }
        .frame(width: 140, height: 280)
        .overlay(alignment: .bottom) {
            Text(front ? "Front" : "Back").font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// Colour scale legend for the heat map.
struct HeatLegend: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Less").font(.caption2).foregroundStyle(.secondary)
            LinearGradient(
                colors: [
                    HeatColor.color(sets: 1, max: 4),
                    HeatColor.color(sets: 2, max: 4),
                    HeatColor.color(sets: 3, max: 4),
                    HeatColor.color(sets: 4, max: 4)
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: 120, height: 8)
            .clipShape(Capsule())
            Text("More").font(.caption2).foregroundStyle(.secondary)
        }
    }
}
