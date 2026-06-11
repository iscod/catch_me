import SwiftUI

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let mode: GameMode

    @State private var state: GameState
    @State private var aiTask: Task<Void, Never>?
    @State private var isAnimating = false
    @State private var animatingEffect: BoardEffect?

    private var isPad: Bool { AdaptiveLayout.isPad(horizontalSizeClass) }

    init(mode: GameMode) {
        self.mode = mode
        _state = State(initialValue: GameState(mode: mode))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1.0, green: 0.93, blue: 0.8), Color(red: 0.78, green: 0.92, blue: 1.0)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: isPad ? 20 : 10) {
                topBar
                statusBar
                itemHintBar
                    .opacity(showItemHint ? 1 : 0)
                    .accessibilityHidden(!showItemHint)
                BoardView(
                    state: state,
                    interactive: boardInteractive
                ) { cell in
                    humanMove(to: cell)
                }
                .padding(.horizontal, isPad ? 40 : 16)
                Spacer(minLength: 0)
            }
            .padding(.top, isPad ? 20 : 8)
            .adaptiveCentered(maxWidth: AdaptiveLayout.gameContentMaxWidth(horizontalSizeClass))

            if state.phase != .playing {
                ResultCelebrationView(
                    phase: state.phase,
                    mode: mode,
                    round: state.round,
                    onRestart: restart,
                    onMenu: {
                        aiTask?.cancel()
                        dismiss()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear { runAIIfNeeded() }
        .onDisappear { aiTask?.cancel() }
    }

    private var boardInteractive: Bool {
        !isAnimating && !state.isAITurn && state.phase == .playing
    }

    private var showItemHint: Bool {
        state.phase == .playing
            && state.currentTurn == .daughter
            && state.hasItemsOnBoard
            && !isAnimating
            && !state.isAITurn
    }

    private var topBar: some View {
        HStack {
            iconButton(systemName: "house.fill", color: Color(red: 0.95, green: 0.45, blue: 0.3)) {
                aiTask?.cancel()
                dismiss()
            }

            Spacer()

            Text(L10n.roundCounter(state.round))
                .font(.system(size: isPad ? 24 : 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.45, green: 0.3, blue: 0.2))

            Spacer()

            iconButton(systemName: "arrow.counterclockwise", color: Color(red: 0.4, green: 0.7, blue: 0.45)) {
                restart()
            }
        }
        .padding(.horizontal, isPad ? 28 : 20)
    }

    private func iconButton(systemName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: isPad ? 22 : 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(isPad ? 14 : 10)
                .background(Circle().fill(color))
        }
        .buttonStyle(.plain)
    }

    private var statusBar: some View {
        HStack(spacing: isPad ? 14 : 10) {
            GamePiece(emoji: statusEmoji, size: isPad ? 44 : 36)
            Text(isAnimating ? statusEffectText : turnText)
                .font(.system(size: isPad ? 22 : 19, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, isPad ? 28 : 22)
        .padding(.vertical, isPad ? 14 : 10)
        .background(Capsule().fill(.white.opacity(0.85)))
        .animation(.easeInOut(duration: 0.2), value: state.currentTurn)
    }

    private var statusEmoji: String {
        guard isAnimating, let animatingEffect else { return state.currentTurn.emoji }
        switch animatingEffect {
        case .banana: return "🤕"
        case .bomb: return "💥"
        case .freeze: return "🥶"
        }
    }

    private var statusEffectText: String {
        guard let animatingEffect else { return turnText }
        switch animatingEffect {
        case .banana: return L10n.peelSlip
        case .bomb: return L10n.bombBlast
        case .freeze: return L10n.freezeFrozen
        }
    }

    private var itemHintBar: some View {
        Text(L10n.itemHint)
            .font(.system(size: isPad ? 18 : 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 0.55, green: 0.38, blue: 0.1))
            .padding(.horizontal, isPad ? 24 : 18)
            .padding(.vertical, isPad ? 10 : 8)
            .background(Capsule().fill(Color(red: 1.0, green: 0.95, blue: 0.7)))
            .frame(height: isPad ? 42 : 36)
    }

    private var turnText: String {
        if state.isAITurn {
            return L10n.aiThinking(state.currentTurn.displayName)
        }
        switch mode {
        case .twoPlayer: return L10n.twoPlayerTurn(state.currentTurn.displayName)
        default: return L10n.turnHuman
        }
    }

    private func humanMove(to cell: GridPosition) {
        guard boardInteractive else { return }
        executeMove(on: state, to: cell)
    }

    private func executeMove(on gameState: GameState, to cell: GridPosition) {
        gameState.move(to: cell)
        if gameState.phase != .playing {
            aiTask?.cancel()
            if gameState.pendingEffect != nil {
                isAnimating = true
                animatingEffect = gameState.pendingEffect
                aiTask = Task {
                    try? await Task.sleep(for: effectDuration(for: gameState.pendingEffect!))
                    guard !Task.isCancelled else { return }
                    gameState.clearPendingEffect()
                    isAnimating = false
                    animatingEffect = nil
                }
            }
            return
        }
        if let effect = gameState.pendingEffect {
            isAnimating = true
            animatingEffect = effect
            aiTask?.cancel()
            aiTask = Task {
                try? await Task.sleep(for: effectDuration(for: effect))
                guard !Task.isCancelled else { return }
                gameState.finishEffectAnimation()
                isAnimating = false
                animatingEffect = nil
                runAIIfNeeded()
            }
        } else {
            runAIIfNeeded()
        }
    }

    private func effectDuration(for effect: BoardEffect) -> Duration {
        switch effect {
        case .banana(let slip):
            switch slip {
            case .thrown: .milliseconds(1300)
            case .stepped: .milliseconds(800)
            }
        case .bomb(let blast):
            switch blast {
            case .thrown: .milliseconds(1200)
            case .stepped: .milliseconds(900)
            }
        case .freeze(let ice):
            switch ice {
            case .thrown: .milliseconds(1400)
            case .stepped: .milliseconds(900)
            }
        }
    }

    private func runAIIfNeeded() {
        guard state.phase == .playing, state.isAITurn, !isAnimating else { return }
        aiTask?.cancel()
        let gameState = state
        aiTask = Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled, gameState.phase == .playing, gameState.isAITurn,
                  let move = AIPlayer.bestMove(for: gameState) else { return }
            gameState.move(to: move)
            if gameState.phase != .playing {
                if let effect = gameState.pendingEffect {
                    await MainActor.run {
                        isAnimating = true
                        animatingEffect = effect
                    }
                    try? await Task.sleep(for: effectDuration(for: effect))
                    guard !Task.isCancelled else { return }
                    gameState.clearPendingEffect()
                    await MainActor.run {
                        isAnimating = false
                        animatingEffect = nil
                    }
                }
                return
            }
            if let effect = gameState.pendingEffect {
                await MainActor.run {
                    isAnimating = true
                    animatingEffect = effect
                }
                try? await Task.sleep(for: effectDuration(for: effect))
                guard !Task.isCancelled else { return }
                gameState.finishEffectAnimation()
                await MainActor.run {
                    isAnimating = false
                    animatingEffect = nil
                }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run { runAIIfNeeded() }
        }
    }

    private func restart() {
        aiTask?.cancel()
        isAnimating = false
        animatingEffect = nil
        state = GameState(mode: mode)
        runAIIfNeeded()
    }
}

#Preview("iPhone") {
    GameView(mode: .playAsDaughter)
}

#Preview("iPad") {
    GameView(mode: .playAsDaughter)
        .previewDevice(PreviewDevice(rawValue: "iPad Pro 11-inch (M4)"))
}
