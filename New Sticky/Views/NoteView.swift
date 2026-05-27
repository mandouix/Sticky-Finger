import SwiftUI
import AppKit

struct NoteView: View {
    let noteID: UUID
    @ObservedObject var store: NoteStore
    weak var windowController: NoteWindowController?

    @State private var content: String = ""
    @State private var isHovered = false
    @State private var editorHeight: CGFloat = 56

    private var note: Note? { store.note(id: noteID) }

    var body: some View {
        ZStack {
            Color.clear
                .glassEffect(.regular, in: Rectangle())

            // Main content column
            VStack(spacing: 0) {
                // Toolbar row — 32pt high, top flush with window top so button
                // centers sit at y=16pt, matching the repositioned traffic lights.
                HStack(alignment: .center) {
                    // Reserve 76pt for traffic lights (left edge at 16pt + 3×12pt buttons + gaps)
                    Spacer().frame(width: 76, height: 1)
                    Spacer()
                    if isHovered {
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

                // Tiptap editor — grows with content; 30pt bottom pad reserves
                // space so the fixed char-count footer never overlaps content.
                TiptapEditor(text: $content, editorHeight: $editorHeight)
                    .frame(height: editorHeight)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
            }
            .ignoresSafeArea(.all, edges: .top)

            // Character count — always pinned 16pt from left and bottom.
            VStack(spacing: 0) {
                Spacer()
                HStack {
                    Text("\(content.count) characters")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.leading, 16)
                .padding(.bottom, 16)
            }
        }
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovered
            }
        }
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
