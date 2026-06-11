import SwiftUI

struct ResultCelebrationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let phase: GamePhase
    let mode: GameMode
    let round: Int
    let onRestart: () -> Void
    let onMenu: () -> Void

    @State private var appeared = false
    @State private var dadBounce = false
    @State private var daughterBounce = false
    @State private var dadWobble = false
    @State private var sparkleSpin = false
    @State private var confettiFall = false

    private var dadWon: Bool { phase == .dadWon }
    private var isPad: Bool { AdaptiveLayout.isPad(horizontalSizeClass) }

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.5 : 0).ignoresSafeArea()

            if dadWon { confettiLayer }

            VStack(spacing: isPad ? 24 : 20) {
                characterStage
                textBlock
                actionButtons
            }
            .padding(isPad ? 36 : 28)
            .frame(maxWidth: AdaptiveLayout.resultCardMaxWidth(horizontalSizeClass))
            .background {
                RoundedRectangle(cornerRadius: isPad ? 32 : 28)
                    .fill(.white)
                    .shadow(color: dadWon ? .orange.opacity(0.25) : .blue.opacity(0.2), radius: 24, y: 8)
            }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)
            .padding(32)
        }
        .onAppear { startAnimations() }
    }

    private var characterStage: some View {
        ZStack {
            if dadWon {
                HStack(spacing: 8) {
                    Text("✨").font(.system(size: 28))
                        .rotationEffect(.degrees(sparkleSpin ? 360 : 0))
                        .offset(y: dadBounce ? -10 : 6)
                    Text("😎")
                        .font(.system(size: 72))
                        .offset(y: dadBounce ? -14 : 4)
                        .rotationEffect(.degrees(dadBounce ? -4 : 4))
                    Text("⭐").font(.system(size: 28))
                        .rotationEffect(.degrees(sparkleSpin ? -360 : 0))
                        .offset(y: dadBounce ? -10 : 6)
                }
                Text("👧")
                    .font(.system(size: 36))
                    .opacity(0.35)
                    .offset(x: 50, y: 28)
                    .rotationEffect(.degrees(15))
            } else {
                HStack(alignment: .bottom, spacing: 20) {
                    Text("😅")
                        .font(.system(size: 56))
                        .rotationEffect(.degrees(dadWobble ? -12 : 12))
                        .offset(x: dadWobble ? -4 : 4)
                    Text("😜")
                        .font(.system(size: 64))
                        .offset(y: daughterBounce ? -18 : 0)
                        .rotationEffect(.degrees(daughterBounce ? -8 : 8))
                }
            }
        }
        .frame(height: isPad ? 130 : 110)
    }

    private var textBlock: some View {
        VStack(spacing: 10) {
            Text(headline)
                .font(.system(size: isPad ? 40 : 34, weight: .heavy, design: .rounded))
                .foregroundStyle(dadWon
                    ? Color(red: 0.95, green: 0.55, blue: 0.15)
                    : Color(red: 0.35, green: 0.55, blue: 0.95))

            Text(subtitle)
                .font(.system(size: isPad ? 19 : 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.85))
                .multilineTextAlignment(.center)

            Text(detail)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var headline: String {
        dadWon ? L10n.dadWinHeadline : L10n.daughterWinHeadline
    }

    private var subtitle: String {
        mode.resultSubtitle(dadWon: dadWon)
    }

    private var detail: String {
        if dadWon {
            return L10n.dadWinDetail(round: round)
        }
        return L10n.daughterWinDetail(round: round)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onRestart) {
                Text(dadWon ? L10n.restartAfterDadWin : L10n.restartAfterDaughterWin)
                    .font(.system(size: isPad ? 21 : 19, weight: .heavy, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isPad ? 16 : 14)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(dadWon
                                ? Color(red: 0.95, green: 0.55, blue: 0.15)
                                : Color(red: 0.4, green: 0.7, blue: 0.45))
                    }
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            Button(action: onMenu) {
                Text(L10n.backToMenu)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var confettiLayer: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let symbols = ["🎉", "⭐", "✨", "🏆", "👏"]
                Text(symbols[i % symbols.count])
                    .font(.system(size: CGFloat(18 + (i % 3) * 6)))
                    .offset(
                        x: CGFloat([-120, -60, 0, 60, 120, -90, 90, -40, 40, -100, 100, 0][i]),
                        y: confettiFall ? CGFloat(280 + (i % 4) * 40) : CGFloat(-80 - (i % 3) * 30)
                    )
                    .opacity(confettiFall ? 0 : 0.9)
                    .rotationEffect(.degrees(confettiFall ? Double(i * 47) : 0))
            }
        }
        .allowsHitTesting(false)
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            appeared = true
        }

        if dadWon {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                dadBounce = true
            }
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                sparkleSpin = true
            }
            withAnimation(.easeIn(duration: 1.8).delay(0.2)) {
                confettiFall = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
                dadWobble = true
            }
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                daughterBounce = true
            }
        }
    }
}

#Preview("爸爸赢") {
    ResultCelebrationView(phase: .dadWon, mode: .twoPlayer, round: 12, onRestart: {}, onMenu: {})
}

#Preview("女儿赢") {
    ResultCelebrationView(phase: .daughterWon, mode: .twoPlayer, round: 8, onRestart: {}, onMenu: {})
}
