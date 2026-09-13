import SwiftUI
import Combine
import PencilKit
import PhotosUI
import UniformTypeIdentifiers
import PDFKit
import WebKit

struct ContentView: View {
    @State private var screen: Screen = .welcome
    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var space = ""
    @State private var folder = ""
    @State private var selected = ""
    @State private var selectedStorage = ""
    @State private var selectedSubject = ""
    @State private var selectedTheme = ""
    @State private var subjectText = ""
    @State private var spaces = [String]()
    @State private var folders = [String]()
    @State private var folderSpaces = [String: String]()
    @State private var pinnedFolders = Set<String>()
    @State private var spaceImages = [String: Data]()
    @State private var folderImages = [String: Data]()
    @State private var canvases = [String]()
    @State private var notebooks = [String]()
    @State private var documentFolders = [String: String]()
    @State private var documentTypes = [String: NewDocumentType]()
    @State private var pdfDocuments = [String: Data]()
    @State private var collectionCreationType: CollectionCreationType?
    @State private var collectionName = ""
    @State private var collectionImageData: Data?
    @State private var selectedCollectionPhoto: PhotosPickerItem?
    @State private var newDocumentType: NewDocumentType?
    @State private var showNewDocumentWindow = false
    @State private var newDocumentName = ""
    @State private var selectedDocumentFolder = "Unfiled"
    @State private var selectedPDFURL: URL?
    @State private var selectedPDFData: Data?
    @State private var isPickingPDF = false
    @State private var showMenu = false
    @State private var showSpaceMenu = false
    @State private var showFolderNewMenu = false
    @State private var showFolderMenu = false
    @State private var folderViewMode: FolderViewMode = .large
    @State private var isSelectingFolders = false
    @State private var selectedFolders = Set<String>()
    @State private var isSelectingItems = false
    @State private var selectedItems = Set<String>()
    @State private var activeDocumentName = ""
    @State private var activeDocumentType: NewDocumentType?
    @State private var showDocumentSidebar = false
    @State private var showWidgetPicker = false
    @State private var placedWidgets = [String]()
    @State private var widgetOffsets = [Int: CGSize]()
    @State private var widgetDragStart = [Int: CGSize]()
    @State private var activeWebWidget: WebWidget?
    @State private var showWebSidebar = false
    @State private var webSearchText = ""
    @State private var documentPageCounts = [String: Int]()
    @State private var notebookPageIndex = [String: Int]()
    @State private var notebookDrawings = [String: [Int: Data]]()
    @State private var documentSearchText = ""
    @State private var documentSidebarMode: DocumentSidebarMode = .browser
    @State private var folderItemTab: FolderItemTab = .all
    @State private var editingFolderName = ""
    @State private var showEditFolderAlert = false
    @State private var editingSpaceName = ""
    @State private var showEditSpaceAlert = false
    @State private var activeTool: CanvasTool = .pen
    @State private var showPenOptions = false
    @State private var penColor = Color.white
    @State private var penWidth: CGFloat = 3
    @State private var canvasDrawingData: Data? = PKDrawing().dataRepresentation()
    @State private var canvasOffset: CGSize = .zero
    @State private var canvasPanAccumulation: CGSize = .zero
    @State private var canvasScale: CGFloat = 1
    @State private var canvasPinchStart: CGFloat?
    @State private var toolRailPosition: CGPoint?
    @State private var toolRailDragStart: CGPoint?
    @State private var showColorRail = false
    @State private var lassoStart: CGPoint?
    @State private var lassoCurrent: CGPoint?
    @State private var selectedLassoRect: CGRect?

    private let canvasWorldSize = CGSize(width: 20000, height: 16000)

    var body: some View {
        Group {
            switch screen {
            case .welcome: welcome
            case .verification: verification
            case .name, .study, .storage, .subjects, .theme, .space, .folder: onboarding
            case .home: home
            case .folderView: folderView
            case .canvas: canvas
            }
        }
        .preferredColorScheme(.dark)
        .foregroundStyle(.white.opacity(0.9))
        .background(Theme.background.ignoresSafeArea())
        .overlay {
            if collectionCreationType != nil {
                collectionCreationWindow
            }
            if showNewDocumentWindow {
                newDocumentWindow
            }
        }
        .fileImporter(isPresented: $isPickingPDF, allowedContentTypes: [.pdf]) { result in
            if case .success(let url) = result {
                selectedPDFURL = url
                if let data = try? Data(contentsOf: url), newDocumentType == .pdf {
                    selectedPDFData = data
                }
                if newDocumentName.isEmpty {
                    newDocumentName = url.deletingPathExtension().lastPathComponent
                }
            }
        }
    }

