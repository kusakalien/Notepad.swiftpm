import Foundation
import PencilKit

// MARK: - Note

struct Note: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var pages: [Page]
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(title: String = "新しいノート") {
        self.title = title
        self.pages = [Page()]
    }
}

// MARK: - Page

struct Page: Identifiable, Codable {
    var id: UUID = UUID()
    var drawingData: Data = Data()
    var createdAt: Date = Date()

    var drawing: PKDrawing {
        get { (try? PKDrawing(data: drawingData)) ?? PKDrawing() }
        set { drawingData = (try? newValue.dataRepresentation()) ?? Data() }
    }
}

// MARK: - Drawing Tool

enum DrawingTool: Equatable {
    case pen
    case eraser
}

// MARK: - Drawing Color

enum DrawingColor: CaseIterable, Equatable {
    case black
    case red
    case blue

    var uiColor: UIColor {
        switch self {
        case .black: return .black
        case .red:   return .systemRed
        case .blue:  return .systemBlue
        }
    }

    var color: Color {
        Color(uiColor: uiColor)
    }

    var name: String {
        switch self {
        case .black: return "黒"
        case .red:   return "赤"
        case .blue:  return "青"
        }
    }
}

// MARK: - Drawing Thickness

enum DrawingThickness: CaseIterable, Equatable {
    case thin
    case medium
    case thick

    var penWidth: CGFloat {
        switch self {
        case .thin:   return 2
        case .medium: return 5
        case .thick:  return 12
        }
    }

    var eraserWidth: CGFloat {
        switch self {
        case .thin:   return 20
        case .medium: return 50
        case .thick:  return 100
        }
    }

    var dotSize: CGFloat {
        switch self {
        case .thin:   return 6
        case .medium: return 11
        case .thick:  return 18
        }
    }

    var label: String {
        switch self {
        case .thin:   return "細"
        case .medium: return "中"
        case .thick:  return "太"
        }
    }
}

// MARK: - Array safe subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
