import SwiftUI
import Down
import Splash
import AppKit // Needed for NSFont

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
    private let highlighter: Splash.SyntaxHighlighter<AttributedStringOutputFormat>

    init() {
        let font = Splash.Font(size: 14)
        let theme = Theme.midnight(withFont: font)
        let format = AttributedStringOutputFormat(theme: theme)
        self.highlighter = Splash.SyntaxHighlighter(format: format)
    }
    
    func highlight(_ code: String, language: String) -> AttributedString {
        let highlighted = highlighter.highlight(code)
        return AttributedString(highlighted)
    }
}

struct MarkdownText: View {
    let content: String
    @State private var attributedContent: AttributedString?
    
    var body: some View {
        Group {
            if let attributed = attributedContent {
                Text(attributed)
                    .font(MarkdownStyle.body)
                    .foregroundColor(MarkdownStyle.bodyColor)
            } else {
                Text(content)
                    .font(MarkdownStyle.body)
                    .foregroundColor(MarkdownStyle.bodyColor)
            }
        }
        .onAppear {
            attributedContent = MarkdownRenderer.shared.render(content)
        }
    }
}

struct CodeBlock: View {
    let content: String
    let language: String
    @State private var highlightedContent: AttributedString?
    
    var body: some View {
        Group {
            if let highlighted = highlightedContent {
                Text(highlighted)
                    .font(MarkdownStyle.code)
            } else {
                Text(content)
                    .font(MarkdownStyle.code)
                    .foregroundColor(MarkdownStyle.codeColor)
            }
        }
        .onAppear {
            highlightedContent = AppSyntaxHighlighter.shared.highlight(content, language: language)
        }
    }
} 