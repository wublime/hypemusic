import Foundation

/// Music drops at midnight in America/New_York (DST-aware). Countdown (`ND NH NM`) and
/// “OUT NOW” copy are derived from `yyyy-MM-dd` release dates from the server.
enum ReleaseSchedule {
    static let newYork = TimeZone(identifier: "America/New_York")!

    /// First instant of the release calendar day in Eastern time.
    static func easternMidnightStartOfReleaseDay(forYYYYMMDD raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2]) else { return nil }
        guard (1 ... 12).contains(m), (1 ... 31).contains(d) else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = newYork

        var comps = DateComponents()
        comps.calendar = calendar
        comps.timeZone = newYork
        comps.year = y
        comps.month = m
        comps.day = d
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps)
    }

    /// `OUT NOW 6/15` using the album’s release calendar day (numeric month / day, Eastern).
    static func outNowLabel(forYYYYMMDD raw: String) -> String {
        guard let start = easternMidnightStartOfReleaseDay(forYYYYMMDD: raw) else {
            return "OUT NOW"
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = newYork
        let month = calendar.component(.month, from: start)
        let day = calendar.component(.day, from: start)
        return "OUT NOW \(month)/\(day)"
    }

    /// `ND NH NM` until Eastern midnight on the release date; empty if unparsable.
    static func countdownLabel(forYYYYMMDD raw: String, now: Date) -> String {
        guard let drop = easternMidnightStartOfReleaseDay(forYYYYMMDD: raw) else {
            return ""
        }
        let remaining = drop.timeIntervalSince(now)
        guard remaining > 0 else { return "" }

        let totalSeconds = Int(floor(remaining))
        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60

        return "\(days)D \(hours)H \(minutes)M"
    }

    /// Badge line for the card: countdown, out-now, or fallback.
    static func badgeText(releaseDateYYYYMMDD: String?, now: Date) -> String {
        guard let raw = releaseDateYYYYMMDD, !raw.isEmpty else {
            return "—"
        }
        guard let drop = easternMidnightStartOfReleaseDay(forYYYYMMDD: raw) else {
            return "—"
        }
        if now >= drop {
            return outNowLabel(forYYYYMMDD: raw)
        }
        return countdownLabel(forYYYYMMDD: raw, now: now)
    }
}
