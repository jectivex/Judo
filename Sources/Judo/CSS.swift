

/// Encapsulation of CSS structures
public enum CSS {
    /// https://developer.mozilla.org/en-US/docs/Web/CSS/angle
    public enum Angle : Hashable {
        case deg(Double)
        case grad(Double)
        case rad(Double)
        case turn(Double)

        var angleValue: Double {
            switch self {
            case .deg(let x): return x
            case .grad(let x): return x
            case .rad(let x): return x
            case .turn(let x): return x
            }
        }
    }

    /// https://developer.mozilla.org/en-US/docs/Web/CSS/font-style#formal_syntax
    public enum FontStyle : Hashable {
        case normal
        case italize
        case oblique(Angle?)
    }


    /// https://developer.mozilla.org/en-US/docs/Web/CSS/font-size
    public enum FontSize : Hashable {


        /// A unit for this font size
        public typealias Unit = OneOf<RelativeUnit>.Or<AbsoluteUnit>

        /// https://developer.mozilla.org/en-US/docs/Web/CSS/length#units
        public enum RelativeUnit : String, CaseIterable, Hashable {
            /// Represents the width, or more precisely the advance measure, of the glyph "0" (zero, the Unicode character U+0030) in the element's font.
            case ch
            /// Represents the calculated font-size of the element. If used on the font-size property itself, it represents the inherited font-size of the element.
            case em
            /// Represents the x-height of the element's font. On fonts with the "x" letter, this is generally the height of lowercase letters in the font; 1ex ≈ 0.5em in many fonts.
            case ex
            /// Represents the font-size of the root element (typically <html>). When used within the root element font-size, it represents its initial value (a common browser default is 16px, but user-defined preferences may modify this).
            case rem
            /// Equal to 1% of the height of the viewport's initial containing block.
            case vh
            /// Equal to 1% of the width of the viewport's initial containing block.
            case vw
            /// Equal to the smaller of vw and vh.
            case vmin
            /// Equal to the larger of vw and vh.
            case vmax
        }

        public enum AbsoluteUnit : String, CaseIterable, Hashable {
            /// One pixel. For screen displays, it traditionally represents one device pixel (dot). However, for printers and high-resolution screens, one CSS pixel implies multiple device pixels. 1px = 1/96th of 1in.
            case px
            /// One centimeter. 1cm = 96px/2.54.
            case cm
            /// One millimeter. 1mm = 1/10th of 1cm.
            case mm
            /// One inch. 1in = 2.54cm = 96px.
            case `in`
            /// One pica. 1pc = 12pt = 1/6th of 1in.
            case pc
            /// One point. 1pt = 1/72nd of 1in.
            case pt
        }

        /// https://developer.mozilla.org/en-US/docs/Web/CSS/font-size
        public enum Size : String, CaseIterable, Hashable {
            case xxsmall = "xx-small"
            case xsmall = "x-small"
            case small = "small"
            case medium = "medium"
            case large = "large"
            case xlarge = "x-large"
            case xxlarge = "xx-large"
            case larger = "larger"
            case smaller = "smaller"
        }
    }

    public enum SystemFont : String, CaseIterable, Hashable {
        case caption = "caption"
        case icon = "icon"
        case menu = "menu"
        case messagebox = "message-box"
        case smallcaption = "small-caption"
        case statusbar = "status-bar"
    }

    /// https://developer.mozilla.org/en-US/docs/Web/CSS/font-stretch
    public enum FontStretch : String, CaseIterable, Hashable {
        case normal = "normal"
        case condensed = "condensed"
        case semicondensed = "semi-condensed"
        case extracondensed = "extra-condensed"
        case ultracondensed = "ultra-condensed"
        case expanded = "expanded"
        case semiexpanded = "semi-expanded"
        case extraexpanded = "extra-expanded"
        case ultraexpanded = "ultra-expanded"
    }

    /// https://developer.mozilla.org/en-US/docs/Web/CSS/font-weight
    public enum CSSFontWeight : String, CaseIterable, Hashable {
        case normal = "normal"
        case bold = "bold"
        case lighter = "lighter"
        case bolder = "bolder"
        case n100 = "100"
        case n200 = "200"
        case n300 = "300"
        case n400 = "400"
        case n500 = "500"
        case n600 = "600"
        case n700 = "700"
        case n800 = "800"
        case n900 = "900"
    }

