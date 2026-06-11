import AVFoundation

/// 轻快追逐风背景音乐(程序合成循环,无需音频文件)
enum BackgroundMusic {
    private static var player: AVAudioPlayer?
    private static let sampleRate = 44_100
    private static let volume: Float = 0.28

    static func start() {
        configureSession()
        if let player, player.isPlaying { return }
        if player == nil {
            guard let data = makeLoopWAV() else { return }
            player = try? AVAudioPlayer(data: data)
            player?.numberOfLoops = -1
            player?.volume = volume
            player?.prepareToPlay()
        }
        player?.play()
    }

    static func pause() {
        player?.pause()
    }

    static func resume() {
        guard player != nil else {
            start()
            return
        }
        player?.play()
    }

    private static func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    // MARK: - 旋律合成

    private struct Note {
        var frequency: Float
        var duration: TimeInterval
        var amplitude: Float
    }

    /// C 大调五声音阶,轻快追逐感
    private static let melody: [Note] = [
        Note(frequency: 392.00, duration: 0.16, amplitude: 0.22), // G4
        Note(frequency: 523.25, duration: 0.16, amplitude: 0.24), // C5
        Note(frequency: 659.25, duration: 0.16, amplitude: 0.24), // E5
        Note(frequency: 783.99, duration: 0.16, amplitude: 0.26), // G5
        Note(frequency: 659.25, duration: 0.16, amplitude: 0.22),
        Note(frequency: 523.25, duration: 0.16, amplitude: 0.22),
        Note(frequency: 392.00, duration: 0.32, amplitude: 0.20),

        Note(frequency: 440.00, duration: 0.16, amplitude: 0.22), // A4
        Note(frequency: 523.25, duration: 0.16, amplitude: 0.24),
        Note(frequency: 659.25, duration: 0.16, amplitude: 0.24),
        Note(frequency: 587.33, duration: 0.16, amplitude: 0.22), // D5
        Note(frequency: 523.25, duration: 0.16, amplitude: 0.22),
        Note(frequency: 392.00, duration: 0.16, amplitude: 0.20),
        Note(frequency: 329.63, duration: 0.32, amplitude: 0.18), // E4

        Note(frequency: 392.00, duration: 0.16, amplitude: 0.22),
        Note(frequency: 493.88, duration: 0.16, amplitude: 0.23), // B4
        Note(frequency: 587.33, duration: 0.16, amplitude: 0.24),
        Note(frequency: 659.25, duration: 0.16, amplitude: 0.24),
        Note(frequency: 587.33, duration: 0.16, amplitude: 0.22),
        Note(frequency: 493.88, duration: 0.16, amplitude: 0.20),
        Note(frequency: 392.00, duration: 0.32, amplitude: 0.20),

        Note(frequency: 329.63, duration: 0.16, amplitude: 0.20),
        Note(frequency: 392.00, duration: 0.16, amplitude: 0.22),
        Note(frequency: 523.25, duration: 0.16, amplitude: 0.24),
        Note(frequency: 659.25, duration: 0.16, amplitude: 0.22),
        Note(frequency: 523.25, duration: 0.16, amplitude: 0.22),
        Note(frequency: 392.00, duration: 0.16, amplitude: 0.20),
        Note(frequency: 261.63, duration: 0.32, amplitude: 0.18), // C4
    ]

    private static let bassLine: [(Float, TimeInterval)] = [
        (130.81, 1.12), // C3
        (98.00, 1.12),  // G2
        (110.00, 1.12), // A2
        (98.00, 1.12),
    ]

    private static func makeLoopWAV() -> Data? {
        let melodyDuration = melody.reduce(0.0) { $0 + $1.duration }
        let bassDuration = bassLine.reduce(0.0) { $0 + $1.1 }
        let loopDuration = max(melodyDuration, bassDuration)
        let frameCount = Int(Double(sampleRate) * loopDuration)
        var samples = [Float](repeating: 0, count: frameCount)

        var melodyFrame = 0
        for note in melody {
            let frames = Int(Double(sampleRate) * note.duration)
            for i in 0..<frames {
                let t = Float(i) / Float(sampleRate)
                let attack = min(1, Float(i) / Float(sampleRate) * 40)
                let release = min(1, Float(frames - i) / Float(sampleRate) * 30)
                let env = min(attack, release)
                let sample = sin(2 * .pi * note.frequency * t) * note.amplitude * env
                let idx = melodyFrame + i
                if idx < frameCount { samples[idx] += sample }
            }
            melodyFrame += frames
        }

        var bassFrame = 0
        for (freq, duration) in bassLine {
            let frames = Int(Double(sampleRate) * duration)
            for i in 0..<frames {
                let t = Float(i) / Float(sampleRate)
                let env = min(1, Float(i) / (Float(sampleRate) * 0.02))
                    * min(1, Float(frames - i) / (Float(sampleRate) * 0.05))
                let sample = sin(2 * .pi * freq * t) * 0.10 * env
                let idx = bassFrame + i
                if idx < frameCount { samples[idx] += sample }
            }
            bassFrame += frames
        }

        return encodeWAV(samples: samples)
    }

    private static func encodeWAV(samples: [Float]) -> Data? {
        let numFrames = samples.count
        let dataSize = numFrames * 2
        var data = Data(capacity: 44 + dataSize)

        func appendUInt32(_ value: UInt32) {
            var le = value.littleEndian
            data.append(Data(bytes: &le, count: 4))
        }
        func appendUInt16(_ value: UInt16) {
            var le = value.littleEndian
            data.append(Data(bytes: &le, count: 2))
        }

        data.append(contentsOf: "RIFF".utf8)
        appendUInt32(UInt32(36 + dataSize))
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        appendUInt32(16)
        appendUInt16(1) // PCM
        appendUInt16(1) // mono
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate * 2))
        appendUInt16(2)
        appendUInt16(16)
        data.append(contentsOf: "data".utf8)
        appendUInt32(UInt32(dataSize))

        for sample in samples {
            let clamped = max(-1, min(1, sample))
            var int16 = Int16(clamped * Float(Int16.max))
            data.append(Data(bytes: &int16, count: 2))
        }
        return data
    }
}
