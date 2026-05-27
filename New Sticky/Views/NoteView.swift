import SwiftUI
import AppKit

struct NoteView: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore
    weak var windowController: NoteWindowController?
    @ObservedObject var bridge: EditorBridge

    @State private var content: String = ""
    @State private var editorHeight: CGFloat = 56

    private var note: Note? { store.note(id: noteID) }

    var body: some View {
        ZStack {
            Color.clear
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))

            // Main content column
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

                TiptapEditor(text: $content, editorHeight: $editorHeight, bridge: bridge)
                    .frame(height: editorHeight)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 34)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(.all, edges: .top)

            // Character count pinned to bottom
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    Text("\(content.count) characters")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.leading, 16)
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
        .onAppear {
            content = store.note(id: noteID)?.content ?? ""
        }
        .onChange(of: content) { _, newValue in
            store.update(id: noteID, content: newValue)
        }
        .onChange(of: editorHeight) { _, newH in
            windowController?.resizeToFit(editorHeight: newH)
        }
        .ignoresSafeArea()
    }
}
