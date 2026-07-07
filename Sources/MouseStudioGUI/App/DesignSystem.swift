#if canImport(SwiftUI)
import SwiftUI
import MouseStudioShared

/// Shared visual language: colors, gradients, and reusable modern components so
/// the whole app looks consistent.
enum Theme {
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.36, green: 0.34, blue: 0.90), Color(red: 0.60, green: 0.30, blue: 0.90)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let cardCorner: CGFloat = 14
    static let controlCorner: CGFloat = 9
}

/// A rounded, material-backed card container.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: Theme.cardCorner))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner)
                    .strokeBorder(Color.primary.opacity(0.06))
            )
    }
}

/// A small colored pill used for gestures / tags.
struct Pill: View {
    let text: String
    var color: Color = .accentColor
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

/// A large screen header with title + optional trailing content.
struct ScreenHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var trailing: Trailing

    init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.largeTitle.bold())
                if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
            }
            Spacer()
            trailing
        }
    }
}

extension ButtonID {
    /// A friendly label for the UI.
    var friendlyName: String {
        switch self {
        case .left: return "Left Click"
        case .right: return "Right Click"
        case .middle: return "Middle Click"
        case .button4: return "Side Back (Button 4)"
        case .button5: return "Side Forward (Button 5)"
        }
    }
    var shortName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        case .middle: return "Middle"
        case .button4: return "Button 4"
        case .button5: return "Button 5"
        }
    }
    var symbol: String {
        switch self {
        case .left, .right, .middle: return "computermouse"
        case .button4: return "arrow.left.circle"
        case .button5: return "arrow.right.circle"
        }
    }
}

extension GestureKind {
    var friendlyName: String {
        switch self {
        case .single: return "Single Click"
        case .double: return "Double Click"
        case .long: return "Long Press"
        case .chordClick: return "Hold + Click"
        case .chordScrollUp: return "Hold + Scroll Up"
        case .chordScrollDown: return "Hold + Scroll Down"
        }
    }
}
#endif
