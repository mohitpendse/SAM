//
//  StudyModels.swift
//  ASM
//

import Foundation
import SwiftUI

enum AppPhase {
    case signedOut
    case onboarding
    case home
    case workspace
}

enum CanvasTool: String, CaseIterable, Identifiable {
    case pen
    case highlighter
    case eraser
    case lasso
    case hand

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pen: "pencil.tip"
        case .highlighter: "highlighter"
        case .eraser: "eraser"
        case .lasso: "lasso"
        case .hand: "hand.draw"
        }
    }

    var title: String {
        switch self {
        case .pen: "Pen"
        case .highlighter: "Highlighter"
        case .eraser: "Eraser"
        case .lasso: "Lasso"
        case .hand: "Move"
        }
    }
}

enum WidgetKind: String, CaseIterable, Identifiable {
    case calculator
    case document
    case flashcards
    case desmos
    case pomodoro
    case research
    case todo
    case wolfram
    case youtube

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calculator: "Calculator"
        case .document: "Document"
        case .flashcards: "Flashcards"
        case .desmos: "Graphing"
        case .pomodoro: "Pomodoro"
        case .research: "Research"
        case .todo: "To-Do List"
        case .wolfram: "Wolfram Alpha"
        case .youtube: "YouTube"
        }
    }

    var icon: String {
        switch self {
        case .calculator: "function"
        case .document: "doc"
        case .flashcards: "rectangle.on.rectangle.angled"
        case .desmos: "chart.xyaxis.line"
        case .pomodoro: "timer"
        case .research: "globe"
        case .todo: "checkmark.square"
        case .wolfram: "x.squareroot"
        case .youtube: "play.rectangle"
        }
    }

    var blurb: String {
        switch self {
        case .calculator: "A scientific calculator you can park next to your work."
        case .document: "Pin a reference document directly onto the board."
        case .flashcards: "Flip cards generated from your notes and sources."
        case .desmos: "Graph equations with Desmos without leaving the canvas."
        case .pomodoro: "A focus timer tuned to your study block."
        case .research: "Search the web beside your notes."
        case .todo: "Keep the next tasks visible while you write."
        case .wolfram: "Look up steps and closed forms with Wolfram Alpha."
        case .youtube: "Watch a lecture clip on the same board."
        }
    }

    var defaultSize: CGSize {
        switch self {
        case .calculator: CGSize(width: 280, height: 420)
        case .document: CGSize(width: 420, height: 560)
        case .youtube: CGSize(width: 420, height: 320)
        case .desmos, .wolfram, .research: CGSize(width: 460, height: 380)
        case .todo: CGSize(width: 300, height: 340)
        case .pomodoro: CGSize(width: 260, height: 280)
        case .flashcards: CGSize(width: 340, height: 280)
        }
    }

    var url: URL? {
        switch self {
        case .desmos: URL(string: "https://www.desmos.com/calculator")
        case .wolfram: URL(string: "https://www.wolframalpha.com")
        case .research: URL(string: "https://www.google.com/search?q=study+notes")
        case .youtube: URL(string: "https://www.youtube.com")
        default: nil
        }
    }
}

enum TutorAction: String, CaseIterable, Identifiable {
    case next = "Next"
    case find = "Find"
    case explain = "Explain"
    case check = "Check"
    case quiz = "Quiz"
    case audio = "Audio"
    case map = "Map"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .next: "arrow.right.circle"
        case .find: "magnifyingglass"
        case .explain: "text.bubble"
        case .check: "checkmark.seal"
        case .quiz: "questionmark.app"
        case .audio: "waveform"
        case .map: "map"
        }
    }
}

enum CanvasItemKind: String {
    case inkPage
    case pdfPage
    case widget
}

struct StudentLearningProfile: Equatable {
    var name: String
    var email: String
    var goal: String
    var exam: String
    var subjects: Set<String>
    var learningModes: Set<String>
    var explanationDepth: String
    var studyBlock: Double
    var friction: String
    var language: String
    var confidence: Double

    var tutorStyle: String {
        let modes = learningModes.sorted().prefix(2).joined(separator: " + ")
        return "\(explanationDepth), \(modes.isEmpty ? "adaptive" : modes), \(language)"
    }

