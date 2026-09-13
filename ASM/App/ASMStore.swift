//
//  ASMStore.swift
//  ASM
//

import Foundation
import Combine
import SwiftUI
import PencilKit
import PDFKit
@MainActor
final class ASMStore: ObservableObject {
    @Published var phase: AppPhase = .signedOut
    @Published var profile = StudentLearningProfile.empty

    @Published var notebooks: [Notebook] = []
    @Published var selectedNotebookID: UUID?
    @Published var selectedBinderID: UUID?
    @Published var items: [CanvasItem] = []
    @Published var selectedItemID: UUID?
    @Published var selection = SelectionState.empty

    @Published var activeTool: CanvasTool = .pen
    @Published var penStyle = PenStyle.pen
    @Published var highlighterStyle = PenStyle.highlighter
    @Published var showWidgetPicker = false
    @Published var showPageLibrary = false
    @Published var selectedWidgetKind: WidgetKind = .document
    @Published var showGeminiPanel = false
    @Published var showPDFImporter = false
    @Published var isSelecting = false
    @Published var lassoRect: CGRect?

    @Published var selectedAction: TutorAction = .explain
    @Published var currentPrompt = "Explain the selected work using my learning profile."
    @Published var tutorMessages: [TutorMessage] = []
    @Published var isTutorLoading = false
    @Published var tutorErrorMessage: String?

    @Published var tasks: [StudyTask] = []
    @Published var flashcards: [Flashcard] = []
    @Published var canvasScale: CGFloat = 1
    @Published var canvasOffset: CGSize = .zero
    @Published var canvasDrawingData: Data? = PKDrawing().dataRepresentation()
    @Published var nextZIndex: Double = 1

    private let geminiService = GeminiService()

    static let worldSize = CGSize(width: 4000, height: 3000)
    static var worldCenter: CGPoint {
        CGPoint(x: worldSize.width / 2, y: worldSize.height / 2)
    }

    init() {
        seedWorkspace()
    }

    var selectedNotebook: Notebook? {
        notebooks.first { $0.id == selectedNotebookID }
    }

    var selectedBinder: Binder? {
        selectedNotebook?.binders.first { $0.id == selectedBinderID }
    }

    var selectedItem: CanvasItem? {
        items.first { $0.id == selectedItemID }
    }

    var incompleteTaskCount: Int {
        tasks.filter { !$0.isDone }.count
    }

    var sortedItems: [CanvasItem] {
        items.sorted { $0.zIndex < $1.zIndex }
    }

    // MARK: - Auth / Onboarding

    func createAccount(name: String, email: String) {
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        phase = .onboarding
    }

    func completeOnboarding() {
        tutorMessages.append(
            TutorMessage(
                role: "ASM Tutor",
                body: "Profile locked for \(profile.name). I will prefer \(profile.tutorStyle.lowercased()) and watch for \(profile.friction.lowercased()).",
                citation: "Personalization"
            )
        )
        phase = .home
    }

    func openHome() {
        phase = .home
    }

    func openCanvas() {
        phase = .workspace
    }

    // MARK: - Notebook / Binder

    func selectNotebook(_ id: UUID) {
        selectedNotebookID = id
        if let first = notebooks.first(where: { $0.id == id })?.binders.first {
            selectedBinderID = first.id
        }
    }

    func selectBinder(_ id: UUID) {
        selectedBinderID = id
        if let page = items.first(where: { $0.binderID == id && $0.kind == .inkPage }) {
            selectedItemID = page.id
            bringToFront(page.id)
        }
    }

    func addBinder() {
        guard let notebookIndex = notebooks.firstIndex(where: { $0.id == selectedNotebookID }) else { return }
        let origin = nextItemOrigin(size: CGSize(width: 640, height: 480))
        let page = makeInkPage(
            title: "Canvas \(items.filter { $0.kind == .inkPage }.count + 1)",
            x: origin.x,
            y: origin.y
        )
        items.append(page)
        let binder = Binder(title: "Binder \(notebooks[notebookIndex].binders.count + 1)", pageIDs: [page.id])
        notebooks[notebookIndex].binders.append(binder)
        selectedBinderID = binder.id
        selectedItemID = page.id
    }

