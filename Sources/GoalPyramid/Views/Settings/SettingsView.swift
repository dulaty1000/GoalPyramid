import SwiftUI
import SwiftData
import UserNotifications
import UniformTypeIdentifiers

/// `.fileExporter`-ге берілетін жеңіл JSON құжат орауышы.
struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

/// Қосымша баптаулары. Барлық мән `@AppStorage` арқылы бірден сақталады
/// (қосымшаны жапса да сақталып қалады). "Тақырып"/"Акцент түсі" мен
/// "Интерфейс тілі" `GoalPyramidApp`/сайдбар деңгейінде де оқылатындықтан,
/// өзгерткен сәтте тиісті жерлер бетті қайта ашпай-ақ дереу жаңарады.
struct SettingsView: View {
    @AppStorage(AppSettingsKey.colorScheme) private var colorSchemeRaw = AppColorScheme.system.rawValue
    @AppStorage(AppSettingsKey.accentColor) private var accentColorRaw = AccentColorOption.blue.rawValue
    @AppStorage(AppSettingsKey.weekStart) private var weekStartRaw = WeekStartDay.monday.rawValue

    @AppStorage(AppSettingsKey.dailyReminderEnabled) private var dailyReminderEnabled = false
    @AppStorage(AppSettingsKey.dailyReminderHour) private var dailyReminderHour = 20
    @AppStorage(AppSettingsKey.dailyReminderMinute) private var dailyReminderMinute = 0
    @AppStorage(AppSettingsKey.summaryEnabled) private var summaryEnabled = false

    @State private var showingPermissionWarning = false

    @Environment(\.modelContext) private var modelContext

    @State private var exportData: Data?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingImportURL: URL?
    @State private var showingImportConfirm = false
    @State private var showingResetConfirm = false
    @State private var dataActionError: String?
    @State private var showingDataActionError = false

    @AppStorage(AppSettingsKey.trashAutoDeleteEnabled) private var trashAutoDeleteEnabled = false
    @AppStorage(AppSettingsKey.trashAutoDeleteDays) private var trashAutoDeleteDays = 30

    @AppStorage(AppSettingsKey.language) private var languageRaw = AppLanguage.kk.rawValue
    @AppStorage(AppSettingsKey.dateFormat) private var dateFormatRaw = AppDateFormat.textual.rawValue

    @AppStorage(AppSettingsKey.completionEffectsEnabled) private var completionEffectsEnabled = false
    @State private var showingShortcuts = false

    private var language: AppLanguage { AppLanguage(rawValue: languageRaw) ?? .kk }

