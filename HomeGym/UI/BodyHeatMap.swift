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
        HeatColor.color(sets: stats.sets(for: group), target: group.weeklySetTarget)
    }

    // MARK: - Drawing

    private func draw(front: Bool, into context: inout GraphicsContext) {
        // One continuous silhouette, filled light and outlined.
        let body = bodyOutline()
        context.fill(body, with: .color(base))
        context.stroke(body, with: .color(outline), lineWidth: 1.4)

        // Muscle regions, clipped to the body so nothing spills past the outline.
        var ctx = context
        ctx.clip(to: body)

        // Deltoids.
        muscle(ellipse(CGPoint(x: 104, y: 84), 13, 14), color(for: .shoulders), &ctx)
        muscle(ellipse(CGPoint(x: 46, y: 84), 13, 14), color(for: .shoulders), &ctx)

        // Upper arm: biceps on the front, triceps on the back.
        let armGroup: MuscleGroup = front ? .biceps : .triceps
        muscle(ellipse(CGPoint(x: 104, y: 118), 10, 30), color(for: armGroup), &ctx)
        muscle(ellipse(CGPoint(x: 46, y: 118), 10, 30), color(for: armGroup), &ctx)

        // Torso.
        if front {
            muscle(ellipse(CGPoint(x: 82, y: 102), 11, 11), color(for: .chest), &ctx)
            muscle(ellipse(CGPoint(x: 68, y: 102), 11, 11), color(for: .chest), &ctx)
            muscle(roundedRect(center: CGPoint(x: 75, y: 138), width: 22, height: 48, radius: 8), color(for: .core), &ctx)
        } else {
            muscle(roundedRect(center: CGPoint(x: 75, y: 116), width: 44, height: 88, radius: 16), color(for: .back), &ctx)
            // Glutes sit at the hips on the back view only.
            muscle(ellipse(CGPoint(x: 83, y: 190), 11, 12), color(for: .glutes), &ctx)
            muscle(ellipse(CGPoint(x: 67, y: 190), 11, 12), color(for: .glutes), &ctx)
        }

        // Thighs (quads front / hamstrings back — both the "legs" group).
        muscle(ellipse(CGPoint(x: 86, y: 214), 12, 33), color(for: .legs), &ctx)
        muscle(ellipse(CGPoint(x: 64, y: 214), 12, 33), color(for: .legs), &ctx)
    }

    private func muscle(_ path: Path, _ fill: Color, _ context: inout GraphicsContext) {
        context.fill(path, with: .color(fill))
        context.stroke(path, with: .color(.gray.opacity(0.4)), lineWidth: 1)
    }

    // MARK: - Shape builders

    /// A continuous, symmetric humanoid outline. The right half is defined top-to-crotch;
    /// the left half is the same points mirrored about the centre, traversed in reverse.
    private func bodyOutline() -> Path {
        let pts: [CGPoint] = [
            CGPoint(x: 75, y: 6),    CGPoint(x: 94, y: 27),   CGPoint(x: 83, y: 49),
            CGPoint(x: 80, y: 56),   CGPoint(x: 113, y: 78),  CGPoint(x: 114, y: 150),
            CGPoint(x: 108, y: 198), CGPoint(x: 109, y: 212), CGPoint(x: 97, y: 200),
            CGPoint(x: 96, y: 150),  CGPoint(x: 90, y: 88),   CGPoint(x: 85, y: 150),
            CGPoint(x: 99, y: 188),  CGPoint(x: 93, y: 256),  CGPoint(x: 86, y: 320),
            CGPoint(x: 98, y: 329),  CGPoint(x: 78, y: 324),  CGPoint(x: 81, y: 258),
            CGPoint(x: 75, y: 202)
        ]
        let ctrls: [CGPoint?] = [
            nil, CGPoint(x: 89, y: 7), CGPoint(x: 94, y: 44),
            nil, CGPoint(x: 93, y: 60), CGPoint(x: 120, y: 110),
            nil, CGPoint(x: 110, y: 206), CGPoint(x: 98, y: 212),
            nil, CGPoint(x: 95, y: 114), CGPoint(x: 91, y: 118),
            CGPoint(x: 87, y: 172), CGPoint(x: 102, y: 214), CGPoint(x: 90, y: 290),
            CGPoint(x: 93, y: 329), CGPoint(x: 86, y: 329), CGPoint(x: 79, y: 300),
            CGPoint(x: 80, y: 242)
        ]
        func mirror(_ p: CGPoint) -> CGPoint { CGPoint(x: 150 - p.x, y: p.y) }

        var path = Path()
        path.move(to: pts[0])
        for i in 1..<pts.count {
            if let control = ctrls[i] { path.addQuadCurve(to: pts[i], control: control) }
            else { path.addLine(to: pts[i]) }
        }
        for i in stride(from: pts.count - 1, through: 1, by: -1) {
            let dest = mirror(pts[i - 1])
            if let control = ctrls[i] { path.addQuadCurve(to: dest, control: mirror(control)) }
            else { path.addLine(to: dest) }
        }
        path.closeSubpath()
        return path
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
