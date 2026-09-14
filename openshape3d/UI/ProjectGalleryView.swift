//
//  ProjectGalleryView.swift
//  openshape3d
//
//  The design library (spec §13.1). Designs live in nested folders
//  (`ProjectFolder`, Shapr3D 5.492): a folder sidebar on regular widths,
//  breadcrumbs, browser-style Back/Forward (⌘[ / ⌘]), folder cards in the
//  grid, drag-and-drop of designs and folders onto any folder, and a
//  "Move to Folder…" picker for the same moves without a drag.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ProjectGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query(sort: \Project.modifiedAt, order: .reverse) private var projects: [Project]
    @Query(sort: \ProjectFolder.name) private var folders: [ProjectFolder]

    @State private var path = NavigationPath()
    @State private var history = FolderNavigationHistory()
    @State private var expandedFolders: Set<UUID> = []
    @State private var renamingProject: Project?
    @State private var renamingFolder: ProjectFolder?
    @State private var renameText = ""
    @State private var creatingFolder = false
    @State private var newFolderName = ""
    @State private var deletingFolder: ProjectFolder?
    @State private var moveRequest: MoveRequest?
    @State private var didHandleLaunchHooks = false
    @State private var showArchiveImporter = false
    @State private var showBugReport = false
    @State private var importErrorMessage: String?

    /// Select mode (Photos-style): card taps toggle membership instead of
    /// opening, and the toolbar offers Move and a confirmed multi-delete.
    @State private var isSelecting = false
    @State private var selectedProjectIDs: Set<PersistentIdentifier> = []
    @State private var confirmingMultiDelete = false

    private let columns = [GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 20)]

    // MARK: Derived

    private var tree: ProjectFolderTree {
        ProjectFolderTree(folders.map {
            FolderNode(id: $0.folderID, name: $0.name, parentID: $0.parentID)
        })
    }

    private var currentFolderID: UUID? { history.current }

    private var currentFolder: ProjectFolder? { folder(withID: currentFolderID) }

    private func folder(withID id: UUID?) -> ProjectFolder? {
        guard let id else { return nil }
        return folders.first { $0.folderID == id }
    }

    /// Where a design is listed: its folder, or the root when that folder is
    /// gone (a damaged store must never hide a design).
    private func listedFolderID(of project: Project) -> UUID? {
        tree.exists(project.folderID) ? project.folderID : nil
    }

    private var visibleProjects: [Project] {
        projects.filter { listedFolderID(of: $0) == currentFolderID }
    }

    private var visibleFolders: [ProjectFolder] {
        tree.children(of: currentFolderID).compactMap { folder(withID: $0.id) }
    }

    private func directCounts(in folderID: UUID) -> (designs: Int, folders: Int) {
        (projects.reduce(0) { $0 + (listedFolderID(of: $1) == folderID ? 1 : 0) },
         tree.children(of: folderID).count)
    }

    private var navigationTitle: String { currentFolder?.name ?? "Designs" }

    var body: some View {
        NavigationStack(path: $path) {
            HStack(spacing: 0) {
                if sizeClass == .regular {
                    FolderSidebar(
                        tree: tree,
                        current: currentFolderID,
                        expanded: $expandedFolders,
                        onSelect: { navigate(to: $0) },
                        onDrop: { payloads, target in move(payloads: payloads, to: target) },
                        onRename: { beginRename(folderID: $0) },
                        onNewSubfolder: { beginNewFolder(in: $0) },
                        onDelete: { deletingFolder = folder(withID: $0) }
                    )
                    Divider().ignoresSafeArea()
                }
                VStack(spacing: 0) {
                    if currentFolderID != nil {
                        breadcrumbs
                        Divider()
                    }
                    content
                }
            }
            .navigationTitle(navigationTitle)
            .onChange(of: navigationTitle) { _, title in MacWindowTitle.want(title) }
            // Inline: a large title would sit over the sidebar column.
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert(
                "Delete \(selectedProjectIDs.count) Design\(selectedProjectIDs.count == 1 ? "" : "s")?",
                isPresented: $confirmingMultiDelete
            ) {
                Button("Delete", role: .destructive, action: deleteSelected)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes the selected designs.")
            }
            .alert(
                "Delete “\(deletingFolder?.name ?? "")”?",
                isPresented: Binding(
                    get: { deletingFolder != nil },
                    set: { if !$0 { deletingFolder = nil } }
                )
            ) {
                Button("Delete", role: .destructive) {
                    if let folder = deletingFolder { delete(folder: folder) }
                    deletingFolder = nil
                }
                Button("Cancel", role: .cancel) { deletingFolder = nil }
            } message: {
                Text(deleteFolderMessage)
            }
            .fileImporter(
                isPresented: $showArchiveImporter,
                allowedContentTypes: [ExportDocument.os3dType, .data]
            ) { result in
                guard case .success(let url) = result else { return }
                let accessing = url.startAccessingSecurityScopedResource()
                defer {
                    if accessing { url.stopAccessingSecurityScopedResource() }
                }
                guard let data = try? Data(contentsOf: url),
                      let archive = ProjectArchive.decode(data) else {
                    importErrorMessage =
                        "That file isn't a readable OpenShape3D archive (or was made by a newer version)."
                    return
                }
                importArchive(archive, fallbackName: url.deletingPathExtension().lastPathComponent)
            }
            .alert(
                "Something Went Wrong",
                isPresented: Binding(
                    get: { importErrorMessage != nil },
                    set: { if !$0 { importErrorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { importErrorMessage = nil }
            } message: {
                Text(importErrorMessage ?? "")
            }
            .navigationDestination(for: PersistentIdentifier.self) { id in
                #if DEBUG
                let _ = OpenTiming.reset("destination requested")
                #endif
                if let project = modelContext.model(for: id) as? Project {
                    EditorView(project: project)
                }
            }
            .task {
                MacWindowTitle.want(navigationTitle)
                // Debug hooks for automated verification (once per launch —
                // .task refires when navigation pops back to the gallery).
                guard !didHandleLaunchHooks else { return }
                didHandleLaunchHooks = true
                // DEBUG only: test/screenshot hooks must not ship in the
                // release binary (2026-08-25 review / readiness audit §5).
                #if DEBUG
                if ProcessInfo.processInfo.environment["OS3D_FRESH"] != nil {
                    createProject() // always a clean design (test isolation)
                } else if ProcessInfo.processInfo.environment["OS3D_AUTO_OPEN"] != nil {
                    if let first = projects.first {
                        path.append(first.persistentModelID)
                    } else {
                        createProject()
                    }
                }
                #endif
            }
            .alert("Rename Design", isPresented: renameProjectBinding) {
                TextField("Name", text: $renameText)
                Button("Cancel", role: .cancel) { renamingProject = nil }
                Button("Rename") {
                    if let project = renamingProject, !renameText.isEmpty {
                        project.name = renameText
                        project.modifiedAt = Date()
                    }
                    renamingProject = nil
                }
            }
            .alert("Rename Folder", isPresented: renameFolderBinding) {
                TextField("Name", text: $renameText)
                Button("Cancel", role: .cancel) { renamingFolder = nil }
                Button("Rename") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let folder = renamingFolder, !trimmed.isEmpty {
                        folder.name = trimmed
                        folder.modifiedAt = Date()
                        save()
                    }
                    renamingFolder = nil
                }
            }
            .alert("New Folder", isPresented: $creatingFolder) {
                TextField("Name", text: $newFolderName)
                Button("Cancel", role: .cancel) { creatingFolder = false }
                Button("Create") {
                    createFolder(named: newFolderName, in: newFolderParent)
                    creatingFolder = false
                }
            } message: {
                Text(newFolderParent.flatMap { folder(withID: $0)?.name }
                    .map { "Inside “\($0)”." } ?? "At the top level.")
            }
            .sheet(isPresented: $showBugReport) {
                BugReportSheet(
                    context: .current(documentName: nil, bodyCount: 0, featureCount: 0,
                                      lastAction: nil),
                    attachmentProvider: nil)
            }
            .sheet(item: $moveRequest) { request in
                FolderPickerSheet(
                    tree: tree,
                    disabled: request.disabledFolders,
                    current: request.currentFolder,
                    onPick: { destination in
                        _ = move(projectIDs: request.projectIDs, folderIDs: request.folderIDs,
                                 to: destination)
                        if isSelecting { exitSelectMode() }
                    }
                )
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        let showsEmpty = visibleFolders.isEmpty && visibleProjects.isEmpty
        if showsEmpty && currentFolderID == nil {
            ContentUnavailableView {
                Label("No Designs", systemImage: "cube.transparent")
            } description: {
                Text("Tap + to create your first design.")
            } actions: {
                Button("New Design", action: createProject)
                    .buttonStyle(.borderedProminent)
            }
        } else if showsEmpty {
            ContentUnavailableView {
                Label("Empty Folder", systemImage: "folder")
            } description: {
                Text("New designs and folders you create here go into “\(navigationTitle)”.")
            } actions: {
                Button("New Design", action: createProject)
                    .buttonStyle(.borderedProminent)
                Button("New Folder") { beginNewFolder(in: currentFolderID) }
            }
            .accessibilityIdentifier("EmptyFolderView")
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(visibleFolders) { folder in
                        folderCell(folder)
                    }
                    ForEach(visibleProjects) { project in
                        projectCell(project)
                    }
                }
                .padding(20)
            }
            // Dropping on the empty grid area moves into the folder on screen.
            .dropDestination(for: String.self) { payloads, _ in
                move(payloads: payloads, to: currentFolderID)
            }
        }
    }

    @ViewBuilder
    private func folderCell(_ folder: ProjectFolder) -> some View {
        let counts = directCounts(in: folder.folderID)
        FolderCard(
            name: folder.name,
            designCount: counts.designs,
            folderCount: counts.folders,
            onOpen: { navigate(to: folder.folderID) },
            onDrop: { payloads in move(payloads: payloads, to: folder.folderID) }
        )
        .draggable(GalleryDragPayload.folder(folder.folderID))
        .opacity(isSelecting ? 0.5 : 1)
        .disabled(isSelecting)
        .contextMenu {
            Button {
                beginRename(folderID: folder.folderID)
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            Button {
                beginNewFolder(in: folder.folderID)
            } label: {
                Label("New Folder Inside", systemImage: "folder.badge.plus")
            }
            Button {
                moveRequest = MoveRequest(
                    projectIDs: [], folderIDs: [folder.folderID],
                    currentFolder: folder.parentID,
                    disabledFolders: Set([folder.folderID]
                        + tree.descendants(of: folder.folderID).map(\.id)))
            } label: {
                Label("Move to Folder…", systemImage: "folder")
            }
            Button(role: .destructive) {
                deletingFolder = folder
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func projectCell(_ project: Project) -> some View {
        if isSelecting {
            Button {
                toggleSelection(project)
            } label: {
                selectableCard(project)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: project.persistentModelID) {
                ProjectCard(project: project)
                    .draggable(GalleryDragPayload.project(project.persistentModelID))
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    renameText = project.name
                    renamingProject = project
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Button {
                    duplicate(project)
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                Button {
                    moveRequest = MoveRequest(
                        projectIDs: [project.persistentModelID], folderIDs: [],
                        currentFolder: listedFolderID(of: project), disabledFolders: [])
                } label: {
                    Label("Move to Folder…", systemImage: "folder")
                }
                Button(role: .destructive) {
                    modelContext.delete(project)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    /// Designs › Folder › Subfolder — each crumb navigates and takes drops.
    private var breadcrumbs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                BreadcrumbButton(
                    title: "Designs", isCurrent: false,
                    onTap: { navigate(to: nil) },
                    onDrop: { move(payloads: $0, to: nil) }
                )
                .accessibilityIdentifier("Crumb-Designs")
                let chain = tree.path(to: currentFolderID)
                ForEach(chain) { node in
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                    BreadcrumbButton(
                        title: node.name, isCurrent: node.id == currentFolderID,
                        onTap: { navigate(to: node.id) },
                        onDrop: { move(payloads: $0, to: node.id) }
                    )
                    .accessibilityIdentifier("Crumb-\(node.name)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Breadcrumbs")
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isSelecting {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: exitSelectMode)
                    .accessibilityIdentifier("CancelSelectButton")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    moveRequest = MoveRequest(
                        projectIDs: Array(selectedProjectIDs), folderIDs: [],
                        currentFolder: currentFolderID, disabledFolders: [])
                } label: {
                    Label(selectedProjectIDs.isEmpty
                        ? "Move" : "Move (\(selectedProjectIDs.count))",
                        systemImage: "folder")
                }
                .disabled(selectedProjectIDs.isEmpty)
                .accessibilityIdentifier("MoveSelectedButton")
            }
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    confirmingMultiDelete = true
                } label: {
                    Text(selectedProjectIDs.isEmpty
                        ? "Delete"
                        : "Delete (\(selectedProjectIDs.count))")
                }
                .disabled(selectedProjectIDs.isEmpty)
                .accessibilityIdentifier("DeleteSelectedButton")
            }
        } else {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    history.goBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .disabled(!history.canGoBack)
                .keyboardShortcut("[", modifiers: .command)
                .accessibilityIdentifier("GalleryBackButton")
                Button {
                    history.goForward()
                } label: {
                    Label("Forward", systemImage: "chevron.right")
                }
                .disabled(!history.canGoForward)
                .keyboardShortcut("]", modifiers: .command)
                .accessibilityIdentifier("GalleryForwardButton")
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showArchiveImporter = true
                } label: {
                    Label("Import Project…", systemImage: "square.and.arrow.down")
                }
                .accessibilityIdentifier("ImportProjectButton")
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showBugReport = true
                } label: {
                    Label("Report a Bug…", systemImage: "ladybug")
                }
                .accessibilityIdentifier("GalleryBugReportButton")
            }
            if !visibleProjects.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Select") { isSelecting = true }
                        .accessibilityIdentifier("SelectProjectsButton")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    beginNewFolder(in: currentFolderID)
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                .accessibilityIdentifier("NewFolderButton")
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: createProject) {
                    Label("New Design", systemImage: "plus")
                }
            }
        }
    }

    private var renameProjectBinding: Binding<Bool> {
        Binding(
            get: { renamingProject != nil },
            set: { if !$0 { renamingProject = nil } }
        )
    }

    private var renameFolderBinding: Binding<Bool> {
        Binding(
            get: { renamingFolder != nil },
            set: { if !$0 { renamingFolder = nil } }
        )
    }

    // MARK: - Folders

    private func navigate(to folderID: UUID?) {
        guard tree.exists(folderID) else { return }
        history.go(to: folderID)
        for node in tree.path(to: folderID) { expandedFolders.insert(node.id) }
    }

    /// Where the pending "New Folder" alert will create; set when the alert
    /// is raised so a folder created from a sidebar row lands in that row.
    @State private var newFolderParent: UUID?

    private func beginNewFolder(in parent: UUID?) {
        newFolderParent = parent
        newFolderName = ProjectFolderTree.uniqueName(
            base: "Untitled Folder", among: tree.children(of: parent).map(\.name))
        creatingFolder = true
    }

    private func createFolder(named name: String, in parent: UUID?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let siblings = tree.children(of: parent).map(\.name)
        let unique = ProjectFolderTree.uniqueName(
            base: trimmed.isEmpty ? "Untitled Folder" : trimmed, among: siblings)
        let folder = ProjectFolder(name: unique, parentID: tree.exists(parent) ? parent : nil)
        modelContext.insert(folder)
        save()
        if let parent { expandedFolders.insert(parent) }
    }

    private func beginRename(folderID: UUID) {
        guard let folder = folder(withID: folderID) else { return }
        renameText = folder.name
        renamingFolder = folder
    }

    private var deleteFolderMessage: String {
        guard let folder = deletingFolder else { return "" }
        let doomed = Set([folder.folderID] + tree.descendants(of: folder.folderID).map(\.id))
        let designs = projects.filter { listedFolderID(of: $0).map(doomed.contains) ?? false }.count
        let subfolders = doomed.count - 1
        var parts: [String] = []
        if designs > 0 { parts.append("\(designs) design\(designs == 1 ? "" : "s")") }
        if subfolders > 0 { parts.append("\(subfolders) subfolder\(subfolders == 1 ? "" : "s")") }
        if parts.isEmpty { return "The folder is empty." }
        return "This permanently deletes the folder and everything in it: "
            + parts.joined(separator: " and ") + "."
    }

    /// Deleting a folder deletes its whole subtree, designs included (the
    /// confirmation spells out the counts). Membership is by ID, so the
    /// cascade is explicit here.
    private func delete(folder: ProjectFolder) {
        let doomed = Set([folder.folderID] + tree.descendants(of: folder.folderID).map(\.id))
        let survivor = tree.parent(of: folder.folderID)
        for project in projects where listedFolderID(of: project).map(doomed.contains) ?? false {
            modelContext.delete(project)
        }
        for row in folders where doomed.contains(row.folderID) {
            modelContext.delete(row)
        }
        history.removing(doomed, fallback: survivor)
        expandedFolders.subtract(doomed)
        save()
    }

    /// Move designs and/or folders into `destination` (`nil` = root). A
    /// folder never moves into itself or its own subtree. Returns whether
    /// anything changed, which is what a drop destination reports back.
    @discardableResult
    private func move(projectIDs: [PersistentIdentifier], folderIDs: [UUID],
                      to destination: UUID?) -> Bool {
        guard tree.exists(destination) else { return false }
        var moved = false
        for project in projects where projectIDs.contains(project.persistentModelID) {
            guard listedFolderID(of: project) != destination else { continue }
            project.folderID = destination
            moved = true
        }
        for folder in folders where folderIDs.contains(folder.folderID) {
            guard tree.canMove(folder: folder.folderID, into: destination),
                  tree.parent(of: folder.folderID) != destination else { continue }
            folder.parentID = destination
            folder.modifiedAt = Date()
            moved = true
        }
        if moved {
            save()
            if let destination { expandedFolders.insert(destination) }
        }
        return moved
    }

    private func move(payloads: [String], to destination: UUID?) -> Bool {
        let decoded = GalleryDragPayload.decode(payloads)
        guard !decoded.projects.isEmpty || !decoded.folders.isEmpty else { return false }
        return move(projectIDs: decoded.projects, folderIDs: decoded.folders, to: destination)
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            importErrorMessage = "Couldn't save the library. \(error.localizedDescription)"
        }
    }

    // MARK: - Select mode

    /// A card in select mode: selection ring + corner check badge.
    private func selectableCard(_ project: Project) -> some View {
        let selected = selectedProjectIDs.contains(project.persistentModelID)
        return ProjectCard(project: project)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                }
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                    .background(Circle().fill(Color(.systemBackground)))
                    .padding(8)
            }
    }

    private func toggleSelection(_ project: Project) {
        let id = project.persistentModelID
        if selectedProjectIDs.contains(id) {
            selectedProjectIDs.remove(id)
        } else {
            selectedProjectIDs.insert(id)
        }
    }

    private func exitSelectMode() {
        isSelecting = false
        selectedProjectIDs = []
    }

    private func deleteSelected() {
        // Resolve against the live query rather than `model(for:)`: an id whose
        // row was deleted elsewhere (another window, sync) can trap while
        // faulting, and `as?` cannot catch a trap.
        for project in projects where selectedProjectIDs.contains(project.persistentModelID) {
            modelContext.delete(project)
        }
        do {
            try modelContext.save()
        } catch {
            // Don't fail silently — the grid would still show the designs.
            importErrorMessage = "Couldn't delete the selected designs. \(error.localizedDescription)"
        }
        exitSelectMode()
    }

    // MARK: - Designs

    /// New designs land in the folder on screen.
    private func createProject() {
        let base = "Untitled"
        let existing = Set(projects.map(\.name))
        var name = base
        var n = 2
        while existing.contains(name) {
            name = "\(base) \(n)"
            n += 1
        }
        let project = Project(name: name)
        project.folderID = currentFolderID
        modelContext.insert(project)
        // Save before navigating so the model ID is permanent — navigating on
        // a temporary ID crashes once autosave swaps it out.
        try? modelContext.save()
        path.append(project.persistentModelID)
    }

    /// Duplicate = archive round-trip: snapshot the rows, remap every UUID
    /// (record IDs and the references inside blobs stay consistent), insert
    /// as a new project next to the original. Unlike the old field-copy,
    /// this carries features, variables, images, symbols and materials, and
    /// can never collide with the original's unique ID columns.
    private func duplicate(_ project: Project) {
        importArchive(
            ProjectArchive.archive(from: project),
            fallbackName: project.name,
            nameSuffix: " Copy",
            folderID: listedFolderID(of: project)
        )
    }

    /// Insert an archive as a new project under a unique name and save.
    /// Imports land in the folder on screen; duplicates next to their source.
    private func importArchive(
        _ archive: ProjectArchive, fallbackName: String, nameSuffix: String = "",
        folderID: UUID?? = nil
    ) {
        let base = (archive.name.isEmpty ? fallbackName : archive.name) + nameSuffix
        let existing = Set(projects.map(\.name))
        var name = base
        var n = 2
        while existing.contains(name) {
            name = "\(base) \(n)"
            n += 1
        }
        let project = archive.remappingAllUUIDs().insert(into: modelContext, name: name)
        project.folderID = folderID ?? currentFolderID
        try? modelContext.save()
    }
}