    private var aboutDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = dailyReminderHour
                comps.minute = dailyReminderMinute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                dailyReminderHour = comps.hour ?? 20
                dailyReminderMinute = comps.minute ?? 0
            }
        )
    }

    var body: some View {
        Form {
            Section(L10n.t(.settingsAppearanceSection, language)) {
                Picker(L10n.t(.settingsTheme, language), selection: $colorSchemeRaw) {
                    ForEach(AppColorScheme.allCases) { option in
                        Text(themeTitle(option)).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.t(.settingsAccentColor, language))
                    HStack(spacing: 10) {
                        ForEach(AccentColorOption.allCases) { option in
                            accentSwatch(option)
                        }
                    }
                }
                .padding(.vertical, 4)

                Picker(L10n.t(.settingsWeekStart, language), selection: $weekStartRaw) {
                    ForEach(WeekStartDay.allCases) { option in
                        Text(weekStartTitle(option)).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(L10n.t(.settingsNotificationsSection, language)) {
                Toggle(L10n.t(.settingsDailyReminder, language), isOn: $dailyReminderEnabled)
                    .onChange(of: dailyReminderEnabled) { _, newValue in
                        if newValue {
                            requestPermissionIfNeeded(resetting: $dailyReminderEnabled)
                        }
                    }

                if dailyReminderEnabled {
                    DatePicker(L10n.t(.settingsReminderTime, language), selection: reminderTimeBinding, displayedComponents: [.hourAndMinute])
                }

                Toggle(L10n.t(.settingsSummaryReminder, language), isOn: $summaryEnabled)
                    .onChange(of: summaryEnabled) { _, newValue in
                        if newValue {
                            requestPermissionIfNeeded(resetting: $summaryEnabled)
                        }
                    }

                if showingPermissionWarning {
                    Text(L10n.t(.settingsPermissionWarning, language))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section(L10n.t(.settingsDataSection, language)) {
                Button(L10n.t(.settingsExport, language)) {
                    startExport()
                }

                Button(L10n.t(.settingsImport, language)) {
                    showingImporter = true
                }

                Button(role: .destructive) {
                    showingResetConfirm = true
                } label: {
                    Label(L10n.t(.settingsResetAll, language), systemImage: "trash.slash.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Toggle(L10n.t(.settingsTrashAutoDelete, language), isOn: $trashAutoDeleteEnabled)

                if trashAutoDeleteEnabled {
                    Picker(L10n.t(.settingsTrashAutoDeletePeriod, language), selection: $trashAutoDeleteDays) {
                        Text(L10n.t(.periodWeek, language)).tag(7)
                        Text(L10n.t(.periodMonth, language)).tag(30)
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section(L10n.t(.settingsLanguageRegionSection, language)) {
                Picker(L10n.t(.settingsInterfaceLanguage, language), selection: $languageRaw) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Picker(L10n.t(.settingsDateFormat, language), selection: $dateFormatRaw) {
                    ForEach(AppDateFormat.allCases) { option in
                        Text(dateFormatTitle(option)).tag(option.rawValue)
                    }
                }
            }

            Section(L10n.t(.settingsOtherSection, language)) {
                Toggle(L10n.t(.settingsCompletionEffects, language), isOn: $completionEffectsEnabled)

                Button(L10n.t(.settingsShortcuts, language)) {
                    showingShortcuts = true
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.t(.settingsAbout, language))
                        .font(.subheadline.bold())
                    Text("\(AppInfo.name) · \(L10n.t(.aboutVersionLabel, language)) \(AppInfo.version) (\(AppInfo.buildNumber))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let buildDate = AppInfo.buildDate {
                        Text("\(L10n.t(.aboutBuildDateLabel, language)): \(aboutDateFormatter.string(from: buildDate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(L10n.t(.aboutDescription, language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(L10n.t(.sidebarSettings, language))
        .sheet(isPresented: $showingShortcuts) {
            KeyboardShortcutsView(language: language)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: JSONDocument(data: exportData ?? Data()),
            contentType: .json,
            defaultFilename: "GoalPyramid-backup-\(Self.exportDateStamp())"
        ) { result in
            if case .failure(let error) = result {
                presentError("\(L10n.t(.errorExportFailed, language)): \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                pendingImportURL = url
                showingImportConfirm = true
            case .failure(let error):
                presentError("\(L10n.t(.errorPickFailed, language)): \(error.localizedDescription)")
            }
        }
        .confirmationDialog(
            L10n.t(.settingsImportConfirmTitle, language),
            isPresented: $showingImportConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.t(.settingsReplace, language), role: .destructive) {
                performImport()
            }
            Button(L10n.t(.settingsCancel, language), role: .cancel) {
                pendingImportURL = nil
            }
        }
        .alert(L10n.t(.settingsResetConfirmTitle, language), isPresented: $showingResetConfirm) {
            Button(L10n.t(.settingsCancel, language), role: .cancel) {}
            Button(L10n.t(.settingsReset, language), role: .destructive) {
                performReset()
            }
        } message: {
            Text(L10n.t(.settingsResetConfirmMessage, language))
        }
        .alert(L10n.t(.settingsErrorTitle, language), isPresented: $showingDataActionError) {
            Button(L10n.t(.settingsOK, language), role: .cancel) {}
        } message: {
            Text(dataActionError ?? "")
        }
    }

    private func startExport() {
        do {
            exportData = try DataBackupManager.exportData(context: modelContext)
            showingExporter = true
        } catch {
            presentError("\(L10n.t(.errorExportFailed, language)): \(error.localizedDescription)")
        }
    }

    private func performImport() {
        guard let url = pendingImportURL else { return }
        pendingImportURL = nil
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            try DataBackupManager.importData(from: data, context: modelContext)
        } catch {
            presentError("\(L10n.t(.errorImportFailed, language)): \(error.localizedDescription)")
        }
    }

    private func performReset() {
        do {
            try DataBackupManager.resetAllData(context: modelContext)
        } catch {
            presentError("\(L10n.t(.errorResetFailed, language)): \(error.localizedDescription)")
        }
    }

    private func presentError(_ message: String) {
        dataActionError = message
        showingDataActionError = true
    }

    private static func exportDateStamp() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    /// Хабарландыруды алғаш рет қосқанда жүйелік рұқсат сұрайды. Пайдаланушы
    /// рұқсат бермесе (немесе бұрын бас тартқан болса), сол toggle-ды қайта
    /// өшіріп, ескерту көрсетеді.
    private func requestPermissionIfNeeded(resetting toggle: Binding<Bool>) {
        NotificationManager.currentAuthorizationStatus { status in
            switch status {
            case .authorized, .provisional:
                showingPermissionWarning = false
            case .notDetermined:
                NotificationManager.requestAuthorization { granted in
                    if granted {
                        showingPermissionWarning = false
                    } else {
                        toggle.wrappedValue = false
                        showingPermissionWarning = true
                    }
                }
            case .denied:
                toggle.wrappedValue = false
                showingPermissionWarning = true
            @unknown default:
                break
            }
        }
    }

    private func themeTitle(_ option: AppColorScheme) -> String {
        switch option {
        case .system: return L10n.t(.themeSystem, language)
        case .light: return L10n.t(.themeLight, language)
        case .dark: return L10n.t(.themeDark, language)
        }
    }

    private func weekStartTitle(_ option: WeekStartDay) -> String {
        switch option {
        case .monday: return L10n.t(.weekStartMonday, language)
        case .sunday: return L10n.t(.weekStartSunday, language)
        }
    }

    private func dateFormatTitle(_ option: AppDateFormat) -> String {
        switch option {
        case .textual: return L10n.t(.dateFormatTextual, language)
        case .ddmmyyyy: return L10n.t(.dateFormatDDMMYYYY, language)
        case .mmddyyyy: return L10n.t(.dateFormatMMDDYYYY, language)
        case .yyyymmdd: return L10n.t(.dateFormatYYYYMMDD, language)
        }
    }

    private func accentColorTitle(_ option: AccentColorOption) -> String {
        switch option {
        case .blue: return L10n.t(.accentBlue, language)
        case .green: return L10n.t(.accentGreen, language)
        case .purple: return L10n.t(.accentPurple, language)
        case .orange: return L10n.t(.accentOrange, language)
        case .pink: return L10n.t(.accentPink, language)
        case .red: return L10n.t(.accentRed, language)
        }
    }

    private func accentSwatch(_ option: AccentColorOption) -> some View {
        let isSelected = accentColorRaw == option.rawValue
        return Circle()
            .fill(option.color)
            .frame(width: 26, height: 26)
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(isSelected ? 0.7 : 0), lineWidth: 2)
                    .padding(-3)
            )
            .overlay(
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .opacity(isSelected ? 1 : 0)
            )
            .contentShape(Circle())
            .onTapGesture { accentColorRaw = option.rawValue }
            .help(accentColorTitle(option))
    }
}