    static let empty = StudentLearningProfile(
        name: "",
        email: "",
        goal: "Score higher with concept clarity",
        exam: "School / College",
        subjects: ["Math", "Physics"],
        learningModes: ["Step-by-step", "Practice problems"],
        explanationDepth: "Balanced",
        studyBlock: 45,
        friction: "I get stuck and lose momentum",
        language: "English + simple Hinglish",
        confidence: 0.45
    )
}

struct Notebook: Identifiable, Equatable {
    let id: UUID
    var title: String
    var binders: [Binder]

    init(id: UUID = UUID(), title: String, binders: [Binder] = []) {
        self.id = id
        self.title = title
        self.binders = binders
    }
}

struct Binder: Identifiable, Equatable {
    let id: UUID
    var title: String
    var pageIDs: [UUID]
    var color: Color

    init(id: UUID = UUID(), title: String, pageIDs: [UUID] = [], color: Color = .asmAccent) {
        self.id = id
        self.title = title
        self.pageIDs = pageIDs
        self.color = color
    }
}

struct CanvasItem: Identifiable, Equatable {
    let id: UUID
    var kind: CanvasItemKind
    var title: String
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var binderID: UUID?
    var pageIndex: Int
    var widgetKind: WidgetKind?
    var pdfData: Data?
    var drawingData: Data?
    var cropInsets: EdgeInsets
    var youtubeURL: String
    var webURL: String
    var zIndex: Double

    init(
        id: UUID = UUID(),
        kind: CanvasItemKind,
        title: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat,
        binderID: UUID? = nil,
        pageIndex: Int = 0,
        widgetKind: WidgetKind? = nil,
        pdfData: Data? = nil,
        drawingData: Data? = nil,
        cropInsets: EdgeInsets = EdgeInsets(),
        youtubeURL: String = "https://www.youtube.com",
        webURL: String = "",
        zIndex: Double = 0
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.binderID = binderID
        self.pageIndex = pageIndex
        self.widgetKind = widgetKind
        self.pdfData = pdfData
        self.drawingData = drawingData
        self.cropInsets = cropInsets
        self.youtubeURL = youtubeURL
        self.webURL = webURL
        self.zIndex = zIndex
    }

    var frame: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    static func == (lhs: CanvasItem, rhs: CanvasItem) -> Bool {
        lhs.id == rhs.id
            && lhs.kind == rhs.kind
            && lhs.title == rhs.title
            && lhs.x == rhs.x
            && lhs.y == rhs.y
            && lhs.width == rhs.width
            && lhs.height == rhs.height
            && lhs.binderID == rhs.binderID
            && lhs.pageIndex == rhs.pageIndex
            && lhs.widgetKind == rhs.widgetKind
            && lhs.pdfData == rhs.pdfData
            && lhs.drawingData == rhs.drawingData
            && lhs.youtubeURL == rhs.youtubeURL
            && lhs.webURL == rhs.webURL
            && lhs.zIndex == rhs.zIndex
    }
}

struct SelectionState: Equatable {
    var itemID: UUID?
    var rect: CGRect?
    var label: String

    static let empty = SelectionState(itemID: nil, rect: nil, label: "Canvas")
}

struct TutorMessage: Identifiable, Equatable {
    let id: UUID
    var role: String
    var body: String
    var citation: String?

    init(id: UUID = UUID(), role: String, body: String, citation: String? = nil) {
        self.id = id
        self.role = role
        self.body = body
        self.citation = citation
    }
}

struct StudyTask: Identifiable, Equatable {
    let id: UUID
    var title: String
    var detail: String
    var isDone: Bool
    var minutes: Int

    init(id: UUID = UUID(), title: String, detail: String, isDone: Bool, minutes: Int) {
        self.id = id
        self.title = title
        self.detail = detail
        self.isDone = isDone
        self.minutes = minutes
    }
}

struct Flashcard: Identifiable, Equatable {
    let id: UUID
    var front: String
    var back: String
    var confidence: Double

    init(id: UUID = UUID(), front: String, back: String, confidence: Double) {
        self.id = id
        self.front = front
        self.back = back
        self.confidence = confidence
    }
}

struct PenStyle: Equatable {
    var color: Color
    var width: CGFloat
    var isHighlighter: Bool

    static let pen = PenStyle(color: .asmInk, width: 2.4, isHighlighter: false)
    static let highlighter = PenStyle(color: Color.yellow.opacity(0.45), width: 14, isHighlighter: true)
}
