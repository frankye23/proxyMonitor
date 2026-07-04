struct GeoInfo: Sendable {
    let country: String
    let countryCode: String
    let city: String
    let isp: String
    let asn: String

    var displayLocation: String {
        var parts: [String] = []
        if !country.isEmpty { parts.append(country) }
        if !city.isEmpty && city != country { parts.append(city) }
        if !isp.isEmpty { parts.append(isp) }
        return parts.joined(separator: " · ")
    }

    static let placeholder = GeoInfo(
        country: "—", countryCode: "—", city: "—", isp: "—", asn: "—"
    )
}
