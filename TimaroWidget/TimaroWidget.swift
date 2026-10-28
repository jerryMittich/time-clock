import SwiftUI
import WidgetKit

@main
struct TimaroWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimaroStatusWidget()
    }
}

struct TimaroStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.widgetKind, provider: StatusProvider()) { entry in
            StatusWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Timaro")
        .description("Your working time today, time account and vacation at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: Timeline

struct StatusEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct StatusProvider: TimelineProvider {
    static let sample = WidgetSnapshot(
        day: Calendar.current.startOfDay(for: .now),
        sessionStart: Date.now.addingTimeInterval(-5.5 * 3600),
        pausedAt: nil,
        closedBreakSeconds: 30 * 60,
        todayClosedSeconds: 0,
        todayTarget: 8 * 3600,
        balance: 3.25 * 3600,
        vacationRemaining: 18.5,
        workplaceName: nil
    )

    private static var empty: WidgetSnapshot {
        WidgetSnapshot(day: Calendar.current.startOfDay(for: .now), sessionStart: nil, pausedAt: nil,
                       closedBreakSeconds: 0, todayClosedSeconds: 0, todayTarget: 8 * 3600,
                       balance: 0, vacationRemaining: 0, workplaceName: nil)
    }

    func placeholder(in context: Context) -> StatusEntry {
        StatusEntry(date: .now, snapshot: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        let snapshot = context.isPreview ? Self.sample : (WidgetSnapshot.load() ?? Self.empty)
        completion(StatusEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load() ?? Self.empty
        let now = Date.now
        // Timers and progress bars update by themselves; extra entries refresh the
        // static texts (hours, "to go") and roll over at midnight.
        var dates = (0..<16).map { now.addingTimeInterval(Double($0) * 15 * 60) }
        if let reached = snapshot.targetReachedAt(now: now) { dates.append(reached) }
        if let midnight = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)) {
            dates.append(midnight)
        }
        let entries = dates.sorted().map { StatusEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: Views

private enum Palette {
    static let sky = Color(red: 0.42, green: 0.76, blue: 1.0)
    static let deepSky = Color(red: 0.13, green: 0.55, blue: 0.93)
    static let positive = Color(red: 0.20, green: 0.74, blue: 0.47)
    static let negative = Color(red: 0.94, green: 0.33, blue: 0.31)
    static let pause = Color(red: 1.0, green: 0.62, blue: 0.20)

    static func balance(_ seconds: TimeInterval) -> Color {
        seconds < -30 ? negative : (seconds > 30 ? positive : .primary)
    }
}

private struct WidgetBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.07, green: 0.16, blue: 0.30), Color(red: 0.02, green: 0.05, blue: 0.12)]
                : [Color(red: 0.84, green: 0.93, blue: 1.0), Color(red: 0.97, green: 0.99, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct StatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StatusEntry

    private var snapshot: WidgetSnapshot { entry.snapshot }
    private var worked: TimeInterval { snapshot.todayWorked(at: entry.date) }
    private var progress: Double {
        snapshot.todayTarget > 0 ? min(worked / snapshot.todayTarget, 1) : (worked > 0 ? 1 : 0)
    }

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        case .systemMedium: medium
        default: small
        }
    }

    // MARK: Pieces

    private var statusLabel: some View {
        Group {
            if snapshot.isPaused {
                Label("On break", systemImage: "cup.and.saucer.fill").foregroundStyle(Palette.pause)
            } else if snapshot.isClockedIn {
                Label("Clocked in", systemImage: "circle.fill").foregroundStyle(Palette.deepSky)
            } else {
                Label("Not clocked in", systemImage: "moon.zzz.fill").foregroundStyle(.secondary)
            }
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    /// Today's worked time; counts up live while working.
    @ViewBuilder
    private var todayTime: some View {
        if let start = snapshot.todayTimerStart(at: entry.date) {
            Text(start, style: .timer)
        } else {
            Text(Formatters.clock(worked))
        }
    }

    /// Progress towards today's target; fills live while working.
    @ViewBuilder
    private var progressBar: some View {
        if let start = snapshot.todayTimerStart(at: entry.date), snapshot.todayTarget > 0 {
            ProgressView(timerInterval: start...start.addingTimeInterval(snapshot.todayTarget), countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(Palette.deepSky)
        } else {
            ProgressView(value: progress)
                .tint(progress >= 1 ? Palette.positive : Palette.deepSky)
        }
    }

    private var targetLine: Text {
        if worked >= snapshot.todayTarget {
            return Text("+\(Formatters.duration(worked - snapshot.todayTarget)) overtime today")
        }
        return Text("Today \(Formatters.duration(worked)) of \(Formatters.duration(snapshot.todayTarget))")
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            statusLabel
            Spacer(minLength: 0)
            todayTime
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            progressBar
            targetLine
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            small
            VStack(alignment: .leading, spacing: 10) {
                figure("Time account", Formatters.signedDuration(snapshot.balance),
                       systemImage: "hourglass", color: Palette.balance(snapshot.balance))
                figure("Vacation left", Formatters.days(snapshot.vacationRemaining),
                       systemImage: "sun.max.fill", color: .primary)
                if let reached = snapshot.targetReachedAt(now: entry.date) {
                    figure("Target reached at", reached.formatted(date: .omitted, time: .shortened),
                           systemImage: "flag.checkered", color: .primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func figure(_ title: LocalizedStringKey, _ value: String, systemImage: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: systemImage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: Lock Screen

    private var circular: some View {
        Group {
            if let start = snapshot.todayTimerStart(at: entry.date), snapshot.todayTarget > 0 {
                ProgressView(timerInterval: start...start.addingTimeInterval(snapshot.todayTarget), countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    Image(systemName: "clock.fill")
                }
            } else {
                ProgressView(value: progress) {
                    EmptyView()
                } currentValueLabel: {
                    Image(systemName: snapshot.isPaused ? "cup.and.saucer.fill" : "clock")
                }
            }
        }
        .progressViewStyle(.circular)
        .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            statusLabel
            todayTime
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .widgetAccentable()
            targetLine
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Group {
            if let start = snapshot.todayTimerStart(at: entry.date) {
                Label { Text(start, style: .timer) } icon: { Image(systemName: "clock.fill") }
            } else if snapshot.isPaused {
                Label { Text("On break") } icon: { Image(systemName: "cup.and.saucer.fill") }
            } else {
                Label { Text("Time account \(Formatters.signedDuration(snapshot.balance))") } icon: { Image(systemName: "hourglass") }
            }
        }
    }
}
