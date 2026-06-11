import SwiftUI

@main
struct CatchMeApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            MenuView()
                .onAppear { BackgroundMusic.start() }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active: BackgroundMusic.resume()
                    case .background: BackgroundMusic.pause()
                    default: break
                    }
                }
        }
    }
}