    private var welcome: some View {
        HStack(spacing: 120) {
            VStack(spacing: 12) {
                brand
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome,")
                        .font(.system(size: 38, weight: .semibold))
                        .fixedSize(horizontal: true, vertical: false)
                    Text("to a new way to study.")
                        .font(.system(size: 21))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                VStack(spacing: 14) {
                    Button {
                        screen = .verification
                    } label: {
                        HStack(spacing: 12) {
                            Image("GoogleLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("Continue with Google")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(AuthProviderButton())

                    Button {
                        screen = .verification
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20, weight: .medium))
                            Text("Continue with Apple")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(AuthProviderButton())

                    HStack(spacing: 12) {
                        Rectangle().fill(Theme.line).frame(height: 1)
                        Text("OR").font(.system(size: 12)).foregroundStyle(Theme.muted)
                        Rectangle().fill(Theme.line).frame(height: 1)
                    }

                    Field(placeholder: "Student or personal email", text: $email)
                    Button("Continue") { screen = .verification }
                        .buttonStyle(PrimaryButton())
                        .disabled(email.isEmpty)
                }
                .frame(width: 340)
                Spacer()
            }
            .frame(width: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 120)
    }

    private var verification: some View {
        HStack(spacing: 120) {
            VStack(spacing: 16) {
                Spacer()
                brand
                Image(systemName: "envelope").font(.system(size: 28)).foregroundStyle(Theme.muted)
                Text("Verification").font(.system(size: 36, weight: .semibold))
                Text("Check your inbox.").font(.system(size: 21)).foregroundStyle(Theme.muted)
                Text("Enter 6-digit Verification code On\n\(email.isEmpty ? "student@example.com" : email)").multilineTextAlignment(.center).foregroundStyle(Theme.muted)
                Field(placeholder: "Enter 6-digit code", text: .constant(""))
                Button("Submit code") { screen = .name }.buttonStyle(PrimaryButton())
                Spacer()
            }.frame(width: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 120)
    }

    private var onboarding: some View {
        VStack(spacing: 0) {
            HStack { brand; Spacer(); progress; Spacer(); Button("Skip") { screen = .home }.buttonStyle(SmallButton()) }.padding(28)
            HStack { onboardingForm }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 70)
        }
    }

    private var onboardingForm: some View {
        VStack(alignment: .center, spacing: 18) {
            switch screen {
            case .name:
                title("👋  Let’s get to know you", "What’s your name?")
                HStack { Field(placeholder: "First name", text: $firstName); Field(placeholder: "Last name", text: $lastName) }
                next(.study)
            case .study:
                title("🧑‍🎓  Are you a student?", "Let’s add some more context around your studies.")
                Text("What is your learning status?")
                choices(["School", "College", "Explorer"], selection: $selected)
                next(.storage)
            case .storage:
                title("💾  Storing your notes", "You can always change your selection in Settings > Sync.")
                Text("Storage location")
                choices(["On My iPad", "iCloud"], selection: $selectedStorage)
                Text("Store and sync your notes across your devices.").foregroundStyle(Theme.muted)
                next(.subjects)
            case .subjects:
                title("📚  Build a learning profile", "Which subject(s) do you study?")
                Field(placeholder: "Type here (comma separate subjects)", text: $subjectText)
                choices(["Engineering", "Medicine", "Law", "Business", "CS", "Humanities", "Social Sciences", "Arts", "Science"], selection: $selectedSubject)
                next(.theme)
            case .theme:
                title("🏡  Make yourself at home", "Pick a theme.")
                Text("Theme")
                choices(["Auto", "Light", "Dark"], selection: $selectedTheme)
                next(.space)
            case .space:
                title("🍎  Create your first space", "Use spaces to organise different parts of your life.")
                Text("Space Name"); Field(placeholder: "Space name", text: $space); next(.folder, action: createSpace)
            case .folder:
                title("📁  Create your first folder", "This will be put in your first space.")
                Text("Folder name"); Field(placeholder: "Folder name", text: $folder); next(.home, action: createFolder)
            default: EmptyView()
            }
            Spacer()
        }
        .frame(maxWidth: 500, alignment: .center)
    }

    private var home: some View {
        HStack(spacing: 0) {
            sidebar
            VStack { topbar("Home"); Spacer(); Image(systemName: "sparkles").font(.system(size: 30)); Text("Good evening, \(firstName.isEmpty ? "Student" : firstName)").font(.system(size: 30, weight: .semibold)); HStack(spacing: 12) { quick("square.and.pencil", "New Canvas", .blue) { createCanvas() }; quick("books.vertical", "New Notebook", .green) { createNotebook() }; quick("doc.badge.plus", "Import PDF", .orange) {} }.padding(.top, 24); if !canvases.isEmpty { Text("Recent").font(.headline).padding(.top, 28); ForEach(canvases, id: \.self) { Text($0).foregroundStyle(Theme.muted) } }; Spacer() }.padding(.horizontal, 38).frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var folderView: some View {
        if folder.isEmpty {
            spaceView
        } else {
            folderDetailView
        }
    }

    private var spaceView: some View {
        HStack(spacing: 0) {
            sidebar
            VStack(alignment: .leading, spacing: 20) {
                breadcrumb

                Text(space.isEmpty ? "My Space" : space)
                    .font(.system(size: 34, weight: .semibold))

                HStack(spacing: 18) {
                    Label("All Items", systemImage: "square.grid.2x2")
                    Spacer()
                    Button {
                        beginCollectionCreation(.folder)
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                    .buttonStyle(PrimaryButton())
                    Button {
                        showSpaceMenu.toggle()
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(SmallButton())
                }

                Divider().overlay(Theme.line)

                let visibleFolders = folders.filter { folderSpaces[$0] == space }
                if visibleFolders.isEmpty {
                    Spacer()
                    Text("This space is empty")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(50)
                    Spacer()
                } else {
                    folderGrid(visibleFolders)
                    Spacer()
                }
            }
            .padding(.horizontal, 38)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                if showSpaceMenu {
                    spaceMenu
                        .padding(.top, 108)
                        .padding(.trailing, 38)
                }
            }
        }
        .alert("Edit Space", isPresented: $showEditSpaceAlert) {
            TextField("Space name", text: $editingSpaceName)
            Button("Cancel", role: .cancel) {}
            Button("Save") { renameCurrentSpace() }
        } message: {
            Text("Change the name of this space.")
        }
    }

    private var folderDetailView: some View {
        HStack(spacing: 0) {
            sidebar
            VStack(alignment: .leading, spacing: 20) {
                breadcrumb

                Text(folder)
                    .font(.system(size: 34, weight: .semibold))

                HStack(spacing: 18) {
                    folderTab("All Items", .all, "square.grid.2x2")
                    folderTab("Folders", .folders, "folder")
                    folderTab("Canvases", .canvases, "square.and.pencil")
                    folderTab("Notebooks", .notebooks, "books.vertical")
                    folderTab("PDFs", .pdfs, "doc")
                    Spacer()
                    Button {
                        showFolderNewMenu.toggle()
                        showFolderMenu = false
                    } label: {
                        Label("New", systemImage: "plus")
                    }
                    .buttonStyle(PrimaryButton())
                    Button {
                        showFolderMenu.toggle()
                        showFolderNewMenu = false
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(SmallButton())
                }

                Divider().overlay(Theme.line)

                folderItemsContent
                Spacer()
            }
            .padding(.horizontal, 38)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                if showFolderNewMenu {
                    folderNewMenu
                        .padding(.top, 108)
                        .padding(.trailing, 88)
                }
                if showFolderMenu {
                    folderMenu
                        .padding(.top, 108)
                        .padding(.trailing, 38)
                }
            }
        }
        .alert("Edit Folder", isPresented: $showEditFolderAlert) {
            TextField("Folder name", text: $editingFolderName)
            Button("Cancel", role: .cancel) {}
            Button("Save") { renameCurrentFolder() }
        } message: {
            Text("Change the name of this folder.")
        }
    }

    private var folderItemsContent: some View {
        let items = folderItems
        return Group {
            if items.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "folder")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.muted)
                        .padding(16)
                        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                    Text("This folder is empty")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Create a folder or start a new canvas to begin working here.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 18)], spacing: 18) {
                    ForEach(items, id: \.self) { item in
                        folderItemTile(item)
                    }
                }
            }
        }
    }

    private var folderItems: [String] {
        let matching = documentFolders.filter { $0.value == folder }.map(\.key)
        switch folderItemTab {
        case .all: return matching
        case .folders: return []
        case .canvases: return matching.filter { documentTypes[$0] == .canvas }
        case .notebooks: return matching.filter { documentTypes[$0] == .notebook }
        case .pdfs: return matching.filter { documentTypes[$0] == .pdf }
        }
    }

    private func folderTab(_ title: String, _ tab: FolderItemTab, _ icon: String) -> some View {
        Button {
            folderItemTab = tab
        } label: {
            Label(title, systemImage: icon)
                .foregroundStyle(folderItemTab == tab ? .white : Theme.muted)
        }
        .buttonStyle(.plain)
    }

