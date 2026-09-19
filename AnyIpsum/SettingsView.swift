import AppKit
import KeyboardShortcuts
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    let model: AppModel

    var body: some View {
        VStack {
            Form {
                Section("General") {
                    Toggle(
                        "Launch at login",
                        isOn: Binding(
                            get: { model.launchesAtLogin },
                            set: model.setLaunchesAtLogin
                        )
                    )

                    if let launchAtLoginError = model.launchAtLoginError {
                        Label(launchAtLoginError, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }

                Section("Keyboard Shortcut") {
                    KeyboardShortcuts.Recorder("Open menu", name: .openMenu)

                    Button("Use Default Shortcut") {
                        model.resetShortcut()
                    }
                }

                Section("Variations") {
                    HStack {
                        Button("Import Text File…") {
                            importVariation()
                        }

                        Text("Maximum file size: 10 KB")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }

                    if model.variations.isEmpty {
                        Text("No variations available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.variations) { variation in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel("Drag to reorder")
                                    .draggable(variation.id) {
                                        variationDragPreview(variation)
                                    }

                                Text(variation.name)
                                Spacer()
                                Button {
                                    model.deleteVariation(variation)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .help("Delete variation")
                                .accessibilityLabel("Delete variation")
                                .buttonStyle(.borderless)
                            }
                            .contentShape(Rectangle())
                            .dropDestination(for: String.self) { items, _ in
                                guard let sourceID = items.first,
                                      let sourceIndex = model.variations.firstIndex(where: { $0.id == sourceID }),
                                      let destinationIndex = model.variations.firstIndex(of: variation),
                                      sourceIndex != destinationIndex else {
                                    return false
                                }

                                let destination = sourceIndex < destinationIndex
                                    ? destinationIndex + 1
                                    : destinationIndex
                                model.reorderVariations(
                                    from: IndexSet(integer: sourceIndex),
                                    to: destination
                                )
                                return true
                            }
                        }
                    }

                    if let variationError = model.variationError {
                        Label(variationError, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)

            Spacer()

            HStack {
                Text("Version \(appVersion)")
                    .foregroundStyle(.secondary)

                Spacer()

                Link(
                    "Visit AnyIpsum on GitHub",
                    destination: URL(string: "https://github.com/jodelamo/AnyIpsum")!
                )
            }
            .font(.callout)
        }
        .frame(width: 480, height: 420)
        .padding()
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private func importVariation() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let alert = NSAlert()
        alert.messageText = "Name Variation"
        alert.informativeText = "Enter a name for this variation."
        let nameField = NSTextField(string: "")
        nameField.placeholderString = "Cat Ipsum"
        nameField.frame = NSRect(x: 0, y: 0, width: 260, height: 24)
        alert.accessoryView = nameField
        alert.addButton(withTitle: "Import")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = nameField

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        model.importVariation(from: url, named: nameField.stringValue)
    }

    private func variationDragPreview(_ variation: Variation) -> some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
            Text(variation.name)
            Spacer()
            Image(systemName: "trash")
                .foregroundStyle(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 440, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
}
