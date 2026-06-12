import Foundation

enum AIPlayer {

    private static func safeArea(daughter: GridPosition, dad: GridPosition) -> Int {
        var count = 0
        for row in 0..<GameState.boardRows {
            for col in 0..<GameState.boardCols {
                let cell = GridPosition(row: row, col: col)
                if daughter.chebyshevDistance(to: cell) < dad.chebyshevDistance(to: cell) {
                    count += 1
                }
            }
        }
        return count
    }

    static func bestMove(for state: GameState) -> GridPosition? {
        guard let role = state.mode.aiRole, role == state.currentTurn else { return nil }
        let moves = state.legalMoves.shuffled()
        switch role {
        case .dad:
            return moves.min { a, b in
                let sa = safeArea(daughter: state.daughterPosition, dad: a)
                let sb = safeArea(daughter: state.daughterPosition, dad: b)
                if sa != sb { return sa < sb }
                return a.chebyshevDistance(to: state.daughterPosition) < b.chebyshevDistance(to: state.daughterPosition)
            }
        case .daughter:
            let candidates = moves.filter { !isRecklessBombOrBananaPickup($0, state: state) }
            let pool = candidates.isEmpty ? moves : candidates
            return pool.max { scoreDaughterMove($0, state: state) < scoreDaughterMove($1, state: state) }
        }
    }

    /// 只剩最后一件道具时，踩进抓捕圈也直接获胜，可以吃。
    private static func isLastItemPickup(_ move: GridPosition, state: GameState) -> Bool {
        state.itemPositions.contains(move) && state.itemPositions.count == 1
    }

    /// 场上还有多件道具时，为吃炸弹/香蕉跳进爸爸抓捕圈等于送死，直接排除。
    private static func isRecklessBombOrBananaPickup(_ move: GridPosition, state: GameState) -> Bool {
        guard state.itemPositions.count > 1 else { return false }
        guard state.bombPositions.contains(move) || state.bananaPositions.contains(move) else { return false }
        let itemsAfterMove = state.itemPositions.subtracting([move])
        return isInDadCaptureRange(
            daughterAt: move,
            dad: state.dadPosition,
            itemPositions: itemsAfterMove
        )
    }

    /// 女儿胜利条件：踩完棋盘上所有道具。多件道具时仅冰冻可进抓捕圈脱身。
    private static func scoreDaughterMove(_ move: GridPosition, state: GameState) -> Int {
        var score = 0
        let isItem = state.itemPositions.contains(move)
        let itemsAfterMove = isItem ? state.itemPositions.subtracting([move]) : state.itemPositions
        let inCaptureRange = isInDadCaptureRange(
            daughterAt: move,
            dad: state.dadPosition,
            itemPositions: itemsAfterMove
        )

        if isItem {
            score += 10_000
            if state.bombPositions.contains(move) { score += 600 }
            else if state.freezePositions.contains(move) { score += 500 }
            else if state.bananaPositions.contains(move) { score += 400 }
            score -= minDistanceToAnyItem(from: move, items: itemsAfterMove, dad: state.dadPosition) * 30
        } else {
            let currentDist = minDistanceToAnyItem(from: state.daughterPosition, items: state.itemPositions, dad: state.dadPosition)
            let newDist = minDistanceToAnyItem(from: move, items: state.itemPositions, dad: state.dadPosition)
            score += (currentDist - newDist) * 150
        }

        score += move.chebyshevDistance(to: state.dadPosition) * 25
        score += safeArea(daughter: move, dad: state.dadPosition) * 2

        if inCaptureRange && !isLastItemPickup(move, state: state) {
            if state.freezePositions.contains(move) {
                score += 3_000
            } else if !isItem {
                score -= 8_000
            }
        }

        return score
    }

    private static func minDistanceToAnyItem(
        from start: GridPosition,
        items: Set<GridPosition>,
        dad: GridPosition
    ) -> Int {
        guard !items.isEmpty else { return 0 }
        let distances = bfsDistances(from: start, blocked: dad)
        return items.compactMap { distances[$0] }.min() ?? 999
    }

    private static func bfsDistances(from start: GridPosition, blocked: GridPosition) -> [GridPosition: Int] {
        var distances: [GridPosition: Int] = [start: 0]
        var queue = [start]
        var head = 0

        while head < queue.count {
            let current = queue[head]
            head += 1
            let step = distances[current]! + 1

            for neighbor in GameState.neighbors(of: current) where neighbor != blocked && distances[neighbor] == nil {
                distances[neighbor] = step
                queue.append(neighbor)
            }
        }
        return distances
    }

    /// 道具被踩掉后，该格是否仍在爸爸一步可抓范围内。
    private static func isInDadCaptureRange(
        daughterAt cell: GridPosition,
        dad: GridPosition,
        itemPositions: Set<GridPosition>
    ) -> Bool {
        GameState.neighbors(of: dad).contains { neighbor in
            neighbor == cell && !itemPositions.contains(cell)
        }
    }
}
