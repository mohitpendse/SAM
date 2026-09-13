//
//  PDFCanvasPage.swift
//  ASM
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct PDFCanvasPage: UIViewRepresentable {
    let data: Data
    let pageIndex: Int
    var cropInsets: EdgeInsets

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePage
        view.displayDirection = .vertical
        view.backgroundColor = .white
        view.isUserInteractionEnabled = false
        apply(to: view)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        apply(to: uiView)
    }

    private func apply(to view: PDFView) {
        if view.document == nil {
            view.document = PDFDocument(data: data)
        }
        if let page = view.document?.page(at: pageIndex) {
            view.go(to: page)
        }
        // Visual crop approximated via content insets on the hosting frame.
        view.layoutDocumentView()
    }
}

struct PDFCropOverlay: View {
    @Binding var insets: EdgeInsets
    var onChange: (EdgeInsets) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle()
                    .stroke(Color.asmAccent, lineWidth: 1.5)
                    .padding(EdgeInsets(
                        top: insets.top,
                        leading: insets.leading,
                        bottom: insets.bottom,
                        trailing: insets.trailing
                    ))
                    .allowsHitTesting(false)

                cropHandle(corner: .topLeading, in: geo.size)
                cropHandle(corner: .topTrailing, in: geo.size)
                cropHandle(corner: .bottomLeading, in: geo.size)
                cropHandle(corner: .bottomTrailing, in: geo.size)
            }
        }
        .allowsHitTesting(true)
    }

    private enum Corner { case topLeading, topTrailing, bottomLeading, bottomTrailing }

    private func cropHandle(corner: Corner, in size: CGSize) -> some View {
        let point: CGPoint = {
            switch corner {
            case .topLeading: return CGPoint(x: insets.leading, y: insets.top)
            case .topTrailing: return CGPoint(x: size.width - insets.trailing, y: insets.top)
            case .bottomLeading: return CGPoint(x: insets.leading, y: size.height - insets.bottom)
            case .bottomTrailing: return CGPoint(x: size.width - insets.trailing, y: size.height - insets.bottom)
            }
        }()

        return Circle()
            .fill(Color.asmAccent)
            .frame(width: 14, height: 14)
            .position(point)
            .allowsHitTesting(true)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        var next = insets
                        switch corner {
                        case .topLeading:
                            next.leading = max(0, min(size.width / 3, value.location.x))
                            next.top = max(0, min(size.height / 3, value.location.y))
                        case .topTrailing:
                            next.trailing = max(0, min(size.width / 3, size.width - value.location.x))
                            next.top = max(0, min(size.height / 3, value.location.y))
                        case .bottomLeading:
                            next.leading = max(0, min(size.width / 3, value.location.x))
                            next.bottom = max(0, min(size.height / 3, size.height - value.location.y))
                        case .bottomTrailing:
                            next.trailing = max(0, min(size.width / 3, size.width - value.location.x))
                            next.bottom = max(0, min(size.height / 3, size.height - value.location.y))
                        }
                        insets = next
                        onChange(next)
                    }
            )
    }
}

struct DocumentImportCoordinator: UIViewControllerRepresentable {
    var isPresented: Binding<Bool>
    var onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: isPresented, onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented.wrappedValue, uiViewController.presentedViewController == nil else { return }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        uiViewController.present(picker, animated: true)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        var isPresented: Binding<Bool>
        var onPick: (URL) -> Void

        init(isPresented: Binding<Bool>, onPick: @escaping (URL) -> Void) {
            self.isPresented = isPresented
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            isPresented.wrappedValue = false
            if let url = urls.first {
                onPick(url)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            isPresented.wrappedValue = false
        }
    }
}
