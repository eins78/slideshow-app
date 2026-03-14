import SwiftUI
import SlideshowKit

struct SlideRowView: View {
    let slide: Slide
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            Text("\(index + 1)")
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(slide.strippedFilename)
                    .font(.body)
                    .lineLimit(1)

                if let caption = slide.sidecar?.caption {
                    Text(caption)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let size = slide.fileSize {
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(index + 1). \(slide.displayName)")
    }
}

#Preview("Slide Row — with caption") {
    let slide = Slide(
        fileURL: URL(fileURLWithPath: "/tmp/003--sunset.jpg"),
        sidecar: SidecarData(caption: "Golden hour at the lake")
    )
    slide.fileSize = 2_450_000
    return SlideRowView(slide: slide, index: 2)
        .frame(width: 350)
        .padding()
}

#Preview("Slide Row — no caption") {
    let slide = Slide(fileURL: URL(fileURLWithPath: "/tmp/beach-photo.jpg"))
    slide.fileSize = 8_100_000
    return SlideRowView(slide: slide, index: 0)
        .frame(width: 350)
        .padding()
}
