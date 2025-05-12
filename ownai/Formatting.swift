import SwiftUI
import Down
import Splash
import AppKit // Needed for NSFont

// Remove the global Paragraph Style, it will be created dynamically
// let improvedParagraphStyle: NSParagraphStyle = ...

struct MarkdownStyle {
    static let heading1 = Font.system(size: 24, weight: .bold)
    static let heading2 = Font.system(size: 20, weight: .bold)
    static let heading3 = Font.system(size: 18, weight: .bold)
    static let body = Font.system(size: 16)
    static let code = Font.system(.body, design: .monospaced)
    static let blockquote = Font.system(size: 16, weight: .medium)
    
    static let headingColor = Color.primary
    static let bodyColor = Color.primary.opacity(0.9)
    static let linkColor = Color.accentColor
    static let codeColor = Color(NSColor.systemGreen)
    static let blockquoteColor = Color.secondary
}

class MarkdownRenderer {
    static let shared = MarkdownRenderer()
    
    func render(_ markdown: String) -> AttributedString {
        do {
            let html = try Down(markdownString: markdown).toHTML()
            let data = Data(html.utf8)
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            let attributedString = try NSAttributedString(data: data, options: options, documentAttributes: nil)
            return AttributedString(attributedString)
        } catch {
            return AttributedString(markdown)
        }
    }
}

class AppSyntaxHighlighter {
    static let shared = AppSyntaxHighlighter()
    // Note: Highlighter itself doesn't store font size;
    // it's applied when generating the AttributedString or by the Text view.
    // We will adjust the CodeBlock view to use the AppStorage font size.
    private func createHighlighter(fontSize: CGFloat) -> Splash.SyntaxHighlighter<AttributedStringOutputFormat> {
        let font = Splash.Font(size: fontSize)
        let theme = Theme.midnight(withFont: font)
        let format = AttributedStringOutputFormat(theme: theme)
        return Splash.SyntaxHighlighter(format: format)
    }
    
    func highlight(_ code: String, language: String, fontSize: CGFloat) -> AttributedString {
        let highlighter = createHighlighter(fontSize: fontSize)
        let highlightedNSAttributedString = highlighter.highlight(code)
        return AttributedString(highlightedNSAttributedString)
    }
}

struct MarkdownText: View {
    let content: String
    @State private var attributedContent: AttributedString?
    
    // Read settings from AppStorage
    @AppStorage("chatFontSize") private var chatFontSize: Double = Double(NSFont.systemFontSize(for: .regular))
    @AppStorage("chatLineSpacing") private var chatLineSpacing: Double = 4.0
    @AppStorage("chatParagraphSpacing") private var chatParagraphSpacing: Double = 8.0

    var body: some View {
        Group {
            if let attributed = attributedContent {
                Text(attributed)
                    .foregroundColor(MarkdownStyle.bodyColor)
            } else {
                Text(content)
                    .font(.system(size: CGFloat(chatFontSize)))
                    .foregroundColor(MarkdownStyle.bodyColor)
            }
        }
        .onAppear { generateAttributedContent() }
        .onChange(of: chatFontSize) { _, _ in generateAttributedContent() }
        .onChange(of: chatLineSpacing) { _, _ in generateAttributedContent() }
        .onChange(of: chatParagraphSpacing) { _, _ in generateAttributedContent() }
    }
    
    private func generateAttributedContent() {
        let rawAttributedString = MarkdownRenderer.shared.render(content)
        let nsAttributedString = NSAttributedString(rawAttributedString)
        let mutableAttributedString = NSMutableAttributedString(attributedString: nsAttributedString)
        
        let standardFont = NSFont.systemFont(ofSize: CGFloat(chatFontSize))
        let fullRange = NSRange(location: 0, length: mutableAttributedString.length)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = CGFloat(chatLineSpacing)
        paragraphStyle.paragraphSpacing = CGFloat(chatParagraphSpacing)

        mutableAttributedString.removeAttribute(NSAttributedString.Key.font, range: fullRange)
        mutableAttributedString.removeAttribute(NSAttributedString.Key.paragraphStyle, range: fullRange)
        
        mutableAttributedString.addAttribute(NSAttributedString.Key.font, value: standardFont, range: fullRange)
        mutableAttributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        attributedContent = AttributedString(mutableAttributedString)
    }
}

struct CodeBlock: View {
    let content: String
    let language: String
    @State private var highlightedContent: AttributedString?
    
    // Read settings from AppStorage
    @AppStorage("chatFontSize") private var chatFontSize: Double = Double(NSFont.systemFontSize(for: .regular))
    @AppStorage("chatLineSpacing") private var chatLineSpacing: Double = 4.0
    @AppStorage("chatParagraphSpacing") private var chatParagraphSpacing: Double = 8.0

    var body: some View {
        Group {
            if let highlighted = highlightedContent {
                Text(highlighted)
                    // Font applied directly to Text for monospaced
                    .font(.system(size: CGFloat(chatFontSize), design: .monospaced))
                    // Line spacing is now part of the AttributedString
            } else {
                // Fallback for non-highlighted content
                Text(content)
                    .font(.system(size: CGFloat(chatFontSize), design: .monospaced))
                    .lineSpacing(CGFloat(chatLineSpacing)) // Apply directly here if not attributed
                    .foregroundColor(MarkdownStyle.codeColor)
            }
        }
        .onAppear { generateHighlightedContent() }
        .onChange(of: chatFontSize) { _, _ in generateHighlightedContent() }
        .onChange(of: chatLineSpacing) { _, _ in generateHighlightedContent() } // Regenerate on spacing change
        .onChange(of: chatParagraphSpacing) { _, _ in generateHighlightedContent() } // Regenerate on spacing change
    }
    
    private func generateHighlightedContent() {
        // Get the highlighted string (which includes colors but base font)
        let highlightedString = AppSyntaxHighlighter.shared.highlight(content, language: language, fontSize: CGFloat(chatFontSize))
        
        // Convert to NSAttributedString to apply paragraph style
        let nsAttributedString = NSAttributedString(highlightedString)
        let mutableAttributedString = NSMutableAttributedString(attributedString: nsAttributedString)
        let fullRange = NSRange(location: 0, length: mutableAttributedString.length)

        // Create paragraph style dynamically
        let paragraphStyle = NSMutableParagraphStyle()
        // For code, only line spacing usually makes sense, paragraph spacing can look odd.
        // Let's apply only line spacing for now, but keep the variable read.
        paragraphStyle.lineSpacing = CGFloat(chatLineSpacing)
        // paragraphStyle.paragraphSpacing = CGFloat(chatParagraphSpacing) // Maybe omit for code?
        
        // Remove potentially conflicting paragraph styles from highlighter
        mutableAttributedString.removeAttribute(NSAttributedString.Key.paragraphStyle, range: fullRange)
        // Apply the desired paragraph style
        mutableAttributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        // Update the state
        highlightedContent = AttributedString(mutableAttributedString)
    }
} 