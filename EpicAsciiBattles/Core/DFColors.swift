import SwiftUI

/// Dwarf Fortress-style color palette
struct DFColors {
    // Standard colors
    static let black = Color(red: 38/255, green: 23/255, blue: 10/255)
    static let blue = Color(red: 15/255, green: 82/255, blue: 186/255)
    static let green = Color(red: 120/255, green: 134/255, blue: 23/255)
    static let cyan = Color(red: 86/255, green: 184/255, blue: 114/255)
    static let red = Color(red: 132/255, green: 0/255, blue: 0/255)
    static let magenta = Color(red: 124/255, green: 26/255, blue: 96/255)
    static let brown = Color(red: 104/255, green: 75/255, blue: 58/255)
    static let lgray = Color(red: 154/255, green: 132/255, blue: 109/255)
    
    // Light/bright colors
    static let dgray = Color(red: 65/255, green: 53/255, blue: 43/255)
    static let lblue = Color(red: 0/255, green: 138/255, blue: 255/255)
    static let lgreen = Color(red: 196/255, green: 219/255, blue: 38/255)
    static let lcyan = Color(red: 72/255, green: 255/255, blue: 184/255)
    static let lred = Color(red: 192/255, green: 61/255, blue: 36/255)
    static let lmagenta = Color(red: 255/255, green: 66/255, blue: 130/255)
    static let yellow = Color(red: 255/255, green: 195/255, blue: 34/255)
    static let white = Color(red: 252/255, green: 250/255, blue: 208/255)
    
    /// Get color by name (for species definitions)
    static func named(_ name: String) -> Color {
        switch name.lowercased() {
        case "black": return black
        case "blue": return blue
        case "green": return green
        case "cyan": return cyan
        case "red": return red
        case "magenta", "pink", "lpink": return magenta
        case "brown": return brown
        case "gray", "grey": return lgray
        case "lgray", "lightgray", "light_gray": return lgray
        case "dgray", "darkgray", "dark_gray": return dgray
        case "lblue", "lightblue", "light_blue": return lblue
        case "lgreen", "lightgreen", "light_green": return lgreen
        case "lcyan", "lightcyan", "light_cyan": return lcyan
        case "lred", "lightred", "light_red": return lred
        case "lmagenta", "lightmagenta", "light_magenta": return lmagenta
        case "yellow": return yellow
        case "orange": return Color(red: 255/255, green: 150/255, blue: 50/255)
        case "purple": return Color(red: 150/255, green: 70/255, blue: 200/255)
        case "white": return white
        default: return white
        }
    }
    
    /// Get UIColor by name (for tileset rendering)
    static func uiNamed(_ name: String) -> UIColor {
        return UIColor(named(name))
    }
    
    /// Team A default color (greenish)
    static let teamA = lgreen
    
    /// Team B default color (reddish)  
    static let teamB = lred
    
    /// Background/floor color
    static let floor = dgray
    
    /// Blood color
    static let blood = red
    
    /// Hit flash color
    static let hitFlash = yellow
}
