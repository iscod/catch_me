import AVFoundation

/// 轻量合成音效,无需额外音频资源文件
enum SoundFX {
    private static let engine = AVAudioEngine()
    private static let player = AVAudioPlayerNode()
    private static let sampleRate: Double = 44_100
    private static var isReady = false

    private static func prepare() {
        guard !isReady else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? engine.start()
        isReady = true
    }

    /// 滑倒:短促「噗通」
    static func dadSlipped() {
        prepare()
        play(segments: [
            (620, 0.05, 0.35),
            (380, 0.07, 0.28),
            (220, 0.09, 0.18)
        ])
    }

    /// 爆炸:低沉「砰」
    static func dadBlasted() {
        prepare()
        play(segments: [
            (140, 0.06, 0.55, noisy: true),
            (75, 0.10, 0.45, noisy: true),
            (45, 0.14, 0.25, noisy: true)
        ])
    }

    /// 冰冻:清脆「叮」
    static func dadFrozen() {
        prepare()
        play(segments: [
            (1046.5, 0.07, 0.30),
            (1318.5, 0.08, 0.28),
            (1568.0, 0.10, 0.22)
        ])
    }

    private static func play(segments: [(freq: Float, duration: TimeInterval, amp: Float, noisy: Bool)]) {
        guard let buffer = makeBuffer(segments: segments) else { return }
        if !engine.isRunning { try? engine.start() }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    private static func makeBuffer(
        segments: [(freq: Float, duration: TimeInterval, amp: Float, noisy: Bool)]
    ) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let totalDuration = segments.reduce(0.0) { $0 + $1.duration }
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }

        buffer.frameLength = frameCount
        var index = 0
        for segment in segments {
            let frames = Int(sampleRate * segment.duration)
            for i in 0..<frames {
                let t = Float(i) / Float(sampleRate)
                let decay = 1 - Float(i) / Float(frames)
                let tone = sin(2 * .pi * segment.freq * t)
                let noise = segment.noisy ? Float.random(in: -1...1) * 0.35 : 0
                channel[index] = (tone * 0.65 + noise) * segment.amp * decay
                index += 1
            }
        }
        return buffer
    }
}

private extension SoundFX {
    static func play(segments: [(Float, TimeInterval, Float)]) {
        play(segments: segments.map { ($0.0, $0.1, $0.2, noisy: false) })
    }
}
