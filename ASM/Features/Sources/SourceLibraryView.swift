//
//  SourceLibraryView.swift
//  ASM
//

import SwiftUI

/// Secondary surface — PDF import is primary via canvas tool rail.
struct SourceLibraryView: View {
    @EnvironmentObject private var store: ASMStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Sources on canvas", subtitle: "PDFs appear as pages you can crop and ask AI about.")
            Button {
                store.showPDFImporter = true
            } label: {
                Label("Import PDF", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            ForEach(store.items.filter { $0.kind == .pdfPage }) { item in
                HStack {
                    Image(systemName: "doc.richtext")
                    Text(item.title)
                    Spacer()
                }
                .padding(12)
                .asmCard()
            }
            Spacer()
        }
        .padding(20)
        .background(Color.asmCanvas)
    }
}