    func addInkPage() {
        guard
            let notebookIndex = notebooks.firstIndex(where: { $0.id == selectedNotebookID }),
            let binderIndex = notebooks[notebookIndex].binders.firstIndex(where: { $0.id == selectedBinderID })
        else { return }

        let origin = nextItemOrigin(size: CGSize(width: 640, height: 480))
        let page = makeInkPage(
            title: "Canvas \(notebooks[notebookIndex].binders[binderIndex].pageIDs.count + 1)",
            x: origin.x,
            y: origin.y
        )
        items.append(page)
        notebooks[notebookIndex].binders[binderIndex].pageIDs.append(page.id)
        selectedItemID = page.id
        bringToFront(page.id)
    }

    // MARK: - Canvas items

    func selectItem(_ id: UUID?) {
        if selectedItemID == id {
            if let id, let item = items.first(where: { $0.id == id }) {
                selection = SelectionState(itemID: id, rect: item.frame, label: item.title)
            }
            return
        }
        selectedItemID = id
        if let id, let item = items.first(where: { $0.id == id }) {
            selection = SelectionState(itemID: id, rect: item.frame, label: item.title)
            bringToFront(id)
        } else {
            selection = .empty
        }
    }

    func bringToFront(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if items[index].zIndex >= nextZIndex { return }
        nextZIndex += 1
        items[index].zIndex = nextZIndex
    }

    func removeItem(_ id: UUID) {
        items.removeAll { $0.id == id }
        for notebookIndex in notebooks.indices {
            for binderIndex in notebooks[notebookIndex].binders.indices {
                notebooks[notebookIndex].binders[binderIndex].pageIDs.removeAll { $0 == id }
            }
        }
        if selectedItemID == id {
            selectedItemID = items.last?.id
            if let selected = selectedItem {
                selection = SelectionState(itemID: selected.id, rect: selected.frame, label: selected.title)
            } else {
                selection = .empty
            }
        }
    }

