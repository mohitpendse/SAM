//
//  HomeDashboardView.swift
//  ASM
//

import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var store: ASMStore
    @State private var showNewMenu = false

    private var displayName: String {
        store.profile.name.isEmpty ? "Student" : store.profile.name
    }

    var body: some View {
        HStack(spacing: 0) {
            homeSidebar
            mainContent
        }
        .background(Color.asmCanvas)
    }

    private var homeSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Text(initials)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.asmInk)
                    }
                Text(displayName)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Image(systemName: "sidebar.left")
                    .foregroundStyle(Color.asmMutedInk)
            }
            .padding(.bottom, 24)

            sidebarItem("house", "Home", selected: true) {}
            sidebarItem("point.3.connected.trianglepath.dotted", "AI Tutors") {}
            sidebarItem("rectangle.on.rectangle.angled", "Flashcards") {}

            Text("Pinned")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.asmMutedInk)
                .padding(.top, 28)
                .padding(.bottom, 8)

            ForEach(store.selectedNotebook?.binders ?? []) { binder in
                Button {
                    store.selectBinder(binder.id)
                    store.openCanvas()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(binder.color)
                        Text(binder.title)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "pin")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.asmMutedInk)
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(Color.asmInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(Color.asmMist, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Text("Spaces")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.asmMutedInk)
                .padding(.top, 24)
                .padding(.bottom, 8)

            sidebarItem("shippingbox", "Mechanics") {
                store.openCanvas()
            }

            Spacer()

            Button {
                store.addInkPage()
                store.openCanvas()
            } label: {
                Label("New Document", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(16)
        .frame(width: 264)
        .background(Color.black.opacity(0.12))
        .overlay(Rectangle().frame(width: 1).foregroundStyle(Color.asmLine), alignment: .trailing)
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Home", systemImage: "house")
                    .foregroundStyle(Color.asmMutedInk)
                Spacer()
                Button {
                    showNewMenu.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(IconControlStyle())
            }

            Spacer(minLength: 34)

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Color.asmInk)
                Text("Good evening, \(displayName)")
                    .font(.system(size: 30, weight: .semibold))
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                quickAction("square.and.pencil", "New Canvas", Color.asmAccent) {
                    store.addInkPage()
                    store.openCanvas()
                }
                quickAction("books.vertical", "New Notebook", Color.asmTeal) {
                    store.addBinder()
                    store.openCanvas()
                }
                quickAction("doc.badge.plus", "Import PDF", Color.asmGold) {
                    store.showPDFImporter = true
                    store.openCanvas()
                }
            }
            .padding(.top, 36)

            sectionHeader("Recents")
            if store.items.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 14)], spacing: 14) {
                    ForEach(store.items.prefix(6)) { item in
                        Button {
                            store.selectItem(item.id)
                            store.openCanvas()
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                                    .frame(height: 84)
                                    .overlay {
                                        Image(systemName: item.kind == .widget ? "square.grid.2x2" : "square.and.pencil")
                                            .font(.system(size: 24))
                                            .foregroundStyle(Color.asmMutedInk)
                                    }
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.asmInk)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.asmMist, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 38)
        .padding(.top, 24)
        .padding(.bottom, 28)
        .overlay(alignment: .topTrailing) {
            if showNewMenu {
                VStack(alignment: .leading, spacing: 4) {
                    menuItem("square.and.pencil", "New Canvas") {
                        store.addInkPage()
                        store.openCanvas()
                    }
                    menuItem("books.vertical", "New Notebook") {
                        store.addBinder()
                        store.openCanvas()
                    }
                    menuItem("folder", "Create folder") {}
                }
                .padding(8)
                .frame(width: 190)
                .background(Color.asmCanvas, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.asmLine))
                .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
                .padding(.top, 68)
                .padding(.trailing, 38)
            }
        }
    }

    private var initials: String {
        displayName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder")
                .font(.system(size: 26))
                .foregroundStyle(Color.asmMutedInk)
            Text("No recent canvases")
                .font(.system(size: 16, weight: .semibold))
            Text("Create a canvas to begin working here.")
                .font(.system(size: 13))
                .foregroundStyle(Color.asmMutedInk)
        }
        .frame(maxWidth: .infinity)
        .padding(38)
        .background(Color.asmMist, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sidebarItem(_ icon: String, _ title: String, selected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.asmInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(selected ? Color.asmMist : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func quickAction(_ icon: String, _ title: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.asmInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(Color.asmMist, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 4, height: 28)
                }
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title).font(.system(size: 16, weight: .semibold))
            Spacer()
            Text("View all").font(.system(size: 12)).foregroundStyle(Color.asmMutedInk)
        }
        .padding(.top, 36)
        .padding(.bottom, 12)
    }

    private func menuItem(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.asmInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
        }
        .buttonStyle(.plain)
    }
}
