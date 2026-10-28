import SwiftUI
import SwiftData

struct ClockView: View {
    @Query(filter: #Predicate<WorkSession> { $0.end == nil }) private var openSessions: [WorkSession]
    @Query(sort: \WorkSession.start, order: .reverse) private var sessions: [WorkSession]
    @Query(sort: \Workplace.name) private var workplaces: [Workplace]
    @Query private var vacationDays: [VacationDay]
    @AppStorage(AppSettings.Key.dailyTargetHours) private var dailyTargetHours = 8.0
    @AppStorage(AppSettings.Key.initialBalanceMinutes) private var initialBalanceMinutes = 0

    @State private var selectedWorkplaceID: UUID?
    private let monitor = LocationMonitor.shared

    private var openSession: WorkSession? { openSessions.first }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ScrollView {
                    VStack(spacing: 20) {
                        if !monitor.hasAlwaysAuthorization {
                            permissionBanner
                        }
                        dial(now: context.date)
                        controls
                        tiles(now: context.date)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(AppBackground())
            .navigationTitle("Timaro")
        }
    }

    // MARK: Sections

    private var permissionBanner: some View {
        Button {
            if monitor.authorization == .notDetermined || monitor.authorization == .authorizedWhenInUse {
                monitor.requestAuthorization()
            } else if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } label: {
            Label("Allow location access \"Always\" to clock in automatically.", systemImage: "location.slash.fill")
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .buttonStyle(.plain)
        .glassCard(cornerRadius: 18, tint: Theme.pause)
    }

    private func dial(now: Date) -> some View {
        let calendar = Calendar.current
        let vacationToday = vacationDays.byDay[calendar.startOfDay(for: now)] ?? 0
        let target = TimeAccount.target(dailyTargetHours * 3600, vacation: vacationToday)
        let todaySeconds = sessions
            .filter { calendar.isDate($0.start, inSameDayAs: now) }
            .reduce(0) { $0 + $1.duration(now: now) }
        let progress = target > 0 ? todaySeconds / target : (todaySeconds > 0 ? 1 : 0)

        return VStack(spacing: 16) {
            if vacationToday > 0 {
                Label(vacationToday >= 1 ? LocalizedStringKey("Vacation today") : "Half day off today",
                      systemImage: "sun.max.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.pause)
            }

            ProgressRing(progress: progress) {
                VStack(spacing: 4) {
                    statusLine(now: now)
                        .font(.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(Formatters.clock(openSession?.duration(now: now) ?? todaySeconds))
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .contentTransition(.numericText())
                        .foregroundStyle(openSession?.isPaused == true ? .secondary : .primary)
                    Text("Today \(Formatters.duration(todaySeconds)) of \(Formatters.duration(target))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 30)
            }
            .frame(width: 260, height: 260)
            .padding(.top, 8)

            Text(todayStatus(worked: todaySeconds, target: target, now: now))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let session = openSession {
                HStack(spacing: 8) {
                    chip("mappin.circle.fill", session.workplace?.name ?? String(localized: "No workplace"))
                    chip("clock", session.start.formatted(date: .omitted, time: .shortened))
                    if session.breakDuration(now: now) >= 60 {
                        chip("cup.and.saucer.fill", Formatters.duration(session.breakDuration(now: now)))
                    }
                }
            } else if !workplaces.isEmpty {
                Menu {
                    Picker("Workplace", selection: $selectedWorkplaceID) {
                        Text("No workplace").tag(UUID?.none)
                        ForEach(workplaces) { Text($0.name).tag(UUID?.some($0.id)) }
                    }
                } label: {
                    Label(workplaces.first { $0.id == selectedWorkplaceID }?.name ?? String(localized: "No workplace"),
                          systemImage: "mappin.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .glassCapsule()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard(cornerRadius: 32)
    }

    @ViewBuilder
    private func statusLine(now: Date) -> some View {
        if let session = openSession {
            if let pausedAt = session.pausedAt {
                Text("On break · \(Formatters.duration(now.timeIntervalSince(pausedAt)))")
                    .foregroundStyle(Theme.pause)
            } else {
                Text(session.isAutomatic ? LocalizedStringKey("Clocked in automatically") : "Clocked in")
                    .foregroundStyle(Theme.deepSky)
            }
        } else {
            Text("Not clocked in").foregroundStyle(.secondary)
        }
    }

    private func chip(_ systemImage: String, _ text: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassCapsule()
    }

    @ViewBuilder
    private var controls: some View {
        GlassGroup(spacing: 28) {
            if let session = openSession {
                HStack(spacing: 28) {
                    if session.isPaused {
                        roundButton("Resume", systemImage: "play.fill", tint: Theme.positive) {
                            ClockService.shared.endBreak()
                        }
                    } else {
                        roundButton("Break", systemImage: "cup.and.saucer.fill", tint: Theme.pause) {
                            ClockService.shared.startBreak()
                        }
                    }
                    roundButton("Finish", systemImage: "stop.fill", tint: Theme.negative) {
                        ClockService.shared.clockOut()
                    }
                }
                .sensoryFeedback(.selection, trigger: session.isPaused)
            } else {
                roundButton("Start", systemImage: "play.fill", tint: Theme.deepSky, size: 150) {
                    let workplace = workplaces.first { $0.id == selectedWorkplaceID }
                    ClockService.shared.clockIn(at: workplace)
                }
            }
        }
        .sensoryFeedback(.success, trigger: openSessions.count)
        .animation(.smooth, value: openSession?.isPaused)
        .animation(.smooth, value: openSessions.count)
    }

    private func roundButton(_ title: LocalizedStringKey,
                             systemImage: String,
                             tint: Color,
                             size: CGFloat = 116,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage).font(.title2.weight(.semibold))
                Text(title).font(.headline)
            }
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassCircle(tint: tint)
    }

    private func tiles(now: Date) -> some View {
        let calendar = Calendar.current
        let week = sessions.filter { calendar.isDate($0.start, equalTo: now, toGranularity: .weekOfYear) }
        let weekSeconds = week.reduce(0) { $0 + $1.duration(now: now) }
        let balance = TimeAccount.balance(sessions.map { $0.accountEntry(now: now) },
                                          target: dailyTargetHours * 3600,
                                          vacation: vacationDays.byDay,
                                          initial: Double(initialBalanceMinutes * 60))
        let year = calendar.component(.year, from: now)
        let vacation = VacationLedger.summary(vacationDays.map(\.ledgerEntry),
                                              year: year,
                                              allowance: AppSettings.vacationAllowance(for: year),
                                              today: now)

        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatTile(title: "Time account", value: Formatters.signedDuration(balance),
                     systemImage: "hourglass", color: Theme.balanceColor(balance))
            StatTile(title: "This week", value: Formatters.duration(weekSeconds),
                     systemImage: "calendar")
            StatTile(title: "Vacation left", value: Formatters.days(vacation.remaining),
                     systemImage: "sun.max.fill")
            StatTile(title: "Vacation taken", value: Formatters.days(vacation.taken),
                     systemImage: "beach.umbrella.fill")
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
}
