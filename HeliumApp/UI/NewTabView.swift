import SwiftUI

struct NewTabView: View {
    @EnvironmentObject private var browser: BrowserStore
    @ObservedObject var tab: BrowserTab
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private let quickLinks: [(String, String, String)] = [
        ("Wikipedia", "w.circle.fill", "https://wikipedia.org"),
        ("GitHub", "chevron.left.forwardslash.chevron.right", "https://github.com"),
        ("YouTube", "play.rectangle.fill", "https://youtube.com"),
        ("Reddit", "bubble.left.and.bubble.right.fill", "https://reddit.com")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                Spacer(minLength: 54)
                brand
                searchField
                quickLinkGrid
                privacySummary
                Spacer(minLength: 40)
            }
            .frame(maxWidth: 680)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .background(
            LinearGradient(
                colors: [Color(red: 0.89, green: 0.91, blue: 1.0), Color(uiColor: .systemBackground)],
                startPoint: .top,
                endPoint: .center
            )
            .opacity(0.6)
        )
    }

    private var brand: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.35, green: 0.45, blue: 0.95), Color(red: 0.15, green: 0.25, blue: 0.70)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Circle().fill(.white.opacity(0.9)).frame(width: 20, height: 20).offset(x: -13, y: -15)
                Circle().fill(.white.opacity(0.72)).frame(width: 14, height: 14).offset(x: 16, y: 1)
                Circle().fill(.white.opacity(0.62)).frame(width: 9, height: 9).offset(x: -2, y: 20)
            }
            .frame(width: 72, height: 72)
            .shadow(color: .blue.opacity(0.22), radius: 18, y: 7)
            Text("Helium")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
            Text(tab.isPrivate ? "Private browsing" : "Quiet browsing by default")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search or enter address", text: $query)
                .focused($searchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.webSearch)
                .submitLabel(.go)
                .onSubmit { browser.navigate(query, in: tab) }
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.07), radius: 16, y: 5)
    }

    private var quickLinkGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 12)], spacing: 12) {
            ForEach(quickLinks, id: \.0) { link in
                Button {
                    browser.navigate(link.2, in: tab)
                } label: {
                    VStack(spacing: 9) {
                        Image(systemName: link.1)
                            .font(.title2)
                            .foregroundStyle(.tint)
                        Text(link.0)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 82)
                    .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var privacySummary: some View {
        Label("Trackers, ads, cookie banners, and fingerprinting are blocked locally", systemImage: "shield.checkered")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 6)
    }
}
