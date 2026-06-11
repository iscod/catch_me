/// 道具命中爸爸时的触觉 + 音效
enum EffectFeedback {
    static func dadSlipped() {
        Haptics.dadSlipped()
        SoundFX.dadSlipped()
    }

    static func dadBlasted() {
        Haptics.dadBlasted()
        SoundFX.dadBlasted()
    }

    static func dadFrozen() {
        Haptics.dadFrozen()
        SoundFX.dadFrozen()
    }
}
