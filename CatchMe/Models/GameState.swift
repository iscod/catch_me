import Foundation
import Observation

struct GridPosition: Equatable, Hashable {
    var row: Int
    var col: Int

    func manhattanDistance(to other: GridPosition) -> Int {
        abs(row - other.row) + abs(col - other.col)
    }

    /// 八方向(王步)最短步数
    func chebyshevDistance(to other: GridPosition) -> Int {
        max(abs(row - other.row), abs(col - other.col))
    }
}

enum Role {
    case dad
    case daughter
}

enum GameMode: String, CaseIterable, Identifiable {
    case twoPlayer
    case playAsDad
    case playAsDaughter

    var id: String { rawValue }

    var systemIcon: String {
        switch self {
        case .twoPlayer: return "person.2.fill"
        case .playAsDad: return "figure.walk"
        case .playAsDaughter: return "figure.run"
        }
    }

    var aiRole: Role? {
        switch self {
        case .twoPlayer: return nil
        case .playAsDad: return .daughter
        case .playAsDaughter: return .dad
        }
    }
}

enum GamePhase: Equatable {
    case playing
    case dadWon
    case daughterWon
}

enum SlipAnimation: Equatable {
    case thrown(from: GridPosition)
    case stepped(at: GridPosition)
}

enum BombAnimation: Equatable {
    case thrown(from: GridPosition)
    case stepped(at: GridPosition)
}

enum FreezeAnimation: Equatable {
    case thrown(from: GridPosition)
    case stepped(at: GridPosition)
}

enum BoardEffect: Equatable {
    case banana(SlipAnimation)
    case bomb(BombAnimation)
    case freeze(FreezeAnimation)
}

@Observable
final class GameState {
    /// 竖屏友好:8 列 x 10 行
    static let boardRows = 10
    static let boardCols = 8

    let mode: GameMode

    private(set) var dadPosition = GridPosition(row: 0, col: 0)
    private(set) var daughterPosition = GridPosition(row: boardRows - 1, col: boardCols - 1)
    private(set) var round = 1
    private(set) var currentTurn: Role = .daughter
    private(set) var phase: GamePhase = .playing
    private(set) var bananaPositions: Set<GridPosition> = []
    private(set) var bombPositions: Set<GridPosition> = []
    private(set) var freezePositions: Set<GridPosition> = []
    private(set) var pendingEffect: BoardEffect?

    init(mode: GameMode) {
        self.mode = mode
        spawnItems()
    }

    func clearPendingEffect() {
        pendingEffect = nil
    }

    /// 道具动画播完后调用；冰冻命中时爸爸本回合不能走棋，直接交还女儿。
    func finishEffectAnimation() {
        let skipDadTurn = if case .freeze = pendingEffect { true } else { false }
        pendingEffect = nil
        guard phase == .playing, currentTurn == .dad, skipDadTurn else { return }
        round += 1
        currentTurn = .daughter
    }

    var itemPositions: Set<GridPosition> {
        bananaPositions.union(bombPositions).union(freezePositions)
    }

    var hasItemsOnBoard: Bool {
        !itemPositions.isEmpty
    }

    var isAITurn: Bool {
        phase == .playing && mode.aiRole == currentTurn
    }

    func position(of role: Role) -> GridPosition {
        role == .dad ? dadPosition : daughterPosition
    }

    var legalMoves: [GridPosition] {
        guard phase == .playing else { return [] }
        var moves = Self.neighbors(of: position(of: currentTurn))
        switch currentTurn {
        case .daughter:
            moves = moves.filter { $0 != dadPosition }
        case .dad:
            moves = moves.filter { !itemPositions.contains($0) }
        }
        return moves
    }

    static func neighbors(of p: GridPosition) -> [GridPosition] {
        [
            (0, 1), (0, -1), (1, 0), (-1, 0),
            (1, 1), (1, -1), (-1, 1), (-1, -1)
        ].compactMap { dr, dc in
            let cell = GridPosition(row: p.row + dr, col: p.col + dc)
            guard (0..<boardRows).contains(cell.row), (0..<boardCols).contains(cell.col) else { return nil }
            return cell
        }
    }

    @discardableResult
    func move(to cell: GridPosition) -> Bool {
        guard legalMoves.contains(cell) else { return false }
        switch currentTurn {
        case .daughter:
            daughterPosition = cell
            let steppedOnBanana = bananaPositions.contains(cell)
            let steppedOnBomb = bombPositions.contains(cell)
            let steppedOnFreeze = freezePositions.contains(cell)
            if steppedOnBanana { bananaPositions.remove(cell) }
            if steppedOnBomb { bombPositions.remove(cell) }
            if steppedOnFreeze { freezePositions.remove(cell) }
            if steppedOnBomb {
                pendingEffect = .bomb(.thrown(from: cell))
            } else if steppedOnFreeze {
                pendingEffect = .freeze(.thrown(from: cell))
            } else if steppedOnBanana {
                pendingEffect = .banana(.thrown(from: cell))
            }
            if !hasItemsOnBoard {
                phase = .daughterWon
            } else {
                currentTurn = .dad
            }
        case .dad:
            dadPosition = cell
            if dadPosition == daughterPosition {
                phase = .dadWon
            } else {
                round += 1
                currentTurn = .daughter
            }
        }
        return true
    }

    private static let minTotalItems = 5

    private func spawnItems() {
        var candidates = Self.itemSpawnCells(excluding: dadPosition, and: daughterPosition)
        var bananaCount = Int.random(in: 2...6)
        var bombCount = Int.random(in: 1...3)
        var freezeCount = Int.random(in: 1...3)

        while bananaCount + bombCount + freezeCount < Self.minTotalItems {
            switch Int.random(in: 0..<3) {
            case 0 where bananaCount < 6: bananaCount += 1
            case 1 where bombCount < 3: bombCount += 1
            case 2 where freezeCount < 3: freezeCount += 1
            default:
                if bananaCount < 6 { bananaCount += 1 }
                else if bombCount < 3 { bombCount += 1 }
                else if freezeCount < 3 { freezeCount += 1 }
            }
        }

        let total = bananaCount + bombCount + freezeCount
        if total > candidates.count {
            var overflow = total - candidates.count
            while overflow > 0, bananaCount > 2 {
                bananaCount -= 1
                overflow -= 1
            }
            while overflow > 0, bombCount > 1 {
                bombCount -= 1
                overflow -= 1
            }
            while overflow > 0, freezeCount > 1 {
                freezeCount -= 1
                overflow -= 1
            }
        }

        bananaPositions = Set(candidates.shuffled().prefix(bananaCount))
        candidates.removeAll { bananaPositions.contains($0) }
        bombPositions = Set(candidates.shuffled().prefix(bombCount))
        candidates.removeAll { bombPositions.contains($0) }
        freezePositions = Set(candidates.shuffled().prefix(freezeCount))
    }

    static func itemSpawnCells(excluding dad: GridPosition, and daughter: GridPosition) -> [GridPosition] {
        (boardRows / 2..<boardRows).flatMap { row in
            (0..<boardCols).map { col in
                GridPosition(row: row, col: col)
            }
        }
        .filter { $0 != dad && $0 != daughter }
    }
}
