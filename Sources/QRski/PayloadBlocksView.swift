import SwiftUI
import AppKit
import QRskiCore

struct PayloadBlocksView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Content", systemImage: "text.cursor")
                .font(.headline)

            ForEach(appState.blocks) { block in
                BlockRowView(
                    block: Binding(
                        get: {
                            appState.blocks.first(where: { $0.id == block.id }) ?? block
                        },
                        set: {
                            guard let i = appState.blocks.firstIndex(where: { $0.id == block.id }) else { return }
                            appState.blocks[i] = $0
                        }
                    ),
                    isFirst: appState.blocks.first?.id == block.id,
                    isLast: appState.blocks.last?.id == block.id,
                    onDelete: {
                        appState.blocks.removeAll { $0.id == block.id }
                        if appState.blocks.isEmpty { appState.blocks.append(PayloadBlock()) }
                    },
                    moveUp: {
                        guard let i = appState.blocks.firstIndex(where: { $0.id == block.id }), i > 0 else { return }
                        appState.blocks.swapAt(i, i - 1)
                    },
                    moveDown: {
                        guard let i = appState.blocks.firstIndex(where: { $0.id == block.id }), i < appState.blocks.count - 1 else { return }
                        appState.blocks.swapAt(i, i + 1)
                    }
                )
            }

            Button {
                appState.blocks.append(PayloadBlock())
            } label: {
                Label("Add Block", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if appState.blocks.count > 1 && !appState.inputText.isEmpty {
                resultRow
            }
        }
    }

    private var resultRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Result")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(appState.inputText, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Copy assembled payload")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(appState.inputText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 6)
            }
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
            .padding(.vertical, 6)
            .background(Color(NSColor.textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: -

private struct BlockRowView: View {
    @Binding var block: PayloadBlock
    let isFirst: Bool
    let isLast: Bool
    let onDelete: () -> Void
    let moveUp: () -> Void
    let moveDown: () -> Void

    @State private var textFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                TextField("Label (optional)", text: $block.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textFieldStyle(.plain)

                Spacer()

                Button(action: moveUp) {
                    Image(systemName: "chevron.up")
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isFirst)
                .foregroundStyle(isFirst ? Color.secondary.opacity(0.3) : .secondary)
                .font(.caption)

                Button(action: moveDown) {
                    Image(systemName: "chevron.down")
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isLast)
                .foregroundStyle(isLast ? Color.secondary.opacity(0.3) : .secondary)
                .font(.caption)

                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .padding(4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
            }

            TabSensitiveTextEditor(text: $block.text, isFocused: $textFocused)
                .frame(minHeight: 50, maxHeight: 100)
                .background(Color(NSColor.textBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(
                            textFocused ? Color.accentColor : Color.secondary.opacity(0.3),
                            lineWidth: textFocused ? 2 : 1
                        )
                )
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Tab-intercepting text editor

private struct TabSensitiveTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let textView = TabInterceptingTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text { textView.string = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TabSensitiveTextEditor
        init(_ parent: TabSensitiveTextEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }
        func textDidBeginEditing(_ notification: Notification) { parent.isFocused = true }
        func textDidEndEditing(_ notification: Notification) { parent.isFocused = false }
    }
}

private final class TabInterceptingTextView: NSTextView {
    override func insertTab(_ sender: Any?) { window?.selectNextKeyView(self) }
    override func insertBacktab(_ sender: Any?) { window?.selectPreviousKeyView(self) }
}
