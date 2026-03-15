import SwiftUI
import MapKit
import SlideshowKit

struct FileInfoPanel: View {
    let slide: Slide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("File Info")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)

                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 3) {
                    if let filename = slide.section.images.first?.filename {
                        infoRow("File", filename)
                    }

                    if let size = slide.fileSize {
                        infoRow("Size", ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    }

                    if let exif = slide.exif {
                        if let camera = exif.cameraModel {
                            infoRow("Camera", camera)
                        }
                        if let lens = exif.lensModel {
                            infoRow("Lens", lens)
                        }
                        if let settings = exif.settingsString {
                            infoRow("Settings", settings)
                        }
                        if let date = exif.dateTaken {
                            infoRow("Date", date.formatted(date: .abbreviated, time: .shortened))
                        }
                        if let res = exif.resolutionString {
                            infoRow("Resolution", res)
                        }
                        if let coord = exif.coordinate {
                            infoRow("GPS", String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                        }
                    }
                }

                if let coord = slide.exif?.coordinate {
                    Map {
                        Marker(coordinate: coord) {
                            Text(slide.displayName)
                        }
                    }
                    .mapStyle(.standard)
                    .mapControlVisibility(.hidden)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(12)
        }
        // EXIF reading wrapped in Task.detached to avoid blocking main actor
        // See: https://developer.apple.com/documentation/imageio/cgimagesource
        .task(id: slide.id) {
            guard slide.exif == nil, let url = slide.primaryImageURL else { return }
            let exif = await Task.detached {
                EXIFReader().read(from: url)
            }.value
            slide.exif = exif
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
        }
    }
}

#Preview("File Info — with EXIF") {
    let slide = Slide(section: SlideSection(
        images: [SlideImage(filename: "003--sunset.jpg")]
    ))
    slide.fileSize = 12_500_000
    var exif = EXIFData()
    exif.cameraModel = "FUJIFILM X-T5"
    exif.lensModel = "XF23mmF1.4 R LM WR"
    exif.focalLength = 23
    exif.aperture = 8
    exif.exposureTime = 1.0 / 250.0
    exif.iso = 160
    exif.imageWidth = 6240
    exif.imageHeight = 4160
    exif.dateTaken = Date()
    slide.exif = exif
    return FileInfoPanel(slide: slide)
        .frame(width: 280, height: 400)
}

#Preview("File Info — no EXIF") {
    let slide = Slide(section: SlideSection(
        images: [SlideImage(filename: "screenshot.png")]
    ))
    slide.fileSize = 450_000
    return FileInfoPanel(slide: slide)
        .frame(width: 280, height: 200)
}
