import SwiftUI

/// 棋盘/界面上的角色棋子,纯 emoji + 轻阴影
struct GamePiece: View {
    let emoji: String
    var size: CGFloat

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.82))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.18), radius: 3, y: 2)
    }
}

extension Role {
    var emoji: String { self == .dad ? "👨" : "👧" }

    /// 根据胜负切换表情(只用单字符 emoji,真机显示稳定)
    func emoji(for phase: GamePhase) -> String {
        switch (self, phase) {
        case (.dad, .dadWon): return "😎"
        case (.dad, .daughterWon): return "😅"
        case (.daughter, .daughterWon): return "😜"
        default: return emoji
        }
    }
}
