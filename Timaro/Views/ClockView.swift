import SwiftUI
import SwiftData

struct ClockView: View {
    @Query(filter: #Predicate<WorkSession> { $0.end == nil }) private var openSessions: [WorkSession]
    @Query(sort: \WorkSession.start, order: .reverse) private var sessions: [WorkSession]
    @Query(sort: \Workplace.name) private var workplaces: [Workplace]
    @AppStorage(AppSettings.Key.dailyTargetHours) private var dailyTargetHours = 8.0
    @AppStorage(AppSettings.Key.initialBalanceMinutes) private var initialBalanceMinutes = 0

    @State private var selectedWorkplaceID: UUID?
    private let monitor = LocationMonitor.shared

    private var openSession: WorkSession? { openSessions.first }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ScrollView {
                    VStack(spacing: 24) {
                        if !monitor.hasAlwaysAuthorization {
                            permissionBanner
                        }
                        statusCard(now: context.date)
                        controls
                        summary(now: context.date)
                    }
                    .padding()
                }
            }
            .navigationTitle("Timaro")
        }
    }

    private var permissionBanner: some View {
        Button {
            if monitor.authorization == .notDetermined || monitor.authorization == .authorizedWhenInUse {
                monitor.requestAuthorization()
            } else if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            Label("Allow location access \"Always\" to clock in automatically.", systemImage: "location.slash")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func statusCard(now: Date) -> some View {
        VStack(spacing: 8) {
            if let session = openSession {
                if let pausedAt = session.pausedAt {
                    Text("On break since \(pausedAt.formatted(date: .omitted, time: .shortened)) · \(Formatters.duration(now.timeIntervalSince(pausedAt)))")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else {
                    Text(session.isAutomatic ? LocalizedStringKey("Clocked in automatically") : "Clocked in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(Formatters.clock(session.duration(now: now)))
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(session.isPaused ? .secondary : .primary)
                Text("\(session.workplace?.name ?? String(localized: "No workplace")) · since \(session.start.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if session.breakDuration(now: now) >= 60 {
                    Text("Breaks: \(Formatters.duration(session.breakDuration(now: now)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Not clocked in")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("--:--:--")
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .foregroundStyle(.tertiary)
                if !workplaces.isEmpty {
                    Picker("Workplace", selection: $selectedWorkplaceID) {
                        Text("No workplace").tag(UUID?.none)
                        ForEach(workplaces) { workplace in
                            Text(workplace.name).tag(UUID?.some(workplace.id))
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var controls: some View {
        if let session = openSession {
            HStack(spacing: 32) {
                if session.isPaused {
                    roundButton("Resume", systemImage: "play.fill", color: .green) {
                        ClockService.shared.endBreak()
                    }
                } else {
                    roundButton("Break", systemImage: "cup.and.saucer.fill", color: .orange) {
                        ClockService.shared.startBreak()
                    }
                }
                roundButton("Finish", systemImage: "stop.fill", color: .red) {
                    ClockService.shared.clockOut()
                }
            }
            .sensoryFeedback(.selection, trigger: session.isPaused)
        } else {
            roundButton("Start", systemImage: "play.fill", color: .green, size: 180) {
                let workplace = workplaces.first { $0.id == selectedWorkplaceID }
                ClockService.shared.clockIn(at: workplace)
            }
            .sensoryFeedback(.success, trigger: openSessions.count)
        }
    }

    private func roundButton(_ title: LocalizedStringKey,
                             systemImage: String,
                             color: Color,
                             size: CGFloat = 130,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage).font(.title)
                Text(title).font(.title3.bold())
            }
            .frame(width: size, height: size)
            .background(color, in: Circle())
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func summary(now: Date) -> some View {
        let calendar = Calendar.current
        let target = dailyTargetHours * 3600
        let today = sessions.filter { calendar.isDate($0.start, inSameDayAs: now) }
        let week = sessions.filter { calendar.isDate($0.start, equalTo: now, toGranularity: .weekOfYear) }
        let todaySeconds = today.reduce(0) { $0 + $1.duration(now: now) }
        let weekSeconds = week.reduce(0) { $0 + $1.duration(now: now) }
        let balance = TimeAccount.balance(sessions.map { $0.accountEntry(now: now) },
                                          target: target,
                                          initial: Double(initialBalanceMinutes * 60))

        return VStack(spacing: 12) {
            if target > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: min(todaySeconds, target), total: target) {
                        HStack {
                            Text("Today")
                            Spacer()
                            Text("\(Formatters.duration(todaySeconds)) / \(Formatters.duration(target))")
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                    }
                    .tint(todaySeconds >= target ? .green : .accentColor)
                    Text(todayStatus(worked: todaySeconds, target: target, now: now))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                stat("Time account", Formatters.signedDuration(balance),
                     color: balance < -30 ? .red : (balance > 30 ? .green : .primary))
                stat("This week", Formatters.duration(weekSeconds))
            }
        }
    }

    private func todayStatus(worked: TimeInterval, target: TimeInterval, now: Date) -> LocalizedStringKey {
        if worked >= target {
            return "+\(Formatters.duration(worked - target)) overtime today"
        }
        let remaining = target - worked
        if let session = openSession, !session.isPaused {
            let finish = now.addingTimeInterval(remaining).formatted(date: .omitted, time: .shortened)
            return "\(Formatters.duration(remaining)) to go · target reached at \(finish)"
        }
        return "\(Formatters.duration(remaining)) to go"
    }

    private func stat(_ title: LocalizedStringKey, _ value: String, color: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).monospacedDigit().foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
