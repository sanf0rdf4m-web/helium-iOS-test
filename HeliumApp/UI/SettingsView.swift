import SwiftUI
import HeliumCore

struct SettingsView: View {
    @EnvironmentObject private var browser: BrowserStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedCategory: SettingsCategory = .appearance
    @State private var searchText = ""
    @State private var showingClearConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var isClearing = false

    @AppStorage("helium.appearance.theme") private var theme = "Dark"
    @AppStorage("helium.appearance.browserLayout") private var browserLayout = "Vertical"
    @AppStorage("helium.appearance.verticalTabsRight") private var verticalTabsRight = false
    @AppStorage("helium.appearance.centerAddressBar") private var centerAddressBar = false
    @AppStorage("helium.appearance.minimalAddressBar") private var minimalAddressBar = false
    @AppStorage("helium.appearance.framelessMode") private var framelessMode = false
    @AppStorage("helium.appearance.roundedWebContent") private var roundedWebContent = true
    @AppStorage("helium.appearance.showHomeButton") private var showHomeButton = false
    @AppStorage("helium.appearance.bookmarksBar") private var bookmarksBar = "Only show on New Tab page"
    @AppStorage("helium.appearance.showBookmarkGroups") private var showBookmarkGroups = false
    @AppStorage("helium.appearance.sidePanel") private var sidePanel = "Right"
    @AppStorage("helium.appearance.showTabPreviews") private var showTabPreviews = true
    @AppStorage("helium.performance.memorySaver") private var memorySaver = true
    @AppStorage("helium.performance.preloadPages") private var preloadPages = false
    @AppStorage("helium.startup.behavior") private var startupBehavior = "Continue where you left off"
    @AppStorage("helium.accessibility.fullKeyboardAccess") private var fullKeyboardAccess = true
    @AppStorage("helium.system.backgroundActivity") private var backgroundActivity = true