    private func folderItemTile(_ name: String) -> some View {
        Button {
            if isSelectingItems {
                if selectedItems.contains(name) { selectedItems.remove(name) }
                else { selectedItems.insert(name) }
            } else {
                activeDocumentName = name
                activeDocumentType = documentTypes[name]
                if activeDocumentType == .notebook {
                    notebookPageIndex[name] = 1
                }
                screen = .canvas
            }
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Theme.panel)
                    .frame(height: 90)
                    .overlay {
                        Image(systemName: itemIcon(for: documentTypes[name]))
                            .font(.system(size: 26))
                            .foregroundStyle(itemColor(for: documentTypes[name]))
                    }
                    .overlay {
                        if selectedItems.contains(name) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                .padding(8)
                        }
                    }
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                Text(itemTypeTitle(documentTypes[name]))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func folderGrid(_ visibleFolders: [String]) -> some View {
        switch folderViewMode {
        case .large:
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 28)], spacing: 28) {
                ForEach(visibleFolders, id: \.self) { folderTile($0, size: 150) }
            }
        case .medium:
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 22)], spacing: 22) {
                ForEach(visibleFolders, id: \.self) { folderTile($0, size: 108) }
            }
        case .small:
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 16)], spacing: 16) {
                ForEach(visibleFolders, id: \.self) { folderTile($0, size: 70) }
            }
        }
    }

    private func folderTile(_ name: String, size: CGFloat) -> some View {
        Button {
            if isSelectingFolders {
                if selectedFolders.contains(name) {
                    selectedFolders.remove(name)
                } else {
                    selectedFolders.insert(name)
                }
            } else {
                folder = name
                screen = .folderView
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                BlueFolderImage(width: size, height: size * 0.68)
                    .overlay {
                        if selectedFolders.contains(name) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                        }
                    }
                Text(name)
                    .font(.system(size: folderViewMode == .small ? 12 : 15, weight: .medium))
                    .lineLimit(1)
                Text("0 items")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            }
        }
        .buttonStyle(.plain)
    }

    private var spaceMenu: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("View as")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
            viewMenuItem("Large tiles", .large)
            viewMenuItem("Medium", .medium)
            viewMenuItem("Small", .small)
            Divider().overlay(Theme.line)
            Button {
                isSelectingFolders = true
                showSpaceMenu = false
            } label: {
                Label("Select", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .buttonStyle(.plain)
            Button {
                editingSpaceName = space
                showEditSpaceAlert = true
                showSpaceMenu = false
            } label: {
                Label("Edit space", systemImage: "pencil")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .buttonStyle(.plain)
            Button(role: .destructive) {
                deleteCurrentSpace()
            } label: {
                Label("Delete space", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .frame(width: 220)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
    }

    private var folderNewMenu: some View {
        VStack(alignment: .leading, spacing: 2) {
            menuItem("square.and.pencil", "New Canvas") {
                beginDocumentCreation(in: folder, type: .canvas)
            }
            menuItem("books.vertical", "New Notebook") {
                beginDocumentCreation(in: folder, type: .notebook)
            }
            menuItem("doc.badge.plus", "Import PDF") {
                beginDocumentCreation(in: folder, type: .pdf)
            }
            Divider().overlay(Theme.line)
            menuItem("folder", "Create folder") {
                showFolderNewMenu = false
                beginCollectionCreation(.folder)
            }
        }
        .padding(8)
        .frame(width: 210)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
    }

    private var folderMenu: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("View as")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
            viewMenuItem("Large tiles", .large)
            viewMenuItem("Medium", .medium)
            viewMenuItem("Small", .small)
            Divider().overlay(Theme.line)
            Button {
                editingFolderName = folder
                showEditFolderAlert = true
                showFolderMenu = false
            } label: {
                Label("Edit folder", systemImage: "pencil")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .buttonStyle(.plain)
            Button {
                if pinnedFolders.contains(folder) { pinnedFolders.remove(folder) }
                else { pinnedFolders.insert(folder) }
                showFolderMenu = false
            } label: {
                Label(pinnedFolders.contains(folder) ? "Unpin folder" : "Pin folder", systemImage: "pin")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .buttonStyle(.plain)
            Button {
                isSelectingItems = true
                showFolderMenu = false
            } label: {
                Label("Select", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .frame(width: 210)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
    }

    private func itemIcon(for type: NewDocumentType?) -> String {
        switch type {
        case .canvas: return "square.and.pencil"
        case .notebook: return "books.vertical"
        case .pdf: return "doc"
        case nil: return "doc"
        }
    }

    private func itemColor(for type: NewDocumentType?) -> Color {
        switch type {
        case .canvas: return .blue
        case .notebook: return .green
        case .pdf: return .orange
        case nil: return Theme.muted
        }
    }

    private func itemTypeTitle(_ type: NewDocumentType?) -> String {
        switch type {
        case .canvas: return "Canvas"
        case .notebook: return "Notebook"
        case .pdf: return "PDF"
        case nil: return "Item"
        }
    }

    private func viewMenuItem(_ title: String, _ mode: FolderViewMode) -> some View {
        Button {
            folderViewMode = mode
            showSpaceMenu = false
        } label: {
            HStack {
                Text(title)
                Spacer()
                if folderViewMode == mode { Image(systemName: "checkmark") }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .buttonStyle(.plain)
    }

    private var canvas: some View {
        GeometryReader { geo in
            ZStack {
                canvasBackdrop
                if activeDocumentType == .notebook {
                    notebookSurface(in: geo)
                } else if activeDocumentType == .pdf, let data = pdfDocuments[activeDocumentName] {
                    PDFDocumentSurface(data: data, pageIndex: currentPageIndex)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    InfiniteGrid(offset: canvasOffset, scale: canvasScale)

                    PencilCanvasPage(
                        drawingData: $canvasDrawingData,
                        tool: pencilTool,
                        isDrawingEnabled: activeTool == .pen || activeTool == .highlighter || activeTool == .eraser,
                        onChange: { canvasDrawingData = $0 }
                    )
                    .frame(width: canvasWorldSize.width, height: canvasWorldSize.height)
                    .scaleEffect(canvasScale, anchor: .center)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .offset(canvasOffset)
                    .allowsHitTesting(activeTool == .pen || activeTool == .highlighter || activeTool == .eraser)
                }

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(canvasPanGesture)
                    .allowsHitTesting(activeTool == .hand)

                Color.clear
                    .contentShape(Rectangle())
                    .gesture(lassoGesture)
                    .allowsHitTesting(activeTool == .lasso)

                if let lassoRect = lassoRectForDisplay {
                    Rectangle()
                        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .background(Color.yellow.opacity(0.08))
                        .frame(width: lassoRect.width, height: lassoRect.height)
                        .position(x: lassoRect.midX, y: lassoRect.midY)
                        .allowsHitTesting(false)
                }

                canvasHeader
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 16)
                    .padding(.horizontal, 18)

                if showDocumentSidebar && (activeDocumentType == .notebook || activeDocumentType == .pdf) {
                    documentSidebar
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                if showWebSidebar {
                    webSearchSidebar
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }

                if showWidgetPicker {
                    widgetPicker
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(.leading, 18)
                        .padding(.bottom, 18)
                }

                ForEach(Array(placedWidgets.enumerated()), id: \.offset) { index, widget in
                    widgetTile(widget, index: index)
                        .offset(widgetOffsets[index] ?? CGSize(width: 24 + CGFloat(index % 3) * 150, height: 120 + CGFloat(index / 3) * 110))
                }

                if let activeWebWidget {
                    webWidgetWindow(activeWebWidget)
                }

                VStack {
                    Spacer()
                    HStack(alignment: .bottom, spacing: 8) {
                        if showColorRail {
                            colorRail(horizontal: false)
                        }
                        toolRail(horizontal: false)
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 18)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .clipped()
            .simultaneousGesture(zoomGesture)
            .simultaneousGesture(notebookPageSwipe)
            .onAppear { }
        }
    }

    private var canvasBackdrop: some View {
        ZStack {
            Theme.background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08).opacity(0.55),
                    Theme.background,
                    Color(red: 0.02, green: 0.08, blue: 0.07).opacity(0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .allowsHitTesting(false)
        }
    }

    private var canvasHeader: some View {
        HStack(spacing: 10) {
            canvasBackButton
            VStack(alignment: .leading, spacing: 3) {
                Text(activeDocumentName.isEmpty ? "Untitled Canvas" : activeDocumentName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label(documentKindTitle, systemImage: itemIcon(for: activeDocumentType))
                    Text("\(Int(canvasScale * 100))%")
                    if activeDocumentType == .notebook || activeDocumentType == .pdf {
                        Text("Page \(currentPageIndex) of \(activeDocumentPageCount)")
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Theme.background.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line))

            Spacer()

            if activeDocumentType == .notebook || activeDocumentType == .pdf {
                HStack(spacing: 4) {
                    Button {
                        goToPage(currentPageIndex - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentPageIndex <= 1)

                    Button {
                        showDocumentSidebar.toggle()
                    } label: {
                        Image(systemName: showDocumentSidebar ? "sidebar.left" : "sidebar.left")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)

                    Button {
                        goToPage(currentPageIndex + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentPageIndex >= activeDocumentPageCount)
                }
                .padding(6)
                .background(Theme.background.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
            }
        }
    }

    private func notebookSurface(in geo: GeometryProxy) -> some View {
        let paperSize = CGSize(width: 794, height: 1123)
        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.22))
                .frame(width: paperSize.width + 36, height: paperSize.height + 42)
                .offset(y: 10)

            RuledNotebookBackground()
                .frame(width: paperSize.width, height: paperSize.height)

            PencilCanvasPage(
                drawingData: notebookDrawingBinding(),
                tool: pencilTool,
                isDrawingEnabled: activeTool == .pen || activeTool == .highlighter || activeTool == .eraser,
                onChange: { data in
                    notebookDrawings[activeDocumentName, default: [:]][notebookPageIndex[activeDocumentName, default: 1]] = data
                }
            )
            .frame(width: paperSize.width, height: paperSize.height)

            VStack {
                HStack {
                    Text(activeDocumentName.isEmpty ? "Notebook" : activeDocumentName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.48))
                    Spacer()
                    Text("\(currentPageIndex)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.36))
                }
                .padding(.horizontal, 28)
                .padding(.top, 22)
                Spacer()
            }
        }
        .frame(width: paperSize.width, height: paperSize.height)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.36), radius: 28, y: 16)
        .scaleEffect(canvasScale, anchor: .center)
        .position(x: geo.size.width / 2, y: geo.size.height / 2)
        .offset(canvasOffset)
        .allowsHitTesting(activeTool == .pen || activeTool == .highlighter || activeTool == .eraser)
    }

    private var notebookPageSwipe: some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                guard activeDocumentType == .notebook,
                      abs(value.translation.width) > abs(value.translation.height),
                      abs(value.translation.width) > 50 else { return }
                let current = notebookPageIndex[activeDocumentName, default: 1]
                let count = documentPageCounts[activeDocumentName, default: 1]
                if value.translation.width < 0, current < count {
                    notebookPageIndex[activeDocumentName] = current + 1
                } else if value.translation.width > 0, current > 1 {
                    notebookPageIndex[activeDocumentName] = current - 1
                }
            }
    }

    private var lassoRectForDisplay: CGRect? {
        if let start = lassoStart, let current = lassoCurrent {
            return CGRect(
                x: min(start.x, current.x),
                y: min(start.y, current.y),
                width: abs(current.x - start.x),
                height: abs(current.y - start.y)
            )
        }
        return selectedLassoRect
    }

    private var lassoGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if lassoStart == nil {
                    lassoStart = value.startLocation
                }
                lassoCurrent = value.location
            }
            .onEnded { value in
                guard let start = lassoStart else { return }
                selectedLassoRect = CGRect(
                    x: min(start.x, value.location.x),
                    y: min(start.y, value.location.y),
                    width: abs(value.location.x - start.x),
                    height: abs(value.location.y - start.y)
                )
                lassoStart = nil
                lassoCurrent = nil
                activeTool = .hand
            }
    }

    private func notebookDrawingBinding() -> Binding<Data?> {
        Binding(
            get: {
                notebookDrawings[activeDocumentName]?[notebookPageIndex[activeDocumentName, default: 1]]
            },
            set: { data in
                if let data {
                    notebookDrawings[activeDocumentName, default: [:]][notebookPageIndex[activeDocumentName, default: 1]] = data
                }
            }
        )
    }

    private var canvasPanGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard activeTool == .hand else { return }
                let delta = CGSize(
                    width: value.translation.width - canvasPanAccumulation.width,
                    height: value.translation.height - canvasPanAccumulation.height
                )
                canvasPanAccumulation = value.translation
                if var selectedLassoRect {
                    selectedLassoRect = selectedLassoRect.offsetBy(dx: delta.width, dy: delta.height)
                    if let data = canvasDrawingData,
                       let drawing = try? PKDrawing(data: data) {
                        canvasDrawingData = drawing
                            .transformed(using: CGAffineTransform(translationX: delta.width, y: delta.height))
                            .dataRepresentation()
                    }
                } else {
                    canvasOffset.width += delta.width
                    canvasOffset.height += delta.height
                }
            }
            .onEnded { _ in
                canvasPanAccumulation = .zero
            }
    }

    private func toolRailDrag(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                let start = toolRailDragStart ?? (toolRailPosition ?? CGPoint(x: size.width - 112, y: size.height / 2))
                toolRailDragStart = start
                toolRailPosition = CGPoint(
                    x: min(max(start.x + value.translation.width, 112), size.width - 112),
                    y: min(max(start.y + value.translation.height, 100), size.height - 100)
                )
            }
            .onEnded { value in
                let currentY = toolRailPosition?.y ?? size.height / 2
                if currentY < 130 || currentY > size.height - 130 {
                    toolRailPosition = CGPoint(x: min(max(toolRailPosition?.x ?? size.width / 2, 180), size.width - 180), y: currentY < size.height / 2 ? 100 : size.height - 100)
                } else {
                    toolRailPosition = CGPoint(x: value.translation.width >= 0 ? size.width - 112 : 112, y: min(max(currentY, 120), size.height - 120))
                }
                toolRailDragStart = nil
            }
    }

    private func isToolbarHorizontal(in size: CGSize) -> Bool {
        guard let position = toolRailPosition else { return false }
        return position.y < 130 || position.y > size.height - 130
    }

    private func isToolbarOnLeft(in size: CGSize) -> Bool {
        guard let position = toolRailPosition else { return false }
        return position.x < size.width / 2
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if canvasPinchStart == nil { canvasPinchStart = canvasScale }
                canvasScale = min(3, max(0.35, (canvasPinchStart ?? 1) * value))
            }
            .onEnded { _ in
                canvasPinchStart = nil
            }
    }

    private var breadcrumb: some View {
        HStack(spacing: 8) {
            Button {
                folder = ""
                activeDocumentName = ""
                screen = .folderView
            } label: {
                Label(space.isEmpty ? "My Space" : space, systemImage: "shippingbox")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.muted)

            if !folder.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                Button {
                    activeDocumentName = ""
                    screen = .folderView
                } label: {
                    Label(folder, systemImage: "folder.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(activeDocumentName.isEmpty ? .white : Theme.muted)
            }

            if !activeDocumentName.isEmpty {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                Text(activeDocumentName)
                    .lineLimit(1)
            }
        }
        .padding(.top, 24)
    }

    private var canvasBackButton: some View {
        Button {
            activeDocumentName = ""
            screen = .folderView
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 38, height: 38)
        }
        .buttonStyle(SmallButton())
    }

    private var documentSidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    screen = .home
                } label: {
                    Image(systemName: "house")
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(IconControlStyle())

                Spacer()

                sidebarModeButton("folder", .browser)
                sidebarModeButton("doc.text", .pages)
                sidebarModeButton("square.grid.2x2", .widgets)
            }
            .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(activeDocumentName.isEmpty ? documentKindTitle : activeDocumentName)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label(documentKindTitle, systemImage: itemIcon(for: activeDocumentType))
                    Text("\(activeDocumentPageCount) pages")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 16)

            switch documentSidebarMode {
            case .browser:
                browserSidebarContent
            case .pages:
                pagesSidebarContent
            case .widgets:
                widgetsSidebarContent
            }
        }
        .padding(18)
        .frame(width: 336, alignment: .topLeading)
        .background(Theme.background.opacity(0.96))
        .overlay(Rectangle().frame(width: 1).foregroundStyle(Theme.line), alignment: .trailing)
        .shadow(color: .black.opacity(0.18), radius: 18, x: 6)
    }

    private func sidebarModeButton(_ icon: String, _ mode: DocumentSidebarMode) -> some View {
        Button {
            documentSidebarMode = mode
        } label: {
            Image(systemName: icon)
                .frame(width: 38, height: 38)
        }
        .buttonStyle(IconControlStyle())
        .overlay {
            if documentSidebarMode == mode {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(.white.opacity(0.75))
            }
        }
    }

    private var browserSidebarContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            sidebarSearchField("Search documents", text: $documentSearchText, icon: "magnifyingglass")

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(searchSpaces, id: \.self) { spaceName in
                        VStack(alignment: .leading, spacing: 4) {
                            Button {
                                space = spaceName
                                folder = ""
                                screen = .folderView
                            } label: {
                                Label(spaceName, systemImage: "shippingbox")
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 7)
                            }
                            .buttonStyle(.plain)

                            ForEach(searchFolders.filter { folderSpaces[$0] == spaceName }, id: \.self) { folderName in
                                VStack(alignment: .leading, spacing: 2) {
                                    Button {
                                        space = spaceName
                                        folder = folderName
                                        screen = .folderView
                                    } label: {
                                        Label(folderName, systemImage: "folder.fill")
                                            .font(.system(size: 13, weight: .medium))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 5)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.leading, 18)

                                    ForEach(searchDocuments.filter { documentFolders[$0] == folderName }, id: \.self) { documentName in
                                        Button {
                                            space = spaceName
                                            folder = folderName
                                            activeDocumentName = documentName
                                            activeDocumentType = documentTypes[documentName]
                                            screen = .canvas
                                        } label: {
                                            Label(documentName, systemImage: itemIcon(for: documentTypes[documentName]))
                                                .font(.system(size: 12))
                                                .lineLimit(1)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.vertical, 5)
                                                .padding(.horizontal, 8)
                                                .background(activeDocumentName == documentName ? Theme.panel : .clear, in: RoundedRectangle(cornerRadius: 8))
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.leading, 38)
                                    }
                                }
                            }
                        }
                        .padding(10)
                        .background(Theme.panel.opacity(0.72), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line.opacity(0.65)))
                    }
                }
            }

            Divider().overlay(Theme.line)
            Button {
                showWidgetPicker.toggle()
            } label: {
                Label("AI Tutor", systemImage: "sparkles")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text("Pages")
                .font(.system(size: 13, weight: .semibold))
            pagePreview(index: 1)
            ForEach(2..<(documentPageCounts[activeDocumentName] ?? 1) + 1, id: \.self) { index in
                pagePreview(index: index)
            }
            Button {
                addPageToActiveDocument()
            } label: {
                Label("Add page", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            Button {
                isPickingPDF = true
            } label: {
                Label("Import page", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }

    private var pagesSidebarContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pages")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text("\(currentPageIndex)/\(activeDocumentPageCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.muted)
            }

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 10)], spacing: 12) {
                    pagePreview(index: 1)
                    ForEach(2..<(documentPageCounts[activeDocumentName] ?? 1) + 1, id: \.self) { index in
                        pagePreview(index: index)
                    }
                }
            }
            HStack(spacing: 10) {
                Button {
                    addPageToActiveDocument()
                } label: {
                    Label("Add", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(OutlineButton())
                Button {
                    isPickingPDF = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(OutlineButton())
            }
            .frame(maxWidth: .infinity)
            Button("Select") {
                isSelectingItems = true
            }
            .buttonStyle(OutlineButton())
        }
    }

    private var widgetsSidebarContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            sidebarSearchField("Search widgets", text: $documentSearchText, icon: "magnifyingglass")
            Button {
                showWidgetPicker = false
            } label: {
                Label("Unlock widgets", systemImage: "lock.open")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButton())
            ForEach(["Pomodoro", "To-Do List", "Calculator", "Research", "ChatGPT", "YouTube", "Graphing", "Wolfram Alpha", "Document", "Flashcards"], id: \.self) { widget in
                Button {
                    placedWidgets.append(widget)
                } label: {
                    HStack {
                        Label(widget, systemImage: widgetIcon(widget))
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(12)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line.opacity(0.7)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func pagePreview(index: Int) -> some View {
        Button {
            goToPage(index)
        } label: {
            let selected = currentPageIndex == index
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(activeDocumentType == .notebook ? Color.white.opacity(0.9) : Theme.panel)
                    .frame(height: 72)
                    .overlay {
                        if activeDocumentType == .notebook {
                            VStack(spacing: 7) {
                                ForEach(0..<5, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.blue.opacity(0.18))
                                        .frame(height: 1)
                                }
                            }
                            .padding(.horizontal, 10)
                        } else if activeDocumentType == .pdf,
                                  let data = pdfDocuments[activeDocumentName],
                                  let document = PDFDocument(data: data),
                                  let page = document.page(at: index - 1) {
                            PDFThumbnail(page: page)
                        } else {
                            Image(systemName: "doc").foregroundStyle(Theme.muted)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .padding(5)
                        }
                    }
                Text("Page \(index)")
                    .font(.system(size: 12, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? .white : Theme.muted)
            }
            .padding(8)
            .background(selected ? Color.white.opacity(0.12) : Theme.panel.opacity(0.55), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Color.white.opacity(0.55) : Theme.line.opacity(0.75)))
        }
        .buttonStyle(.plain)
    }

    private var widgetPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Widgets")
                .font(.system(size: 15, weight: .semibold))
            ForEach(["Pomodoro", "To-Do List", "Calculator", "Web Search", "ChatGPT", "YouTube", "Flashcards", "Graphing"], id: \.self) { widget in
                Button {
                    placedWidgets.append(widget)
                    showWidgetPicker = false
                } label: {
                    Label(widget, systemImage: widgetIcon(widget))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 190)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
    }

    private var webSearchSidebar: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Web Search", systemImage: "globe")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button {
                    showWebSidebar = false
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 6) {
                TextField("Search the web", text: $webSearchText)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                Button {
                    webSearchText = webSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
                } label: {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(IconControlStyle())
            }

            WebWidgetView(urlString: webSearchURL.absoluteString)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(14)
        .frame(width: 330)
        .frame(maxHeight: .infinity)
        .background(Theme.background.opacity(0.98))
        .overlay(Rectangle().frame(width: 1).foregroundStyle(Theme.line), alignment: .trailing)
    }

    private var webSearchURL: URL {
        let query = webSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query.isEmpty ? "study notes" : query)]
        return components?.url ?? URL(string: "https://www.google.com")!
    }

    private var activeDocumentPageCount: Int {
        max(1, documentPageCounts[activeDocumentName, default: 1])
    }

    private var currentPageIndex: Int {
        min(max(1, notebookPageIndex[activeDocumentName, default: 1]), activeDocumentPageCount)
    }

    private var documentKindTitle: String {
        switch activeDocumentType {
        case .canvas: return "Canvas"
        case .notebook: return "Notebook"
        case .pdf: return "PDF"
        case nil: return "Canvas"
        }
    }

    private func goToPage(_ index: Int) {
        guard activeDocumentType == .notebook || activeDocumentType == .pdf else { return }
        notebookPageIndex[activeDocumentName] = min(max(1, index), activeDocumentPageCount)
        canvasOffset = .zero
    }

    private func sidebarSearchField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.muted)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(11)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line.opacity(0.75)))
    }

    private var searchFolders: [String] {
        folders.filter { documentSearchText.isEmpty || $0.localizedCaseInsensitiveContains(documentSearchText) }
    }

    private var searchSpaces: [String] {
        spaces.filter { documentSearchText.isEmpty || $0.localizedCaseInsensitiveContains(documentSearchText) }
    }

    private var searchDocuments: [String] {
        documentFolders.keys.filter { name in
            documentSearchText.isEmpty || name.localizedCaseInsensitiveContains(documentSearchText)
        }.sorted()
    }

    private func widgetIcon(_ widget: String) -> String {
        switch widget {
        case "Pomodoro": return "timer"
        case "To-Do List": return "checkmark.square"
        case "Calculator": return "function"
        case "Web Search": return "globe"
        case "ChatGPT": return "bubble.left.and.bubble.right"
        case "YouTube": return "play.rectangle"
        case "Flashcards": return "rectangle.on.rectangle.angled"
        default: return "chart.xyaxis.line"
        }
    }

    private func widgetTile(_ widget: String, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            if widget == "Pomodoro" {
                InlinePomodoroWidget()
            } else if widget == "To-Do List" {
                InlineTodoWidget()
            } else if widget == "Calculator" {
                InlineCalculatorWidget()
            } else {
                Button {
                    if let webWidget = WebWidget(rawValue: widget) {
                        activeWebWidget = webWidget
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: widgetIcon(widget))
                        Text(widget)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(12)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line))
                }
                .buttonStyle(.plain)
            }

            Button {
                placedWidgets.remove(at: index)
                widgetOffsets = widgetOffsets.reduce(into: [:]) { result, entry in
                    if entry.key < index { result[entry.key] = entry.value }
                    if entry.key > index { result[entry.key - 1] = entry.value }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white, .black.opacity(0.7))
            }
            .buttonStyle(.plain)
            .padding(6)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .gesture(widgetDrag(index: index))
    }

    private func widgetDrag(index: Int) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                let start = widgetDragStart[index] ?? (widgetOffsets[index] ?? .zero)
                widgetDragStart[index] = start
                widgetOffsets[index] = CGSize(
                    width: start.width + value.translation.width,
                    height: start.height + value.translation.height
                )
            }
            .onEnded { _ in
                widgetDragStart[index] = nil
            }
    }

    private func webWidgetWindow(_ widget: WebWidget) -> some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Label(widget.rawValue, systemImage: widgetIcon(widget.rawValue))
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Button {
                        activeWebWidget = nil
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .background(Theme.background)

                WebWidgetView(urlString: widget.url.absoluteString)
            }
            .frame(width: 620, height: 520)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))
            .shadow(color: .black.opacity(0.4), radius: 24)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(.white.opacity(0.2)).frame(width: 28, height: 28)
                Text("\(firstName) \(lastName)")
                Spacer()
            }
            .padding(.bottom, 16)

            nav("house", "Home", true) { screen = .home }
            nav("point.3.connected.trianglepath.dotted", "AI Tutors") {}
            nav("rectangle.on.rectangle.angled", "Flashcards") {}

            if !pinnedFolders.isEmpty {
                Text("Pinned")
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 18)

                ForEach(folders.filter { pinnedFolders.contains($0) }, id: \.self) { item in
                    collectionNav("pin.fill", item, imageData: folderImages[item]) {
                        folder = item
                        screen = .folderView
                    }
                }
            }

            HStack {
                Text("Spaces")
                    .foregroundStyle(Theme.muted)
                Spacer()
                Button {
                    beginCollectionCreation(.space)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.muted)
            }
            .padding(.top, 18)

            ForEach(spaces, id: \.self) { item in
                collectionNav("shippingbox", item, imageData: spaceImages[item]) {
                    space = item
                    folder = ""
                    screen = .folderView
                }
            }

            Spacer()
            Button("＋  New Document") {
                beginDocumentCreation()
            }
            .buttonStyle(OutlineButton())
        }
        .padding(14)
        .frame(width: 270)
        .overlay(Rectangle().frame(width: 1).foregroundStyle(Theme.line), alignment: .trailing)
    }

    private var collectionCreationWindow: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(collectionCreationType == .folder ? "New Folder" : "New Space")
                        .font(.system(size: 22, weight: .semibold))
                    Spacer()
                    Button {
                        resetCollectionCreation()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }

                Group {
                    if let data = collectionImageData, let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        if collectionCreationType == .folder {
                            BlueFolderImage(width: 180, height: 122)
                        } else {
                            Image(systemName: "shippingbox")
                                .font(.system(size: 42))
                                .foregroundStyle(Theme.muted)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipped()
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line))

                PhotosPicker(selection: $selectedCollectionPhoto, matching: .images) {
                    Label("Add image", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(OutlineButton())

                TextField("Enter name", text: $collectionName)
                    .textFieldStyle(.plain)
                    .padding(13)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line))

                HStack {
                    Button("Cancel") {
                        resetCollectionCreation()
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button("Add") {
                        addCollection()
                    }
                    .buttonStyle(PrimaryButton())
                    .disabled(collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .frame(width: 420)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line))
            .shadow(color: .black.opacity(0.35), radius: 30)
        }
        .task(id: selectedCollectionPhoto) {
            guard let selectedCollectionPhoto,
                  let data = try? await selectedCollectionPhoto.loadTransferable(type: Data.self) else { return }
            collectionImageData = data
        }
    }

    private var newDocumentWindow: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("New Document")
                        .font(.system(size: 22, weight: .semibold))
                    Spacer()
                    Button {
                        resetDocumentCreation()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    documentChoice("square.and.pencil", "Canvas", .blue, selected: newDocumentType == .canvas) {
                        newDocumentType = .canvas
                        selectedPDFURL = nil
                    }
                    documentChoice("books.vertical", "Notebook", .green, selected: newDocumentType == .notebook) {
                        newDocumentType = .notebook
                        selectedPDFURL = nil
                    }
                    documentChoice("doc.badge.plus", "PDF", .orange, selected: newDocumentType == .pdf) {
                        newDocumentType = .pdf
                        isPickingPDF = true
                    }
                }

                if newDocumentType == .pdf {
                    Button {
                        isPickingPDF = true
                    } label: {
                        Label(selectedPDFURL?.lastPathComponent ?? "Choose PDF", systemImage: "doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(OutlineButton())
                }

                TextField("File name", text: $newDocumentName)
                    .textFieldStyle(.plain)
                    .padding(13)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line))

                Picker("Location", selection: $selectedDocumentFolder) {
                    Text("Unfiled").tag("Unfiled")
                    ForEach(folders, id: \.self) { item in
                        Text(item).tag(item)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Theme.panel, in: RoundedRectangle(cornerRadius: 10))

                Button {
                    addDocument()
                } label: {
                    Text("Add")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButton())
                .disabled(newDocumentType == nil || newDocumentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (newDocumentType == .pdf && selectedPDFURL == nil))
            }
            .padding(24)
            .frame(width: 460)
            .background(Theme.background, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line))
            .shadow(color: .black.opacity(0.35), radius: 30)
        }
    }

    private func documentChoice(_ icon: String, _ title: String, _ color: Color, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selected ? color.opacity(0.3) : Theme.panel, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? color : Theme.line))
        }
        .buttonStyle(.plain)
    }

    private func collectionNav(_ icon: String, _ text: String, imageData: Data?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                } else {
                    if icon == "folder.fill" || icon == "pin.fill" {
                        BlueFolderImage(width: 20, height: 16)
                    } else {
                        Image(systemName: icon)
                    }
                }
                Text(text)
                    .lineLimit(1)
                Spacer()
            }
            .padding(10)
        }
        .buttonStyle(.plain)
    }

    private func beginCollectionCreation(_ type: CollectionCreationType) {
        collectionCreationType = type
        collectionName = ""
        collectionImageData = nil
        selectedCollectionPhoto = nil
    }

    private func addCollection() {
        let name = collectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, let type = collectionCreationType else { return }

        switch type {
        case .folder:
            guard !folders.contains(name) else { return }
            folders.append(name)
            folderSpaces[name] = space.isEmpty ? (spaces.first ?? "") : space
            if let collectionImageData { folderImages[name] = collectionImageData }
        case .space:
            guard !spaces.contains(name) else { return }
            spaces.append(name)
            if let collectionImageData { spaceImages[name] = collectionImageData }
        }
        resetCollectionCreation()
    }

    private func resetCollectionCreation() {
        collectionCreationType = nil
        collectionName = ""
        collectionImageData = nil
        selectedCollectionPhoto = nil
    }

    private func beginDocumentCreation() {
        showNewDocumentWindow = true
        newDocumentType = nil
        newDocumentName = ""
        selectedDocumentFolder = folders.first ?? "Unfiled"
        selectedPDFURL = nil
        isPickingPDF = false
    }

    private func beginDocumentCreation(in folder: String, type: NewDocumentType) {
        beginDocumentCreation()
        selectedDocumentFolder = folder
        newDocumentType = type
        showFolderNewMenu = false
        if type == .pdf {
            isPickingPDF = true
        }
    }

    private func addDocument() {
        let name = newDocumentName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let type = newDocumentType, !name.isEmpty else { return }

        switch type {
        case .canvas, .pdf:
            canvases.append(name)
        case .notebook:
            notebooks.append(name)
        }
        documentFolders[name] = selectedDocumentFolder
        documentTypes[name] = type
        documentPageCounts[name] = 1
        notebookPageIndex[name] = 1
        notebookDrawings[name] = [1: PKDrawing().dataRepresentation()]
        if type == .pdf, let selectedPDFData {
            pdfDocuments[name] = selectedPDFData
            documentPageCounts[name] = PDFDocument(data: selectedPDFData)?.pageCount ?? 1
        }
        resetDocumentCreation()
    }

    private func addPageToActiveDocument() {
        guard !activeDocumentName.isEmpty else { return }
        documentPageCounts[activeDocumentName, default: 1] += 1
        let nextPage = documentPageCounts[activeDocumentName, default: 1]
        notebookPageIndex[activeDocumentName] = nextPage
        notebookDrawings[activeDocumentName, default: [:]][nextPage] = PKDrawing().dataRepresentation()
    }

    private func resetDocumentCreation() {
        showNewDocumentWindow = false
        newDocumentType = nil
        newDocumentName = ""
        selectedDocumentFolder = "Unfiled"
        selectedPDFURL = nil
        selectedPDFData = nil
        isPickingPDF = false
    }

    private func toolbarGroup(in size: CGSize) -> some View {
        let horizontal = isToolbarHorizontal(in: size)
        let onLeft = isToolbarOnLeft(in: size)

        return Group {
            if horizontal {
                HStack(spacing: 8) {
                    toolRail(horizontal: true)
                    if showColorRail { colorRail(horizontal: true) }
                }
            } else if onLeft {
                HStack(spacing: 8) {
                    toolRail(horizontal: false)
                    if showColorRail { colorRail(horizontal: false) }
                }
            } else {
                HStack(spacing: 8) {
                    if showColorRail { colorRail(horizontal: false) }
                    toolRail(horizontal: false)
                }
            }
        }
    }

    private func toolRail(horizontal: Bool) -> some View {
        Group {
            if horizontal {
                HStack(spacing: 6) { toolRailItems(horizontal: true) }
            } else {
                VStack(spacing: 6) { toolRailItems(horizontal: false) }
            }
        }
        .font(.system(size: 18))
        .padding(10)
        .background(Theme.background.opacity(0.94), in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(Theme.line.opacity(0.9)))
        .shadow(color: .black.opacity(0.34), radius: 18, y: 8)
    }

    @ViewBuilder
    private func toolRailItems(horizontal: Bool) -> some View {
        toolButton(.hand, "hand.draw")
        toolButton(.pen, "pencil.tip")
        toolButton(.highlighter, "highlighter")
        toolButton(.eraser, "eraser")
        toolButton(.lasso, "lasso")
        if horizontal {
            Divider().frame(height: 24)
        } else {
            Divider().frame(width: 24)
        }
        Button {
            showWidgetPicker.toggle()
        } label: {
            Image(systemName: "square.grid.2x2").frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)

        Button {
            showWebSidebar.toggle()
        } label: {
            Image(systemName: "globe").frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)

        if activeDocumentType == .notebook || activeDocumentType == .pdf {
            Button {
                showDocumentSidebar.toggle()
            } label: {
                Image(systemName: "sidebar.left").frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }

        Button {
            addPageToActiveDocument()
        } label: {
            Image(systemName: "plus.rectangle").frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)

        Image(systemName: "sparkles").frame(width: 38, height: 38)
    }

    private func colorRail(horizontal: Bool) -> some View {
        Group {
            if horizontal {
                HStack(spacing: 10) {
                    colorSwatches
                }
            } else {
                VStack(spacing: 10) {
                    colorSwatches
                }
            }
        }
        .padding(10)
        .background(Theme.background.opacity(0.94), in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(Theme.line.opacity(0.9)))
        .shadow(color: .black.opacity(0.34), radius: 18, y: 8)
    }

    private var colorSwatches: some View {
        Group {
            ForEach([Color.white, .yellow, .orange, .pink, .green, .cyan, .purple], id: \.self) { color in
                Button {
                    penColor = color
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if penColor == color {
                                Circle().stroke(.white, lineWidth: 2.5)
                            }
                        }
                        .overlay(Circle().stroke(Color.black.opacity(0.16)))
                }
                .buttonStyle(.plain)
            }

        }
    }
    private var menu: some View { Group { if showMenu { VStack(alignment: .leading) { menuItem("square.and.pencil", "New Canvas") { createCanvas() }; menuItem("books.vertical", "New Notebook") { createNotebook() }; menuItem("doc.badge.plus", "Import PDF") {}; Divider(); menuItem("folder", "Create folder") { createFolder() } }.padding(10).frame(width: 190).background(Theme.background, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line)).padding(.top, 68).padding(.trailing, 22) } } }
    private var brand: some View { HStack { Image(systemName: "sparkles"); Text("amphi").font(.system(size: 18, weight: .bold)) } }
    private var progress: some View { HStack { ForEach(0..<3) { _ in Capsule().fill(.white).frame(width: 46, height: 6) } } }
    private var cardStack: some View { ZStack { card("brain.head.profile", "Deep Thinker", .purple, -40, -70); card("speedometer", "Guided", .teal, 30, 45); card("rocket.fill", "Speed Run", .orange, 110, -55) }.frame(maxHeight: .infinity).background(Theme.background, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line)) }
    private func title(_ a: String, _ b: String) -> some View { VStack(alignment: .center, spacing: 8) { Text(a).font(.system(size: 28, weight: .semibold)); Text(b).foregroundStyle(Theme.muted).multilineTextAlignment(.center) } }
    private func next(_ target: Screen, action: @escaping () -> Void = {}) -> some View { Button("Next") { action(); screen = target }.buttonStyle(PrimaryButton()).frame(maxWidth: .infinity, alignment: .center) }
    private func choices(_ values: [String], selection: Binding<String>) -> some View { LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(3, values.count)), spacing: 10) { ForEach(values, id: \.self) { value in Button(value) { selection.wrappedValue = value }.buttonStyle(ChoiceButton(selected: selection.wrappedValue == value)) } } }
    private func previewCard(_ a: String, _ b: String, _ c: Color) -> some View { VStack(alignment: .leading) { Text("■  \(a)").foregroundStyle(c); Text(b) }.padding(18).frame(width: 180, height: 96).background(Theme.panel, in: RoundedRectangle(cornerRadius: 12)) }
    private func card(_ icon: String, _ text: String, _ color: Color, _ x: CGFloat, _ y: CGFloat) -> some View { VStack { Image(systemName: icon).foregroundStyle(color); Text(text).fontWeight(.semibold); Text("Learn in your own way.").font(.system(size: 11)).foregroundStyle(Theme.muted) }.multilineTextAlignment(.center).padding(18).frame(width: 170, height: 150).background(Theme.panel, in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.line)).offset(x: x, y: y) }
    private func nav(_ icon: String, _ text: String, _ selected: Bool = false, _ action: @escaping () -> Void) -> some View { Button(action: action) { Label(text, systemImage: icon).frame(maxWidth: .infinity, alignment: .leading).padding(10).background(selected ? Theme.panel : .clear, in: RoundedRectangle(cornerRadius: 9)) }.buttonStyle(.plain) }
    private func quick(_ icon: String, _ text: String, _ color: Color, _ action: @escaping () -> Void) -> some View { Button(action: action) { Label(text, systemImage: icon).frame(maxWidth: .infinity).padding(24).background(Theme.panel, in: RoundedRectangle(cornerRadius: 13)).overlay(alignment: .leading) { Capsule().fill(color).frame(width: 4, height: 30) } }.buttonStyle(.plain) }
    private func topbar(_ text: String) -> some View { HStack { Text(text).foregroundStyle(Theme.muted); Spacer(); Image(systemName: "magnifyingglass") }.padding(.top, 24) }
    private func menuItem(_ icon: String, _ text: String, _ action: @escaping () -> Void) -> some View { Button(action: action) { Label(text, systemImage: icon).frame(maxWidth: .infinity, alignment: .leading).padding(8) }.buttonStyle(.plain) }

    private var pencilTool: PKTool {
        switch activeTool {
        case .highlighter:
            return PKInkingTool(.marker, color: UIColor(penColor.opacity(0.45)), width: penWidth * 3)
        case .eraser:
            return PKEraserTool(.vector)
        default:
            return PKInkingTool(.pen, color: UIColor(penColor), width: penWidth)
        }
    }

    private func toolButton(_ tool: CanvasTool, _ icon: String) -> some View {
        Button {
            if (tool == .pen || tool == .highlighter) && activeTool == tool {
                showColorRail.toggle()
            } else {
                activeTool = tool
                showColorRail = tool == .pen || tool == .highlighter
                showPenOptions = false
            }
        } label: {
            Image(systemName: icon)
                .frame(width: 38, height: 38)
                .foregroundStyle(activeTool == tool ? Color.black : .white.opacity(0.86))
                .background(activeTool == tool ? .white : Theme.panel.opacity(0.35), in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(activeTool == tool ? .white : Theme.line.opacity(0.5)))
        }
        .buttonStyle(.plain)
    }

    private var penOptions: some View {
        HStack(spacing: 8) {
            ForEach([Color.white, .blue, .red, .orange, .yellow, .black], id: \.self) { color in
                Button {
                    penColor = color
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Theme.line))
                }
                .buttonStyle(.plain)
            }
            Slider(value: $penWidth, in: 1...10)
                .frame(width: 72)
        }
        .padding(10)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
    }

    private func createSpace() {
        let value = space.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty && !spaces.contains(value) {
            spaces.append(value)
            if spaces.count == 1 { space = value }
        }
    }

    private func createFolder() {
        let value = folder.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty && !folders.contains(value) {
            folders.append(value)
            folderSpaces[value] = space.isEmpty ? (spaces.first ?? "") : space
        }
        showMenu = false
    }

    private func renameCurrentSpace() {
        let newName = editingSpaceName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty, !spaces.contains(newName), !space.isEmpty else { return }

        for index in folders.indices where folderSpaces[folders[index]] == space {
            folderSpaces[folders[index]] = newName
        }
        if let image = spaceImages.removeValue(forKey: space) {
            spaceImages[newName] = image
        }
        if let index = spaces.firstIndex(of: space) {
            spaces[index] = newName
        }
        space = newName
    }

    private func renameCurrentFolder() {
        let newName = editingFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty, !folders.contains(newName), !folder.isEmpty else { return }

        if let index = folders.firstIndex(of: folder) {
            folders[index] = newName
        }
        if let owner = folderSpaces.removeValue(forKey: folder) {
            folderSpaces[newName] = owner
        }
        if let image = folderImages.removeValue(forKey: folder) {
            folderImages[newName] = image
        }
        if pinnedFolders.remove(folder) != nil {
            pinnedFolders.insert(newName)
        }
        folder = newName
    }

    private func deleteCurrentSpace() {
        guard !space.isEmpty else { return }
        let deletedSpace = space
        let deletedFolders = folders.filter { folderSpaces[$0] == deletedSpace }
        folders.removeAll { folderSpaces[$0] == deletedSpace }
        deletedFolders.forEach {
            folderSpaces.removeValue(forKey: $0)
            folderImages.removeValue(forKey: $0)
            pinnedFolders.remove($0)
        }
        spaces.removeAll { $0 == deletedSpace }
        spaceImages.removeValue(forKey: deletedSpace)
        space = spaces.first ?? ""
        folder = ""
        showSpaceMenu = false
        screen = .home
    }

    private func createCanvas() {
        let title = "Canvas \(canvases.count + 1)"
        canvases.append(title)
        canvasDrawingData = PKDrawing().dataRepresentation()
        showMenu = false
        screen = .canvas
    }

    private func createNotebook() {
        notebooks.append("Notebook \(notebooks.count + 1)")
        showMenu = false
    }
}