    public struct Font: Hashable {
        public var style: String?
        public var variant: String?
        public var weight: String?
        public var stretch: String?
        public var size: String?
        public var lineHeight: OneOf<String>.Or<Double>?
        public var family: [String]?
    }

    /// Symbolic CSS Colors
    public enum ColorName : String, CaseIterable, Hashable {
        case black
        case navy
        case blue
        case green
        case lime
        case aqua
        case teal
        case maroon
        case purple
        case olive
        case gray
        case silver
        case red
        case fuchsia
        case orange
        case yellow
        case white
        case darkblue
        case mediumblue
        case darkgreen
        case darkcyan
        case deepskyblue
        case darkturquoise
        case mediumspringgreen
        case springgreen
        case cyan
        case midnightblue
        case dodgerblue
        case lightseagreen
        case forestgreen
        case seagreen
        case darkslategray
        case limegreen
        case mediumseagreen
        case turquoise
        case royalblue
        case steelblue
        case darkslateblue
        case mediumturquoise
        case indigo
        case darkolivegreen
        case cadetblue
        case cornflowerblue
        case rebeccapurple
        case mediumaquamarine
        case dimgray
        case slateblue
        case olivedrab
        case slategray
        case lightslategray
        case mediumslateblue
        case lawngreen
        case chartreuse
        case aquamarine
        case skyblue
        case lightskyblue
        case blueviolet
        case darkred
        case darkmagenta
        case saddlebrown
        case darkseagreen
        case lightgreen
        case mediumpurple
        case darkviolet
        case palegreen
        case darkorchid
        case yellowgreen
        case sienna
        case brown
        case darkgray
        case lightblue
        case greenyellow
        case paleturquoise
        case lightsteelblue
        case powderblue
        case firebrick
        case darkgoldenrod
        case mediumorchid
        case rosybrown
        case darkkhaki
        case mediumvioletred
        case indianred
        case peru
        case chocolate
        case tan
        case lightgray
        case thistle
        case orchid
        case goldenrod
        case palevioletred
        case crimson
        case gainsboro
        case plum
        case burlywood
        case lightcyan
        case lavender
        case darksalmon
        case violet
        case palegoldenrod
        case lightcoral
        case khaki
        case aliceblue
        case honeydew
        case azure
        case sandybrown
        case wheat
        case beige
        case whitesmoke
        case mintcream
        case ghostwhite
        case salmon
        case antiquewhite
        case linen
        case lightgoldenrodyellow
        case oldlace
        case magenta
        case deeppink
        case orangered
        case tomato
        case hotpink
        case coral
        case darkorange
        case lightsalmon
        case lightpink
        case pink
        case gold
        case peachpuff
        case navajowhite
        case moccasin
        case bisque
        case mistyrose
        case blanchedalmond
        case papayawhip
        case lavenderblush
        case seashell
        case cornsilk
        case lemonchiffon
        case floralwhite
        case snow
        case lightyellow
        case ivory

