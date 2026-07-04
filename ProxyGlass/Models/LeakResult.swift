import SwiftUI

enum LeakResult: String, Sendable {
    case pass
    case fail
    case testing
    case notChecked
    case notApplicable

    var icon: String {
        switch self {
        case .pass: "checkmark.circle.fill"
        case .fail: "xmark.circle.fill"
        case .testing: "progress.indicator"
        case .notChecked: "minus.circle"
        case .notApplicable: "circle.slash"
        }
    }

    var color: Color {
        switch self {
        case .pass: PGStatusColors.safe
        case .fail: PGStatusColors.danger
        case .testing: PGStatusColors.info
        case .notChecked, .notApplicable: PGStatusColors.muted
        }
    }

    var label: String {
        switch self {
        case .pass: "PASS"
        case .fail: "FAIL"
        case .testing: "检测中"
        case .notChecked: "未检测"
        case .notApplicable: "不适用"
        }
    }
}
