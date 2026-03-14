import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultViewMode") private var defaultViewMode = "list"
    @AppStorage("showFileExtensions") private var showFileExtensions = true
    @AppStorage("showSlideCounter") private var showSlideCounter = true
    @AppStorage("editorFontSize") private var editorFontSize = 13.0

    var body: some View {
        TabView {
            Tab("General", systemImage: "gear") {
                Form {
                    Picker("Default view mode", selection: $defaultViewMode) {
                        Text("List").tag("list")
                        Text("Grid").tag("grid")
                    }
                    Toggle("Show file extensions", isOn: $showFileExtensions)
                }
                .formStyle(.grouped)
            }

            Tab("Presentation", systemImage: "play.rectangle") {
                Form {
                    Toggle("Show slide counter", isOn: $showSlideCounter)
                }
                .formStyle(.grouped)
            }

            Tab("Editor", systemImage: "pencil") {
                Form {
                    Stepper("Editor font size: \(Int(editorFontSize))", value: $editorFontSize, in: 10...24)
                }
                .formStyle(.grouped)
            }
        }
        .frame(width: 450, height: 250)
    }
}

#Preview("Settings") {
    SettingsView()
}
