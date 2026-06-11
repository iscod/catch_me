import Foundation

private extension Bool {
    static func random(probability: Double) -> Bool {
        Double.random(in: 0...1) < probability
    }
}

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
            let itemMoves = moves.filter {
                state.bananaPositions.contains($0)
                    || state.bombPositions.contains($0)
                    || state.freezePositions.contains($0)
            }
            if !itemMoves.isEmpty, Bool.random(probability: 0.85) {
                return itemMoves.randomElement()
            }
            return moves.max { a, b in
                let da = a.chebyshevDistance(to: state.dadPosition)
                let db = b.chebyshevDistance(to: state.dadPosition)
                if da != db { return da < db }
                return safeArea(daughter: a, dad: state.dadPosition) < safeArea(daughter: b, dad: state.dadPosition)
            }
        }
    }
}
