import Testing
@testable import ProxyGlass

@Suite("DomainNameMapper")
struct DomainNameMapperTests {

    @Test("Known domains map to service names")
    func knownDomains() {
        let cases: [(String, String)] = [
            ("r4---sn-a5mlrn76.googlevideo.com", "YouTube"),
            ("www.youtube.com", "YouTube"),
            ("api.bilibili.com", "B站"),
            ("pbs.twimg.com", "X/Twitter"),
            ("images-na.ssl-images-amazon.com", "Amazon"),
            ("api.spotify.com", "Spotify"),
            ("gateway.icloud.com", "Apple"),
            ("github.com", "GitHub"),
            ("store.steampowered.com", "Steam"),
        ]
        for (domain, expectedService) in cases {
            let result = DomainNameMapper.serviceDisplayName(for: domain)
            #expect(result == expectedService, "Expected \(expectedService) for \(domain), got \(result)")
        }
    }

    @Test("Unknown domains return extracted root domain")
    func unknownDomains() {
        let result = DomainNameMapper.serviceDisplayName(for: "random-unknown-xyz.example.com")
        #expect(result == "example")
    }

    @Test("Empty host returns empty")
    func emptyDomain() {
        let result = DomainNameMapper.serviceDisplayName(for: "")
        #expect(result == "")
    }

    @Test("Process name simplification")
    func processSimplification() {
        let simplified = DomainNameMapper.friendlyProcessName("google chrome")
        #expect(simplified == "Chrome")
    }

    @Test("Unknown process stays unchanged")
    func unknownProcess() {
        let simplified = DomainNameMapper.friendlyProcessName("curl")
        #expect(simplified == "curl")
    }

    @Test("Empty process returns fallback")
    func emptyProcess() {
        let simplified = DomainNameMapper.friendlyProcessName("")
        #expect(simplified == "未知")
    }
}
