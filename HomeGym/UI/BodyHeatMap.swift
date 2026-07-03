import SwiftUI
import Foundation

/// Maps a set count to a cold→hot colour: grey when untrained, then a diverging
/// blue → pale → red ramp. Scaled to a weekly per-muscle target (not to the top
/// group), so the colour means "how much have I trained this this week". The pale
/// midpoint avoids the muddy magenta a vivid blue→red would produce.
enum HeatColor {
    static let untrained = Color.gray.opacity(0.18)
    /// Sets per muscle group that count as a fully "hot" week.
    static let weeklyTargetSets = 8

    static func color(sets: Int, target: Int = weeklyTargetSets) -> Color {
        guard sets > 0 else { return untrained }
        let t = min(1.0, Double(sets) / Double(max(1, target)))
        return coolToHot(t)
    }

    private static func coolToHot(_ t: Double) -> Color {
        let cold = (r: 0.20, g: 0.48, b: 0.96)   // blue
        let mid  = (r: 0.88, g: 0.88, b: 0.92)   // pale
        let hot  = (r: 0.92, g: 0.16, b: 0.20)   // red
        func lerp(_ a: (r: Double, g: Double, b: Double), _ b: (r: Double, g: Double, b: Double), _ u: Double) -> Color {
            Color(red: a.r + (b.r - a.r) * u, green: a.g + (b.g - a.g) * u, blue: a.b + (b.b - a.b) * u)
        }
        return t < 0.5 ? lerp(cold, mid, t / 0.5) : lerp(mid, hot, (t - 0.5) / 0.5)
    }
}

/// Front + back body figures in a clean-silhouette style: a light outline body with
/// distinct muscle-group regions tinted by how much each group was trained this week.
struct BodyHeatMap: View {
    let stats: WeeklyStats

    private let canvas = CGSize(width: 150, height: 330)
    private let base = Color.gray.opacity(0.16)
    private let outline = Color.gray.opacity(0.55)

    var body: some View {
        HStack(alignment: .top, spacing: 40) {
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

    private func color(for group: MuscleGroup) -> Color {
        HeatColor.color(sets: stats.sets(for: group))
    }

    // MARK: - Drawing

    private func draw(front: Bool, into context: inout GraphicsContext) {
        drawBaseBody(&context)

        // Deltoids.
        muscle(circle(CGPoint(x: 44, y: 74), 14), color(for: .shoulders), &context)
        muscle(circle(CGPoint(x: 106, y: 74), 14), color(for: .shoulders), &context)

        // Upper-arm muscle patch: biceps on the front, triceps on the back.
        let armGroup: MuscleGroup = front ? .biceps : .triceps
        muscle(ellipse(CGPoint(x: 36, y: 112), 9, 26), color(for: armGroup), &context)
        muscle(ellipse(CGPoint(x: 114, y: 112), 9, 26), color(for: armGroup), &context)

        // Torso muscles, clipped to the torso outline so they never spill past the body.
        var torsoClip = context
        torsoClip.clip(to: torsoPath())
        if front {
            muscle(ellipse(CGPoint(x: 64, y: 96), 14, 12), color(for: .chest), &torsoClip)
            muscle(ellipse(CGPoint(x: 86, y: 96), 14, 12), color(for: .chest), &torsoClip)
            muscle(roundedRect(center: CGPoint(x: 75, y: 136), width: 24, height: 48, radius: 8), color(for: .core), &torsoClip)
        } else {
            muscle(roundedRect(center: CGPoint(x: 75, y: 112), width: 52, height: 92, radius: 16), color(for: .back), &torsoClip)
        }

        // Thighs (quads on the front, hamstrings on the back — both are the "legs" group).
        muscle(ellipse(CGPoint(x: 63, y: 208), 12, 34), color(for: .legs), &context)
        muscle(ellipse(CGPoint(x: 87, y: 208), 12, 34), color(for: .legs), &context)
    }

    /// The light-grey body: head, neck, tapered torso, arms and legs.
    private func drawBaseBody(_ context: inout GraphicsContext) {
        baseFill(torsoPath(), &context)

        for side in [CGFloat(-1), CGFloat(1)] {
            let shoulderX = 75 + side * 31
            let elbowX = 75 + side * 47
            let wristX = 75 + side * 53
            baseFill(taper(CGPoint(x: shoulderX, y: 80), CGPoint(x: elbowX, y: 150), 23, 16), &context)
            baseFill(circle(CGPoint(x: elbowX, y: 150), 8), &context)
            baseFill(taper(CGPoint(x: elbowX, y: 152), CGPoint(x: wristX, y: 214), 15, 11), &context)
        }

        for hipX in [CGFloat(64), CGFloat(86)] {
            let kneeX = hipX + (hipX < 75 ? -2 : 2)
            baseFill(taper(CGPoint(x: hipX, y: 178), CGPoint(x: kneeX, y: 250), 30, 20), &context)
            baseFill(circle(CGPoint(x: kneeX, y: 250), 10), &context)
            baseFill(taper(CGPoint(x: kneeX, y: 252), CGPoint(x: kneeX, y: 316), 19, 13), &context)
        }

        baseFill(circle(CGPoint(x: 44, y: 74), 15), &context)
        baseFill(circle(CGPoint(x: 106, y: 74), 15), &context)
        baseFill(roundedRect(center: CGPoint(x: 75, y: 52), width: 18, height: 20, radius: 5), &context)
        baseFill(ellipse(CGPoint(x: 75, y: 26), 17, 20), &context)
    }

    private func baseFill(_ path: Path, _ context: inout GraphicsContext) {
        context.fill(path, with: .color(base))
        context.stroke(path, with: .color(outline), lineWidth: 1.2)
    }

    private func muscle(_ path: Path, _ fill: Color, _ context: inout GraphicsContext) {
        context.fill(path, with: .color(fill))
        context.stroke(path, with: .color(.gray.opacity(0.4)), lineWidth: 1)
    }

    // MARK: - Shape builders

    private func torsoPath() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 46, y: 68))
        p.addLine(to: CGPoint(x: 104, y: 68))
        p.addQuadCurve(to: CGPoint(x: 92, y: 150), control: CGPoint(x: 104, y: 120))
        p.addLine(to: CGPoint(x: 98, y: 178))
        p.addLine(to: CGPoint(x: 52, y: 178))
        p.addLine(to: CGPoint(x: 58, y: 150))
        p.addQuadCurve(to: CGPoint(x: 46, y: 68), control: CGPoint(x: 46, y: 120))
        p.closeSubpath()
        return p
    }

    private func taper(_ a: CGPoint, _ b: CGPoint, _ widthA: CGFloat, _ widthB: CGFloat) -> Path {
        let dx = b.x - a.x, dy = b.y - a.y
        let len = max(0.0001, hypot(dx, dy))
        let nx = -dy / len, ny = dx / len
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

/// Cold→hot colour scale legend for the heat map.
struct HeatLegend: View {
    var body: some View {
        HStack(spacing: 8) {
            Text("Less").font(.caption2).foregroundStyle(.secondary)
            LinearGradient(
                colors: [
                    HeatColor.color(sets: 1),
                    HeatColor.color(sets: 4),
                    HeatColor.color(sets: 8)
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: 120, height: 8)
            .clipShape(Capsule())
            Text("More").font(.caption2).foregroundStyle(.secondary)
        }
    }
}
