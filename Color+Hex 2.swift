// Shared Color extension for hex string parsing. Avoids conflicts with any existing init(hex:) by using a distinct initializer name.
import SwiftUI

public extension Color {
    /// Initialize a Color from a hex string like "#RRGGBB" or "#RRGGBBAA" (alpha last).
    /// Examples: "#FFB300", "#1A1A1C", "0F0F10", "#FFB300FF".
    init(hexString: String) {
        // Remove non-alphanumeric characters
        let hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "0x", with: "")
            .replacingOccurrences(of: "0X", with: "")

        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0, a: UInt64 = 255
        var value: UInt64 = 0

        let scanner = Scanner(string: hex)
        if scanner.scanHexInt64(&value) {
            switch hex.count {
            case 3: // RGB (12-bit, e.g., FFF)
                r = (value >> 8) & 0xF
                g = (value >> 4) & 0xF
                b = value & 0xF
                // Expand from 0..15 to 0..255
                r = (r << 4) | r
                g = (g << 4) | g
                b = (b << 4) | b
            case 6: // RRGGBB
                r = (value >> 16) & 0xFF
                g = (value >> 8) & 0xFF
                b = value & 0xFF
            case 8: // RRGGBBAA (alpha last)
                r = (value >> 24) & 0xFF
                g = (value >> 16) & 0xFF
                b = (value >> 8) & 0xFF
                a = value & 0xFF
            default:
                // Unsupported length; default to clear
                self = .clear
                return
            }
        } else {
            self = .clear
            return
        }

        self = Color(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}
