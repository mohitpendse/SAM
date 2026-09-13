//
//  StudyWidgets.swift
//  ASM
//

import SwiftUI
import WebKit

struct WidgetChrome<Content: View>: View {
    let title: String
    let icon: String
    var onClose: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.asmLine))
        .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
    }
}

struct WebWidgetView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero)
        web.scrollView.isScrollEnabled = true
        load(into: web)
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url?.absoluteString != urlString {
            load(into: uiView)
        }
    }

    private func load(into web: WKWebView) {
        guard let url = URL(string: urlString) else { return }
        web.load(URLRequest(url: url))
    }
}

struct CalculatorWidget: View {
    @State private var display = "0"
    @State private var stored: Double?
    @State private var pendingOp: String?
    @State private var shouldReset = false

    private let keys: [[String]] = [
        ["C", "±", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
        ["0", ".", "sin", "="]
    ]

    var body: some View {
        VStack(spacing: 10) {
            Text(display)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 8)
                .padding(.top, 6)

            ForEach(keys, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            tap(key)
                        } label: {
                            Text(key)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(opKeys.contains(key) ? Color.asmInk : Color.asmMist, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .foregroundStyle(opKeys.contains(key) ? .white : Color.asmInk)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
    }

    private var opKeys: Set<String> { ["÷", "×", "−", "+", "="] }

    private func tap(_ key: String) {
        switch key {
        case "C":
            display = "0"; stored = nil; pendingOp = nil
        case "±":
            if let value = Double(display) { display = format(-value) }
        case "%":
            if let value = Double(display) { display = format(value / 100) }
        case "sin":
            if let value = Double(display) { display = format(sin(value * .pi / 180)) }
        case "÷", "×", "−", "+":
            stored = Double(display)
            pendingOp = key
            shouldReset = true
        case "=":
            guard let left = stored, let right = Double(display), let op = pendingOp else { return }
            let result: Double
            switch op {
            case "÷": result = right == 0 ? 0 : left / right
            case "×": result = left * right
            case "−": result = left - right
            default: result = left + right
            }
            display = format(result)
            stored = nil
            pendingOp = nil
        case ".":
            if shouldReset { display = "0."; shouldReset = false; return }
            if !display.contains(".") { display += "." }
        default:
            if shouldReset || display == "0" {
                display = key
                shouldReset = false
            } else {
                display += key
            }
        }
    }

    private func format(_ value: Double) -> String {
        value == floor(value) ? String(Int(value)) : String(format: "%.6g", value)
    }
}

struct TodoWidget: View {
    @EnvironmentObject private var store: ASMStore
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Add task", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(Color.asmMist, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Button {
                    store.addTask(title: draft)
                    draft = ""
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(IconControlStyle())
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(store.tasks) { task in
                        Button {
                            store.toggleTask(task)
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(task.isDone ? Color.asmTeal : Color.asmMutedInk)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(task.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .strikethrough(task.isDone)
                                        .foregroundStyle(Color.asmInk)
                                    Text("\(task.minutes)m")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.asmMutedInk)
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
    }
}

struct PomodoroWidget: View {
    @EnvironmentObject private var store: ASMStore
    @State private var remaining: Int = 0
    @State private var running = false
    @State private var tickTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 16) {
            Text(timeString)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text("Focus block")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.asmMutedInk)

            HStack(spacing: 10) {
                Button(running ? "Pause" : "Start") {
                    toggle()
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("Reset") {
                    reset()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(16)
        .onAppear {
            if remaining == 0 {
                remaining = Int(store.profile.studyBlock) * 60
            }
        }
        .onDisappear {
            tickTask?.cancel()
        }
    }

    private var timeString: String {
        let m = remaining / 60
        let s = remaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func toggle() {
        if running {
            tickTask?.cancel()
            running = false
        } else {
            running = true
            tickTask = Task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    if Task.isCancelled { break }
                    if remaining > 0 {
                        remaining -= 1
                    } else {
                        running = false
                        break
                    }
                }
            }
        }
    }

    private func reset() {
        tickTask?.cancel()
        running = false
        remaining = Int(store.profile.studyBlock) * 60
    }
}

struct FlashcardWidget: View {
    @EnvironmentObject private var store: ASMStore
    @State private var index = 0
    @State private var flipped = false

    var body: some View {
        VStack(spacing: 12) {
            if store.flashcards.isEmpty {
                Text("No cards yet")
                    .foregroundStyle(Color.asmMutedInk)
            } else {
                let card = store.flashcards[index % store.flashcards.count]
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { flipped.toggle() }
                } label: {
                    VStack(spacing: 10) {
                        Text(flipped ? "Answer" : "Prompt")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.asmMutedInk)
                        Text(flipped ? card.back : card.front)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.asmInk)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 110)
                    }
                    .padding(14)
                    .background(Color.asmMist, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)

                HStack {
                    Button("Prev") {
                        flipped = false
                        index = (index - 1 + store.flashcards.count) % store.flashcards.count
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    Spacer()
                    Button("Generate") {
                        store.generateFlashcardsFromSelection()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    Spacer()
                    Button("Next") {
                        flipped = false
                        index = (index + 1) % store.flashcards.count
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding(12)
    }
}

struct YouTubeWidget: View {
    let item: CanvasItem
    @EnvironmentObject private var store: ASMStore
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField("YouTube URL or embed", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(Color.asmMist, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onAppear { draft = item.youtubeURL }
                Button("Go") {
                    store.updateWidgetURL(item.id, url: normalizeYouTube(draft))
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(10)

            WebWidgetView(urlString: item.youtubeURL)
        }
    }

    private func normalizeYouTube(_ raw: String) -> String {
        if raw.contains("youtube.com/watch?v="),
           let id = raw.split(separator: "v=").last?.split(separator: "&").first {
            return "https://www.youtube.com/embed/\(id)"
        }
        if raw.contains("youtu.be/"),
           let id = raw.split(separator: "/").last?.split(separator: "?").first {
            return "https://www.youtube.com/embed/\(id)"
        }
        return raw
    }
}

struct BrowserWidget: View {
    let item: CanvasItem
    let placeholder: String
    @EnvironmentObject private var store: ASMStore
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField(placeholder, text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(Color.asmMist, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .onAppear { draft = item.webURL.isEmpty ? (item.widgetKind?.url?.absoluteString ?? "") : item.webURL }
                Button("Go") {
                    var url = draft
                    if !url.contains("://") { url = "https://\(url)" }
                    store.updateWidgetURL(item.id, url: url)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(10)

            WebWidgetView(urlString: item.webURL.isEmpty ? (item.widgetKind?.url?.absoluteString ?? "https://www.google.com") : item.webURL)
        }
    }
}

struct CanvasWidgetHost: View {
    let item: CanvasItem

    var body: some View {
        Group {
            switch item.widgetKind {
            case .calculator:
                WidgetChrome(title: "Calculator", icon: "function") {
                    CalculatorWidget()
                }
            case .todo:
                WidgetChrome(title: "To-Do", icon: "checklist") {
                    TodoWidget()
                }
            case .pomodoro:
                WidgetChrome(title: "Pomodoro", icon: "timer") {
                    PomodoroWidget()
                }
            case .flashcards:
                WidgetChrome(title: "Flashcards", icon: "rectangle.on.rectangle.angled") {
                    FlashcardWidget()
                }
            case .youtube:
                WidgetChrome(title: "YouTube", icon: "play.rectangle") {
                    YouTubeWidget(item: item)
                }
            case .desmos:
                WidgetChrome(title: "Desmos", icon: "chart.xyaxis.line") {
                    BrowserWidget(item: item, placeholder: "Desmos URL")
                }
            case .wolfram:
                WidgetChrome(title: "Wolfram", icon: "sum") {
                    BrowserWidget(item: item, placeholder: "Wolfram URL")
                }
            case .research:
                WidgetChrome(title: "Research", icon: "magnifyingglass") {
                    BrowserWidget(item: item, placeholder: "Search or URL")
                }
            case .document:
                WidgetChrome(title: "Document", icon: "doc") {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.asmMutedInk)
                        Text("Pin a PDF from the widget sidebar.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.asmMutedInk)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(16)
                }
            case .none:
                EmptyView()
            }
        }
    }
}
