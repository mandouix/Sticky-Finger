import SwiftUI

enum NoteColor: String, Codable, CaseIterable {
    case `default`
    case yellow
    case orange
    case rose
    case purple
    case blue
    case teal
    case graphite

    // Overlay tint applied on top of the glass background
    var tintColor: Color {
        switch self {
        case .default:  return .clear
        case .yellow:   return Color(red: 1.0,  green: 0.82, blue: 0.0)
        case .orange:   return Color(red: 1.0,  green: 0.52, blue: 0.12)
        case .rose:     return Color(red: 1.0,  green: 0.2,  blue: 0.34)
        case .purple:   return Color(red: 0.72, green: 0.3,  blue: 1.0)
        case .blue:     return Color(red: 0.08, green: 0.48, blue: 1.0)
        case .teal:     return Color(red: 0.15, green: 0.82, blue: 0.76)
        case .graphite: return Color(white: 0.45)
        }
    }

    // Color shown in the picker swatch circle
    var swatchColor: Color {
        self == .default ? Color(white: 0.82) : tintColor
    }

    // CSS value injected into the editor as --accent
    var cssAccent: String {
        switch self {
        case .default:  return "CanvasText"
        case .yellow:   return "rgb(255,209,0)"
        case .orange:   return "rgb(255,133,31)"
        case .rose:     return "rgb(255,51,87)"
        case .purple:   return "rgb(184,77,255)"
        case .blue:     return "rgb(20,122,255)"
        case .teal:     return "rgb(38,209,194)"
        case .graphite: return "rgb(115,115,115)"
        }
    }
}
