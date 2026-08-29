import Foundation

/// "Қосымша туралы" блогы үшін бумадан оқылатын метадеректер.
enum AppInfo {
    static var name: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "GoalPyramid"
    }

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Нақты "құрастыру күні" сақталмайды, сол себепті орындалатын файлдың
    /// өзгерту күнін жуықтап қолданамыз.
    static var buildDate: Date? {
        guard let path = Bundle.main.executablePath else { return nil }
        let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        return attrs?[.modificationDate] as? Date
    }
}
