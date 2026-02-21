import SwiftUI

struct DrawingToolbarView: View {
    @Binding var selectedTool: DrawingTool
    @Binding var selectedColor: DrawingColor
    @Binding var selectedThickness: DrawingThickness

    var body: some View {
        HStack(spacing: 20) {

            // MARK: Tool selector (Pen / Eraser)
            HStack(spacing: 4) {
                ToolToggleButton(
                    icon: "pencil.tip",
                    label: "ペン",
                    isSelected: selectedTool == .pen
                ) {
                    selectedTool = .pen
                }

                ToolToggleButton(
                    icon: "eraser.fill",
                    label: "消しゴム",
                    isSelected: selectedTool == .eraser
                ) {
                    selectedTool = .eraser
                }
            }

            toolbarDivider()

            // MARK: Thickness selector
            HStack(spacing: 6) {
                ForEach(DrawingThickness.allCases, id: \.self) { thickness in
                    Button {
                        selectedThickness = thickness
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedThickness == thickness
                                      ? Color.accentColor.opacity(0.15)
                                      : Color.clear)
                                .frame(width: 44, height: 44)

                            Circle()
                                .fill(Color.primary)
                                .frame(
                                    width: thickness.dotSize,
                                    height: thickness.dotSize
                                )
                        }
                    }
                    .accessibilityLabel(thickness.label)
                }
            }

            toolbarDivider()

            // MARK: Color selector
            HStack(spacing: 8) {
                ForEach(DrawingColor.allCases, id: \.self) { drawingColor in
                    Button {
                        selectedColor = drawingColor
                        // Automatically switch to pen when a color is tapped
                        selectedTool = .pen
                    } label: {
                        ZStack {
                            Circle()
                                .fill(drawingColor.color)
                                .frame(width: 28, height: 28)
                                .shadow(
                                    color: drawingColor.color.opacity(0.4),
                                    radius: 2, x: 0, y: 1
                                )

                            // Selection ring
                            if selectedTool == .pen && selectedColor == drawingColor {
                                Circle()
                                    .stroke(Color.primary.opacity(0.8), lineWidth: 2.5)
                                    .frame(width: 36, height: 36)
                            }
                        }
                        .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel(drawingColor.name)
                }
            }
        }
    }

    @ViewBuilder
    private func toolbarDivider() -> some View {
        Divider()
            .frame(height: 32)
    }
}

// MARK: - ToolToggleButton

private struct ToolToggleButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(isSelected ? Color.accentColor : .primary)
            .frame(width: 56, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
        }
    }
}
