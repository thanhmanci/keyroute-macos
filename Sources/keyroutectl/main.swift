import Carbon
import Foundation

let englishInputSourceID = "com.apple.keylayout.ABC"
let vietnameseInputSourceID = "com.apple.inputmethod.VietnameseIM.VietnameseSimpleTelex"

func stringProperty(_ source: TISInputSource, key: CFString) -> String? {
    guard let pointer = TISGetInputSourceProperty(source, key) else {
        return nil
    }
    return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
}

func boolProperty(_ source: TISInputSource, key: CFString) -> Bool? {
    guard let pointer = TISGetInputSourceProperty(source, key) else {
        return nil
    }
    let value = Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue()
    return CFBooleanGetValue(value)
}

func currentInputSourceID() -> String? {
    let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    return stringProperty(source, key: kTISPropertyInputSourceID)
}

@discardableResult
func selectInputSource(id: String) -> Bool {
    let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
    let sources = TISCreateInputSourceList(filter, false).takeRetainedValue() as NSArray
    guard sources.count > 0 else {
        return false
    }
    let source = sources[0] as! TISInputSource
    return TISSelectInputSource(source) == noErr
}

func listInputSources() {
    let sources = TISCreateInputSourceList(nil, false).takeRetainedValue() as NSArray
    for item in sources {
        let source = item as! TISInputSource
        guard let id = stringProperty(source, key: kTISPropertyInputSourceID),
              let name = stringProperty(source, key: kTISPropertyLocalizedName) else {
            continue
        }

        if let enabled = boolProperty(source, key: kTISPropertyInputSourceIsEnabled), !enabled {
            continue
        }

        print("\(id)\t\(name)")
    }
}

func printUsageAndExit() -> Never {
    let command = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "keyroutectl"
    fputs("""
    Usage:
      \(command) current
      \(command) list
      \(command) en
      \(command) vi
      \(command) select <input-source-id>

    Defaults:
      EN: \(englishInputSourceID)
      VI: \(vietnameseInputSourceID)

    """, stderr)
    exit(64)
}

let args = Array(CommandLine.arguments.dropFirst())
guard let command = args.first else {
    printUsageAndExit()
}

switch command {
case "current":
    if let current = currentInputSourceID() {
        print(current)
    } else {
        exit(1)
    }
case "list":
    listInputSources()
case "en":
    exit(selectInputSource(id: englishInputSourceID) ? 0 : 1)
case "vi":
    exit(selectInputSource(id: vietnameseInputSourceID) ? 0 : 1)
case "select":
    guard args.count == 2 else {
        printUsageAndExit()
    }
    exit(selectInputSource(id: args[1]) ? 0 : 1)
default:
    printUsageAndExit()
}
