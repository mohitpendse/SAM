//
//  ASMDesignSystem.swift
//  ASM
//

import SwiftUI

extension Color {
    static let asmInk = Color.white.opacity(0.92)
    static let asmMutedInk = Color.white.opacity(0.48)
    static let asmCanvas = Color(red: 0.055, green: 0.055, blue: 0.06)
    static let asmMist = Color.white.opacity(0.07)
    static let asmLine = Color.white.opacity(0.12)
    static let asmAccent = Color(red: 0.18, green: 0.48, blue: 1.0)
    static let asmTeal = Color(red: 0.18, green: 0.78, blue: 0.48)
    static let asmIndigo = Color(red: 0.48, green: 0.26, blue: 0.95)
    static let asmGold = Color(red: 1.0, green: 0.58, blue: 0.12)
    static let asmRose = Color(red: 1.0, green: 0.22, blue: 0.30)
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? Color.asmInk.opacity(0.86) : Color.asmInk, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.asmInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(configuration.isPressed ? Color.asmMist : Color.asmCanvas, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.asmLine))
    }
}

struct RailIconStyle: ButtonStyle {
    var selected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(selected ? .white : Color.asmInk.opacity(0.85))
            .frame(width: 40, height: 40)
            .background(
                selected ? Color.asmInk : (configuration.isPressed ? Color.asmMist : Color.clear),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
    }
}

struct IconControlStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.asmInk)
            .frame(width: 36, height: 36)
            .background(configuration.isPressed ? Color.asmMist.opacity(0.7) : Color.asmMist, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

struct CardSurface: ViewModifier {
    var fill: Color = .white
    var border: Color = .asmLine
    var shadow: Bool = false
    var radius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(border))
            .shadow(color: shadow ? .black.opacity(0.08) : .clear, radius: 18, y: 8)
    }
}

extension View {
    func asmCard(fill: Color = .white, border: Color = .asmLine, shadow: Bool = false, radius: CGFloat = 12) -> some View {
        modifier(CardSurface(fill: fill, border: border, shadow: shadow, radius: radius))
    }
}

struct ChoiceChip: View {
    let text: String
    let isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
                Text(text)
                    .lineLimit(1)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(isSelected ? .white : Color.asmInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isSelected ? Color.asmInk : .white, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.asmLine))
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 700
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct DotGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 28
        var y = rect.minY + 8
        while y <= rect.maxY {
            var x = rect.minX + 8
            while x <= rect.maxX {
                path.addEllipse(in: CGRect(x: x, y: y, width: 1.5, height: 1.5))
                x += spacing
            }
            y += spacing
        }
        return path
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.asmInk)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.asmMutedInk)
            }
        }
    }
}

struct FloatingRailBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .fixedSize()
            .background(Color.asmCanvas.opacity(0.96), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.asmLine))
            .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
    }
}

extension View {
    func floatingRail() -> some View {
        modifier(FloatingRailBackground())
    }
}
