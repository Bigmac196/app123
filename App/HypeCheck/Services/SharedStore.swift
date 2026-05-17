import Foundation

/// App Group identifier — must match the capability enabled on BOTH the app
/// and the share-extension targets in the Xcode project.
enum AppGroup {
    static let identifier = "group.com.hypecheck.app"
}

/// Lightweight handoff between the Share Extension and the main app via the
/// App Group container. The extension writes a small JSON "pending check";
/// the app consumes it on deep-link open.
struct PendingCheck: Codable {
    let id: UUID
    let url: URL
    let pageText: String?
}

final class SharedStore {
    static let shared = SharedStore()
    private init() {}

    private var directory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)?
            .appendingPathComponent("pending", isDirectory: true)
    }

    func writePending(_ check: PendingCheck) {
        guard let dir = directory else { return }
        try? FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("\(check.id.uuidString).json")
        try? JSONEncoder().encode(check).write(to: file, options: .atomic)
    }

    func takePending(id: UUID) -> PendingCheck? {
        guard let dir = directory else { return nil }
        let file = dir.appendingPathComponent("\(id.uuidString).json")
        guard let data = try? Data(contentsOf: file),
              let check = try? JSONDecoder().decode(PendingCheck.self, from: data)
        else { return nil }
        try? FileManager.default.removeItem(at: file)
        return check
    }
}