enum Screen { case welcome, verification, name, study, storage, subjects, theme, space, folder, home, folderView, canvas }
private enum CollectionCreationType { case folder, space }
private enum NewDocumentType { case canvas, notebook, pdf }
private enum FolderViewMode { case large, medium, small }
private enum FolderItemTab { case all, folders, canvases, notebooks, pdfs }
private enum DocumentSidebarMode { case browser, pages, widgets }
private enum WebWidget: String {
    case chatGPT = "ChatGPT"
    case youtube = "YouTube"

    var url: URL {
        switch self {
        case .chatGPT: URL(string: "https://chatgpt.com")!
        case .youtube: URL(string: "https://www.youtube.com")!
        }
    }
}
private enum Theme { static let background = Color(red: 0.045, green: 0.045, blue: 0.05); static let panel = Color.white.opacity(0.055); static let muted = Color.white.opacity(0.48); static let line = Color.white.opacity(0.13) }
private struct Field: View { let placeholder: String; @Binding var text: String; var body: some View { TextField(placeholder, text: $text).textFieldStyle(.plain).padding(13).background(Theme.panel, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line)) } }
private struct PrimaryButton: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.foregroundStyle(.black).padding(.horizontal, 18).padding(.vertical, 12).background(.white, in: RoundedRectangle(cornerRadius: 9)).opacity(configuration.isPressed ? 0.7 : 1) } }
private struct OutlineButton: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.foregroundStyle(.white.opacity(0.85)).frame(maxWidth: .infinity).padding(12).background(Theme.panel, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line)).opacity(configuration.isPressed ? 0.7 : 1) } }
private struct AuthProviderButton: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.font(.system(size: 15, weight: .medium)).foregroundStyle(.white.opacity(0.88)).frame(maxWidth: .infinity).padding(.vertical, 12).background(Theme.panel, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.line)).opacity(configuration.isPressed ? 0.55 : 1) } }
private struct SmallButton: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.padding(.horizontal, 15).padding(.vertical, 9).background(Theme.panel, in: RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line)) } }
private struct ChoiceButton: ButtonStyle { let selected: Bool; func makeBody(configuration: Configuration) -> some View { configuration.label.frame(maxWidth: .infinity).padding(20).background(selected ? Theme.panel : .clear, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? .white : Theme.line)) } }
private struct BlueFolderImage: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: max(4, height * 0.16), style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.08, green: 0.52, blue: 1), Color(red: 0.02, green: 0.25, blue: 0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)

            RoundedRectangle(cornerRadius: max(3, height * 0.14), style: .continuous)
                .fill(Color(red: 0.05, green: 0.42, blue: 0.94))
                .frame(width: width * 0.48, height: height * 0.24)
                .offset(x: width * 0.08, y: -height * 0.08)
        }
        .frame(width: width, height: height)
        .shadow(color: .blue.opacity(0.28), radius: max(2, height * 0.08), y: max(1, height * 0.04))
    }
}
private struct GoogleMark: View { var body: some View { Text("G").font(.system(size: 21, weight: .bold)).foregroundStyle(LinearGradient(colors: [.blue, .green, .yellow, .red], startPoint: .topLeading, endPoint: .bottomTrailing)) } }
private struct AmphiDotGrid: View { var body: some View { Canvas { context, size in for x in stride(from: 8, through: size.width, by: 52) { for y in stride(from: 8, through: size.height, by: 52) { context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 4, height: 4)), with: .color(.white.opacity(0.2))) } } } } }
private struct InfiniteGrid: View {
    let offset: CGSize
    let scale: CGFloat
    private let spacing: CGFloat = 32

