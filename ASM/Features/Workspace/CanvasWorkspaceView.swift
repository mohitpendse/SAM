//
//  CanvasWorkspaceView.swift
//  ASM
//

import SwiftUI
import PencilKit

struct CanvasWorkspaceView: View {
    @EnvironmentObject private var store: ASMStore
    @State private var lassoStart: CGPoint?
    @State private var lassoCurrent: CGPoint?
    @State private var panAccum: CGSize = .zero
    @State private var pinchStart: CGFloat?

    private let worldSize = ASMStore.worldSize

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.asmCanvas

                InfiniteDotGrid(scale: store.canvasScale, offset: store.canvasOffset)

                PencilCanvasPage(
                    drawingData: $store.canvasDrawingData,
                    tool: store.makeInkTool(),
                    isDrawingEnabled: store.activeTool == .pen || store.activeTool == .highlighter || store.activeTool == .eraser,
                    onChange: { store.updateCanvasDrawing(data: $0) }
                )
                .allowsHitTesting(store.activeTool == .pen || store.activeTool == .highlighter || store.activeTool == .eraser)

                canvasLayer
                    .frame(width: worldSize.width, height: worldSize.height)
                    .scaleEffect(store.canvasScale, anchor: .center)
                    .offset(store.canvasOffset)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                if store.activeTool == .lasso, let start = lassoStart, let current = lassoCurrent {
                    lassoOverlay(from: start, to: current)
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .optionalGesture(lassoGesture(in: geo.size), enabled: store.activeTool == .lasso)
            .simultaneousGesture(zoomGesture)
            .onTapGesture {
                if store.activeTool == .hand {
                    store.selectItem(nil)
                }
            }
        }
    }

    private var canvasLayer: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())
                .gesture(backgroundPanGesture)

            ForEach(store.items) { item in
                CanvasItemView(item: item)
                    .frame(width: item.width, height: item.height)
                    .position(x: item.x + item.width / 2, y: item.y + item.height / 2)
                    .zIndex(item.zIndex)
            }
        }
        .frame(width: worldSize.width, height: worldSize.height)
        .coordinateSpace(name: "asmCanvas")
    }

    private var backgroundPanGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard store.activeTool == .hand || store.activeTool == .lasso else { return }
                guard store.activeTool != .lasso else { return }
                let delta = CGSize(
                    width: value.translation.width - panAccum.width,
                    height: value.translation.height - panAccum.height
                )
                panAccum = value.translation
                store.canvasOffset.width += delta.width * store.canvasScale
                store.canvasOffset.height += delta.height * store.canvasScale
            }
            .onEnded { _ in
                panAccum = .zero
            }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if pinchStart == nil { pinchStart = store.canvasScale }
                store.canvasScale = min(2.4, max(0.35, (pinchStart ?? 1) * value))
            }
            .onEnded { _ in
                pinchStart = nil
            }
    }

    private func lassoGesture(in _: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard store.activeTool == .lasso else { return }
                if lassoStart == nil {
                    lassoStart = value.startLocation
                }
                lassoCurrent = value.location
            }
            .onEnded { value in
                guard store.activeTool == .lasso, let start = lassoStart else { return }
                let rect = CGRect(
                    x: min(start.x, value.location.x),
                    y: min(start.y, value.location.y),
                    width: abs(value.location.x - start.x),
                    height: abs(value.location.y - start.y)
                )
                store.finishLasso(in: rect)
                lassoStart = nil
                lassoCurrent = nil
            }
    }

    private func lassoOverlay(from start: CGPoint, to current: CGPoint) -> some View {
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        return Rectangle()
            .stroke(Color.asmAccent, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            .background(Color.asmAccent.opacity(0.08))
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .allowsHitTesting(false)
    }
}

private struct InfiniteDotGrid: View {
    let scale: CGFloat
    let offset: CGSize

    private let spacing: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let scaledSpacing = spacing * scale
                guard scaledSpacing > 2 else { return }

                let originX = positiveModulo(size.width / 2 + offset.width, scaledSpacing)
                let originY = positiveModulo(size.height / 2 + offset.height, scaledSpacing)
                let radius = max(0.7, min(1.5, scale * 1.5))
                let dotColor = Color.asmInk.opacity(0.08)

