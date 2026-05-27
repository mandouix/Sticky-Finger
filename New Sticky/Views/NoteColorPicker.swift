import SwiftUI

struct NoteColorPicker: View {
    @Binding var selectedColor: NoteColor
    @Binding var isExpanded: Bool

    private let circleSize: CGFloat = 18
    private let swatchSize: CGFloat = 22
    private let columns = Array(repeating: GridItem(.fixed(22), spacing: 6), count: 4)

    var body: some View {
        Circle()
            .fill(selectedColor.swatchColor)
            .frame(width: circleSize, height: circleSize)
            .overlay(Circle().strokeBorder(Color.primary.opacity(0.2), lineWidth: 0.75))
            .onTapGesture {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                    isExpanded.toggle()
                }
            }
            .pointerCursor()
            // Grid floats above the circle, anchored to its bottom-trailing corner
            .overlay(alignment: .bottomTrailing) {
                if isExpanded {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(NoteColor.allCases, id: \.rawValue) { color in
                            swatch(color)
                        }
                    }
                    .padding(8)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                    .fixedSize()
                    .offset(y: -(circleSize + 6))
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.15, anchor: .bottomTrailing).combined(with: .opacity),
                        removal:   .scale(scale: 0.15, anchor: .bottomTrailing).combined(with: .opacity)
                    ))
                }
            }
    }

    @ViewBuilder
    private func swatch(_ color: NoteColor) -> some View {
        let isSelected = selectedColor == color
        ZStack {
            Circle()
                .fill(color.swatchColor)
                .frame(width: swatchSize, height: swatchSize)

            if color == .default {
                Image(systemName: "circle.slash")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color.primary.opacity(0.35))
            }

            Circle()
                .strokeBorder(
                    isSelected ? Color.primary.opacity(0.75) : Color.primary.opacity(0.12),
                    lineWidth: isSelected ? 2 : 0.5
                )
                .frame(width: swatchSize, height: swatchSize)
        }
        .scaleEffect(isSelected ? 1.12 : 1.0)
        .animation(.spring(response: 0.2), value: isSelected)
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                selectedColor = color
                isExpanded = false
            }
        }
        .pointerCursor()
    }
}
