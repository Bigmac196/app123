import Foundation

/// Stateless text/number helpers shared by every analyzer. Pure functions, no
/// dependencies — trivially unit-testable.
public enum HeuristicKit {

    public static func contains(_ haystack: String, any needles: [String]) -> Bool {
        let h = haystack.lowercased()
        return needles.contains { h.contains($0.lowercased()) }
    }

    public static func count(_ haystack: String, occurrencesOfAny needles: [String]) -> Int {
        let h = haystack.lowercased()
        return needles.reduce(0) { acc, n in
            acc + h.components(separatedBy: n.lowercased()).count - 1
        }
    }

    /// First number that appears near any of `keywords` (same ~40 chars).
    public static func number(in text: String, near keywords: [String]) -> Double? {
        let lower = text.lowercased()
        for kw in keywords.map({ $0.lowercased() }) {
            guard let r = lower.range(of: kw) else { continue }
            let start = lower.index(r.lowerBound,
                offsetBy: -40, limitedBy: lower.startIndex) ?? lower.startIndex
            let end = lower.index(r.upperBound,
                offsetBy: 40, limitedBy: lower.endIndex) ?? lower.endIndex
            if let n = firstNumber(in: String(lower[start..<end])) { return n }
        }
        return nil
    }

    public static func firstNumber(in text: String) -> Double? {
        guard let r = text.range(of: #"\d[\d,]*(\.\d+)?"#, options: .regularExpression)
        else { return nil }
        return Double(String(text[r]).replacingOccurrences(of: ",", with: ""))
    }

    /// Parses a weight capacity in lbs from free text (handles kg → lbs).
    public static func weightCapacityLbs(in text: String) -> Double? {
        let lower = text.lowercased()
        if let r = lower.range(of: #"(\d{2,4})\s?(lb|lbs|pounds)"#,
                               options: .regularExpression),
           let n = firstNumber(in: String(lower[r])) { return n }
        if let r = lower.range(of: #"(\d{2,4})\s?(kg|kilograms)"#,
                               options: .regularExpression),
           let n = firstNumber(in: String(lower[r])) { return n * 2.20462 }
        return nil
    }

    public static func warrantyYears(in text: String) -> Double? {
        let lower = text.lowercased()
        if let r = lower.range(of: #"(\d{1,2})[\s-]?year"#,
                               options: .regularExpression),
           let n = firstNumber(in: String(lower[r])) { return n }
        if lower.contains("lifetime warranty") { return 10 }
        if let r = lower.range(of: #"(\d{1,3})[\s-]?month"#,
                               options: .regularExpression),
           let n = firstNumber(in: String(lower[r])) { return n / 12 }
        return nil
    }

    /// Size in fluid ounces parsed from "1.7 fl oz", "100 ml", "50ml" etc.
    public static func fluidOunces(in text: String) -> Double? {
        let lower = text.lowercased()
        if let r = lower.range(of: #"(\d+(\.\d+)?)\s?(fl\.?\s?oz|ounce)"#,
                               options: .regularExpression),
           let n = firstNumber(in: String(lower[r])) { return n }
        if let r = lower.range(of: #"(\d+(\.\d+)?)\s?ml"#,
                               options: .regularExpression),
           let n = firstNumber(in: String(lower[r])) { return n / 29.5735 }
        return nil
    }

    public static func double(_ decimal: Decimal?) -> Double? {
        guard let decimal else { return nil }
        return NSDecimalNumber(decimal: decimal).doubleValue
    }

    // Shared trust tiers ---------------------------------------------------

    public enum Tier: Int { case veryLow, low, mid, high, veryHigh }

    public static func ratingTier(_ rating: Double?) -> Tier {
        guard let r = rating else { return .mid }
        switch r {
        case ..<3.0: return .veryLow
        case 3.0..<3.7: return .low
        case 3.7..<4.2: return .mid
        case 4.2..<4.6: return .high
        default: return .veryHigh
        }
    }

    public static func reviewVolumeTier(_ count: Int?) -> Tier {
        guard let c = count else { return .low }
        switch c {
        case ..<25: return .veryLow
        case 25..<150: return .low
        case 150..<800: return .mid
        case 800..<5000: return .high
        default: return .veryHigh
        }
    }
}
