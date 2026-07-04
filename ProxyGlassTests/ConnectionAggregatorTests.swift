import Testing
@testable import ProxyGlass

@Suite("ConnectionAggregator models")
struct ConnectionAggregatorTests {

    private func makeConnection(
        id: String = "1",
        host: String = "example.com",
        process: String = "curl",
        upload: UInt64 = 100,
        download: UInt64 = 200,
        routeType: RouteType = .proxy
    ) -> AggregatedConnection {
        AggregatedConnection(
            id: id,
            process: process,
            host: host,
            destinationIP: "1.2.3.4",
            upload: upload,
            download: download,
            routeType: routeType,
            wentThroughKernel: true,
            proxyChain: "node1",
            currentUpload: 0,
            currentDownload: 0
        )
    }

    @Test("totalBytes sums upload and download")
    func totalBytes() {
        let conn = makeConnection(upload: 150, download: 350)
        #expect(conn.totalBytes == 500)
    }

    @Test("friendlyProcessName delegates to DomainNameMapper")
    func friendlyProcess() {
        let conn = makeConnection(process: "google chrome")
        #expect(conn.friendlyProcessName == "Chrome")
    }

    @Test("serviceName delegates to DomainNameMapper")
    func serviceName() {
        let conn = makeConnection(host: "api.bilibili.com")
        #expect(conn.serviceName == "B站")
    }

    @Test("wentThroughKernel preserved")
    func kernelFlag() {
        let conn = makeConnection(routeType: .direct)
        #expect(conn.wentThroughKernel == true)
    }

    @Test("TrafficSnapshot empty has zero values")
    func emptySnapshot() {
        let snap = TrafficSnapshot.empty
        #expect(snap.totalBytes == 0)
        #expect(snap.proxyBytes == 0)
        #expect(snap.directBytes == 0)
        #expect(snap.connectionCount == 0)
        #expect(snap.topConnections.isEmpty)
        #expect(snap.riskAlerts.isEmpty)
    }

    @Test("TrafficSnapshot empty proxyRatio is zero")
    func emptyRatio() {
        let snap = TrafficSnapshot.empty
        #expect(snap.proxyRatio == 0)
        #expect(snap.directRatio == 0)
    }

    @Test("RiskAlert types exist")
    func riskAlertTypes() {
        let alert = RiskAlert(
            id: "test",
            type: .highSpeedDirect,
            severity: .high,
            title: "Test",
            description: "Desc",
            suggestion: "Fix"
        )
        #expect(alert.id == "test")
        #expect(alert.title == "Test")
    }
}
