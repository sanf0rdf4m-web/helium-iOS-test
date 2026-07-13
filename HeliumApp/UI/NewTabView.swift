import SwiftUI

struct NewTabView: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab

    @State private var customShortcuts: [QuickLink] = []
    @State private var isAddingShortcut = false
    @State private var shortcutName = ""
    @State private var shortcutAddress = ""

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                shortcutGrid(width: proxy.size.width)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .overlay(alignment: .bottomTrailing) {
                Button(action: presentShortcutEditor) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(HeliumTheme.primaryText)
                        .frame(width: 32, height: 32)
                        .background(HeliumTheme.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Customize this page")
                .padding(14)
            }
        }
        .background(HeliumTheme.content)
        .sheet(isPresented: $isAddingShortcut) {
            shortcutEditor
                .presentationDetents([.height(310)])
                .presentationBackground(HeliumTheme.raised)
        }
    }

    @ViewBuilder
    private func shortcutGrid(width: CGFloat) -> some View {
        let count = width >= 760 ? 6 : width >= 500 ? 4 : 3
        let itemWidth: CGFloat = 96
        let spacing: CGFloat = 12
        let columns = Array(repeating: GridItem(.fixed(itemWidth), spacing: spacing), count: count)

        if customShortcuts.isEmpty {
            Button(action: presentShortcutEditor) {
                ShortcutLabel(title: "Add shortcut", symbol: "plus")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add shortcut")
        } else {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(customShortcuts) { shortcut in
                    shortcutButton(shortcut)
                }

                Button(action: presentShortcutEditor) {
                    ShortcutLabel(title: "Add shortcut", symbol: "plus")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add shortcut")
            }
            .frame(maxWidth: (CGFloat(count) * itemWidth) + (CGFloat(count - 1) * spacing))
            .padding(.horizontal, 16)
        }
    }

    private func shortcutButton(_ shortcut: QuickLink) -> some View {
        Button {
            browser.navigate(shortcut.address, in: tab)
        } label: {
            ShortcutLabel(title: shortcut.title, symbol: "globe")
        }
        .buttonStyle(.plain)
        .accessibilityLabel(shortcut.title)
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
            .scrollContentBackground(.hidden)
            .background(HeliumTheme.raised)
            .navigationTitle("Add shortcut")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isAddingShortcut = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addShortcut)
                        .disabled(!canAddShortcut)
                }
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private var canAddShortcut: Bool {
        !shortcutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !shortcutAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func presentShortcutEditor() {
        shortcutName = ""
        shortcutAddress = ""
        isAddingShortcut = true
    }

    private func addShortcut() {
        guard canAddShortcut else { return }
        customShortcuts.append(
            QuickLink(
                title: shortcutName.trimmingCharacters(in: .whitespacesAndNewlines),
                address: shortcutAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        isAddingShortcut = false
    }
}

private struct ShortcutLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(HeliumTheme.primaryText)
                .frame(width: 40, height: 40)
                .background(
                    HeliumTheme.tile,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )

            Text(title)
                .font(.system(size: 12.5))
                .foregroundStyle(HeliumTheme.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: 96)
        }
        .contentShape(Rectangle())
    }
}

private struct QuickLink: Identifiable {
    let id = UUID()
    let title: String
    let address: String
}
