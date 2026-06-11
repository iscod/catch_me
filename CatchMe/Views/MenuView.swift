import SwiftUI

struct MenuView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedMode: GameMode = .playAsDaughter
    @State private var activeGame: GameSession?

    private var isPad: Bool { AdaptiveLayout.isPad(horizontalSizeClass) }
    private var contentWidth: CGFloat { AdaptiveLayout.menuMaxWidth(horizontalSizeClass) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.93, blue: 0.8), Color(red: 0.78, green: 0.92, blue: 1.0)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            if isPad {
                padLayout
            } else {
                phoneLayout
            }
        }
        .fullScreenCover(item: $activeGame) { session in
            GameView(mode: session.mode)
        }
    }

    // MARK: - iPhone

    private var phoneLayout: some View {
        VStack(spacing: 0) {
            ScrollView {
                menuContent
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    .adaptiveCentered(maxWidth: contentWidth)
            }

            startButton
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .adaptiveCentered(maxWidth: contentWidth)
                .background {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                }
        }
    }

    // MARK: - iPad

    private var padLayout: some View {
        VStack {
            Spacer(minLength: 24)
            menuContent
                .padding(40)
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.08), radius: 24, y: 8)
                }
                .adaptiveCentered(maxWidth: contentWidth)
            Spacer(minLength: 24)
        }
        .padding(.horizontal, 48)
    }

    private var menuContent: some View {
        VStack(spacing: isPad ? 32 : 20) {
            titleSection
            modeSection
            if isPad { startButton }
        }
    }

    private var titleSection: some View {
        VStack(spacing: isPad ? 10 : 6) {
            HStack(spacing: 12) {
                Text("👨")
                Text("🏃")
                    .font(.system(size: isPad ? 48 : 40))
                Text("👧")
            }
            .font(.system(size: isPad ? 64 : 52))
            Text(L10n.appTitle)
                .font(.system(size: isPad ? 42 : 34, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.95, green: 0.45, blue: 0.3))
            Text(L10n.appSubtitle)
                .font(.system(size: isPad ? 18 : 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var modeSection: some View {
        VStack(spacing: isPad ? 16 : 12) {
            sectionTitle(L10n.chooseMode)
            if isPad {
                HStack(spacing: 16) {
                    ForEach(GameMode.allCases) { mode in
                        padModeCard(mode)
                    }
                }
            } else {
                ForEach(GameMode.allCases) { mode in
                    phoneModeCard(mode)
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isPad ? 22 : 20, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity, alignment: isPad ? .center : .leading)
    }

    // iPad: 竖排卡片,三列等宽
    private func padModeCard(_ mode: GameMode) -> some View {
        Button {
            selectedMode = mode
        } label: {
            VStack(spacing: 10) {
                modeIcon(mode)
                Text(mode.title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Text(mode.subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: selectedMode == mode ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(selectedMode == mode ? Color(red: 0.95, green: 0.45, blue: 0.3) : Color.gray.opacity(0.4))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, minHeight: 168)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.98, green: 0.96, blue: 0.93))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                selectedMode == mode ? Color(red: 0.95, green: 0.45, blue: 0.3) : Color.clear,
                                lineWidth: 3
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // iPhone: 横排卡片
    private func phoneModeCard(_ mode: GameMode) -> some View {
        Button {
            selectedMode = mode
        } label: {
            HStack(spacing: 14) {
                modeIcon(mode)
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(mode.subtitle)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: selectedMode == mode ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(selectedMode == mode ? Color(red: 0.95, green: 0.45, blue: 0.3) : Color.gray.opacity(0.4))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white.opacity(0.85))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(
                                selectedMode == mode ? Color(red: 0.95, green: 0.45, blue: 0.3) : .clear,
                                lineWidth: 3
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private var startButton: some View {
        Button {
            activeGame = GameSession(mode: selectedMode)
        } label: {
            Text(L10n.startGame)
                .font(.system(size: isPad ? 28 : 24, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, isPad ? 22 : 18)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.75, blue: 0.4), Color(red: 0.25, green: 0.6, blue: 0.35)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.top, isPad ? 4 : 0)
    }

    @ViewBuilder
    private func modeIcon(_ mode: GameMode) -> some View {
        let iconSize: CGFloat = isPad ? 36 : 32
        switch mode {
        case .twoPlayer:
            HStack(spacing: 4) {
                Text("👨").font(.system(size: iconSize))
                Text("👧").font(.system(size: iconSize))
            }
        case .playAsDad:
            Text("👨").font(.system(size: iconSize + 4))
        case .playAsDaughter:
            Text("👧").font(.system(size: iconSize + 4))
        }
    }
}

struct GameSession: Identifiable {
    let id = UUID()
    let mode: GameMode
}

#Preview("iPhone") {
    MenuView()
}

#Preview("iPad") {
    MenuView()
        .previewDevice(PreviewDevice(rawValue: "iPad Pro 11-inch (M4)"))
}
