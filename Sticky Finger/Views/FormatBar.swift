import SwiftUI

struct FormatBar: View {
    @ObservedObject var bridge: EditorBridge
    @State private var hovered: Int? = nil

    var body: some View {
        HStack(spacing: 2) {
            formatButton(index: 0, icon: "character.cursor.ibeam") {
                Button { bridge.toggleBold() }      label: { Label("Bold",          systemImage: "bold") }
                Button { bridge.toggleItalic() }    label: { Label("Italic",        systemImage: "italic") }
                Button { bridge.toggleUnderline() } label: { Label("Underline",     systemImage: "underline") }
                Button { bridge.toggleStrike() }    label: { Label("Strikethrough", systemImage: "strikethrough") }
            }

            formatButton(index: 1, icon: "textformat.size") {
                Button { bridge.setHeading(0) } label: { Text("Paragraph") }
                Button { bridge.setHeading(1) } label: { Text("Heading 1") }
                Button { bridge.setHeading(2) } label: { Text("Heading 2") }
                Button { bridge.setHeading(3) } label: { Text("Heading 3") }
            }

            formatButton(index: 2, icon: "list.bullet") {
                Button { bridge.toggleBullet() }  label: { Label("Bullet List",   systemImage: "list.bullet") }
                Button { bridge.toggleOrdered() } label: { Label("Numbered List", systemImage: "list.number") }
                Button { bridge.toggleTask() }    label: { Label("Task List",     systemImage: "checklist") }
            }

            formatButton(index: 3, icon: "chevron.left.forwardslash.chevron.right") {
                Button { bridge.toggleCode() }        label: { Label("Inline Code", systemImage: "curlybraces") }
                Button { bridge.toggleCodeBlock() }   label: { Label("Code Block",  systemImage: "terminal") }
                Button { bridge.toggleBlockquote() }  label: { Label("Blockquote",  systemImage: "text.quote") }
            }
        }
        .padding(2)
        .glassEffect(.regular, in: Capsule())
        .overlay(Capsule().fill(Color.black.opacity(0.18)).allowsHitTesting(false))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private func formatButton<Content: View>(
        index: Int,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu(content: content) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 32, height: 32)
        .background(Circle().fill(hovered == index ? Color.primary.opacity(0.1) : Color.clear).frame(width: 28, height: 28))
        .clipShape(Circle())
        .onHover { inside in
            withAnimation(.easeOut(duration: 0.12)) {
                hovered = inside ? index : nil
            }
            if inside { NSCursor.pointingHand.push() }
            else { NSCursor.pop() }
        }
    }
}
