import SwiftUI
import PencilKit

struct CanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var tool: DrawingTool
    var color: DrawingColor
    var thickness: DrawingThickness

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.backgroundColor = .white
        canvas.delegate = context.coordinator
        // Allow both Apple Pencil and finger input
        canvas.drawingPolicy = .anyInput
        canvas.alwaysBounceVertical = false
        canvas.isScrollEnabled = false
        applyTool(to: canvas)
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Sync drawing when changed externally (e.g. page switch via .id())
        if !context.coordinator.isUpdatingFromDelegate && uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        applyTool(to: uiView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func applyTool(to canvas: PKCanvasView) {
        switch tool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: color.uiColor, width: thickness.penWidth)
        case .eraser:
            canvas.tool = PKEraserTool(.bitmap, width: thickness.eraserWidth)
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasView
        var isUpdatingFromDelegate = false

        init(_ parent: CanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUpdatingFromDelegate = true
            parent.drawing = canvasView.drawing
            isUpdatingFromDelegate = false
        }
    }
}
