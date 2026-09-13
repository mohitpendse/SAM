# SAM

SAM is an iPad-first **study OS**: a white infinite canvas with notes, PDFs, and widgets, plus a Gemini tutor that uses both the workspace *and* a student learning profile.

Positioning:

- all study tools on one board
- SAM difference: the tutor is personalized (how you learn, exam goals, blockers, language, study-block length)

## Features

- Sign up → personalization questionnaire → home → canvas
- Infinite dotted canvas with pan, zoom, pen, highlighter, eraser, lasso, and hand tools
- Handwritten pages (PencilKit) and imported PDF pages on the same board
- Study widgets: calculator, flashcards, Desmos/graphing, Pomodoro, research, to-do, Wolfram Alpha, YouTube
- Compact right tool rail; widget picker as a side panel so the canvas stays clear
- Context AI actions on selected work: Next, Find, Explain, Check, Quiz, Audio, Map
- Gemini tutor panel (API key required; otherwise the app reports a missing-key error)

## Requirements

- Xcode 26.4+ (project uses iOS deployment target **26.4**)
- iPad Simulator or device recommended (also targets iPhone / Mac Catalyst family `1,2,7`)
- Optional: [Google Gemini API key](https://ai.google.dev/) for live tutoring

Bundle ID: `com.mohitpendse.asm`

## Getting started

1. Open `ASM.xcodeproj` in Xcode.
2. Select the **ASM** scheme.
3. For Gemini, add a Run environment variable:
   - **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables**
   - `GEMINI_API_KEY` = your key
   - Optional: `GEMINI_MODEL` (default `gemini-3.8-flash`)
4. Build and run on an **iPad** (landscape).

Do not commit API keys. Keep secrets in the scheme, `Secrets.xcconfig`, or `.env` (gitignored).

## Project layout

```
ASM/
  ASMApp.swift                 App entry
  ContentView.swift            Root flow
  App/ASMStore.swift           Workspace state, canvas items, tutor
  Models/StudyModels.swift     Profile, notebooks, widgets, selection
  Design/ASMDesignSystem.swift Colors, chips, floating chrome
  Features/
    Auth/                      Sign up
    Onboarding/                Learning-profile questionnaire
    Home/                      Notebooks, binders, spaces
    Workspace/                 Canvas shell, tool rail, Gemini panel
    Canvas/                    PencilKit pages, PDF pages
    Widgets/                   Calculator, YouTube, timer, etc.
    Gemini/                    Gemini API client
    Revision/                  Revision dashboard
    Sources/                   Source library
```

## License

Private project. All rights reserved.
