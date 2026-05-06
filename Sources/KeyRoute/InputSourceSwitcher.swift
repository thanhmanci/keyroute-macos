import Carbon
import Foundation

struct InputSourceInfo: Equatable {
    var id: String
    var name: String
}

final class InputSourceSwitcher {
    func currentInputSourceID() -> String? {
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        return stringProperty(source, key: kTISPropertyInputSourceID)
    }

    func selectInputSource(id: String) -> Bool {
        let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
        let sources = TISCreateInputSourceList(filter, false).takeRetainedValue() as NSArray
        guard sources.count > 0 else {
            return false
        }
        let source = sources[0] as! TISInputSource
        return TISSelectInputSource(source) == noErr
    }

    func enabledInputSources() -> [InputSourceInfo] {
        let sources = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
        return sources.compactMap { item in
            let source = item as! TISInputSource
            guard let id = stringProperty(source, key: kTISPropertyInputSourceID),
                  let name = stringProperty(source, key: kTISPropertyLocalizedName) else {
                return nil
            }

            if let enabled = boolProperty(source, key: kTISPropertyInputSourceIsEnabled), !enabled {
                return nil
            }

            return InputSourceInfo(id: id, name: name)
        }
    }

    private func stringProperty(_ source: TISInputSource, key: CFString) -> String? {
        guard let pointer = TISGetInputSourceProperty(source, key) else {
            return nil
        }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    private func boolProperty(_ source: TISInputSource, key: CFString) -> Bool? {
        guard let pointer = TISGetInputSourceProperty(source, key) else {
            return nil
        }
        let value = Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue()
        return CFBooleanGetValue(value)
    }
}