// MARK: - Move request

private struct MoveRequest: Identifiable {
    let id = UUID()
    var projectIDs: [PersistentIdentifier]
    var folderIDs: [UUID]
    /// Where the items are now (shown with a checkmark).
    var currentFolder: UUID?
    /// Folders that cannot be a destination (a moving folder and its subtree).
    var disabledFolders: Set<UUID>
}

// MARK: - Drag payloads

/// Drag-and-drop carries plain strings: a folder's UUID, or a design's
/// `PersistentIdentifier` as base64 JSON. Prefixed so a stray text drop from
/// another app decodes to nothing rather than to a move.
private enum GalleryDragPayload {
    private static let projectPrefix = "os3d-design:"
    private static let folderPrefix = "os3d-folder:"

    static func project(_ id: PersistentIdentifier) -> String {
        let json = (try? JSONEncoder().encode(id)) ?? Data()
        return projectPrefix + json.base64EncodedString()
    }

    static func folder(_ id: UUID) -> String { folderPrefix + id.uuidString }

    static func decode(_ payloads: [String]) -> (projects: [PersistentIdentifier], folders: [UUID]) {
        var projects: [PersistentIdentifier] = []
        var folders: [UUID] = []
        for payload in payloads {
            if payload.hasPrefix(projectPrefix) {
                let body = String(payload.dropFirst(projectPrefix.count))
                if let data = Data(base64Encoded: body),
                   let id = try? JSONDecoder().decode(PersistentIdentifier.self, from: data) {
                    projects.append(id)
                }
            } else if payload.hasPrefix(folderPrefix),
                      let id = UUID(uuidString: String(payload.dropFirst(folderPrefix.count))) {
                folders.append(id)
            }
        }
        return (projects, folders)
    }
}

