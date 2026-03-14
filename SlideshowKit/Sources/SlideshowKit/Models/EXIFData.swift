import Foundation
import CoreLocation

/// Extracted EXIF metadata from an image file.
public struct EXIFData: Equatable, Sendable {
    public var cameraMake: String?
    public var cameraModel: String?
    public var lensModel: String?
    public var focalLength: Double?
    public var aperture: Double?
    public var exposureTime: Double?
    public var iso: Int?
    public var dateTaken: Date?
    public var imageWidth: Int?
    public var imageHeight: Int?
    public var coordinate: CLLocationCoordinate2D?

    public init() {}

    /// Formatted shutter speed (e.g., "1/250s" or "2s").
    public var shutterSpeedString: String? {
        guard let t = exposureTime else { return nil }
        if t >= 1 {
            return "\(Int(t))s"
        } else {
            return "1/\(Int(round(1.0 / t)))s"
        }
    }

    /// Formatted camera settings string (e.g., "24mm · f/8 · 1/250s · ISO 100").
    public var settingsString: String? {
        var parts: [String] = []
        if let fl = focalLength { parts.append("\(Int(fl.rounded()))mm") }
        if let ap = aperture { parts.append("f/\(ap)") }
        if let ss = shutterSpeedString { parts.append(ss) }
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
