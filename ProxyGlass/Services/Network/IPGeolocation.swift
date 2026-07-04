import Foundation

struct IPInfo: Sendable {
    let ip: String
    let country: String
    let countryCode: String
    let city: String
    let isp: String
    let asn: String
}

struct IPProvider: Sendable {
    let name: String
    let url: URL
}

final class IPGeolocation: Sendable {
    private let providers: [IPProvider] = [
        IPProvider(name: "ip-api.com", url: URL(string: "https://ip-api.com/json")!),
        IPProvider(name: "ipinfo.io", url: URL(string: "https://ipinfo.io/json")!),
        IPProvider(name: "ipapi.co", url: URL(string: "https://ipapi.co/json/")!),
        IPProvider(name: "ip.sb", url: URL(string: "https://api.ip.sb/geoip")!),
    ]

    func fetchExitIPInfo() async -> IPInfo? {
        await withTaskGroup(of: IPInfo?.self) { group in
            for provider in providers {
                group.addTask { [provider] in
                    try? await self.fetchFromProvider(provider)
                }
            }
            var results: [IPInfo] = []
            for await result in group {
                if let r = result { results.append(r) }
            }
            return results.first
        }
    }

    private func fetchFromProvider(_ provider: IPProvider) async throws -> IPInfo? {
        let (data, _) = try await URLSession.shared.data(from: provider.url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return IPInfo(
            ip: json["query"] as? String ?? json["ip"] as? String ?? "",
            country: json["country"] as? String ?? "",
            countryCode: json["countryCode"] as? String ?? json["country_code"] as? String ?? "",
            city: json["city"] as? String ?? "",
            isp: json["isp"] as? String ?? json["org"] as? String ?? "",
            asn: json["as"] as? String ?? ""
        )
    }
}
