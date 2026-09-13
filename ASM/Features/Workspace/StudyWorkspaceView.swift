//
//  StudyWorkspaceView.swift
//  ASM
//

import SwiftUI
import UniformTypeIdentifiers

struct StudyWorkspaceView: View {
    @EnvironmentObject private var store: ASMStore

    var body: some View {
        CanvasWorkspaceView()
                .overlay {
                    if store.showWidgetPicker {
                        Color.black.opacity(0.04)
                            .ignoresSafeArea()
                            .onTapGesture { store.showWidgetPicker = false }
                    }
                }
                .overlay(alignment: .trailing) {
                    HStack(alignment: .center, spacing: 12) {
                        if store.showWidgetPicker {
                            WidgetCatalogSidebar()
                        }
                        ToolRailView()
                    }
                    .padding(.trailing, 16)
                }
                .overlay(alignment: .bottom) {
                    if store.selectedItemID != nil || store.lassoRect != nil {
                        AILassoBar()
                            .padding(.bottom, 16)
                    }
                }
                .overlay(alignment: .trailing) {
                    if store.showGeminiPanel {
                        GeminiSlideOver()
                            .transition(.move(edge: .trailing))
                    }
                }
                .background(Color.asmCanvas)
        .background(Color.asmCanvas)
        .fileImporter(
            isPresented: $store.showPDFImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                store.importPDF(from: url)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: store.showGeminiPanel)
        .animation(.easeInOut(duration: 0.18), value: store.showWidgetPicker)
    }
}
