import SwiftUI

struct PromptLibraryScreen: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @EnvironmentObject private var promptStore: PromptLibraryStore
    @State private var editingPrompt: SavedPrompt?
    @State private var showNewPrompt = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeader(
                    "Prompt library",
                    eyebrow: "Save & reuse",
                    subtitle: "Name and save prompts you reuse often. Tap a saved prompt to load it into the composer.",
                    systemImage: "bookmark.fill",
                    theme: viewModel.configuration.theme
                )
                .padding(.horizontal)

                if let error = promptStore.lastError {
                    StoreErrorBanner(message: error) { promptStore.lastError = nil }
                        .padding(.horizontal)
                }

                if promptStore.prompts.isEmpty {
                    ContentUnavailableView(
                        "No saved prompts",
                        systemImage: "bookmark.slash",
                        description: Text("Save a prompt from the composer or tap the button above to write one from scratch.")
                    )
                    .padding(.horizontal)
                } else {
                    ForEach(promptStore.prompts) { prompt in
                        PromptRow(prompt: prompt, theme: viewModel.configuration.theme) {
                            loadPrompt(prompt)
                        } editAction: {
                            editingPrompt = prompt
                        }
                        .contextMenu {
                            Button {
                                editingPrompt = prompt
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                    promptStore.remove(prompt)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .readableContentFrame(maxWidth: 980)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Prompts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewPrompt = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
                .accessibilityLabel("New prompt")
            }
        }
        .appBackground(theme: viewModel.configuration.theme)
        .sheet(isPresented: $showNewPrompt) {
            PromptEditorView(store: promptStore)
        }
        .sheet(item: $editingPrompt) { prompt in
            PromptEditorView(store: promptStore, existing: prompt)
        }
    }

    private func loadPrompt(_ prompt: SavedPrompt) {
        viewModel.useQuickStart(prompt.text)
    }
}

private struct PromptRow: View {
    let prompt: SavedPrompt
    let theme: ColorTheme
    let action: () -> Void
    let editAction: () -> Void

    var body: some View {
        GlassCard(radius: 24) {
            HStack(alignment: .top, spacing: 14) {
                GradientIconBadge(systemImage: "text.quote", theme: theme, size: 38)

                VStack(alignment: .leading, spacing: 6) {
                    Text(prompt.name)
                        .font(.headline)
                    Text(prompt.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(prompt.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(spacing: 10) {
                    Button(action: editAction) {
                        Image(systemName: "pencil")
                            .font(.caption.weight(.bold))
                    }
                    .accessibilityLabel("Edit prompt")
                    Button(action: action) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(theme.gradient)
                    }
                    .accessibilityLabel("Load prompt into composer")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prompt: \(prompt.name)")
        .accessibilityHint("Tap arrow to load into composer, pencil to edit")
    }
}

private struct PromptEditorView: View {
    @ObservedObject var store: PromptLibraryStore
    var existing: SavedPrompt?

    @State private var name: String
    @State private var text: String
    @Environment(\.dismiss) private var dismiss

    init(store: PromptLibraryStore, existing: SavedPrompt? = nil) {
        self.store = store
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _text = State(initialValue: existing?.text ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Prompt name") {
                    TextField("Monthly pricing card", text: $name)
                        .accessibilityLabel("Prompt name")
                }

                Section("Prompt text") {
                    TextEditor(text: $text)
                        .frame(minHeight: 140)
                        .accessibilityLabel("Prompt text")
                }
            }
            .navigationTitle(existing == nil ? "New prompt" : "Edit prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let existing {
                            var updated = existing
                            updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            updated.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            store.update(updated)
                        } else {
                            store.save(SavedPrompt(
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                text: text.trimmingCharacters(in: .whitespacesAndNewlines)
                            ))
                        }
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
