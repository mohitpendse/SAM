//
//  PersonalizationView.swift
//  ASM
//

import SwiftUI

struct PersonalizationView: View {
    @EnvironmentObject private var store: ASMStore

    private let goals = ["Score higher with concept clarity", "Prepare for an entrance exam", "Finish assignments faster", "Revise without forgetting"]
    private let exams = ["School / College", "JEE", "NEET", "SAT", "CAT", "University finals", "Self learning"]
    private let subjects = ["Math", "Physics", "Chemistry", "Biology", "Economics", "CS", "History", "English"]
    private let modes = ["Step-by-step", "Diagrams", "Examples first", "Practice problems", "Short videos", "Audio recap"]
    private let depths = ["Quick", "Balanced", "Deep"]
    private let frictions = ["I get stuck and lose momentum", "I procrastinate", "I forget after reading", "I cannot organize sources"]
    private let languages = ["English", "English + simple Hinglish", "Hindi", "Marathi"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "hexagon.fill")
                        .foregroundStyle(Color.asmAccent)
                    Text("ASM")
                        .font(.system(size: 16, weight: .bold))
                }
                Spacer()
                Text("Personalize tutor")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.asmMutedInk)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.asmCanvas)
            .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.asmLine), alignment: .bottom)

            HStack(alignment: .top, spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("How should ASM teach you?")
                            .font(.system(size: 26, weight: .semibold))
                        Text("This profile shapes explanations, flashcards, revision plans, and next steps.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.asmMutedInk)

                        picker("Primary goal", goals, $store.profile.goal)
                        picker("Current track", exams, $store.profile.exam)
                        multi("Subjects", subjects, $store.profile.subjects)
                        multi("Learn fastest with", modes, $store.profile.learningModes)
                        picker("Explanation depth", depths, $store.profile.explanationDepth)
                        slider("Study block", $store.profile.studyBlock, 15...90, "minutes")
                        slider("Confidence", $store.profile.confidence, 0...1, "confidence")
                        picker("Usual blocker", frictions, $store.profile.friction)
                        picker("Language", languages, $store.profile.language)
                    }
                    .padding(28)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Tutor memory")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.asmMutedInk)
                    Text(store.profile.tutorStyle)
                        .font(.system(size: 16, weight: .semibold))
                    Text(store.profile.friction)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.asmMutedInk)
                    Text("\(Int(store.profile.studyBlock)) min blocks")
                        .font(.system(size: 13, weight: .medium))

                    Spacer()

                    Button {
                        store.completeOnboarding()
                    } label: {
                        Text("Open canvas")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(24)
                .frame(width: 280)
                .background(Color.asmCanvas)
                .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.asmLine), alignment: .leading)
            }
            .background(Color.asmCanvas)
        }
    }

    private func picker(_ title: String, _ options: [String], _ selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    ChoiceChip(text: option, isSelected: selection.wrappedValue == option) {
                        selection.wrappedValue = option
                    }
                }
            }
        }
    }

    private func multi(_ title: String, _ options: [String], _ selection: Binding<Set<String>>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    ChoiceChip(text: option, isSelected: selection.wrappedValue.contains(option)) {
                        if selection.wrappedValue.contains(option) {
                            selection.wrappedValue.remove(option)
                        } else {
                            selection.wrappedValue.insert(option)
                        }
                    }
                }
            }
        }
    }

    private func slider(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            VStack(alignment: .leading, spacing: 8) {
                Slider(value: value, in: range, step: suffix == "minutes" ? 5 : 0.05)
                Text(suffix == "minutes" ? "\(Int(value.wrappedValue)) minutes" : "\(Int(value.wrappedValue * 100))% confidence")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.asmMutedInk)
            }
            .padding(12)
            .asmCard(radius: 10)
        }
    }
}
