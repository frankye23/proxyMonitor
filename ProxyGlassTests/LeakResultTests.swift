import Testing
@testable import ProxyGlass

@Suite("LeakResult model")
struct LeakResultTests {

    @Test("All LeakResult cases have unique icons")
    func uniqueIcons() {
        let cases: [LeakResult] = [.pass, .fail, .testing, .notChecked, .notApplicable]
        let icons = Set(cases.map(\.icon))
        #expect(icons.count == cases.count)
    }

    @Test("All LeakResult cases have unique labels")
    func uniqueLabels() {
        let cases: [LeakResult] = [.pass, .fail, .testing, .notChecked, .notApplicable]
        let labels = Set(cases.map(\.label))
        #expect(labels.count == cases.count)
    }

    @Test("Pass result uses safe color")
    func passColor() {
        #expect(LeakResult.pass.color == PGStatusColors.safe)
    }

    @Test("Fail result uses danger color")
    func failColor() {
        #expect(LeakResult.fail.color == PGStatusColors.danger)
    }

    @Test("LeakCheckType has correct display names")
    func leakCheckTypeDisplayNames() {
        #expect(LeakCheckType.dns.displayName == "DNS 泄漏")
        #expect(LeakCheckType.ipv6.displayName == "IPv6")
        #expect(LeakCheckType.webrtc.displayName == "WebRTC")
    }

    @Test("LeakCheckType identfiable via rawValue")
    func leakCheckTypeId() {
        #expect(LeakCheckType.dns.id == "dns")
        #expect(LeakCheckType.ipv6.id == "ipv6")
        #expect(LeakCheckType.webrtc.id == "webrtc")
    }
}
