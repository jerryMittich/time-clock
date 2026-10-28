import SwiftUI
import SwiftData

struct ClockView: View {
    @Query(filter: #Predicate<WorkSession> { $0.end == nil }) private var openSessions: [WorkSession]
    @Query(sort: \WorkSession.start, order: .reverse) private var sessions: [WorkSession]
    @Query(sort: \Workplace.name) private var workplaces: [Workplace]
    @AppStorage(AppSettings.Key.weeklyTargetHours) private var weeklyTargetHours = 40.0

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
                        punchButton
                        summary(now: context.date)
                    }
                    .padding()
                }
            }
            .navigationTitle("Vivaro")
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
                Text(session.isAutomatic ? LocalizedStringKey("Clocked in automatically") : "Clocked in")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(Formatters.clock(session.duration(now: now)))
                    .font(.system(size: 56, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("\(session.workplace?.name ?? String(localized: "No workplace")) · since \(session.start.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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

    private var punchButton: some View {
        Button {
            if openSession != nil {
                ClockService.shared.clockOut()
            } else {
                let workplace = workplaces.first { $0.id == selectedWorkplaceID }
                ClockService.shared.clockIn(at: workplace)
            }
        } label: {
            Text(openSession == nil ? LocalizedStringKey("Clock in") : "Clock out")
                .font(.title2.bold())
                .frame(width: 180, height: 180)
                .background(openSession == nil ? Color.green : Color.red, in: Circle())
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: openSession == nil)
    }

    private func summary(now: Date) -> some View {
        let calendar = Calendar.current
        let today = sessions.filter { calendar.isDate($0.start, inSameDayAs: now) }
        let week = sessions.filter { calendar.isDate($0.start, equalTo: now, toGranularity: .weekOfYear) }
        let todaySeconds = today.reduce(0) { $0 + $1.duration(now: now) }
        let weekSeconds = week.reduce(0) { $0 + $1.duration(now: now) }
        let weekEarnings = week.reduce(0) { $0 + $1.earnings(now: now) }
        let target = weeklyTargetHours * 3600

        return VStack(spacing: 12) {
            HStack {
                stat("Today", Formatters.duration(todaySeconds))
                stat("This week", Formatters.duration(weekSeconds))
                stat("Earned", Formatters.currency(weekEarnings))
            }
            if target > 0 {
                ProgressView(value: min(weekSeconds, target), total: target) {
                    Text("Weekly target")
                        .font(.caption)
                } currentValueLabel: {
                    Text(weekSeconds > target
                         ? LocalizedStringKey("Overtime \(Formatters.duration(weekSeconds - target))")
                         : LocalizedStringKey("\(Formatters.duration(target - weekSeconds)) to go"))
                        .font(.caption)
                }
            }
        }
    }

    private func stat(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
