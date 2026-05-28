import SwiftUI
import AppKit

private struct HoverBlurModifier: ViewModifier {
    var opacity: Double
    var scale: CGFloat
    var blur: CGFloat
    var anchor: UnitPoint
    func body(content: Content) -> some View {
        content.opacity(opacity).scaleEffect(scale, anchor: anchor).blur(radius: blur)
    }
}

struct NoteView: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore
    weak var windowController: NoteWindowController?
    @ObservedObject var bridge: EditorBridge

    @State private var content: String = ""
    @State private var editorHeight: CGFloat = 56
    @State private var isColorPickerOpen = false
    private var note: Note? { store.note(id: noteID) }
    private var noteColor: NoteColor { note?.noteColor ?? .default }

    private var colorBinding: Binding<NoteColor> {
        Binding(
            get: { store.note(id: noteID)?.noteColor ?? .default },
            set: { store.update(id: noteID, color: $0) }
        )
    }

    var body: some View {
        ZStack {
            // Glass background
            Color.clear
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))

            // Dark tint to deepen the glass
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.08))
                .allowsHitTesting(false)

            // Soften the glassEffect border stroke
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(Color.black.opacity(0.35), lineWidth: 1)
                .allowsHitTesting(false)

            // Color tint overlay
            if noteColor != .default {
                RoundedRectangle(cornerRadius: 24)
                    .fill(noteColor.tintColor.opacity(0.05))
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.25), value: noteColor)
            }

            // Main content column
            GeometryReader { geo in
                VStack(spacing: 0) {
                    HStack(alignment: .center) {
                        Spacer().frame(width: 40, height: 1)
                        Spacer()
                        if bridge.isWindowHovered {
                            NoteToolbar(
                                noteID: noteID,
                                store: store,
                                bridge: bridge,
                                windowController: windowController
                            )
                            .transition(.asymmetric(
                                insertion: .modifier(
                                    active:   HoverBlurModifier(opacity: 0, scale: 1, blur: 12, anchor: .trailing),
                                    identity: HoverBlurModifier(opacity: 1, scale: 1, blur: 0,  anchor: .trailing)
                                ),
                                removal: .modifier(
                                    active:   HoverBlurModifier(opacity: 0, scale: 1, blur: 4,  anchor: .trailing),
                                    identity: HoverBlurModifier(opacity: 1, scale: 1, blur: 0,  anchor: .trailing)
                                )
                            ))
                        }
                    }
                    .frame(height: 32)
                    .padding(.top, 8)
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .padding(.bottom, 16)

                    let availableH = max(56, geo.size.height - 56 - 52)
                    let isScrollable = editorHeight > availableH
                    let fadeTop    = isScrollable && bridge.scrollTop > 4
                    let fadeBottom = isScrollable && (bridge.scrollBottom > 4 || bridge.scrollTop < 4)
                    let fadeH: CGFloat = 52
                    TiptapEditor(text: $content, editorHeight: $editorHeight, bridge: bridge)
                        .frame(height: min(editorHeight, availableH))
                        .mask(alignment: .top) {
                            VStack(spacing: 0) {
                                LinearGradient(
                                    colors: [fadeTop ? .clear : .black, .black],
                                    startPoint: .top, endPoint: .bottom
                                )
                                .frame(height: fadeH)
                                Color.black
                                LinearGradient(
                                    colors: [.black, fadeBottom ? .clear : .black],
                                    startPoint: .top, endPoint: .bottom
                                )
                                .frame(height: fadeH)
                            }
                            .animation(.easeInOut(duration: 0.2), value: fadeTop)
                            .animation(.easeInOut(duration: 0.2), value: fadeBottom)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 52)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(.all, edges: .top)
            }

            // Dismiss color picker on outside click
            if isColorPickerOpen {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            isColorPickerOpen = false
                        }
                    }
                    .ignoresSafeArea()
            }

            // Character count + color picker pinned to bottom
            VStack(spacing: 0) {
                Spacer()
                HStack(alignment: .center) {
                    Text("\(bridge.visibleCharCount) characters")
                        .font(.system(size: 13))
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                    Spacer()
                    if bridge.isWindowHovered {
                        NoteColorPicker(selectedColor: colorBinding, isExpanded: $isColorPickerOpen)
                            .transition(.asymmetric(
                                insertion: .modifier(
                                    active:   HoverBlurModifier(opacity: 0, scale: 1, blur: 12, anchor: .bottomTrailing),
                                    identity: HoverBlurModifier(opacity: 1, scale: 1, blur: 0,  anchor: .bottomTrailing)
                                ),
                                removal: .modifier(
                                    active:   HoverBlurModifier(opacity: 0, scale: 1, blur: 4,  anchor: .bottomTrailing),
                                    identity: HoverBlurModifier(opacity: 1, scale: 1, blur: 0,  anchor: .bottomTrailing)
                                )
                            ))
                    }
                }
                .frame(height: 36)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        // Note title (shown when not hovered and no selection)
        .overlay(alignment: .top) {
            if !bridge.isWindowHovered && !bridge.state.visible {
                Text(note?.title ?? "New Note")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 56)
                    .padding(.top, 16)
                    .transition(.opacity)
            }
        }
        .environment(\.controlActiveState, .active)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: bridge.isWindowHovered)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isColorPickerOpen)
        .onAppear {
            content = store.note(id: noteID)?.content ?? ""
            bridge.setAccentColor(noteColor.cssAccent)
        }
        .onChange(of: content) { _, newValue in
            store.update(id: noteID, content: newValue)
        }
        .onChange(of: editorHeight) { _, newH in
            windowController?.resizeToFit(editorHeight: newH)
        }
        .onChange(of: noteColor) { _, newColor in
            bridge.setAccentColor(newColor.cssAccent)
        }
        .onChange(of: bridge.isWindowHovered) { _, hovered in
            if !hovered { isColorPickerOpen = false }
        }
        .ignoresSafeArea()
    }
}
