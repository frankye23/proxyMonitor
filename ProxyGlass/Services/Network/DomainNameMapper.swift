import Foundation

enum DomainNameMapper {
    private static let rules: [(patterns: [String], name: String)] = [
        (["bilibili.com", "hdslb.com"], "B站"),
        (["douyu.com", "douyucdn.cn"], "斗鱼"),
        (["xiaohongshu.com", "xhscdn.com"], "小红书"),
        (["youtube.com", "googlevideo.com", "ytimg.com"], "YouTube"),
        (["google.com", "googleapis.com", "gstatic.com"], "Google"),
        (["steamstatic.com", "steampowered.com", "steamcontent.com"], "Steam"),
        (["github.com", "githubusercontent.com"], "GitHub"),
        (["netflix.com", "nflxvideo.net"], "Netflix"),
        (["spotify.com", "scdn.co"], "Spotify"),
        (["twitter.com", "x.com", "twimg.com"], "X/Twitter"),
        (["taobao.com", "alicdn.com"], "淘宝"),
        (["jd.com", "360buyimg.com"], "京东"),
        (["weibo.com", "sinaimg.cn"], "微博"),
        (["qq.com", "qpic.cn", "gtimg.cn"], "QQ"),
        (["wechat.com", "weixin.qq.com"], "微信"),
        (["zhihu.com", "zhimg.com"], "知乎"),
        (["douyin.com", "douyinpic.com"], "抖音"),
        (["amazon.com", "amazonaws.com"], "Amazon"),
        (["microsoft.com", "live.com", "office.com"], "Microsoft"),
        (["apple.com", "icloud.com"], "Apple"),
        (["cloudflare.com", "cloudflare-dns.com"], "Cloudflare"),
    ]

    private static let processRules: [(pattern: String, name: String)] = [
        ("google chrome", "Chrome"),
        ("chrome", "Chrome"),
        ("firefox", "Firefox"),
        ("safari", "Safari"),
        ("microsoft edge", "Edge"),
        ("edge", "Edge"),
        ("steamwebhelper", "Steam"),
        ("steam", "Steam"),
        ("thunder", "迅雷"),
        ("bilibili", "B站"),
        ("spotify", "Spotify"),
        ("netease", "网易"),
    ]

    static func serviceDisplayName(for host: String) -> String {
        let lower = host.lowercased()
        for rule in rules {
            for pattern in rule.patterns {
                if lower.hasSuffix(pattern) || lower.hasSuffix("." + pattern) {
                    return rule.name
                }
            }
        }
        return extractDomain(host)
    }

    static func friendlyProcessName(_ process: String) -> String {
        let lower = process.lowercased()
        for rule in processRules {
            if lower.contains(rule.pattern) {
                return rule.name
            }
        }
        return process.isEmpty ? "未知" : process
    }

    private static func extractDomain(_ host: String) -> String {
        let parts = host.split(separator: ".")
        if parts.count >= 2 {
            return String(parts[parts.count - 2])
        }
        return host
    }
}