    var body: some View {
        GeometryReader { proxy in
            Group {
                if horizontalSizeClass == .regular, proxy.size.width >= 700 {
                    regularLayout
                } else {
                    compactLayout
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HeliumTheme.window)
        }
        .foregroundStyle(HeliumTheme.primaryText)
        .confirmationDialog(
            "Clear history, cookies, caches, and website storage?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Browsing Data", role: .destructive, action: clearBrowsingData)
        }
        .confirmationDialog(
            "Restore Helium appearance settings to their defaults?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restore Defaults", role: .destructive, action: restoreAppearanceDefaults)
        }
    }

    private var regularLayout: some View {
        HStack(spacing: 0) {
            categoryRail
                .frame(width: 270)

            Rectangle()
                .fill(HeliumTheme.subtleBorder)
                .frame(width: 1)

            VStack(spacing: 14) {
                searchField
                settingsContent
            }
            .frame(maxWidth: 570)
            .padding(.horizontal, 34)
            .padding(.top, 12)

            Spacer(minLength: 18)
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 24, weight: .semibold))
                .padding(.horizontal, 18)
                .padding(.top, 14)

            searchField
                .padding(.horizontal, 16)

            Menu {
                ForEach(SettingsCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Label(category.rawValue, systemImage: category.symbol)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selectedCategory.symbol)
                        .frame(width: 20)
                    Text(selectedCategory.rawValue)
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(HeliumTheme.secondaryText)
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(
                    HeliumTheme.raised,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .accessibilityLabel("Settings category, \(selectedCategory.rawValue)")

            settingsContent
        }
    }

    private var categoryRail: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings")
                .font(.system(size: 24, weight: .semibold))
                .padding(.leading, 18)
                .padding(.top, 14)
                .padding(.bottom, 14)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 2) {
                    ForEach(filteredCategories) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: category.symbol)
                                    .font(.system(size: 14, weight: .medium))
                                    .frame(width: 20)
                                Text(category.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(
                                selectedCategory == category
                                    ? HeliumTheme.primaryText
                                    : HeliumTheme.secondaryText
                            )
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(
                                selectedCategory == category ? HeliumTheme.selected : Color.clear,
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                    }

                    if filteredCategories.isEmpty {
                        Text("No matching categories")
                            .font(.system(size: 13))
                            .foregroundStyle(HeliumTheme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 16)
            }
        }
        .background(HeliumTheme.window)
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(HeliumTheme.secondaryText)

            TextField("Search settings", text: $searchText)
                .font(.system(size: 13.5))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(HeliumTheme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear settings search")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(
            HeliumTheme.field,
            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(HeliumTheme.focus, lineWidth: 1.5)
        }
    }

    private var settingsContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            categoryDetail
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder
    private var categoryDetail: some View {
        switch selectedCategory {
        case .profiles:
            informationalSection(
                title: "Profiles",
                rows: [
                    ("Personal profile", "Bookmarks, history, and preferences are stored on this device."),
                    ("Private browsing", "Private tabs use a non-persistent WebKit data store.")
                ]
            )
        case .appearance:
            appearanceSection
        case .privacy:
            privacySection
        case .performance:
            performanceSection
        case .searchEngine:
            searchEngineSection
        case .defaultBrowser:
            informationalSection(
                title: "Default browser",
                rows: [("Make Helium your default", "Choose Helium in the iOS or iPadOS Default Browser App setting.")]
            )
        case .onStartup:
            startupSection
        case .languages:
            informationalSection(
                title: "Languages",
                rows: [("App language", "Helium currently follows your system language and region settings.")]
            )
        case .downloads:
            informationalSection(
                title: "Downloads",
                rows: [("Download location", "Downloads are managed through the iOS share and Files interfaces.")]
            )
        case .accessibility:
            accessibilitySection
        case .system:
            systemSection
        case .reset:
            resetSection
        case .extensions:
            informationalSection(
                title: "Extensions",
                rows: [("Browser extensions", "Desktop Chromium extensions are not available in this WebKit-based port.")]
            )
        case .about:
            aboutSection
        }
    }

    private var appearanceSection: some View {
        settingsSection(title: "Appearance") {
            SettingsValueRow(title: "Theme", value: "", showsExternalLink: true)
            SettingsDivider()
            SettingsValueRow(title: "Customize your toolbar", value: "", showsExternalLink: true)
            SettingsDivider()
            SettingsPickerRow(
                title: "Browser layout",
                selection: $browserLayout,
                options: ["Vertical", "Horizontal"]
            )
            SettingsToggleRow(title: "Show vertical tabs on right side", isOn: $verticalTabsRight, inset: true)
            SettingsToggleRow(title: "Center the address bar", isOn: $centerAddressBar, inset: true)
            SettingsToggleRow(title: "Minimal address bar", isOn: $minimalAddressBar, inset: true)
            SettingsToggleRow(
                title: "Frameless mode",
                subtitle: "Automatically hide browser UI until you hover the window edge",
                isOn: $framelessMode
            )
            SettingsDivider()
            SettingsToggleRow(title: "Show a rounded frame around web contents", isOn: $roundedWebContent)
            SettingsDivider()
            SettingsToggleRow(title: "Show home button", subtitle: "Disabled", isOn: $showHomeButton)
            SettingsDivider()
            SettingsPickerRow(
                title: "Bookmarks bar",
                selection: $bookmarksBar,
                options: ["Always", "Only show on New Tab page", "Never"]
            )
            SettingsToggleRow(title: "Show tab groups in bookmarks bar", isOn: $showBookmarkGroups)
            SettingsDivider()
            SettingsValueRow(title: "Side panel position", value: "")
            SettingsPickerRow(
                title: "Helium Panels",
                selection: $sidePanel,
                options: ["Right", "Left"]
            )
            SettingsDivider()
            SettingsValueRow(title: "Tab hover preview card", value: "")
            SettingsToggleRow(title: "Show tab preview images", isOn: $showTabPreviews, inset: true)
        }
    }

    private var privacySection: some View {
        settingsSection(title: "Privacy and security") {
            SettingsPickerRow(
                title: "Protection level",
                selection: privacyBinding(\.shieldLevel),
                options: ShieldLevel.allCases,
                titleForOption: { $0.rawValue.capitalized }
            )
            SettingsDivider()
            SettingsToggleRow(title: "Block ads", isOn: privacyBinding(\.blockAds))
            SettingsToggleRow(title: "Block trackers", isOn: privacyBinding(\.blockTrackers))
            SettingsToggleRow(title: "Block third-party cookies", isOn: privacyBinding(\.blockThirdPartyCookies))
            SettingsToggleRow(title: "Fingerprint protection", isOn: privacyBinding(\.blockFingerprinting))
            SettingsToggleRow(title: "Upgrade connections to HTTPS", isOn: privacyBinding(\.upgradeConnections))
            SettingsToggleRow(title: "Global Privacy Control", isOn: privacyBinding(\.sendGlobalPrivacyControl))
            SettingsToggleRow(title: "Do Not Track", isOn: privacyBinding(\.sendDoNotTrack))
        }
    }

    private var performanceSection: some View {
        settingsSection(title: "Performance") {
            SettingsToggleRow(
                title: "Memory Saver",
                subtitle: "Reduce memory used by tabs you have not opened recently",
                isOn: $memorySaver
            )
            SettingsDivider()
            SettingsToggleRow(
                title: "Preload pages",
                subtitle: "Load likely destinations before you select them",
                isOn: $preloadPages
            )
        }
    }

    private var searchEngineSection: some View {
        settingsSection(title: "Search engine") {
            SettingsPickerRow(
                title: "Search engine used in the address bar",
                selection: preferenceBinding(\.searchEngine),
                options: SearchEngine.allCases,
                titleForOption: { $0.displayName }
            )
        }
    }

    private var startupSection: some View {
        settingsSection(title: "On startup") {
            SettingsPickerRow(
                title: "When Helium starts",
                selection: $startupBehavior,
                options: ["Open the New Tab page", "Continue where you left off"]
            )
        }
    }

    private var accessibilitySection: some View {
        settingsSection(title: "Accessibility") {
            SettingsToggleRow(
                title: "Full keyboard access",
                subtitle: "Keep browser controls reachable from a hardware keyboard",
                isOn: $fullKeyboardAccess
            )
            SettingsDivider()
            SettingsValueRow(title: "Text size", value: "Managed by iOS")
        }
    }

    private var systemSection: some View {
        settingsSection(title: "System") {
            SettingsToggleRow(
                title: "Allow background activity",
                subtitle: "Let active transfers finish when Helium leaves the foreground",
                isOn: $backgroundActivity
            )
            SettingsDivider()
            SettingsValueRow(title: "Browser engine", value: "Apple WebKit")
        }
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reset settings")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(HeliumTheme.secondaryText)

            VStack(spacing: 0) {
                Button {
                    showingResetConfirmation = true
                } label: {
                    SettingsValueRow(title: "Restore appearance settings", value: "")
                }
                .buttonStyle(.plain)

                SettingsDivider()

                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    HStack {
                        Text("Clear browsing data")
                            .foregroundStyle(Color.red)
                        Spacer()
                        if isClearing {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 48)
                }
                .buttonStyle(.plain)
                .disabled(isClearing)
            }
            .background(
                HeliumTheme.raised,
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )
        }
    }

    private var aboutSection: some View {
        settingsSection(title: "About Helium") {
            SettingsValueRow(title: "Engine", value: "Apple WebKit")
            SettingsDivider()
            SettingsValueRow(title: "Version", value: "0.1.0")
            SettingsDivider()
            Link(destination: URL(string: "https://helium.computer")!) {
                SettingsValueRow(title: "Official Helium project", value: "", showsExternalLink: true)
            }
            .buttonStyle(.plain)
            SettingsDivider()
            Text("Unofficial community port. Not affiliated with or endorsed by imput LLC. No analytics or first-party advertising.")
                .font(.system(size: 12.5))
                .foregroundStyle(HeliumTheme.secondaryText)
                .padding(16)
        }
    }

    private func informationalSection(
        title: String,
        rows: [(title: String, detail: String)]
    ) -> some View {
        settingsSection(title: title) {
            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(.system(size: 14))
                    Text(row.detail)
                        .font(.system(size: 12.5))
                        .foregroundStyle(HeliumTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if index < rows.count - 1 {
                    SettingsDivider()
                }
            }
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(HeliumTheme.secondaryText)

            VStack(spacing: 0, content: content)
                .background(
                    HeliumTheme.raised,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(HeliumTheme.subtleBorder, lineWidth: 1)
                }
        }
    }

    private var filteredCategories: [SettingsCategory] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SettingsCategory.allCases }
        return SettingsCategory.allCases.filter {
            $0.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    private func clearBrowsingData() {
        isClearing = true
        Task {
            browser.clearHistory()
            await browser.clearWebsiteData()
            isClearing = false
        }
    }

    private func restoreAppearanceDefaults() {
        theme = "Dark"
        browserLayout = "Vertical"
        verticalTabsRight = false
        centerAddressBar = false
        minimalAddressBar = false
        framelessMode = false
        roundedWebContent = true
        showHomeButton = false
        bookmarksBar = "Only show on New Tab page"
        showBookmarkGroups = false
        sidePanel = "Right"
        showTabPreviews = true
    }

    private func preferenceBinding<Value>(
        _ keyPath: WritableKeyPath<BrowserPreferences, Value>
    ) -> Binding<Value> {
        Binding(
            get: { browser.preferences[keyPath: keyPath] },
            set: { value in
                var preferences = browser.preferences
                preferences[keyPath: keyPath] = value
                browser.preferences = preferences
            }
        )
    }

    private func privacyBinding<Value>(
        _ keyPath: WritableKeyPath<PrivacySettings, Value>
    ) -> Binding<Value> {
        Binding(
            get: { browser.preferences.privacy[keyPath: keyPath] },
            set: { value in
                var preferences = browser.preferences
                preferences.privacy[keyPath: keyPath] = value
                browser.preferences = preferences
            }
        )
    }
}

