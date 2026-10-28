import SwiftData

extension ModelContext {
    /// Deletes and saves right away, so the deletion survives even if the app is closed
    /// before SwiftData's autosave runs, and updates the widgets.
    @MainActor
    func deleteAndSave(_ models: [any PersistentModel]) {
        for model in models { delete(model) }
        try? save()
        WidgetBridge.refresh()
    }
}
