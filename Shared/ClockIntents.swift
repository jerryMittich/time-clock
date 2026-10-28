import AppIntents

// Buttons in the widget. As LiveActivityIntents they run in the app's process (iOS
// launches the app in the background if needed), so they use the same database and
// rules as the buttons in the app. The widget target only needs the declarations.

struct StartShiftIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Start"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await ClockActions.run(.start)
        return .result()
    }
}

struct StartBreakIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Break"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await ClockActions.run(.startBreak)
        return .result()
    }
}

struct EndBreakIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Resume"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await ClockActions.run(.endBreak)
        return .result()
    }
}

struct FinishShiftIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Finish"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await ClockActions.run(.finish)
        return .result()
    }
}

enum ClockActions {
    enum Action { case start, startBreak, endBreak, finish }

    @MainActor
    static func run(_ action: Action) {
        #if !TIMARO_WIDGET
        let clock = ClockService.shared
        switch action {
        case .start: clock.clockIn(at: clock.lastWorkplace())
        case .startBreak: clock.startBreak()
        case .endBreak: clock.endBreak()
        case .finish: clock.clockOut()
        }
        #endif
    }
}