        public var hexCode: String {
            switch self {
            case .aliceblue: return "#f0f8ff"
            case .antiquewhite: return "#faebd7"
            case .aqua: return "#00ffff"
            case .aquamarine: return "#7fffd4"
            case .azure: return "#f0ffff"
            case .beige: return "#f5f5dc"
            case .bisque: return "#ffe4c4"
            case .black: return "#000000"
            case .blanchedalmond: return "#ffebcd"
            case .blue: return "#0000ff"
            case .blueviolet: return "#8a2be2"
            case .brown: return "#a52a2a"
            case .burlywood: return "#deb887"
            case .cadetblue: return "#5f9ea0"
            case .chartreuse: return "#7fff00"
            case .chocolate: return "#d2691e"
            case .coral: return "#ff7f50"
            case .cornflowerblue: return "#6495ed"
            case .cornsilk: return "#fff8dc"
            case .crimson: return "#dc143c"
            case .cyan: return "#00ffff"
            case .darkblue: return "#00008b"
            case .darkcyan: return "#008b8b"
            case .darkgoldenrod: return "#b8860b"
            case .darkgray: return "#a9a9a9"
            case .darkgreen: return "#006400"
            //case .darkgrey: return "#a9a9a9"
            case .darkkhaki: return "#bdb76b"
            case .darkmagenta: return "#8b008b"
            case .darkolivegreen: return "#556b2f"
            case .darkorange: return "#ff8c00"
            case .darkorchid: return "#9932cc"
            case .darkred: return "#8b0000"
            case .darksalmon: return "#e9967a"
            case .darkseagreen: return "#8fbc8f"
            case .darkslateblue: return "#483d8b"
            case .darkslategray: return "#2f4f4f"
            //case .darkslategrey: return "#2f4f4f"
            case .darkturquoise: return "#00ced1"
            case .darkviolet: return "#9400d3"
            case .deeppink: return "#ff1493"
            case .deepskyblue: return "#00bfff"
            case .dimgray: return "#696969"
            //case .dimgrey: return "#696969"
            case .dodgerblue: return "#1e90ff"
            case .firebrick: return "#b22222"
            case .floralwhite: return "#fffaf0"
            case .forestgreen: return "#228b22"
            case .fuchsia: return "#ff00ff"
            case .gainsboro: return "#dcdcdc"
            case .ghostwhite: return "#f8f8ff"
            case .gold: return "#ffd700"
            case .goldenrod: return "#daa520"
            case .gray: return "#808080"
            case .green: return "#008000"
            case .greenyellow: return "#adff2f"
            //case .grey: return "#808080"
            case .honeydew: return "#f0fff0"
            case .hotpink: return "#ff69b4"
            case .indianred: return "#cd5c5c"
            case .indigo: return "#4b0082"
            case .ivory: return "#fffff0"
            case .khaki: return "#f0e68c"
            case .lavender: return "#e6e6fa"
            case .lavenderblush: return "#fff0f5"
            case .lawngreen: return "#7cfc00"
            case .lemonchiffon: return "#fffacd"
            case .lightblue: return "#add8e6"
            case .lightcoral: return "#f08080"
            case .lightcyan: return "#e0ffff"
            case .lightgoldenrodyellow: return "#fafad2"
            case .lightgray: return "#d3d3d3"
            case .lightgreen: return "#90ee90"
            //case .lightgrey: return "#d3d3d3"
            case .lightpink: return "#ffb6c1"
            case .lightsalmon: return "#ffa07a"
            case .lightseagreen: return "#20b2aa"
            case .lightskyblue: return "#87cefa"
            case .lightslategray: return "#778899"
            //case .lightslategrey: return "#778899"
            case .lightsteelblue: return "#b0c4de"
            case .lightyellow: return "#ffffe0"
            case .lime: return "#00ff00"
            case .limegreen: return "#32cd32"
            case .linen: return "#faf0e6"
            case .magenta: return "#ff00ff"
            case .maroon: return "#800000"
            case .mediumaquamarine: return "#66cdaa"
            case .mediumblue: return "#0000cd"
            case .mediumorchid: return "#ba55d3"
            case .mediumpurple: return "#9370db"
            case .mediumseagreen: return "#3cb371"
            case .mediumslateblue: return "#7b68ee"
            case .mediumspringgreen: return "#00fa9a"
            case .mediumturquoise: return "#48d1cc"
            case .mediumvioletred: return "#c71585"
            case .midnightblue: return "#191970"
            case .mintcream: return "#f5fffa"
            case .mistyrose: return "#ffe4e1"
            case .moccasin: return "#ffe4b5"
            case .navajowhite: return "#ffdead"
            case .navy: return "#000080"
            case .oldlace: return "#fdf5e6"
            case .olive: return "#808000"
            case .olivedrab: return "#6b8e23"
            case .orange: return "#ffa500"
            case .orangered: return "#ff4500"
            case .orchid: return "#da70d6"
            case .palegoldenrod: return "#eee8aa"
            case .palegreen: return "#98fb98"
            case .paleturquoise: return "#afeeee"
            case .palevioletred: return "#db7093"
            case .papayawhip: return "#ffefd5"
            case .peachpuff: return "#ffdab9"
            case .peru: return "#cd853f"
            case .pink: return "#ffc0cb"
            case .plum: return "#dda0dd"
            case .powderblue: return "#b0e0e6"
            case .purple: return "#800080"
            case .rebeccapurple: return "#663399"
            case .red: return "#ff0000"
            case .rosybrown: return "#bc8f8f"
            case .royalblue: return "#4169e1"
            case .saddlebrown: return "#8b4513"
            case .salmon: return "#fa8072"
            case .sandybrown: return "#f4a460"
            case .seagreen: return "#2e8b57"
            case .seashell: return "#fff5ee"
            case .sienna: return "#a0522d"
            case .silver: return "#c0c0c0"
            case .skyblue: return "#87ceeb"
            case .slateblue: return "#6a5acd"
            case .slategray: return "#708090"
            //case .slategrey: return "#708090"
            case .snow: return "#fffafa"
            case .springgreen: return "#00ff7f"
            case .steelblue: return "#4682b4"
            case .tan: return "#d2b48c"
            case .teal: return "#008080"
            case .thistle: return "#d8bfd8"
            case .tomato: return "#ff6347"
            case .turquoise: return "#40e0d0"
            case .violet: return "#ee82ee"
            case .wheat: return "#f5deb3"
            case .white: return "#ffffff"
            case .whitesmoke: return "#f5f5f5"
            case .yellow: return "#ffff00"
            case .yellowgreen: return "#9acd32"
            }
        }

