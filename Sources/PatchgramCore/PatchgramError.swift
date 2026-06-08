import Foundation

public enum PatchgramError: LocalizedError, Equatable {
    case invalidAppBundle(String)
    case unsupportedAppBundle(String)
    case destinationExists(String)
    case missingFile(String)
    case missingExecutable(String)
    case binaryPatternNotFound(String)
    case binaryPatternAmbiguous(String, Int)
    case incompatibleBinaryPatch(String)
    case processFailed(String)
    case transformFailed(String)
    case unknownRule(String)
    case unreadableFile(String)
    case missingWriteAccess(String)

    public var errorDescription: String? {
        switch self {
        case let .invalidAppBundle(path):
            return "`\(path)` does not look like a Telegram Desktop app bundle."
        case let .unsupportedAppBundle(bundleIdentifier):
            return "`\(bundleIdentifier)` is not supported by Patchgram. Select the official Telegram Desktop app bundle (`com.tdesktop.Telegram`)."
        case let .destinationExists(path):
            return "Destination already exists: `\(path)`."
        case let .missingFile(path):
            return "Required file is missing: `\(path)`."
        case let .missingExecutable(path):
            return "Could not find app executable: `\(path)`."
        case let .binaryPatternNotFound(name):
            return "Binary pattern was not found: `\(name)`. This Telegram build likely needs a new pattern pack."
        case let .binaryPatternAmbiguous(name, count):
            return "Binary pattern `\(name)` matched \(count) times; refusing to patch ambiguously."
        case let .incompatibleBinaryPatch(message):
            return message
        case let .processFailed(message):
            return message
        case let .transformFailed(message):
            return message
        case let .unknownRule(id):
            return "Unknown patch rule: `\(id)`."
        case let .unreadableFile(path):
            return "Could not read or write file: `\(path)`."
        case let .missingWriteAccess(path):
            return "Patchgram does not have write access to `\(path)`. Choose a writable app copy or grant edit access and try again."
        }
    }
}
