//
//  RevisionDashboardView.swift
//  ASM
//

import SwiftUI

struct RevisionDashboardView: View {
    @EnvironmentObject private var store: ASMStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeader(title: "Revision", subtitle: "Tasks and mastery from your profile.")
                ForEach(store.tasks) { task in
                    Button {
                        store.toggleTask(task)
                    } label: {
                        HStack {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isDone ? Color.asmTeal : Color.asmMutedInk)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title).font(.system(size: 15, weight: .semibold))
                                Text(task.detail).font(.system(size: 12)).foregroundStyle(Color.asmMutedInk)
                            }
                            Spacer()
                            Text("\(task.minutes)m")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.asmMutedInk)
                        }
                        .padding(12)
                        .asmCard()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Color.asmCanvas)
    }
}