        public var colorCode: Int {
            switch self {
            case .black: return 0x000000
            case .navy: return 0x000080
            case .blue: return 0x0000FF
            case .green: return 0x008000
            case .lime: return 0x00FF00
            case .aqua: return 0x00FFFF
            case .teal: return 0x008080
            case .maroon: return 0x800000
            case .purple: return 0x800080
            case .olive: return 0x808000
            case .gray: return 0x808080
            case .silver: return 0xC0C0C0
            case .red: return 0xFF0000
            case .fuchsia: return 0xFF00FF
            case .orange: return 0xFFA500
            case .yellow: return 0xFFFF00
            case .white: return 0xFFFFFF
            case .darkblue: return 0x00008B
            case .mediumblue: return 0x0000CD
            case .darkgreen: return 0x006400
            case .darkcyan: return 0x008B8B
            case .deepskyblue: return 0x00BFFF
            case .darkturquoise: return 0x00CED1
            case .mediumspringgreen: return 0x00FA9A
            case .springgreen: return 0x00FF7F
            case .cyan: return 0x00FFFF
            case .midnightblue: return 0x191970
            case .dodgerblue: return 0x1E90FF
            case .lightseagreen: return 0x20B2AA
            case .forestgreen: return 0x228B22
            case .seagreen: return 0x2E8B57
            case .darkslategray: return 0x2F4F4F
            case .limegreen: return 0x32CD32
            case .mediumseagreen: return 0x3CB371
            case .turquoise: return 0x40E0D0
            case .royalblue: return 0x4169E1
            case .steelblue: return 0x4682B4
            case .darkslateblue: return 0x483D8B
            case .mediumturquoise: return 0x48D1CC
            case .indigo: return 0x4B0082
            case .darkolivegreen: return 0x556B2F
            case .cadetblue: return 0x5F9EA0
            case .cornflowerblue: return 0x6495ED
            case .rebeccapurple: return 0x663399
            case .mediumaquamarine: return 0x66CDAA
            case .dimgray: return 0x696969
            case .slateblue: return 0x6A5ACD
            case .olivedrab: return 0x6B8E23
            case .slategray: return 0x708090
            case .lightslategray: return 0x778899
            case .mediumslateblue: return 0x7B68EE
            case .lawngreen: return 0x7CFC00
            case .chartreuse: return 0x7FFF00
            case .aquamarine: return 0x7FFFD4
            case .skyblue: return 0x87CEEB
            case .lightskyblue: return 0x87CEFA
            case .blueviolet: return 0x8A2BE2
            case .darkred: return 0x8B0000
            case .darkmagenta: return 0x8B008B
            case .saddlebrown: return 0x8B4513
            case .darkseagreen: return 0x8FBC8F
            case .lightgreen: return 0x90EE90
            case .mediumpurple: return 0x9370DB
            case .darkviolet: return 0x9400D3
            case .palegreen: return 0x98FB98
            case .darkorchid: return 0x9932CC
            case .yellowgreen: return 0x9ACD32
            case .sienna: return 0xA0522D
            case .brown: return 0xA52A2A
            case .darkgray: return 0xA9A9A9
            case .lightblue: return 0xADD8E6
            case .greenyellow: return 0xADFF2F
            case .paleturquoise: return 0xAFEEEE
            case .lightsteelblue: return 0xB0C4DE
            case .powderblue: return 0xB0E0E6
            case .firebrick: return 0xB22222
            case .darkgoldenrod: return 0xB8860B
            case .mediumorchid: return 0xBA55D3
            case .rosybrown: return 0xBC8F8F
            case .darkkhaki: return 0xBDB76B
            case .mediumvioletred: return 0xC71585
            case .indianred: return 0xCD5C5C
            case .peru: return 0xCD853F
            case .chocolate: return 0xD2691E
            case .tan: return 0xD2B48C
            case .lightgray: return 0xD3D3D3
            case .thistle: return 0xD8BFD8
            case .orchid: return 0xDA70D6
            case .goldenrod: return 0xDAA520
            case .palevioletred: return 0xDB7093
            case .crimson: return 0xDC143C
            case .gainsboro: return 0xDCDCDC
            case .plum: return 0xDDA0DD
            case .burlywood: return 0xDEB887
            case .lightcyan: return 0xE0FFFF
            case .lavender: return 0xE6E6FA
            case .darksalmon: return 0xE9967A
            case .violet: return 0xEE82EE
            case .palegoldenrod: return 0xEEE8AA
            case .lightcoral: return 0xF08080
            case .khaki: return 0xF0E68C
            case .aliceblue: return 0xF0F8FF
            case .honeydew: return 0xF0FFF0
            case .azure: return 0xF0FFFF
            case .sandybrown: return 0xF4A460
            case .wheat: return 0xF5DEB3
            case .beige: return 0xF5F5DC
            case .whitesmoke: return 0xF5F5F5
            case .mintcream: return 0xF5FFFA
            case .ghostwhite: return 0xF8F8FF
            case .salmon: return 0xFA8072
            case .antiquewhite: return 0xFAEBD7
            case .linen: return 0xFAF0E6
            case .lightgoldenrodyellow: return 0xFAFAD2
            case .oldlace: return 0xFDF5E6
            case .magenta: return 0xFF00FF
            case .deeppink: return 0xFF1493
            case .orangered: return 0xFF4500
            case .tomato: return 0xFF6347
            case .hotpink: return 0xFF69B4
            case .coral: return 0xFF7F50
            case .darkorange: return 0xFF8C00
            case .lightsalmon: return 0xFFA07A
            case .lightpink: return 0xFFB6C1
            case .pink: return 0xFFC0CB
            case .gold: return 0xFFD700
            case .peachpuff: return 0xFFDAB9
            case .navajowhite: return 0xFFDEAD
            case .moccasin: return 0xFFE4B5
            case .bisque: return 0xFFE4C4
            case .mistyrose: return 0xFFE4E1
            case .blanchedalmond: return 0xFFEBCD
            case .papayawhip: return 0xFFEFD5
            case .lavenderblush: return 0xFFF0F5
            case .seashell: return 0xFFF5EE
            case .cornsilk: return 0xFFF8DC
            case .lemonchiffon: return 0xFFFACD
            case .floralwhite: return 0xFFFAF0
            case .snow: return 0xFFFAFA
            case .lightyellow: return 0xFFFFE0
            case .ivory: return 0xFFFFF0
            }
        }
    }
}


