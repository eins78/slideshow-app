import SwiftUI

struct WelcomeView: View {
    var onOpen: () -> Void
    var onNew: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Slideshow", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Present image slideshows with captions and presenter notes.")
        } actions: {
            Button("Open Slideshow...") { onOpen() }
                .buttonStyle(.borderedProminent)
            Button("Create New...") { onNew() }
        }
    }
}