    var body: some View {
        Canvas { context, size in
            let scaledSpacing = spacing * scale
            let startX = ((offset.width.truncatingRemainder(dividingBy: scaledSpacing)) + scaledSpacing).truncatingRemainder(dividingBy: scaledSpacing)
            let startY = ((offset.height.truncatingRemainder(dividingBy: scaledSpacing)) + scaledSpacing).truncatingRemainder(dividingBy: scaledSpacing)

            for x in stride(from: startX, through: size.width, by: scaledSpacing) {
                for y in stride(from: startY, through: size.height, by: scaledSpacing) {
                    let dot = Path(ellipseIn: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3))
                    context.fill(dot, with: .color(.white.opacity(0.16)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct RuledNotebookBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 32
            for y in stride(from: 24, through: size.height, by: spacing) {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(line, with: .color(.blue.opacity(0.18)), lineWidth: 1)
            }
            var margin = Path()
            margin.move(to: CGPoint(x: 72, y: 0))
            margin.addLine(to: CGPoint(x: 72, y: size.height))
            context.stroke(margin, with: .color(.red.opacity(0.2)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

private struct PDFDocumentSurface: UIViewRepresentable {
    let data: Data
    let pageIndex: Int

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.displaysPageBreaks = true
        view.pageBreakMargins = UIEdgeInsets(top: 18, left: 0, bottom: 18, right: 0)
        view.backgroundColor = UIColor(red: 0.045, green: 0.045, blue: 0.05, alpha: 1)
        view.document = PDFDocument(data: data)
        goToSelectedPage(in: view)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.dataRepresentation() != data {
            uiView.document = PDFDocument(data: data)
        }
        uiView.autoScales = true
        goToSelectedPage(in: uiView)
    }

    private func goToSelectedPage(in view: PDFView) {
        guard let page = view.document?.page(at: max(0, pageIndex - 1)),
              view.currentPage !== page else { return }
        view.go(to: page)
    }
}

private struct PDFThumbnail: UIViewRepresentable {
    let page: PDFPage

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .white
        return view
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = page.thumbnail(of: CGSize(width: 90, height: 70), for: .cropBox)
    }
}

private struct InlinePomodoroWidget: View {
    @State private var remaining = 30 * 60
    @State private var isRunning = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Pomodoro", systemImage: "timer")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("30 min")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
            }
            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
            HStack(spacing: 8) {
                Button(isRunning ? "Pause" : "Start") {
                    isRunning.toggle()
                }
                .buttonStyle(PrimaryButton())
                Button("Reset") {
                    isRunning = false
                    remaining = 30 * 60
                }
                .buttonStyle(SmallButton())
            }
        }
        .padding(12)
        .frame(width: 220)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
        .onReceive(timer) { _ in
            guard isRunning, remaining > 0 else {
                if remaining == 0 { isRunning = false }
                return
            }
            remaining -= 1
        }
    }
}

private struct InlineTodoWidget: View {
    @State private var draft = ""
    @State private var tasks: [(title: String, isDone: Bool)] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("To-Do List", systemImage: "checkmark.square")
                .font(.system(size: 13, weight: .semibold))

            HStack(spacing: 6) {
                TextField("Add task", text: $draft)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Theme.panel, in: RoundedRectangle(cornerRadius: 8))
                Button {
                    let title = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !title.isEmpty else { return }
                    tasks.append((title, false))
                    draft = ""
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(IconControlStyle())
            }

            ForEach(tasks.indices, id: \.self) { index in
                Button {
                    tasks[index].isDone.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tasks[index].isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(tasks[index].isDone ? .green : Theme.muted)
                        Text(tasks[index].title)
                            .strikethrough(tasks[index].isDone)
                            .lineLimit(1)
                        Spacer()
                    }
                    .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }

            if tasks.isEmpty {
                Text("No tasks yet")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            }
        }
        .padding(12)
        .frame(width: 260, alignment: .leading)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
    }
}

private struct InlineCalculatorWidget: View {
    @State private var display = "0"
    @State private var storedValue: Double?
    @State private var pendingOperation: String?
    @State private var shouldReset = false

