//
//  CanvasChromeViews.swift
//  ASM
//

import SwiftUI

struct BinderRailView: View {
    @EnvironmentObject private var store: ASMStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "hexagon.fill")
                    .foregroundStyle(Color.asmAccent)
                Text("ASM")
                    .font(.system(size: 15, weight: .bold))
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Text(store.selectedNotebook?.title ?? "Notebook")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.asmMutedInk)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(store.selectedNotebook?.binders ?? []) { binder in
                        BinderSection(binder: binder)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                Button {
                    store.addInkPage()
                } label: {
                    Label("Canvas", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    store.addBinder()
                } label: {
                    Label("Binder", systemImage: "rectangle.stack.badge.plus")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    store.phase = .onboarding
                } label: {
                    Label("Profile", systemImage: "person.crop.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(12)
        }
        .frame(width: 176)
        .background(Color.asmCanvas.opacity(0.98))
        .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.asmLine), alignment: .trailing)
    }
}

private struct BinderSection: View {
    @EnvironmentObject private var store: ASMStore
    let binder: Binder

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                store.selectBinder(binder.id)
            } label: {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(binder.color)
                        .frame(width: 8, height: 18)
                    Text(binder.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.asmInk)
                    Spacer()
                }
                .padding(8)
                .background(
                    store.selectedBinderID == binder.id ? Color.asmMist : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
            }
            .buttonStyle(.plain)

            ForEach(binder.pageIDs, id: \.self) { pageID in
                if let page = store.items.first(where: { $0.id == pageID }) {
                    Button {
                        store.selectItem(page.id)
                        store.selectBinder(binder.id)
                    } label: {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 11))
                            Text(page.title)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                        }
                        .foregroundStyle(store.selectedItemID == page.id ? Color.asmAccent : Color.asmMutedInk)
                        .padding(.leading, 18)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct PenStylePopover: View {
    @EnvironmentObject private var store: ASMStore
    let tool: CanvasTool

    private let colors: [Color] = [.asmInk, .asmAccent, .asmRose, .asmTeal, .asmGold, .black]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Button {
                    if tool == .highlighter {
                        store.highlighterStyle.color = color.opacity(0.45)
                        store.penStyle = store.highlighterStyle
                    } else {
                        store.penStyle.color = color
                    }
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.asmLine))
                }
                .buttonStyle(.plain)
            }

            Slider(
                value: Binding(
                    get: { tool == .highlighter ? store.highlighterStyle.width : store.penStyle.width },
                    set: { value in
                        if tool == .highlighter {
                            store.highlighterStyle.width = value
                            store.penStyle = store.highlighterStyle
                        } else {
                            store.penStyle.width = value
                        }
                    }
                ),
                in: tool == .highlighter ? 8...24 : 1...8
            )
            .frame(width: 76)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .floatingRail()
    }
}

struct ToolRailView: View {
    @EnvironmentObject private var store: ASMStore
    @State private var styleTool: CanvasTool?

    var body: some View {
        VStack(spacing: 5) {
            ForEach(CanvasTool.allCases) { tool in
                HStack(spacing: 8) {
                    if styleTool == tool {
                        PenStylePopover(tool: tool)
                            .fixedSize()
                            .transition(.scale(scale: 0.92, anchor: .trailing).combined(with: .opacity))
                    }

                    Button {
                        store.setTool(tool)
                        if tool != .pen && tool != .highlighter {
                            styleTool = nil
                        }
                    } label: {
                        Image(systemName: tool.icon)
                    }
                    .buttonStyle(RailIconStyle(selected: store.activeTool == tool))
                    .highPriorityGesture(
                        TapGesture(count: 2)
                            .onEnded {
                                guard tool == .pen || tool == .highlighter else { return }
                                store.setTool(tool)
                                styleTool = styleTool == tool ? nil : tool
                            }
                    )
                    .help(tool.title)
                }
            }

            Divider()
                .frame(width: 22)
                .padding(.vertical, 4)

            Button {
                store.showWidgetPicker.toggle()
                if store.showWidgetPicker {
                    store.showGeminiPanel = false
                }
            } label: {
                Image(systemName: "square.grid.2x2")
            }
            .buttonStyle(RailIconStyle(selected: store.showWidgetPicker))
            .help("Widgets")

            Button {
                store.showPDFImporter = true
            } label: {
                Image(systemName: "doc.badge.plus")
            }
            .buttonStyle(RailIconStyle())
            .help("Import PDF")

            Button {
                store.showGeminiPanel.toggle()
                if store.showGeminiPanel {
                    store.showWidgetPicker = false
                }
            } label: {
                Image(systemName: "sparkles")
            }
            .buttonStyle(RailIconStyle(selected: store.showGeminiPanel))
            .help("AI Tutor")
        }
        .padding(8)
        .background(Color.asmCanvas.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.asmLine))
        .shadow(color: .black.opacity(0.10), radius: 16, y: 6)
        .animation(.easeOut(duration: 0.16), value: styleTool)
    }
}

struct WidgetCatalogSidebar: View {
    @EnvironmentObject private var store: ASMStore
    @State private var query = ""

