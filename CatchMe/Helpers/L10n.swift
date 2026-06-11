import Foundation

enum L10n {
    static var appTitle: String { String(localized: "app.title") }
    static var appSubtitle: String { String(localized: "app.subtitle") }
    static var chooseMode: String { String(localized: "menu.chooseMode") }
    static var startGame: String { String(localized: "menu.startGame") }
    static var backToMenu: String { String(localized: "result.backToMenu") }

    static var dadWinHeadline: String { String(localized: "result.dadWin.headline") }
    static var daughterWinHeadline: String { String(localized: "result.daughterWin.headline") }
    static var restartAfterDadWin: String { String(localized: "result.restart.dadWin") }
    static var restartAfterDaughterWin: String { String(localized: "result.restart.daughterWin") }

    static var turnHuman: String { String(localized: "turn.human") }
    static var itemHint: String { String(localized: "item.hint") }
    static var peelSlip: String { String(localized: "peel.slip") }
    static var bombBlast: String { String(localized: "bomb.blast") }
    static var freezeFrozen: String { String(localized: "freeze.frozen") }

    static func roundCounter(_ round: Int) -> String {
        String(format: String(localized: "round.counter %lld"), round)
    }

    static func aiThinking(_ roleName: String) -> String {
        String(format: String(localized: "turn.aiThinking %@"), roleName)
    }

    static func twoPlayerTurn(_ roleName: String) -> String {
        String(format: String(localized: "turn.twoPlayer %@"), roleName)
    }

    static func dadWinDetail(round: Int) -> String {
        String(format: String(localized: "result.dadWin.detail %lld"), round)
    }

    static func daughterWinDetail(round: Int) -> String {
        String(format: String(localized: "result.daughterWin.detail %lld"), round)
    }
}

extension Role {
    var displayName: String {
        self == .dad ? String(localized: "role.dad") : String(localized: "role.daughter")
    }
}

extension GameMode {
    var title: String {
        switch self {
        case .twoPlayer: String(localized: "mode.twoPlayer.title")
        case .playAsDad: String(localized: "mode.playAsDad.title")
        case .playAsDaughter: String(localized: "mode.playAsDaughter.title")
        }
    }

    var subtitle: String {
        switch self {
        case .twoPlayer: String(localized: "mode.twoPlayer.subtitle")
        case .playAsDad: String(localized: "mode.playAsDad.subtitle")
        case .playAsDaughter: String(localized: "mode.playAsDaughter.subtitle")
        }
    }

    func resultSubtitle(dadWon: Bool) -> String {
        switch (dadWon, self) {
        case (true, .playAsDad): String(localized: "result.subtitle.dadWin.playAsDad")
        case (true, .playAsDaughter): String(localized: "result.subtitle.dadWin.playAsDaughter")
        case (true, .twoPlayer): String(localized: "result.subtitle.dadWin.twoPlayer")
        case (false, .playAsDaughter): String(localized: "result.subtitle.daughterWin.playAsDaughter")
        case (false, .playAsDad): String(localized: "result.subtitle.daughterWin.playAsDad")
        case (false, .twoPlayer): String(localized: "result.subtitle.daughterWin.twoPlayer")
        }
    }
}
