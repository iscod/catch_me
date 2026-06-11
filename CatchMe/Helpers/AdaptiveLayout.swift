import SwiftUI

/// iPhone / iPad 自适应尺寸
enum AdaptiveLayout {
    static func isPad(_ sizeClass: UserInterfaceSizeClass?) -> Bool {
        sizeClass == .regular
    }

    static func menuMaxWidth(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isPad(sizeClass) ? 720 : 500
    }

    static func boardMaxWidth(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isPad(sizeClass) ? 520 : .infinity
    }

    static func boardMaxHeight(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isPad(sizeClass) ? 680 : .infinity
    }

    static func resultCardMaxWidth(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isPad(sizeClass) ? 440 : 340
    }

    static func gameContentMaxWidth(_ sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isPad(sizeClass) ? 600 : .infinity
    }
}

extension View {
    /// 大屏居中,限制最大宽度
    func adaptiveCentered(maxWidth: CGFloat) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
