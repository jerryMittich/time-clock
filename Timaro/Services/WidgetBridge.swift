import Foundation
import SwiftData
import WidgetKit

/// Publishes the current status to the widgets whenever it changes.
@MainActor
enum WidgetBridge {
    static func refresh(now: Date = .now) {
        let context = Persistence.container.mainContext
        let sessions = (try? context.fetch(FetchDescriptor<WorkSession>())) ?? []
        let vacation = (try? context.fetch(FetchDescriptor<VacationDay>())) ?? []
        let calendar = Calendar.current
        let defaults = UserDefaults.standard

        let target = defaults.double(forKey: AppSettings.Key.dailyTargetHours) * 3600
        let vacationByDay = vacation.byDay
        let today = calendar.startOfDay(for: now)
        let open = sessions.first { $0.isOpen }
        let todayClosed = sessions
            .filter { !$0.isOpen && calendar.isDate($0.start, inSameDayAs: now) }
            .reduce(0) { $0 + $1.duration() }
        let balance = TimeAccount.balance(sessions.map { $0.accountEntry(now: now) },
                                          target: target,
                                          vacation: vacationByDay,
                                          initial: Double(defaults.integer(forKey: AppSettings.Key.initialBalanceMinutes) * 60))
        let year = calendar.component(.year, from: now)
        let vacationSummary = VacationLedger.summary(vacation.map(\.ledgerEntry),
                                                     year: year,
                                                     allowance: AppSettings.vacationAllowance(for: year),
                                                     today: now)

        let snapshot = WidgetSnapshot(
            day: today,
            sessionStart: open?.start,
            pausedAt: open?.pausedAt,
            closedBreakSeconds: Double((open?.breakMinutes ?? 0) * 60),
            todayClosedSeconds: todayClosed,
            todayTarget: TimeAccount.target(target, vacation: vacationByDay[today] ?? 0),
            balance: balance,
            vacationRemaining: vacationSummary.remaining,
            workplaceName: open?.workplace?.name
        )
        guard snapshot != WidgetSnapshot.load() else { return }
        snapshot.save()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshot.widgetKind)
    }
}
