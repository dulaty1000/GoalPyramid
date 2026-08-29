import Foundation
import AppKit
import UniformTypeIdentifiers
import ImageIO

/// Бір импорттау әрекетінің нәтижесі — `NoteAttachment` жазбасын құруға
/// қажетті барлық өріс.
struct NoteAttachmentImportResult {
    let storedFileName: String
    let originalFileName: String
    let isImage: Bool
    let thumbnailData: Data?
}

/// "Идеялар" тіркемелерінің іс жүзіндегі файлдарын дискіде сақтайды.
/// Барлығы толықтай offline — `~/Library/Application Support/<bundle-id>/
/// Attachments/` папкасында, интернетке тәуелсіз.
enum AttachmentStore {
    static let directory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let bundleID = Bundle.main.bundleIdentifier ?? "GoalPyramid"
        let dir = base.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent("Attachments", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func fileURL(for storedFileName: String) -> URL {
        directory.appendingPathComponent(storedFileName)
    }

    private static func uniqueStoredName(extension ext: String) -> String {
        UUID().uuidString + (ext.isEmpty ? "" : ".\(ext)")
    }

    static func isImageFile(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .image)
    }

    /// NSOpenPanel/drag-and-drop арқылы келген файлды көшіріп сақтайды.
    static func importFile(from sourceURL: URL) throws -> NoteAttachmentImportResult {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

        let storedName = uniqueStoredName(extension: sourceURL.pathExtension)
        let dest = fileURL(for: storedName)
        try FileManager.default.copyItem(at: sourceURL, to: dest)

        let isImage = isImageFile(dest)
        return NoteAttachmentImportResult(
            storedFileName: storedName,
            originalFileName: sourceURL.lastPathComponent,
            isImage: isImage,
            thumbnailData: isImage ? makeThumbnail(from: dest) : nil
        )
    }

    /// Алмасу буферінен (Cmd+V) келген дайын Data (мыс. скриншот).
    static func importData(_ data: Data, suggestedName: String, isImage: Bool) throws -> NoteAttachmentImportResult {
        let ext = (suggestedName as NSString).pathExtension
        let storedName = uniqueStoredName(extension: ext)
        let dest = fileURL(for: storedName)
        try data.write(to: dest)
        return NoteAttachmentImportResult(
            storedFileName: storedName,
            originalFileName: suggestedName,
            isImage: isImage,
            thumbnailData: isImage ? makeThumbnail(from: dest) : nil
        )
    }

    static func delete(storedFileName: String) {
        try? FileManager.default.removeItem(at: fileURL(for: storedFileName))
    }

    static func makeThumbnail(from url: URL, maxPixelSize: CGFloat = 240) -> Data? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let rep = NSBitmapImageRep(cgImage: cgThumb)
        return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
    }
}
