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

    /// 第 5 排(0-based row 4)：随机撒少量道具
    private static let scoutRow = boardRows / 2 - 1
    private static let scoutRowItemCount = 2
    /// 第 6 排(0-based row 5)：横向道具墙，爸爸不能踏入
    private static let barrierRow = boardRows / 2
    private static let minExtraItems = 7

    private enum ItemKind: CaseIterable {
        case banana, bomb, freeze
    }

    private func spawnItems() {
        var bananas = Set<GridPosition>()
        var bombs = Set<GridPosition>()
        var freezes = Set<GridPosition>()

        for col in 0..<Self.boardCols {
            placeRandomItem(
                at: GridPosition(row: Self.barrierRow, col: col),
                bananas: &bananas, bombs: &bombs, freezes: &freezes
            )
        }

        let scoutCells = (0..<Self.boardCols)
            .map { GridPosition(row: Self.scoutRow, col: $0) }
            .filter { $0 != dadPosition && $0 != daughterPosition }
            .shuffled()
            .prefix(Self.scoutRowItemCount)
        for cell in scoutCells {
            placeRandomItem(at: cell, bananas: &bananas, bombs: &bombs, freezes: &freezes)
        }

        var candidates = Self.itemSpawnCells(excluding: dadPosition, and: daughterPosition)
        var bananaCount = Int.random(in: 3...7)
        var bombCount = Int.random(in: 2...4)
        var freezeCount = Int.random(in: 2...4)

        while bananaCount + bombCount + freezeCount < Self.minExtraItems {
            switch Int.random(in: 0..<3) {
            case 0 where bananaCount < 8: bananaCount += 1
            case 1 where bombCount < 5: bombCount += 1
            case 2 where freezeCount < 5: freezeCount += 1
            default:
                if bananaCount < 8 { bananaCount += 1 }
                else if bombCount < 5 { bombCount += 1 }
                else if freezeCount < 5 { freezeCount += 1 }
            }
        }

        let total = bananaCount + bombCount + freezeCount
        if total > candidates.count {
            var overflow = total - candidates.count
            while overflow > 0, bananaCount > 3 {
                bananaCount -= 1
                overflow -= 1
            }
            while overflow > 0, bombCount > 2 {
                bombCount -= 1
                overflow -= 1
            }
            while overflow > 0, freezeCount > 2 {
                freezeCount -= 1
                overflow -= 1
            }
        }

        bananas.formUnion(candidates.shuffled().prefix(bananaCount))
        candidates.removeAll { bananas.contains($0) || bombs.contains($0) || freezes.contains($0) }
        bombs.formUnion(candidates.shuffled().prefix(bombCount))
        candidates.removeAll { bananas.contains($0) || bombs.contains($0) || freezes.contains($0) }
        freezes.formUnion(candidates.shuffled().prefix(freezeCount))

        bananaPositions = bananas
        bombPositions = bombs
        freezePositions = freezes
    }

    private func placeRandomItem(
        at cell: GridPosition,
        bananas: inout Set<GridPosition>,
        bombs: inout Set<GridPosition>,
        freezes: inout Set<GridPosition>
    ) {
        switch ItemKind.allCases.randomElement()! {
        case .banana: bananas.insert(cell)
        case .bomb: bombs.insert(cell)
        case .freeze: freezes.insert(cell)
        }
    }

    static func itemSpawnCells(excluding dad: GridPosition, and daughter: GridPosition) -> [GridPosition] {
        ((barrierRow + 1)..<boardRows).flatMap { row in
            (0..<boardCols).map { col in
                GridPosition(row: row, col: col)
            }
        }
        .filter { $0 != dad && $0 != daughter }
    }
}