    private let keys = [
        ["C", "±", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
        ["0", ".", "=" ]
    ]

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Label("Calculator", systemImage: "function")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(display)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
            }

            ForEach(keys, id: \.self) { row in
                HStack(spacing: 7) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            tap(key)
                        } label: {
                            Text(key)
                                .frame(maxWidth: .infinity)
                                .frame(height: 28)
                                .background(isOperator(key) ? Color.white.opacity(0.16) : Theme.panel, in: RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 250)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
    }

    private func isOperator(_ key: String) -> Bool {
        ["÷", "×", "−", "+", "="].contains(key)
    }

    private func tap(_ key: String) {
        switch key {
        case "C":
            display = "0"
            storedValue = nil
            pendingOperation = nil
            shouldReset = false
        case "±":
            if let value = Double(display) { display = format(-value) }
        case "%":
            if let value = Double(display) { display = format(value / 100) }
        case "÷", "×", "−", "+":
            storedValue = Double(display)
            pendingOperation = key
            shouldReset = true
        case "=":
            guard let left = storedValue, let right = Double(display), let operation = pendingOperation else { return }
            let result: Double
            switch operation {
            case "÷": result = right == 0 ? 0 : left / right
            case "×": result = left * right
            case "−": result = left - right
            default: result = left + right
            }
            display = format(result)
            storedValue = nil
            pendingOperation = nil
            shouldReset = true
        case ".":
            if shouldReset { display = "0."; shouldReset = false }
            else if !display.contains(".") { display += "." }
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

#Preview { ContentView() }
