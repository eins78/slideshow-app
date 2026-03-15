import SwiftUI

struct WelcomeView: View {
    var onOpen: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Slideshow", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Present image slideshows with captions and presenter notes.")
        } actions: {
            Button("Open Slideshow...") { onOpen() }
                .accessibilityIdentifier("openSlideshowButton")
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview("Welcome") {
    WelcomeView(onOpen: {})
        .frame(width: 600, height: 400)
}
