import Foundation

/// Hardware-free regression test. Compile alongside CameraSettings.swift.
@main
struct CameraSettingsPersistenceTests {
    static func main() throws {
        let preferences = MemoryPreferences()
        let initial = CameraSettings(preferences: preferences)
        precondition(initial.lensPosition == 120 && initial.brightness == 0)
        precondition(!initial.meterOnSubject && !initial.bokehEnabled)

        initial.manualFocus = true
        initial.lensPosition = 187
        initial.brightness = -3
        initial.autoExposure = false
        initial.exposureUs = 12_000
        initial.iso = 800
        initial.manualWhiteBalance = true
        initial.whiteBalanceK = 4200
        initial.antiBanding = .hz50
        initial.outputMode = .hd720
        initial.fps = 40
        initial.mirrorPreview = false
        initial.showAdvanced = true
        initial.meterOnSubject = true
        precondition(initial.coldDirty)

        let restored = CameraSettings(preferences: preferences)
        precondition(restored.manualFocus && restored.lensPosition == 187)
        precondition(restored.brightness == -3)
        precondition(!restored.autoExposure && restored.exposureUs == 12_000 && restored.iso == 800)
        precondition(restored.manualWhiteBalance && restored.whiteBalanceK == 4200)
        precondition(restored.antiBanding == .hz50 && restored.meterOnSubject)
        precondition(restored.outputMode == .hd720 && restored.fps == 40)
        precondition(!restored.mirrorPreview && restored.showAdvanced && !restored.coldDirty)

        restored.reset()
        let reset = CameraSettings(preferences: preferences)
        precondition(!reset.manualFocus && reset.lensPosition == 120 && reset.brightness == 0)
        precondition(reset.autoExposure && reset.exposureUs == 8000)

        func restore(_ json: String) -> CameraSettings {
            preferences.set(Data(json.utf8), forKey: CameraSettings.persistenceKey)
            return CameraSettings(preferences: preferences)
        }
        let partial = restore(#"{"version":1,"brightness":4}"#)
        precondition(partial.brightness == 4 && partial.lensPosition == 120)
        precondition(!partial.meterOnSubject)
        let invalid = restore(#"{"version":1,"brightness":999,"lensPosition":-1,"fps":0,"iso":99999,"exposureUs":-1,"contrast":2}"#)
        precondition(invalid.brightness == 0 && invalid.lensPosition == 120 && invalid.fps == 30)
        precondition(invalid.iso == 400 && invalid.exposureUs == 8000 && invalid.contrast == 2)
        for json in ["not JSON", #"{"version":1,"lensPosition":"wrong type"}"#,
                     #"{"version":1,"afMode":"unknown"}"#,
                     #"{"version":2,"brightness":4}"#] {
            let fallback = restore(json)
            precondition(fallback.brightness == 0 && fallback.lensPosition == 120 && !fallback.coldDirty)
        }
        print("Camera settings persistence: passed round-trip, reset, defaults, and invalid-data checks")
    }
}

/// Exercise real JSON persistence without changing the user's preference domain.
private final class MemoryPreferences: UserDefaults {
    private var stored: [String: Data] = [:]
    override func data(forKey defaultName: String) -> Data? { stored[defaultName] }
    override func set(_ value: Any?, forKey defaultName: String) { stored[defaultName] = value as? Data }
}
