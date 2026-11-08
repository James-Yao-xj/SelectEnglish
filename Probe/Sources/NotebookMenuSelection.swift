import AppKit

/// Bind notebook menu items to record identity so prepending records cannot change their target.
enum NotebookMenuSelection {
    static func item(for entry: SavedAnalysis, title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.representedObject = entry.id
        return item
    }

    /// Resolve the selected record by UUID, never by its current array position or display title.
    static func entry(for item: NSMenuItem?, in entries: [SavedAnalysis]) -> SavedAnalysis? {
        guard let id = item?.representedObject as? UUID else { return nil }
        return entries.first { $0.id == id }
    }
}
