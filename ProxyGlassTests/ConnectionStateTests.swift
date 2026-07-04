import Testing
@testable import ProxyGlass

@Suite("ConnectionState model")
struct ConnectionStateTests {

    @Test("TrafficStatus allDirect uses correct heroColor")
    func allDirectHeroColor() {
        let status = TrafficStatus.allDirect
        #expect(status.heroColor == PGStatusColors.heroRedOrange)
    }

    @Test("TrafficStatus allProxied uses correct heroColor")
    func allProxiedHeroColor() {
        let status = TrafficStatus.allProxied
        #expect(status.heroColor == PGStatusColors.heroTeal)
    }

    @Test("TrafficStatus seven cases exist")
    func sevenCasesExist() {
        let all: [TrafficStatus] = [.allProxied, .mostlyProxied, .mixed, .mostlyDirect, .allDirect, .noTraffic, .noData]
        #expect(all.count == 7)
    }

    @Test("TrafficStatus title is non-empty for all cases")
    func titlesNonEmpty() {
        let all: [TrafficStatus] = [.allProxied, .mostlyProxied, .mixed, .mostlyDirect, .allDirect, .noTraffic, .noData]
        for status in all {
            #expect(!status.title.isEmpty)
        }
    }

    @Test("TrafficStatus sfSymbol is non-empty for all cases")
    func symbolsNonEmpty() {
        let all: [TrafficStatus] = [.allProxied, .mostlyProxied, .mixed, .mostlyDirect, .allDirect, .noTraffic, .noData]
        for status in all {
            #expect(!status.sfSymbol.isEmpty)
        }
    }

    @Test("RouteType proxy and direct are distinct")
    func routeTypeDistinct() {
        #expect(RouteType.proxy != RouteType.direct)
    }
}