extension CSS {

    // CSS font parser regular expression
    private static let fontParseRegexp = Result {
        try NSRegularExpression(pattern: "^\\s*(?=(?:(?:[-a-z]+\\s*){0,2}(italic|oblique))?)(?=(?:(?:[-a-z]+\\s*){0,2}(small-caps))?)(?=(?:(?:[-a-z]+\\s*){0,2}(bold(?:er)?|lighter|[1-9]00))?)(?:(?:normal|\\1|\\2|\\3)\\s*){0,3}((?:xx?-)?(?:small|large)|medium|smaller|larger|[.\\d]+(?:\\%|in|[cem]m|ex|p[ctx]))(?:\\s*\\/\\s*(normal|[.\\d]+(?:\\%|in|[cem]m|ex|p[ctx])))?\\s*([-,\"\\sa-z]+?)\\s*$", options: .caseInsensitive)
    }


    static func hsl2rgbOLD(h: Double, s: Double, l: Double) -> (r: Double, g: Double, b: Double) {
        func hueToRGB(m1: Double, m2: Double, h: Double) -> Double {
            var h = h
            if (h < 0.0) { h += 1.0 }
            if (h > 1.0) { h -= 1.0 }
            if (h < 1.0 / 6.0) { return (m1 + (m2 - m1) * h * 6.0) }
            if (h < 1.0 / 2.0) { return m2 }
            if (h < 2.0 / 3.0) { return (m1 + (m2 - m1) * ((2.0 / 3.0) - h) * 6.0) }
            return m1
        }

        if s == 0.0 {
            return (l, l, l)
        } else {
            var m2 = 0.0
            if l <= 0.5 {
                m2 = l * (1.0 + s)
            } else {
                m2 = l + s - l * s
            }

            let m1 = 2.0 * l - m2

            return (hueToRGB(m1: m1, m2: m2, h: h + (1.0 / 3.0)), hueToRGB(m1: m1, m2: m2, h: h), hueToRGB(m1: m1, m2: m2, h: h - (1.0 / 3.0)))
        }
    }

