import SwiftUI

/// Shared look: light-blue accent (AccentColor asset), a soft sky gradient behind every
/// screen, and Liquid Glass surfaces on iOS 26 with a material fallback on older systems.
enum Theme {
    static let sky = Color(red: 0.42, green: 0.76, blue: 1.0)
    static let deepSky = Color(red: 0.13, green: 0.55, blue: 0.93)
    static let positive = Color(red: 0.20, green: 0.74, blue: 0.47)
    static let negative = Color(red: 0.94, green: 0.33, blue: 0.31)
    static let pause = Color(red: 1.0, green: 0.62, blue: 0.20)

    static func balanceColor(_ seconds: TimeInterval) -> Color {
        seconds < -30 ? negative : (seconds > 30 ? positive : .primary)
    }
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: scheme == .dark
                    ? [Color(red: 0.05, green: 0.12, blue: 0.24), Color(red: 0.02, green: 0.04, blue: 0.10)]
                    : [Color(red: 0.84, green: 0.93, blue: 1.0), Color(red: 0.97, green: 0.99, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .fill(Theme.sky.opacity(scheme == .dark ? 0.30 : 0.45))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: 140, y: -300)
            Circle()
                .fill(Theme.deepSky.opacity(scheme == .dark ? 0.25 : 0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -160, y: 260)
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Rounded glass panel.
    @ViewBuilder
    func glassCard(cornerRadius: CGFloat = 26, tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            let glass: Glass = tint.map { Glass.regular.tint($0.opacity(0.25)) } ?? .regular
            self.glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.35), lineWidth: 0.5))
        }
    }

    /// Tinted, interactive glass circle for the big clock buttons.
    @ViewBuilder
    func glassCircle(tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(tint).interactive(), in: .circle)
        } else {
            self.background(tint.gradient, in: Circle())
                .shadow(color: tint.opacity(0.35), radius: 12, y: 6)
        }
    }

    /// Small glass capsule (chips, menus).
    @ViewBuilder
    func glassCapsule() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            self.background(.ultraThinMaterial, in: Capsule())
        }
    }

    /// Prominent glass button (primary actions in sheets and onboarding).
    @ViewBuilder
    func prominentButton() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }

    /// Lets the sky gradient show through lists and forms.
    func screenBackground() -> some View {
        self.scrollContentBackground(.hidden)
            .background(AppBackground())
    }
}

/// Glass container that lets neighbouring glass shapes blend on iOS 26.
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat = 24
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}

/// Circular progress ring. Values above 1 draw a second lap in green (overtime).
struct ProgressRing<Center: View>: View {
    var progress: Double
    var lineWidth: CGFloat = 18
    @ViewBuilder var center: Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.sky.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(AngularGradient(colors: [Theme.sky, Theme.deepSky, Theme.sky], center: .center),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress > 1 {
                Circle()
                    .trim(from: 0, to: min(progress - 1, 1))
                    .stroke(Theme.positive, style: StrokeStyle(lineWidth: lineWidth * 0.55, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            center
        }
        .animation(.smooth, value: progress)
    }
}

/// Small glass tile with a caption and a value.
struct StatTile: View {
    var title: LocalizedStringKey
    var value: String
    var systemImage: String
    var color: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassCard(cornerRadius: 20)
    }
}
