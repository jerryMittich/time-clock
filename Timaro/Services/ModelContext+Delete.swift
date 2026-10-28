import SwiftData

extension ModelContext {
    /// Deletes and saves right away, so the deletion survives even if the app is closed
    /// before SwiftData's autosave runs, and updates the widgets.
    ///
    /// Views must not keep showing a model after it is deleted: SwiftData traps when a
    /// deleted, saved model is read (e.g. by a row animating out). Lists therefore show
    /// value snapshots and delete by identifier.
    @MainActor
    func deleteAndSave(_ ids: [PersistentIdentifier]) {
        for id in ids {
            delete(model(for: id))
        }
        try? save()
        WidgetBridge.refresh()
    }
}