    static func hsl2rgb(h hue: Double, s saturation: Double, l lightness: Double) -> (r: Double, g: Double, b: Double) {
        let h = hue
        let s = saturation
        let l = lightness

        let t2: Double
        var t3: Double
        var val: Double

        if (s == 0) {
            val = l * 255
            return (val, val, val)
        }

        if (l < 0.5) {
            t2 = l * (1 + s)
        } else {
            t2 = l + s - l * s
        }

        let t1 = 2 * l - t2

        var rgb = [0.0, 0.0, 0.0] // the current RGB buffer

        for i in 0..<3 {
            t3 = h + 1 / 3 * -(Double(i) - 1)
            if (t3 < 0) {
                t3 += 1
            }

            if (t3 > 1) {
                t3 -= 1
            }

            if (6 * t3 < 1) {
                val = t1 + (t2 - t1) * 6 * t3
            } else if (2 * t3 < 1) {
                val = t2
            } else if (3 * t3 < 2) {
                val = t1 + (t2 - t1) * (2 / 3 - t3) * 6
            } else {
                val = t1
            }

            rgb[i] = val * 255
        }

        return (rgb[0] / 255, rgb[1] / 255, rgb[2] / 255)
    }
}


#if canImport(CoreGraphics)
import CoreGraphics

extension CSS {
    public static func parseColorStyleNative(css string: String) -> CGColor? {
        // first check for a named color
        let css = ColorName(rawValue: string.lowercased())?.hexCode ?? string

        func rgba(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> CGColor? {
            // return CGColor(red: r, green: g, blue: b, alpha: a)
            return CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [r, g, b, a])
        }

        if css.hasPrefix("#") {
            var c = css.makeIterator()
            if c.next() != "#" { return nil }
            func part(_ c1: Character?, _ c2: Character?) -> CGFloat {
                let prefix = String([c1 ?? "F", c2 ?? "F"])
                return CGFloat(Int(prefix, radix: 16) ?? 0) / 255.0
            }

            // #ABC <- shorthand w/o alpha
            // #ABCD <- shorthand w/ alpha
            // #AABBCC <- longhand w/o alpha
            // #AABBCCDD <- longhand w/alpha
            let shorthand = css.count < 6
            func parseComponent() -> CGFloat {
                let first = c.next()
                let second = shorthand ? first : c.next()
                return part(first, second)
            }
            return rgba(r: parseComponent(), g: parseComponent(), b: parseComponent(), a: parseComponent())
        }

        // try parsing arguments in parent
        let parts = css.split { $0 == "(" || $0 == ")" }
        if parts.count != 2 { return nil }
        let space = parts[0]

        let comps = parts[1].split { $0 == "," || $0 == " " }.map(String.init)
        if comps.count < 3 { return nil }

        func pbase(_ str: String, base: Int? = nil) -> Double? {
            let chars = str
            if chars.isEmpty { return nil }
            if chars.last == "%" {
                guard let percent = Double(String(chars.dropLast())) else { return nil }
                return percent / 100.0
            } else {
                guard let number = Double(str) else { return nil }
                if let base = base {
                    return number / Double(base)
                } else {
                    return number
                }
            }
        }


        if space == "rgb" && comps.count == 3 {
            guard let r = pbase(comps[0], base: 255),
                let g = pbase(comps[1], base: 255),
                let b = pbase(comps[2], base: 255) else {
                return nil
            }
            return rgba(r: CGFloat(r), g: CGFloat(g), b: CGFloat(b), a: 1.0)
        }

        if space == "rgba" && comps.count == 4 {
            guard let r = pbase(comps[0], base: 255),
                let g = pbase(comps[1], base: 255),
                let b = pbase(comps[2], base: 255),
                let a = pbase(comps[3], base: nil) else {
                return nil
            }
            return rgba(r: CGFloat(r), g: CGFloat(g), b: CGFloat(b), a: CGFloat(a))
        }

        if space == "hsl" && comps.count == 3 {
            guard let h = pbase(comps[0], base: 360),
                let s = pbase(comps[1], base: 100),
                let l = pbase(comps[2], base: 100) else {
                return nil
            }

            let rgb = hsl2rgb(h: h, s: s, l: l)
            return rgba(r: CGFloat(rgb.r), g: CGFloat(rgb.g), b: CGFloat(rgb.b), a: 1.0)
        }

        return nil
    }


