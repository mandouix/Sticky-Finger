import SwiftUI
import AppKit

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
                                windowController: windowController
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .trailing)))
                        }
                    }
                    .frame(height: 32)
                    .padding(.top, 8)
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .padding(.bottom, 16)

                    let availableH = max(56, geo.size.height - 56 - 48)
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
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(.all, edges: .top)
            }

            // Character count + color picker pinned to bottom
            VStack(spacing: 0) {
                Spacer()
                HStack(alignment: .center) {
                    Text("\(content.count) characters")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    if bridge.isWindowHovered {
                        NoteColorPicker(selectedColor: colorBinding, isExpanded: $isColorPickerOpen)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
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
        .animation(.easeInOut(duration: 0.15), value: bridge.isWindowHovered)
        .animation(.easeInOut(duration: 0.15), value: isColorPickerOpen)
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