private enum SettingsCategory: String, CaseIterable, Identifiable {
    case profiles = "Profiles"
    case appearance = "Appearance and behavior"
    case privacy = "Privacy and security"
    case performance = "Performance"
    case searchEngine = "Search engine"
    case defaultBrowser = "Default browser"
    case onStartup = "On startup"
    case languages = "Languages"
    case downloads = "Downloads"
    case accessibility = "Accessibility"
    case system = "System"
    case reset = "Reset settings"
    case extensions = "Extensions"
    case about = "About Helium"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .profiles: "person.crop.circle"
        case .appearance: "paintbrush"
        case .privacy: "shield.lefthalf.filled"
        case .performance: "speedometer"
        case .searchEngine: "magnifyingglass"
        case .defaultBrowser: "app.badge.checkmark"
        case .onStartup: "power"
        case .languages: "character.book.closed"
        case .downloads: "arrow.down.circle"
        case .accessibility: "figure.arms.open"
        case .system: "laptopcomputer"
        case .reset: "arrow.counterclockwise"
        case .extensions: "puzzlepiece.extension"
        case .about: "info.circle"
        }
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(HeliumTheme.border)
            .frame(height: 1)
    }
}

private struct SettingsValueRow: View {
    let title: String
    let value: String
    var showsExternalLink = false

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13.5))
                .foregroundStyle(HeliumTheme.primaryText)
            Spacer(minLength: 14)
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundStyle(HeliumTheme.secondaryText)
                    .lineLimit(1)
            }
            if showsExternalLink {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HeliumTheme.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .contentShape(Rectangle())
    }
}

private struct SettingsToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var inset = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13.5))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(HeliumTheme.secondaryText)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .controlSize(.mini)
                .tint(HeliumTheme.accent)
        }
        .padding(.leading, inset ? 64 : 16)
        .padding(.trailing, 16)
        .frame(minHeight: subtitle == nil ? 42 : 54)
    }
}

private struct SettingsPickerRow<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [Value]
    let titleForOption: (Value) -> String

    init(
        title: String,
        selection: Binding<Value>,
        options: [Value],
        titleForOption: @escaping (Value) -> String
    ) {
        self.title = title
        _selection = selection
        self.options = options
        self.titleForOption = titleForOption
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(size: 13.5))
            Spacer(minLength: 12)
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(titleForOption(option))
                        .lineLimit(1)
                        .tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(HeliumTheme.primaryText)
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
    }
}

private extension SettingsPickerRow where Value == String {
    init(title: String, selection: Binding<String>, options: [String]) {
        self.init(
            title: title,
            selection: selection,
            options: options,
            titleForOption: { $0 }
        )
    }
}
