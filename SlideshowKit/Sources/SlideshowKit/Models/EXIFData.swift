import Foundation
import CoreLocation

/// Extracted EXIF metadata from an image file.
public struct EXIFData: Equatable, Sendable {
    public var cameraMake: String?
    public var cameraModel: String?
    public var lensModel: String?
    public var focalLength: Double?
    public var aperture: Double?
    public var shutterSpeed: String?
    public var iso: Int?
    public var dateTaken: Date?
    public var imageWidth: Int?
    public var imageHeight: Int?
    public var coordinate: CLLocationCoordinate2D?

    public init() {}

    /// Formatted camera settings string (e.g., "24mm · f/8 · 1/250s · ISO 100").
    public var settingsString: String? {
        var parts: [String] = []
        if let fl = focalLength { parts.append("\(Int(fl))mm") }
        if let ap = aperture { parts.append("f/\(ap)") }
        if let ss = shutterSpeed { parts.append(ss) }
        if let iso { parts.append("ISO \(iso)") }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Resolution string (e.g., "8192 × 5464").
    public var resolutionString: String? {
        guard let w = imageWidth, let h = imageHeight else { return nil }
        return "\(w) × \(h)"
    }
}

// CLLocationCoordinate2D is not Equatable by default
extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
