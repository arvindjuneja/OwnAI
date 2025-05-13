import SwiftUI
import AppKit // For NSViewRepresentable components like NSTextView and NSVisualEffectView

// MARK: - CustomTextEditor for Enter/Shift+Enter
struct CustomTextEditor: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void
    
    // Read font size setting
    @AppStorage("chatFontSize") private var chatFontSize: Double = Double(NSFont.systemFontSize(for: .regular))

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        // Apply user font size
        textView.font = NSFont.systemFont(ofSize: CGFloat(chatFontSize))
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.delegate = context.coordinator
        textView.allowsUndo = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.lineFragmentPadding = 0
        return textView
    }
    func updateNSView(_ nsView: NSTextView, context: Context) {
        let currentSize = nsView.font?.pointSize ?? NSFont.systemFontSize(for: .regular)
        let newSize = CGFloat(chatFontSize)
        
        // Update text if different
        if nsView.string != text {
            nsView.string = text
        }
        // Update font size if different
        if abs(currentSize - newSize) > 0.1 {
             nsView.font = NSFont.systemFont(ofSize: newSize)
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CustomTextEditor
        init(_ parent: CustomTextEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                parent.text = textView.string
            }
        }
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if NSEvent.modifierFlags.contains(.shift) {
                    textView.insertNewline(nil)
                } else {
                    parent.onCommit()
                }
                return true
            }
            return false
        }
    }
}

// MARK: - Animated Gradient Border
struct AnimatedGradientBorder: View {
    var cornerRadius: CGFloat
    @State private var animate = false
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        .accentColor, .purple, .blue, .green, .yellow, .orange, .red, .accentColor
                    ]),
                    center: .center,
                    angle: .degrees(animate ? 360 : 0)
                ),
                lineWidth: 2.2
            )
            .opacity(0.7)
            .onAppear {
                withAnimation(Animation.linear(duration: 3.5).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}

// MARK: - VisualEffectBlur for glassmorphism
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
} 