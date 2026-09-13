//
//  GeminiWorkspaceViews.swift
//  ASM
//

import SwiftUI

/// Kept as lightweight sheets / secondary surfaces opened from widgets.
struct FlashcardDeckView: View {
    @EnvironmentObject private var store: ASMStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Flashcards", subtitle: "Generated from selection and weak concepts.")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                    ForEach(store.flashcards) { card in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(card.front)
                                .font(.system(size: 15, weight: .bold))
                            Divider()
                            Text(card.back)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.asmMutedInk)
                        }
                        .padding(14)
                        .asmCard(shadow: true)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.asmCanvas)
    }
}
