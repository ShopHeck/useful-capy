import SwiftUI

enum ColorTheme: String, CaseIterable, Identifiable {
    case aurora = "Aurora"
    case ocean = "Ocean"
    case sunset = "Sunset"
    case graphite = "Graphite"
    case candy = "Candy"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .aurora: return Color(red: 0.30, green: 0.84, blue: 0.68)
        case .ocean: return Color(red: 0.20, green: 0.50, blue: 0.96)
        case .sunset: return Color(red: 1.00, green: 0.39, blue: 0.30)
        case .graphite: return Color(red: 0.62, green: 0.67, blue: 0.76)
        case .candy: return Color(red: 0.96, green: 0.36, blue: 0.83)
        }
    }

    var secondary: Color {
        switch self {
        case .aurora: return Color(red: 0.22, green: 0.48, blue: 0.96)
        case .ocean: return Color(red: 0.10, green: 0.78, blue: 0.86)
        case .sunset: return Color(red: 1.00, green: 0.72, blue: 0.28)
        case .graphite: return Color(red: 0.18, green: 0.20, blue: 0.27)
        case .candy: return Color(red: 0.53, green: 0.38, blue: 1.00)
        }
    }

    var background: Color {
        switch self {
        case .graphite: return Color(red: 0.06, green: 0.07, blue: 0.10)
        default: return Color(red: 0.97, green: 0.98, blue: 1.00)
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: [accent, secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var darkGradient: LinearGradient {
        LinearGradient(colors: [secondary.opacity(0.95), Color.black.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

enum VisualStyle: String, CaseIterable, Identifiable {
    case glass = "Soft glass"
    case bold = "Bold startup"
    case minimal = "Clean minimal"
    case playful = "Playful rounded"

    var id: String { rawValue }

    var cornerRadius: CGFloat {
        switch self {
        case .glass: return 30
        case .bold: return 24
        case .minimal: return 18
        case .playful: return 36
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .minimal: return 10
        case .bold: return 24
        default: return 18
        }
    }
}

enum MotionLevel: String, CaseIterable, Identifiable {
    case calm = "Calm"
    case lively = "Lively"
    case energetic = "Energetic"

    var id: String { rawValue }

    var spring: Animation {
        switch self {
        case .calm: return .easeInOut(duration: 0.28)
        case .lively: return .spring(response: 0.36, dampingFraction: 0.78)
        case .energetic: return .spring(response: 0.28, dampingFraction: 0.62)
        }
    }
}

enum OutputType: String, CaseIterable, Identifiable {
    case react = "React + CSS"
    case html = "HTML + CSS"
    case swiftUI = "SwiftUI"

    var id: String { rawValue }
}

struct DesignConfiguration: Hashable {
    var theme: ColorTheme = .aurora
    var visualStyle: VisualStyle = .glass
    var motionLevel: MotionLevel = .lively
    var outputType: OutputType = .react
}

enum GenerationMode: String, Hashable {
    case ai = "AI-powered"
    case fallback = "Template fallback"
}

struct GeneratedSection: Identifiable, Hashable, Codable {
    var id = UUID()
    var title: String
    var detail: String
    var iconName: String

    init(title: String, detail: String, iconName: String = "sparkles") {
        self.title = title
        self.detail = detail
        self.iconName = iconName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        detail = try container.decodeIfPresent(String.self, forKey: .detail) ?? ""
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "sparkles"
    }

    enum CodingKeys: String, CodingKey {
        case title
        case detail
        case iconName
    }
}

struct GeneratedMetric: Identifiable, Hashable, Codable {
    var id = UUID()
    var value: String
    var label: String
    var trend: String

    init(value: String, label: String, trend: String = "") {
        self.value = value
        self.label = label
        self.trend = trend
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decodeIfPresent(String.self, forKey: .value) ?? ""
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        trend = try container.decodeIfPresent(String.self, forKey: .trend) ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case value
        case label
        case trend
    }
}

struct GeneratedFormField: Identifiable, Hashable, Codable {
    var id = UUID()
    var label: String
    var placeholder: String
    var kind: String
    var required: Bool

    init(label: String, placeholder: String, kind: String = "text", required: Bool = true) {
        self.label = label
        self.placeholder = placeholder
        self.kind = kind
        self.required = required
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder) ?? ""
        kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? "text"
        required = try container.decodeIfPresent(Bool.self, forKey: .required) ?? true
    }

    enum CodingKeys: String, CodingKey {
        case label
        case placeholder
        case kind
        case required
    }
}

struct GeneratedDesign: Identifiable, Hashable {
    let id = UUID()
    let template: DesignTemplate
    let prompt: String
    let configuration: DesignConfiguration
    let headline: String
    let subheadline: String
    let createdAt: Date
    var kicker: String = "Generated with InterfaceForge"
    var primaryAction: String = "Get started"
    var secondaryAction: String = "See details"
    var sections: [GeneratedSection] = []
    var metrics: [GeneratedMetric] = []
    var formFields: [GeneratedFormField] = []
    var reactCode: String? = nil
    var htmlCode: String? = nil
    var cssCode: String? = nil
    var swiftUICode: String? = nil
    var generationMode: GenerationMode = .fallback
    var generationStatus: String = "Template fallback generated on device."
    var generationError: String? = nil
}
