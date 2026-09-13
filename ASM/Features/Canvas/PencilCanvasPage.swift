//
//  PencilCanvasPage.swift
//  ASM
//

import SwiftUI
import PencilKit

struct PencilCanvasPage: UIViewRepresentable {
    @Binding var drawingData: Data?
    var tool: PKTool
    var isDrawingEnabled: Bool
    var onChange: (Data) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.isScrollEnabled = false
        canvas.tool = tool
        canvas.isUserInteractionEnabled = isDrawingEnabled
        if let drawingData, let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
            context.coordinator.lastData = drawingData
        }
        context.coordinator.canvas = canvas
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = tool
        uiView.isUserInteractionEnabled = isDrawingEnabled
        context.coordinator.onChange = onChange

        if let drawingData,
           drawingData != context.coordinator.lastData,
              let drawing = try? PKDrawing(data: drawingData) {
            uiView.drawing = drawing
            context.coordinator.lastData = drawingData
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var onChange: (Data) -> Void
        weak var canvas: PKCanvasView?
        var lastData: Data?
        private var pendingChange: DispatchWorkItem?
        private var hasPendingChange = false

        init(onChange: @escaping (Data) -> Void) {
            self.onChange = onChange
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !hasPendingChange else { return }
            hasPendingChange = true

            let change = DispatchWorkItem { [weak self, weak canvasView] in
                guard let self, let canvasView else { return }
                let data = canvasView.drawing.dataRepresentation()
                self.lastData = data
                self.hasPendingChange = false
                self.onChange(data)
            }
            pendingChange = change
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: change)
        }

        deinit {
            pendingChange?.cancel()
        }
    }
}