                for x in stride(from: originX, through: size.width, by: scaledSpacing) {
                    for y in stride(from: originY, through: size.height, by: scaledSpacing) {
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - radius / 2, y: y - radius / 2, width: radius, height: radius)),
                            with: .color(dotColor)
                        )
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func positiveModulo(_ value: CGFloat, _ modulus: CGFloat) -> CGFloat {
        let remainder = value.truncatingRemainder(dividingBy: modulus)
        return remainder >= 0 ? remainder : remainder + modulus
    }
}

struct CanvasItemView: View {
    @EnvironmentObject private var store: ASMStore
    let item: CanvasItem
    @State private var cropInsets: EdgeInsets
    @State private var dragAccum: CGSize = .zero
    @State private var resizeAccum: CGSize = .zero

    init(item: CanvasItem) {
        self.item = item
        _cropInsets = State(initialValue: item.cropInsets)
    }

    private var isSelected: Bool {
        store.selectedItemID == item.id
    }

    private var drawingEnabled: Bool {
        store.activeTool == .pen || store.activeTool == .highlighter || store.activeTool == .eraser
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if item.kind == .inkPage {
                    content
                } else {
                    VStack(spacing: 0) {
                        dragChrome
                        content
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.asmAccent, lineWidth: 1.5)
                }
            }

            if isSelected {
                Circle()
                    .fill(Color.asmAccent)
                    .frame(width: 14, height: 14)
                    .padding(6)
                    .highPriorityGesture(resizeGesture)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.selectItem(item.id)
        }
        .optionalGesture(moveGesture, enabled: store.activeTool == .hand && item.kind != .widget)
    }

    private var dragChrome: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.asmMutedInk)
                Image(systemName: item.kind == .widget ? (item.widgetKind?.icon ?? "square.grid.2x2") : "doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.asmMutedInk)
                Text(item.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.asmInk)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .highPriorityGesture(moveGesture)

            if item.kind == .widget {
                Button {
                    store.removeItem(item.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.asmMutedInk)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.asmMist.opacity(0.96))
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .inkPage:
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.clear)
                PencilCanvasPage(
                    drawingData: Binding(
                        get: { store.items.first(where: { $0.id == item.id })?.drawingData },
                        set: { if let data = $0 { store.updateDrawing(item.id, data: data) } }
                    ),
                    tool: store.makeInkTool(),
                    isDrawingEnabled: drawingEnabled && isSelected,
                    onChange: { store.updateDrawing(item.id, data: $0) }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        case .pdfPage:
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
                if let data = item.pdfData {
                    PDFCanvasPage(data: data, pageIndex: item.pageIndex, cropInsets: cropInsets)
                        .padding(EdgeInsets(
                            top: cropInsets.top,
                            leading: cropInsets.leading,
                            bottom: cropInsets.bottom,
                            trailing: cropInsets.trailing
                        ))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                if isSelected {
                    PDFCropOverlay(insets: $cropInsets) { store.updateCrop(item.id, insets: $0) }
                }
            }
        case .widget:
            CanvasWidgetHost(item: item)
                .allowsHitTesting(store.activeTool != .lasso)
        }
    }

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                if store.selectedItemID != item.id {
                    store.selectItem(item.id)
                }
                let delta = CGSize(
                    width: value.translation.width - dragAccum.width,
                    height: value.translation.height - dragAccum.height
                )
                dragAccum = value.translation
                store.moveItem(item.id, by: delta)
            }
            .onEnded { _ in
                dragAccum = .zero
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let delta = CGSize(
                    width: value.translation.width - resizeAccum.width,
                    height: value.translation.height - resizeAccum.height
                )
                resizeAccum = value.translation
                store.resizeItem(item.id, width: item.width + delta.width, height: item.height + delta.height)
            }
            .onEnded { _ in
                resizeAccum = .zero
            }
    }
}

private extension View {
    @ViewBuilder
    func optionalGesture<G: Gesture>(_ gesture: G, enabled: Bool) -> some View {
        if enabled {
            self.gesture(gesture)
        } else {
            self
        }
    }
}