    func moveItem(_ id: UUID, by translation: CGSize) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].x += translation.width
        items[index].y += translation.height
        if selectedItemID == id {
            selection.rect = items[index].frame
        }
    }

    func resizeItem(_ id: UUID, width: CGFloat, height: CGFloat) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].width = max(180, width)
        items[index].height = max(140, height)
        if selectedItemID == id {
            selection.rect = items[index].frame
        }
    }

    func updateDrawing(_ id: UUID, data: Data) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].drawingData = data
    }

    func updateCanvasDrawing(data: Data) {
        canvasDrawingData = data
    }

    func updateCrop(_ id: UUID, insets: EdgeInsets) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].cropInsets = insets
    }

    func updateWidgetURL(_ id: UUID, url: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if items[index].widgetKind == .youtube {
            items[index].youtubeURL = url
        } else {
            items[index].webURL = url
        }
    }

    func spawnWidget(_ kind: WidgetKind) {
        if kind == .document {
            showWidgetPicker = false
            showPDFImporter = true
            return
        }
        let size = kind.defaultSize
        let origin = nextItemOrigin(size: size)
        let item = CanvasItem(
            kind: .widget,
            title: kind.title,
            x: origin.x,
            y: origin.y,
            width: size.width,
            height: size.height,
            widgetKind: kind,
            youtubeURL: kind == .youtube ? "https://www.youtube.com/embed/dQw4w9WgXcQ" : "https://www.youtube.com",
            webURL: kind.url?.absoluteString ?? "",
            zIndex: nextZIndex + 1
        )
        nextZIndex += 1
        items.append(item)
        selectedItemID = item.id
        selection = SelectionState(itemID: item.id, rect: item.frame, label: item.title)
        showWidgetPicker = false
        showPageLibrary = false
        activeTool = .hand
    }

    func importPDF(from url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url),
              let document = PDFDocument(data: data) else { return }

        let pageCount = min(document.pageCount, 6)
        for index in 0..<pageCount {
            let item = CanvasItem(
                kind: .pdfPage,
                title: "\(url.deletingPathExtension().lastPathComponent) · p\(index + 1)",
                x: Self.worldCenter.x - 180 + CGFloat(index) * 28,
                y: Self.worldCenter.y - 240 + CGFloat(index) * 24,
                width: 360,
                height: 480,
                pageIndex: index,
                pdfData: data,
                zIndex: nextZIndex + Double(index + 1)
            )
            items.append(item)
        }
        nextZIndex += Double(pageCount + 1)
        if let last = items.last(where: { $0.kind == .pdfPage }) {
            selectedItemID = last.id
            selection = SelectionState(itemID: last.id, rect: last.frame, label: last.title)
        }
        showPDFImporter = false
    }

    func setTool(_ tool: CanvasTool) {
        activeTool = tool
        isSelecting = tool == .lasso
        if tool != .lasso {
            lassoRect = nil
        }
        if tool == .highlighter {
            penStyle = highlighterStyle
        } else if tool == .pen {
            penStyle = .pen
        }
    }

    func finishLasso(in rect: CGRect) {
        lassoRect = rect
        selection = SelectionState(
            itemID: selectedItemID,
            rect: rect,
            label: selectedItem?.title ?? "Selected region"
        )
        showGeminiPanel = true
    }

    // MARK: - Tasks / Flashcards

    func toggleTask(_ task: StudyTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isDone.toggle()
    }

    func addTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.insert(
            StudyTask(title: trimmed, detail: "Added from canvas to-do widget", isDone: false, minutes: 10),
            at: 0
        )
    }

    func generateFlashcardsFromSelection() {
        let topic = selection.label
        flashcards.insert(
            contentsOf: [
                Flashcard(
                    front: "Key idea in \(topic)?",
                    back: "Start from your preferred \(profile.learningModes.sorted().first?.lowercased() ?? "example") and restate the constraint before solving.",
                    confidence: 0.4
                ),
                Flashcard(
                    front: "Common mistake on \(topic)?",
                    back: "Skipping the boundary check — matches your blocker: \(profile.friction.lowercased()).",
                    confidence: 0.35
                )
            ],
            at: 0
        )
        showGeminiPanel = true
        tutorMessages.append(
            TutorMessage(
                role: "ASM Tutor",
                body: "Generated 2 flashcards from \(topic), tuned for \(profile.explanationDepth.lowercased()) recall.",
                citation: topic
            )
        )
    }

    // MARK: - AI

    func runSelectedAction() {
        let context = selection.label
        let prompt = currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let userPrompt = prompt.isEmpty ? selectedAction.rawValue : prompt
        let request = GeminiTutorRequest(
            action: selectedAction,
            prompt: userPrompt,
            selection: selection,
            profile: profile,
            recentMessages: tutorMessages
        )

        tutorMessages.append(TutorMessage(role: "You", body: userPrompt, citation: nil))
        showGeminiPanel = true
        isTutorLoading = true
        tutorErrorMessage = nil

        Task {
            do {
                let answer = try await geminiService.generateTutorResponse(for: request)
                tutorMessages.append(TutorMessage(role: "ASM Tutor", body: answer, citation: context))
            } catch {
                let fallback = localTutorAnswer(for: selectedAction, context: context)
                tutorErrorMessage = error.localizedDescription
                tutorMessages.append(TutorMessage(role: "ASM Tutor", body: fallback, citation: "Offline fallback"))
            }
            isTutorLoading = false
        }
    }

    private func localTutorAnswer(for action: TutorAction, context: String) -> String {
        let modes = profile.learningModes.sorted().joined(separator: " + ").lowercased()

        switch action {
        case .next:
            return "Next \(Int(profile.studyBlock / 3)) min: rebuild the diagram for \(context), then do 3 checks. Keep momentum around your blocker: \(profile.friction)."
        case .find:
            return "Related material for \(context): open the indexed PDF page, jump to the Desmos widget for a visual, and pull 1 worked example in your \(profile.language) style."
        case .explain:
            return "\(profile.explanationDepth) explanation of \(context): lead with \(modes.isEmpty ? "a short model" : modes), then translate each step into equations. Ask you to restate before I continue."
        case .check:
            return "Check on \(context): method looks mostly right. Re-verify the boundary you marked; that is where students with your profile usually slip."
        case .quiz:
            return "Quiz: If \(context) removes the unconstrained maximum, where do you look next: edge, vertex, or original point? Answer in one line."
        case .audio:
            return "Audio overview plan (\(Int(min(profile.studyBlock, 8))) min): 1m recap of \(context), 2m worked example, 1m active recall in \(profile.language)."
        case .map:
            return "Mind map: \(context) -> visual model -> constraints -> equations -> check -> flashcard. Depth: \(profile.explanationDepth)."
        }
    }

    func makeInkTool() -> PKTool {
        switch activeTool {
        case .eraser:
            return PKEraserTool(.vector)
        case .highlighter:
            let ink = PKInkingTool(.marker, color: UIColor(highlighterStyle.color), width: highlighterStyle.width)
            return ink
        case .pen, .lasso, .hand:
            let ink = PKInkingTool(.pen, color: UIColor(penStyle.color), width: penStyle.width)
            return ink
        }
    }

    // MARK: - Seed

    private func seedWorkspace() {
        items = []

        let binder = Binder(title: "Mechanics", color: .asmAccent)
        let notebook = Notebook(title: "Mechanics Revision", binders: [binder])
        notebooks = [notebook]
        selectedNotebookID = notebook.id
        selectedBinderID = binder.id
        selectedItemID = nil
        selection = .empty

        tasks = [
            StudyTask(title: "Rebuild the constraint diagram", detail: "Diagram-first before solving.", isDone: false, minutes: 12),
            StudyTask(title: "Solve 5 similar problems", detail: "Check each step.", isDone: false, minutes: 24),
            StudyTask(title: "Revise flashcards", detail: "Active recall block.", isDone: true, minutes: 9)
        ]

        flashcards = [
            Flashcard(front: "Why does a constraint change the objective?", back: "It limits feasible values, so the unconstrained optimum may be invalid.", confidence: 0.42),
            Flashcard(front: "What should you check after deriving an equation?", back: "Units, boundary conditions, and whether each constraint is active.", confidence: 0.68)
        ]

        tutorMessages = [
            TutorMessage(
                role: "ASM Tutor",
                body: "Select notes or a PDF region, then use Next, Find, Explain, or Check. I already know your learning profile.",
                citation: "Workspace"
            )
        ]
    }

    private func nextItemOrigin(size: CGSize) -> CGPoint {
        if let selected = selectedItem {
            return CGPoint(x: selected.x + 36, y: selected.y + 28)
        }
        return CGPoint(
            x: Self.worldCenter.x - size.width / 2,
            y: Self.worldCenter.y - size.height / 2
        )
    }

    private func makeInkPage(title: String, x: CGFloat, y: CGFloat, width: CGFloat = 480, height: CGFloat = 640) -> CanvasItem {
        nextZIndex += 1
        return CanvasItem(
            kind: .inkPage,
            title: title,
            x: x,
            y: y,
            width: width,
            height: height,
            binderID: selectedBinderID,
            drawingData: PKDrawing().dataRepresentation(),
            zIndex: nextZIndex
        )
    }
}