    /// Parse the given font CSS string, caching the results
    public static func parseFontStyleNative(css string: String) -> CTFont? {
        wip(nil)
    }


}


import CoreText

#if canImport(AppKit) // exists merely as a reference implementation for test cases
import AppKit

extension CSS {
    /// Parses the given CSS attribute using macOS' `NSAttributedString.init(html:)`, which spins up a web view internally to parse the string (and thus is very heavyweight and constrained to the main thread)
    ///
    /// - Note: this is slow, must be run on the main thread
    /// - TODO: @MainActor
    private static func parseCSSWebKit(key: NSAttributedString.Key, value: String) -> Any? {
        NSAttributedString(html: ("<span style='\(key == .font ? "font" : key == .foregroundColor ? "color" : key.rawValue): \(value)'>X</span>").utf8Data, options: [:], documentAttributes: nil)?.attribute(key, at: 0, effectiveRange: nil)
    }

    public static func parseColorStyleWebKit(css string: String) -> CGColor? {
        (parseCSSWebKit(key: .foregroundColor, value: string) as? NSColor)?.cgColor
    }

    #if canImport(UIKit)
    typealias NativeFont = UIFont
    #elseif canImport(AppKit)
    typealias NativeFont = NSFont
    #endif

    /// Parse the given font CSS string, caching the results
    public static func parseFontStyleWebKit(css string: String) -> CTFont? {
        (parseCSSWebKit(key: .font, value: string) as? NativeFont)
    }

    public static func parseColorStyle(css string: String) -> CGColor? {
        parseColorStyleWebKit(css: string)
    }

    /// Parse the given font CSS string, caching the results
    public static func parseFontStyle(css string: String) -> CTFont? {
        parseFontStyleWebKit(css: string)
    }
}
#else

extension CSS {
    public static func parseColorStyle(css string: String) -> CGColor? {
        parseColorStyleNative(css: string)
    }

    /// Parse the given font CSS string, caching the results
    public static func parseFontStyle(css string: String) -> CTFont? {
        parseFontStyleNative(css: string)
    }

    @available(*, deprecated, message: "not available on platform")
    public static func parseColorStyleWebKit(css string: String) -> CGColor? {
        parseColorStyleNative(css: string)
    }

    /// Parse the given font CSS string, caching the results
    @available(*, deprecated, message: "not available on platform")
    public static func parseFontStyleWebKit(css string: String) -> CTFont? {
        parseFontStyleNative(css: string)
    }
}

#endif // canImport(AppKit)
#endif // canImport(CoreGraphics)
//
/// Deferred work-in-progress; note of the given todo item; enable deprecation to provide messages for the todo
@available(*, deprecated, message: "work in progress")
@discardableResult fileprivate func wip<T>(_ t: T) -> T { return t }