    private var filteredKinds: [WidgetKind] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return WidgetKind.allCases }
        return WidgetKind.allCases.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) || $0.blurb.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.asmMutedInk)
                    TextField("Search widgets", text: $query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.asmLine))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(filteredKinds) { kind in
                            Button {
                                store.selectedWidgetKind = kind
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: kind.icon)
                                        .font(.system(size: 15, weight: .semibold))
                                        .frame(width: 18)
                                    Text(kind.title)
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                }
                                .foregroundStyle(Color.asmInk)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                                .background(
                                    store.selectedWidgetKind == kind ? Color.white : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(12)
            .frame(width: 210)
            .background(Color.asmMist.opacity(0.55))

            VStack(spacing: 18) {
                Spacer(minLength: 12)
                Image(systemName: store.selectedWidgetKind.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.asmInk)
                Text(store.selectedWidgetKind.title)
                    .font(.system(size: 22, weight: .bold))
                Text(store.selectedWidgetKind.blurb)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.asmMutedInk)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)

                WidgetCatalogPreview(kind: store.selectedWidgetKind)
                    .frame(maxWidth: 300, maxHeight: 210)

                Spacer(minLength: 8)

                Button {
                    store.spawnWidget(store.selectedWidgetKind)
                } label: {
                    Label("Add widget", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Color.asmInk, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 22)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.asmLine))
        .shadow(color: .black.opacity(0.10), radius: 24, y: 10)
        .frame(width: 620, height: 520)
    }
}

private struct WidgetCatalogPreview: View {
    let kind: WidgetKind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.asmInk.opacity(0.85), lineWidth: 3))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)

            Group {
                switch kind {
                case .document:
                    VStack(alignment: .leading, spacing: 8) {
                        Capsule().fill(Color.asmRose.opacity(0.45)).frame(width: 72, height: 6)
                        ForEach(0..<6, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.asmInk.opacity(0.08))
                                .frame(height: 8)
                        }
                    }
                    .padding(20)
                case .calculator:
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8).fill(Color.asmMist).frame(height: 36)
                        ForEach(0..<3, id: \.self) { _ in
                            HStack {
                                ForEach(0..<4, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 8).fill(Color.asmMist).frame(height: 28)
                                }
                            }
                        }
                    }
                    .padding(20)
                case .pomodoro:
                    VStack(spacing: 10) {
                        Text("25:00")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Capsule().fill(Color.asmInk).frame(width: 88, height: 10)
                    }
                case .youtube:
                    ZStack {
                        RoundedRectangle(cornerRadius: 8).fill(Color.asmMist)
                        Image(systemName: "play.fill").font(.title).foregroundStyle(Color.asmInk.opacity(0.35))
                    }
                    .padding(24)
                default:
                    VStack(spacing: 10) {
                        Image(systemName: kind.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(Color.asmMutedInk)
                        RoundedRectangle(cornerRadius: 6).fill(Color.asmMist).frame(height: 10)
                        RoundedRectangle(cornerRadius: 6).fill(Color.asmMist).frame(width: 120, height: 10)
                    }
                    .padding(24)
                }
            }
        }
        .padding(.horizontal, 28)
    }
}

struct AILassoBar: View {
    @EnvironmentObject private var store: ASMStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.selection.label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.asmMutedInk)
                .lineLimit(1)

            HStack(spacing: 6) {
                ForEach(TutorAction.allCases) { action in
                    Button {
                        store.selectedAction = action
                        store.runSelectedAction()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: action.icon)
                                .font(.system(size: 14, weight: .semibold))
                            Text(action.rawValue)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(store.selectedAction == action ? .white : Color.asmInk)
                        .frame(width: 54, height: 48)
                        .background(
                            store.selectedAction == action ? Color.asmInk : Color.asmMist,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .floatingRail()
    }
}

struct MiniMapView: View {
    @EnvironmentObject private var store: ASMStore

    private let world = ASMStore.worldSize

    var body: some View {
        GeometryReader { geo in
            let scaleX = geo.size.width / world.width
            let scaleY = geo.size.height / world.height
            let scale = min(scaleX, scaleY)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.asmLine)

                ForEach(store.items) { item in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(item.kind == .widget ? Color.asmAccent.opacity(0.45) : Color.asmInk.opacity(0.25))
                        .frame(width: max(4, item.width * scale), height: max(4, item.height * scale))
                        .offset(x: item.x * scale, y: item.y * scale)
                }
            }
        }
        .frame(width: 128, height: 88)
        .floatingRail()
    }
}

struct ProfileBadgeView: View {
    @EnvironmentObject private var store: ASMStore

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.wave.2")
                .foregroundStyle(Color.asmAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.profile.name.isEmpty ? "Student" : store.profile.name)
                    .font(.system(size: 12, weight: .bold))
                Text("\(store.profile.explanationDepth) · \(Int(store.profile.studyBlock))m · \(store.profile.friction)")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.asmMutedInk)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .floatingRail()
    }
}

struct GeminiSlideOver: View {
    @EnvironmentObject private var store: ASMStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ASM Tutor")
                        .font(.system(size: 16, weight: .bold))
                    Text(store.selection.label)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.asmMutedInk)
                }
                Spacer()
                Button {
                    store.showGeminiPanel = false
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(IconControlStyle())
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(store.tutorMessages) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.role)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(message.role == "You" ? Color.asmAccent : Color.asmTeal)
                            Text(message.body)
                                .font(.system(size: 13))
                            if let citation = message.citation {
                                Text(citation)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.asmMutedInk)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(message.role == "You" ? Color.asmMist : Color.white, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.asmLine))
                    }
                }
            }

            TextField("Ask about the selection…", text: $store.currentPrompt)
                .textFieldStyle(.plain)
                .padding(10)
                .background(Color.asmMist, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button {
                store.runSelectedAction()
            } label: {
                Label(store.selectedAction.rawValue, systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(14)
        .frame(width: 320)
        .frame(maxHeight: .infinity)
        .background(.white)
        .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.asmLine), alignment: .leading)
        .shadow(color: .black.opacity(0.08), radius: 20, x: -4)
    }
}
