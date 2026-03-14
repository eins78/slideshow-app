import Testing
import Foundation
@testable import SlideshowKit

@Suite("EXIFData")
struct EXIFDataTests {
    @Test("shutterSpeedString formats sub-second exposure")
    func subSecondShutter() {
        var exif = EXIFData()
        exif.exposureTime = 1.0 / 250.0
        #expect(exif.shutterSpeedString == "1/250s")
    }

    @Test("shutterSpeedString formats multi-second exposure")
    func multiSecondShutter() {
        var exif = EXIFData()
        exif.exposureTime = 30.0
        #expect(exif.shutterSpeedString == "30s")
    }

    @Test("shutterSpeedString formats exactly 1 second")
    func oneSecondShutter() {
        var exif = EXIFData()
        exif.exposureTime = 1.0
        #expect(exif.shutterSpeedString == "1s")
    }

    @Test("shutterSpeedString formats camera-standard fractional seconds")
    func fractionalSecondShutter() {
        var exif = EXIFData()
        exif.exposureTime = 1.3
        #expect(exif.shutterSpeedString == "1.3s")

        exif.exposureTime = 1.6
        #expect(exif.shutterSpeedString == "1.6s")

        exif.exposureTime = 2.5
        #expect(exif.shutterSpeedString == "2.5s")
    }

    @Test("shutterSpeedString returns nil when no exposure")
    func nilShutter() {
        let exif = EXIFData()
        #expect(exif.shutterSpeedString == nil)
    }

    @Test("settingsString joins all components")
    func fullSettings() {
        var exif = EXIFData()
        exif.focalLength = 24.0
        exif.aperture = 8.0
        exif.exposureTime = 1.0 / 250.0
        exif.iso = 100
        #expect(exif.settingsString == "24mm · f/8 · 1/250s · ISO 100")
    }

    @Test("settingsString uses clean integer for whole-number aperture")
    func wholeNumberAperture() {
        var exif = EXIFData()
        exif.aperture = 4.0
        #expect(exif.settingsString == "f/4")
    }

    @Test("settingsString preserves fractional aperture")
    func fractionalAperture() {
        var exif = EXIFData()
        exif.aperture = 2.8
        #expect(exif.settingsString == "f/2.8")
    }

    @Test("settingsString returns nil when all fields empty")
    func emptySettings() {
        let exif = EXIFData()
        #expect(exif.settingsString == nil)
    }

    @Test("resolutionString formats width × height")
    func resolution() {
        var exif = EXIFData()
        exif.imageWidth = 6240
        exif.imageHeight = 4160
        #expect(exif.resolutionString == "6240 × 4160")
    }

    @Test("resolutionString returns nil when dimensions missing")
    func nilResolution() {
        let exif = EXIFData()
        #expect(exif.resolutionString == nil)
    }
}
