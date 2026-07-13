import SwiftUI

struct NewTabView: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab

    @State private var customShortcuts: [QuickLink] = []
    @State private var isAddingShortcut = false
    @State private var shortcutName = ""
    @State private var shortcutAddress = ""

    private let defaultShortcuts: [QuickLink] = [
        QuickLink(
            title: "Cover Your Tracks",
            symbol: "hand.raised.fingers.spread.fill",
            tint: Color(red: 0.08, green: 0.33, blue: 0.22),
            address: "https://coveryourtracks.eff.org"
        ),
        QuickLink(
            title: "PrivacyTests.org",
            symbol: "checkmark",
            tint: Color(red: 0.08, green: 0.72, blue: 0.02),
            address: "https://privacytests.org"
        ),
        QuickLink(
            title: "Browserleaks",
            symbol: "touchid",
            tint: Color(red: 0.10, green: 0.10, blue: 0.11),
            address: "https://browserleaks.com"
        ),
        QuickLink(
            title: "Homepage",
            asset: "HeliumMark",
            address: "https://helium.computer"
        ),
        QuickLink(
            title: "Techlore",
            symbol: "lock.shield.fill",
            tint: Color(red: 0.03, green: 0.20, blue: 0.27),
            address: "https://techlore.tech"
        )
    ]

    var body: some View {
        GeometryReader { proxy in
            let layout = ShortcutLayout(width: proxy.size.width)

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 32)
                    shortcutGrid(layout: layout)
                    Spacer(minLength: 32)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    presentShortcutEditor()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.02, green: 0.11, blue: 0.23))
                        .frame(width: 34, height: 34)
                        .background(
                            Color(red: 0.835, green: 0.89, blue: 0.996),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Customize shortcuts")
                .padding(16)
            }
        }
        .background(Color(red: 0.992, green: 0.973, blue: 0.984))
        .sheet(isPresented: $isAddingShortcut) {
            shortcutEditor
        }
    }

    private func shortcutGrid(layout: ShortcutLayout) -> some View {
        LazyVGrid(columns: layout.columns, spacing: layout.rowSpacing) {
            ForEach(defaultShortcuts + customShortcuts) { link in
                shortcutButton(link, width: layout.itemWidth)
            }

            Button {
                presentShortcutEditor()
            } label: {
                shortcutLabel(
                    title: "Add shortcut",
                    symbol: "plus",
                    asset: nil,
                    tint: Color(red: 0.02, green: 0.11, blue: 0.23),
                    width: layout.itemWidth
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add shortcut")
        }
        .frame(maxWidth: layout.gridWidth)
        .padding(.horizontal, 16)
    }

    private func shortcutButton(_ link: QuickLink, width: CGFloat) -> some View {
        Button {
            browser.navigate(link.address, in: tab)
        } label: {
            shortcutLabel(
                title: link.title,
                symbol: link.symbol,
                asset: link.asset,
                tint: link.tint,
                width: width
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(link.title)
    }

    private func shortcutLabel(
        title: String,
        symbol: String?,
        asset: String?,
        tint: Color,
        width: CGFloat
    ) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color(red: 0.898, green: 0.89, blue: 0.89))

                if let asset {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                } else if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(tint)
                }
            }
            .frame(width: 48, height: 48)

            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(red: 0.07, green: 0.07, blue: 0.08))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: width)
        }
        .frame(width: width)
        .contentShape(Rectangle())
    }

    private var shortcutEditor: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $shortcutName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                TextField("URL", text: $shortcutAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            }
            .navigationTitle("Add shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isAddingShortcut = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addShortcut()
                    }
                    .disabled(
                        shortcutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        shortcutAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func presentShortcutEditor() {
        shortcutName = ""
        shortcutAddress = ""
        isAddingShortcut = true
    }

    private func addShortcut() {
        let name = shortcutName.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = shortcutAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !address.isEmpty else { return }

        customShortcuts.append(
            QuickLink(
                title: name,
                symbol: "globe",
                tint: Color(red: 0.02, green: 0.11, blue: 0.23),
                address: address
            )
        )
        isAddingShortcut = false
    }
}

private struct QuickLink: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String?
    let asset: String?
    let tint: Color
    let address: String

    init(
        title: String,
        symbol: String? = nil,
        asset: String? = nil,
        tint: Color = .primary,
        address: String
    ) {
        self.title = title
        self.symbol = symbol
        self.asset = asset
        self.tint = tint
        self.address = address
    }
}

private struct ShortcutLayout {
    let itemWidth: CGFloat
    let gridWidth: CGFloat
    let rowSpacing: CGFloat
    let columns: [GridItem]

    init(width: CGFloat) {
        let count = width >= 600 ? 6 : 3
        let spacing: CGFloat = width >= 600 ? 12 : 10
        let availableWidth = min(width - 32, width >= 600 ? 680 : width - 32)
        let itemWidth = min(102, (availableWidth - (CGFloat(count - 1) * spacing)) / CGFloat(count))

        self.itemWidth = itemWidth
        self.gridWidth = availableWidth
        self.rowSpacing = 28
        self.columns = Array(
            repeating: GridItem(.fixed(itemWidth), spacing: spacing, alignment: .top),
            count: count
        )
    }
}