// MARK: - Sidebar

/// The folder tree beside the grid (regular widths): "Designs" at the top,
/// folders below with disclosure chevrons. Rows navigate, take drops, and
/// carry the folder context menu.
private struct FolderSidebar: View {
    let tree: ProjectFolderTree
    let current: UUID?
    @Binding var expanded: Set<UUID>
    let onSelect: (UUID?) -> Void
    let onDrop: ([String], UUID?) -> Bool
    let onRename: (UUID) -> Void
    let onNewSubfolder: (UUID) -> Void
    let onDelete: (UUID) -> Void

    /// The row a drag is hovering (`Slot(folder: nil)` = the root row).
    @State private var targeted: Slot?

    private struct Slot: Hashable { let folder: UUID? }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                Text("Library")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 14)
                    .padding(.bottom, 4)
                row(id: nil, name: "Designs", icon: "square.grid.2x2", depth: 0,
                    hasChildren: false, identifier: "SidebarRoot")
                ForEach(tree.flattened(expanded: expanded), id: \.node.id) { entry in
                    row(id: entry.node.id, name: entry.node.name, icon: "folder",
                        depth: entry.depth + 1,
                        hasChildren: !tree.children(of: entry.node.id).isEmpty,
                        identifier: "SidebarFolder-\(entry.node.name)")
                        .contextMenu {
                            Button {
                                onRename(entry.node.id)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            Button {
                                onNewSubfolder(entry.node.id)
                            } label: {
                                Label("New Folder Inside", systemImage: "folder.badge.plus")
                            }
                            Button(role: .destructive) {
                                onDelete(entry.node.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                if tree.isEmpty {
                    Text("Folders you create appear here.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 12)
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .frame(width: 236)
        .background(Color(.secondarySystemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("FolderSidebar")
    }

    /// `identifier` goes on the row's select button, never the HStack: an
    /// identifier on the container collapses it into one element and hides
    /// the disclosure chevron from XCUITest (gotcha 2).
    private func row(id: UUID?, name: String, icon: String, depth: Int,
                     hasChildren: Bool, identifier: String) -> some View {
        let isCurrent = id == current
        let isTargeted = targeted == Slot(folder: id)
        return HStack(spacing: 6) {
            if let id, hasChildren {
                Button {
                    if expanded.contains(id) { expanded.remove(id) } else { expanded.insert(id) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .rotationEffect(.degrees(expanded.contains(id) ? 90 : 0))
                        .frame(width: 16, height: 16)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel(expanded.contains(id) ? "Collapse" : "Expand")
                .accessibilityIdentifier("SidebarDisclosure-\(name)")
            } else {
                Color.clear.frame(width: 16, height: 16)
            }
            Button {
                onSelect(id)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isCurrent && id != nil ? "folder.fill" : icon)
                        .font(.system(size: 15))
                        .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
                        .frame(width: 20)
                    Text(name)
                        .lineLimit(1)
                        .foregroundStyle(isCurrent ? Color.accentColor : Color.primary)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 7)
                .padding(.trailing, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(name)
            .accessibilityIdentifier(identifier)
        }
        .padding(.leading, CGFloat(depth) * 14 + 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? Color.accentColor.opacity(0.14)
                      : isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
        )
        .overlay {
            if isTargeted {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }
        }
        .dropDestination(for: String.self) { payloads, _ in
            onDrop(payloads, id)
        } isTargeted: { hovering in
            if hovering { targeted = Slot(folder: id) }
            else if targeted == Slot(folder: id) { targeted = nil }
        }
    }
}

// MARK: - Cards and crumbs

/// A folder in the grid: opens on tap, takes drops, shows what it holds.
private struct FolderCard: View {
    let name: String
    let designCount: Int
    let folderCount: Int
    let onOpen: () -> Void
    let onDrop: ([String]) -> Bool

    @State private var isTargeted = false

    private var summary: String {
        var parts: [String] = []
        if folderCount > 0 { parts.append("\(folderCount) folder\(folderCount == 1 ? "" : "s")") }
        if designCount > 0 { parts.append("\(designCount) design\(designCount == 1 ? "" : "s")") }
        return parts.isEmpty ? "Empty" : parts.joined(separator: ", ")
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                    Image(systemName: "folder.fill")
                        .font(.system(size: 46))
                        .foregroundStyle(Color.accentColor.opacity(0.8))
                }
                .aspectRatio(4.0 / 3.0, contentMode: .fit)

                Text(name)
                    .font(.headline)
                    .lineLimit(1)
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                if isTargeted {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                }
            }
            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityIdentifier("FolderCard-\(name)")
        .dropDestination(for: String.self) { payloads, _ in
            onDrop(payloads)
        } isTargeted: { isTargeted = $0 }
    }
}

private struct BreadcrumbButton: View {
    let title: String
    let isCurrent: Bool
    let onTap: () -> Void
    let onDrop: ([String]) -> Bool

    @State private var isTargeted = false

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                .foregroundStyle(isCurrent ? Color.primary : Color.accentColor)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isTargeted ? Color.accentColor.opacity(0.14) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .disabled(isCurrent)
        .dropDestination(for: String.self) { payloads, _ in
            onDrop(payloads)
        } isTargeted: { isTargeted = $0 }
    }
}

private struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                if let data = project.thumbnail, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 40))
                        .foregroundStyle(.tertiary)
                }
            }
            .aspectRatio(4.0 / 3.0, contentMode: .fit)

            Text(project.name)
                .font(.headline)
                .lineLimit(1)
            Text(project.modifiedAt, format: .relative(presentation: .named))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}

// MARK: - Move picker

/// "Move to Folder…": the whole tree as an indented list; the root first.
/// Folders that cannot receive the move (a moving folder and its subtree)
/// are disabled, and the items' present location carries a checkmark.
private struct FolderPickerSheet: View {
    let tree: ProjectFolderTree
    let disabled: Set<UUID>
    let current: UUID?
    let onPick: (UUID?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                pickRow(id: nil, name: "Designs", icon: "square.grid.2x2", depth: 0)
                    .accessibilityIdentifier("MovePickRoot")
                ForEach(tree.flattened(), id: \.node.id) { entry in
                    pickRow(id: entry.node.id, name: entry.node.name, icon: "folder",
                            depth: entry.depth + 1)
                        .accessibilityIdentifier("MovePick-\(entry.node.name)")
                }
            }
            .navigationTitle("Move to Folder")
            .onDisappear { MacWindowTitle.restore() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("MovePickCancel")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func pickRow(id: UUID?, name: String, icon: String, depth: Int) -> some View {
        let isDisabled = id.map(disabled.contains) ?? false
        let isCurrent = id == current
        return Button {
            onPick(id)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(isDisabled ? Color.secondary : Color.accentColor)
                    .frame(width: 22)
                Text(name)
                    .foregroundStyle(isDisabled ? Color.secondary : Color.primary)
                Spacer()
                if isCurrent {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, CGFloat(depth) * 18)
        }
        .disabled(isDisabled || isCurrent)
    }
}

#Preview {
    ProjectGalleryView()
        .modelContainer(for: [Project.self, ProjectFolder.self], inMemory: true)
}
