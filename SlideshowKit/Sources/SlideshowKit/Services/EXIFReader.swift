import Foundation
import ImageIO
import CoreLocation

/// Reads EXIF metadata from image files via CGImageSource.
/// Must be called from Task.detached — performs synchronous file I/O.
/// See: https://developer.apple.com/documentation/imageio/cgimagesource
public struct EXIFReader: Sendable {
    public init() {}

    /// Read EXIF data from an image file URL.
    public func read(from url: URL) -> EXIFData? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }

        var data = EXIFData()

        // EXIF dictionary
        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            data.focalLength = exif[kCGImagePropertyExifFocalLength] as? Double
            data.aperture = exif[kCGImagePropertyExifFNumber] as? Double
            data.iso = (exif[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first
            data.exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double

            if let dateStr = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
                data.dateTaken = parseEXIFDate(dateStr)
            }
        }

        // TIFF dictionary (camera info)
        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            data.cameraMake = tiff[kCGImagePropertyTIFFMake] as? String
            data.cameraModel = tiff[kCGImagePropertyTIFFModel] as? String
        }

        // Lens info from EXIF Aux
        if let aux = properties[kCGImagePropertyExifAuxDictionary] as? [CFString: Any] {
            data.lensModel = aux[kCGImagePropertyExifAuxLensModel] as? String
        }

        // Image dimensions
        data.imageWidth = properties[kCGImagePropertyPixelWidth] as? Int
        data.imageHeight = properties[kCGImagePropertyPixelHeight] as? Int

        // GPS
        if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
               let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
               let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
               let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String {
                let latitude = latRef == "S" ? -lat : lat
                let longitude = lonRef == "W" ? -lon : lon
                data.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }

        return data
    }

    // Per-call DateFormatter — DateFormatter is not thread-safe, and EXIFReader
    // is called from Task.detached (concurrent). Static instance would race.
    private func parseEXIFDate(_ string: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return f.date(from: string)
    }
}
