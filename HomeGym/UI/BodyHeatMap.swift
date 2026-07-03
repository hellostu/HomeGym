import SwiftUI
import Foundation

/// Maps a set count to a heat colour: grey when untrained, then blue → red as the
/// weekly volume for that muscle group rises relative to the most-trained group.
enum HeatColor {
    static func color(sets: Int, max: Int) -> Color {
        guard sets > 0 else { return Color.gray.opacity(0.22) }
        let intensity = max > 0 ? Double(sets) / Double(max) : 0
        return Color(hue: 0.6 * (1 - intensity), saturation: 0.85, brightness: 0.9)
    }
}

/// Front + back body figures whose muscle regions are tinted by how much each group
/// has been trained this week. Drawn as a connected silhouette (tapered torso, arms
/// and legs) via Canvas rather than floating shapes.
struct BodyHeatMap: View {
    let stats: WeeklyStats

    // Design canvas size; the figure is laid out in these coordinates.
    private let canvas = CGSize(width: 150, height: 330)
    private let neutral = Color.gray.opacity(0.22)

    var body: some View {
        HStack(alignment: .top, spacing: 36) {
            labelledFigure("Front", front: true)
            labelledFigure("Back", front: false)
        }
    }

    private func labelledFigure(_ title: String, front: Bool) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            Canvas { context, _ in draw(front: front, into: &context) }
                .frame(width: canvas.width, height: canvas.height)
        }
    }

    private func color(for group: MuscleGroup?) -> Color {
        guard let group else { return neutral }
        return HeatColor.color(sets: stats.sets(for: group), max: stats.maxGroupSets)
    }

    // MARK: - Drawing

    private func draw(front: Bool, into context: inout GraphicsContext) {
        // Torso base (tapered: broad shoulders → waist → hips).
        let torso = torsoPath()
        paint(torso, neutral, &context)

        // Legs (thighs coloured; calves neutral).
        for hipX in [CGFloat(64), CGFloat(86)] {
            let kneeX = hipX + (hipX < 75 ? -2 : 2)
            paint(taper(CGPoint(x: hipX, y: 178), CGPoint(x: kneeX, y: 250), 30, 20), color(for: .legs), &context)
            paint(circle(CGPoint(x: kneeX, y: 250), 10), color(for: .legs), &context)
            paint(taper(CGPoint(x: kneeX, y: 252), CGPoint(x: kneeX, y: 316), 19, 13), neutral, &context)
        }

        // Arms (upper arm coloured biceps/triceps; forearm neutral).
        let armGroup: MuscleGroup = front ? .biceps : .triceps
        for side in [CGFloat(-1), CGFloat(1)] {
            let shoulderX = 75 + side * 31
            let elbowX = 75 + side * 47
            let wristX = 75 + side * 53
            paint(taper(CGPoint(x: shoulderX, y: 80), CGPoint(x: elbowX, y: 150), 23, 16), color(for: armGroup), &context)
            paint(circle(CGPoint(x: elbowX, y: 150), 8), neutral, &context)
            paint(taper(CGPoint(x: elbowX, y: 152), CGPoint(x: wristX, y: 214), 15, 11), neutral, &context)
        }

        // Torso muscle overlays.
        if front {
            paint(ellipse(CGPoint(x: 63, y: 98), 15, 12), color(for: .chest), &context)
            paint(ellipse(CGPoint(x: 87, y: 98), 15, 12), color(for: .chest), &context)
            paint(roundedRect(center: CGPoint(x: 75, y: 140), width: 30, height: 46, radius: 8), color(for: .core), &context)
        } else {
            paint(roundedRect(center: CGPoint(x: 75, y: 118), width: 50, height: 104, radius: 16), color(for: .back), &context)
        }

        // Deltoids sit on top of the shoulder/arm junction.
        paint(circle(CGPoint(x: 44, y: 76), 15), color(for: .shoulders), &context)
        paint(circle(CGPoint(x: 106, y: 76), 15), color(for: .shoulders), &context)

        // Neck + head (neutral).
        paint(roundedRect(center: CGPoint(x: 75, y: 52), width: 18, height: 20, radius: 5), neutral, &context)
        paint(ellipse(CGPoint(x: 75, y: 26), 17, 20), neutral, &context)
    }

    private func paint(_ path: Path, _ fill: Color, _ context: inout GraphicsContext) {
        context.fill(path, with: .color(fill))
        context.stroke(path, with: .color(.black.opacity(0.28)), lineWidth: 1)
    }

    // MARK: - Shape builders

    private func torsoPath() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 46, y: 68))
        p.addLine(to: CGPoint(x: 104, y: 68))     // shoulders
        p.addQuadCurve(to: CGPoint(x: 92, y: 150), control: CGPoint(x: 104, y: 120))  // to waist R
        p.addLine(to: CGPoint(x: 98, y: 178))     // hip R
        p.addLine(to: CGPoint(x: 52, y: 178))     // hip L
        p.addLine(to: CGPoint(x: 58, y: 150))     // waist L
        p.addQuadCurve(to: CGPoint(x: 46, y: 68), control: CGPoint(x: 46, y: 120))
        p.closeSubpath()
        return p
    }

    private func taper(_ a: CGPoint, _ b: CGPoint, _ widthA: CGFloat, _ widthB: CGFloat) -> Path {
        let dx = b.x - a.x, dy = b.y - a.y
        let len = max(0.0001, hypot(dx, dy))
        let nx = -dy / len, ny = dx / len   // unit perpendicular
        var p = Path()
        p.move(to: CGPoint(x: a.x + nx * widthA / 2, y: a.y + ny * widthA / 2))
        p.addLine(to: CGPoint(x: b.x + nx * widthB / 2, y: b.y + ny * widthB / 2))
        p.addLine(to: CGPoint(x: b.x - nx * widthB / 2, y: b.y - ny * widthB / 2))
        p.addLine(to: CGPoint(x: a.x - nx * widthA / 2, y: a.y - ny * widthA / 2))
        p.closeSubpath()
        return p
    }

    private func circle(_ center: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
    }

    private func ellipse(_ center: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2))
    }

    private func roundedRect(center: CGPoint, width: CGFloat, height: CGFloat, radius: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height),
             cornerRadius: radius)
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
