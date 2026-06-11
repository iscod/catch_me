import SwiftUI

struct BoardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let state: GameState
    let interactive: Bool
    let onTap: (GridPosition) -> Void

    private static let lightCell = Color(red: 1.0, green: 0.97, blue: 0.88)
    private static let darkCell = Color(red: 0.93, green: 0.87, blue: 0.74)
    private static let highlight = Color(red: 0.45, green: 0.8, blue: 0.5)
    private static let bananaHighlight = Color(red: 1.0, green: 0.82, blue: 0.15)
    private static let bombHighlight = Color(red: 1.0, green: 0.45, blue: 0.35)
    private static let freezeHighlight = Color(red: 0.45, green: 0.82, blue: 1.0)
    private static let boardFrame = Color(red: 0.55, green: 0.42, blue: 0.3)

    @State private var effectVisual: EffectVisual = .idle

    private var aspect: CGFloat {
        CGFloat(GameState.boardCols) / CGFloat(GameState.boardRows)
    }

    var body: some View {
        GeometryReader { geo in
            let maxW = min(geo.size.width, AdaptiveLayout.boardMaxWidth(horizontalSizeClass))
            let maxH = min(geo.size.height, AdaptiveLayout.boardMaxHeight(horizontalSizeClass))
            let boardWidth = min(maxW, maxH * aspect)
            let cellSize = boardWidth / CGFloat(GameState.boardCols)
            let boardHeight = cellSize * CGFloat(GameState.boardRows)

            ZStack(alignment: .topLeading) {
                grid(cellSize: cellSize)
                pieces(cellSize: cellSize)
                effectOverlay(cellSize: cellSize)
            }
            .frame(width: boardWidth, height: boardHeight)
            .background {
                RoundedRectangle(cornerRadius: isPad ? 16 : 12)
                    .fill(Self.boardFrame)
            }
            .clipShape(RoundedRectangle(cornerRadius: isPad ? 16 : 12))
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .onChange(of: state.pendingEffect) { _, effect in
                guard let effect else {
                    effectVisual = .idle
                    return
                }
                runEffectAnimation(effect)
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
        .frame(maxWidth: AdaptiveLayout.boardMaxWidth(horizontalSizeClass))
        .frame(maxHeight: AdaptiveLayout.boardMaxHeight(horizontalSizeClass))
    }

    private var isPad: Bool { AdaptiveLayout.isPad(horizontalSizeClass) }

    private func grid(cellSize: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<GameState.boardRows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<GameState.boardCols, id: \.self) { col in
                        cellView(row: row, col: col, cellSize: cellSize)
                    }
                }
            }
        }
    }

    private func cellView(row: Int, col: Int, cellSize: CGFloat) -> some View {
        let cell = GridPosition(row: row, col: col)
        let isLegal = interactive && state.legalMoves.contains(cell)
        let hasBanana = state.bananaPositions.contains(cell)
        let hasBomb = state.bombPositions.contains(cell)
        let hasFreeze = state.freezePositions.contains(cell)

        return RoundedRectangle(cornerRadius: cellSize * 0.15)
            .fill((row + col).isMultiple(of: 2) ? Self.lightCell : Self.darkCell)
            .overlay {
                if isLegal {
                    BreathingHighlight(
                        cornerRadius: cellSize * 0.15,
                        inset: cellSize * 0.1,
                        color: Self.highlight
                    )
                }
                if hasBanana {
                    BreathingHighlight(
                        cornerRadius: cellSize * 0.15,
                        inset: cellSize * 0.12,
                        color: Self.bananaHighlight
                    )
                }
                if hasBomb {
                    BreathingHighlight(
                        cornerRadius: cellSize * 0.15,
                        inset: cellSize * 0.12,
                        color: Self.bombHighlight
                    )
                }
                if hasFreeze {
                    BreathingHighlight(
                        cornerRadius: cellSize * 0.15,
                        inset: cellSize * 0.12,
                        color: Self.freezeHighlight
                    )
                }
            }
            .overlay {
                if hasBanana {
                    Text("🍌")
                        .font(.system(size: cellSize * 0.42))
                        .allowsHitTesting(false)
                } else if hasBomb {
                    Text("💣")
                        .font(.system(size: cellSize * 0.42))
                        .allowsHitTesting(false)
                } else if hasFreeze {
                    Text("❄️")
                        .font(.system(size: cellSize * 0.42))
                        .allowsHitTesting(false)
                }
            }
            .frame(width: cellSize, height: cellSize)
            .contentShape(Rectangle())
            .onTapGesture {
                if isLegal { onTap(cell) }
            }
    }

    private func pieces(cellSize: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            pieceView(
                role: .daughter,
                position: state.daughterPosition,
                cellSize: cellSize,
                dimmed: state.phase == .dadWon,
                victoryBounce: state.phase == .daughterWon
            )
            pieceView(
                role: .dad,
                position: state.dadPosition,
                cellSize: cellSize,
                dimmed: false,
                victoryBounce: state.phase == .dadWon,
                victoryWobble: state.phase == .daughterWon,
                dadReaction: dadReaction
            )
        }
        .allowsHitTesting(false)
    }

    private var dadReaction: DadReaction {
        switch effectVisual {
        case .bananaSlip: return .slipped
        case .bombBlast: return .blasted
        case .iceFreeze: return .frozen
        default: return .normal
        }
    }

    @ViewBuilder
    private func effectOverlay(cellSize: CGFloat) -> some View {
        if case .flying(let emoji, let from, let progress) = effectVisual {
            let fromPt = cellCenter(from, cellSize: cellSize)
            let toPt = cellCenter(state.dadPosition, cellSize: cellSize)
            let arc = sin(progress * .pi) * cellSize * 0.6
            Text(emoji)
                .font(.system(size: cellSize * 0.45))
                .position(
                    x: fromPt.x + (toPt.x - fromPt.x) * progress,
                    y: fromPt.y + (toPt.y - fromPt.y) * progress - arc
                )
                .allowsHitTesting(false)
        }
        if case .bombBlast = effectVisual {
            let pt = cellCenter(state.dadPosition, cellSize: cellSize)
            Text("💥")
                .font(.system(size: cellSize * 0.7))
                .position(x: pt.x, y: pt.y)
                .scaleEffect(1.2)
                .allowsHitTesting(false)
        }
        if case .iceFreeze = effectVisual {
            let pt = cellCenter(state.dadPosition, cellSize: cellSize)
            Text("🧊")
                .font(.system(size: cellSize * 0.35))
                .position(x: pt.x - cellSize * 0.22, y: pt.y - cellSize * 0.2)
                .allowsHitTesting(false)
            Text("🧊")
                .font(.system(size: cellSize * 0.3))
                .position(x: pt.x + cellSize * 0.24, y: pt.y + cellSize * 0.18)
                .allowsHitTesting(false)
        }
    }

    private func pieceView(
        role: Role,
        position: GridPosition,
        cellSize: CGFloat,
        dimmed: Bool,
        victoryBounce: Bool = false,
        victoryWobble: Bool = false,
        dadReaction: DadReaction = .normal
    ) -> some View {
        let displayEmoji: String = {
            guard role == .dad else { return role.emoji(for: state.phase) }
            switch dadReaction {
            case .slipped: return "🤕"
            case .blasted: return "😵"
            case .frozen: return "🥶"
            case .normal: return role.emoji(for: state.phase)
            }
        }()
        let wobble = dadReaction == .slipped || (victoryWobble && dadReaction == .normal)
        let wobbleDegrees: Double = {
            switch dadReaction {
            case .slipped: return -18
            case .frozen: return 0
            case .blasted, .normal: return victoryWobble ? -8 : 0
            }
        }()

        return GamePiece(emoji: displayEmoji, size: cellSize * 0.78)
            .offset(x: CGFloat(position.col) * cellSize + cellSize * 0.11,
                    y: CGFloat(position.row) * cellSize + cellSize * 0.11)
            .offset(y: victoryBounce ? -4 : 0)
            .rotationEffect(.degrees(wobbleDegrees))
            .opacity(dimmed ? 0.35 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: position)
            .animation(wobble ? .easeInOut(duration: 0.12).repeatCount(6, autoreverses: true) : .default, value: wobble)
            .animation(victoryBounce ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default, value: victoryBounce)
            .animation(victoryWobble ? .easeInOut(duration: 0.35).repeatForever(autoreverses: true) : .default, value: victoryWobble)
    }

    private func cellCenter(_ pos: GridPosition, cellSize: CGFloat) -> CGPoint {
        CGPoint(
            x: CGFloat(pos.col) * cellSize + cellSize / 2,
            y: CGFloat(pos.row) * cellSize + cellSize / 2
        )
    }

    private func runEffectAnimation(_ effect: BoardEffect) {
        switch effect {
        case .banana(let slip):
            switch slip {
            case .thrown(let from):
                effectVisual = .flying(emoji: "🍌", from: from, progress: 0)
                withAnimation(.easeInOut(duration: 0.5)) {
                    effectVisual = .flying(emoji: "🍌", from: from, progress: 1)
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    EffectFeedback.dadSlipped()
                    withAnimation(.easeInOut(duration: 0.8)) {
                        effectVisual = .bananaSlip
                    }
                }
            case .stepped:
                EffectFeedback.dadSlipped()
                withAnimation(.easeInOut(duration: 0.8)) {
                    effectVisual = .bananaSlip
                }
            }
        case .bomb(let blast):
            switch blast {
            case .thrown(let from):
                effectVisual = .flying(emoji: "💣", from: from, progress: 0)
                withAnimation(.easeInOut(duration: 0.5)) {
                    effectVisual = .flying(emoji: "💣", from: from, progress: 1)
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    EffectFeedback.dadBlasted()
                    withAnimation(.easeOut(duration: 0.35)) {
                        effectVisual = .bombBlast
                    }
                }
            case .stepped:
                EffectFeedback.dadBlasted()
                withAnimation(.easeOut(duration: 0.35)) {
                    effectVisual = .bombBlast
                }
            }
        case .freeze(let ice):
            switch ice {
            case .thrown(let from):
                effectVisual = .flying(emoji: "❄️", from: from, progress: 0)
                withAnimation(.easeInOut(duration: 0.5)) {
                    effectVisual = .flying(emoji: "❄️", from: from, progress: 1)
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    EffectFeedback.dadFrozen()
                    withAnimation(.easeInOut(duration: 0.9)) {
                        effectVisual = .iceFreeze
                    }
                }
            case .stepped:
                EffectFeedback.dadFrozen()
                withAnimation(.easeInOut(duration: 0.9)) {
                    effectVisual = .iceFreeze
                }
            }
        }
    }
}

private enum DadReaction {
    case normal, slipped, blasted, frozen
}

private enum EffectVisual: Equatable {
    case idle
    case flying(emoji: String, from: GridPosition, progress: CGFloat)
    case bananaSlip
    case bombBlast
    case iceFreeze
}

/// 可走格子的呼吸灯高亮
private struct BreathingHighlight: View {
    let cornerRadius: CGFloat
    let inset: CGFloat
    let color: Color

    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(color.opacity(pulse ? 0.58 : 0.22))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(color.opacity(pulse ? 0.9 : 0.4), lineWidth: 2)
            }
            .padding(inset)
            .scaleEffect(pulse ? 1.0 : 0.92)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}
