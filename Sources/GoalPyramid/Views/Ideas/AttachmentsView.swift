import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AppKit

/// "Идеялар" парағының ішіндегі тіркемелер тартпасы: файл/сурет таңдау
/// (NSOpenPanel), Cmd+V (алмасу буферінен), drag & drop — үшеуі де осында
/// жиналады. Тек осы бет үшін — басқа беттерге (Бүгін, Апта, т.б.) тимейді.
struct AttachmentsView: View {
    let noteID: UUID

    @Environment(\.modelContext) private var context
    @Environment(\.appLanguage) private var language
    @Query private var allAttachments: [NoteAttachment]

    @State private var showingImporter = false
    @State private var isDropTargeted = false
    @State private var zoomedAttachment: NoteAttachment?
    @State private var errorMessage: String?
    @State private var showingError = false

    private var attachments: [NoteAttachment] {
        allAttachments
            .filter { $0.noteID == noteID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.t(.attachmentsLabel, language))
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showingImporter = true
                } label: {
                    Label(L10n.t(.attachFileAction, language), systemImage: "paperclip")
                }
                .buttonStyle(.plain)
                .font(.caption)
            }

            if !attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(attachments) { attachment in
                            attachmentTile(attachment)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.accent, lineWidth: isDropTargeted ? 2 : 0)
        )
        .onDrop(of: [.fileURL, .image], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
            return true
        }
        .onPasteCommand(of: [.image, .fileURL]) { providers in
            handlePaste(providers)
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls { importFile(url) }
            case .failure(let error):
                presentError(error.localizedDescription)
            }
        }
        .sheet(item: $zoomedAttachment) { attachment in
            ImageZoomView(url: AttachmentStore.fileURL(for: attachment.storedFileName), language: language)
        }
        .alert(L10n.t(.settingsErrorTitle, language), isPresented: $showingError) {
            Button(L10n.t(.settingsOK, language), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func attachmentTile(_ attachment: NoteAttachment) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                tileThumbnail(attachment)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.08))
                    )

                Button {
                    delete(attachment)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.secondary, .white)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
                .help(L10n.t(.removeAttachmentHelp, language))
            }
            Text(attachment.originalFileName)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 72)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if !attachment.isImage {
                NSWorkspace.shared.open(AttachmentStore.fileURL(for: attachment.storedFileName))
            }
        }
        .onTapGesture(count: 1) {
            if attachment.isImage {
                zoomedAttachment = attachment
            }
        }
    }

    @ViewBuilder
    private func tileThumbnail(_ attachment: NoteAttachment) -> some View {
        if attachment.isImage, let data = attachment.thumbnailData, let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
        } else {
            ZStack {
                Theme.cardBackground
                Image(systemName: "doc.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func importFile(_ url: URL) {
        do {
            let result = try AttachmentStore.importFile(from: url)
            saveAttachment(result)
        } catch {
            presentError("\(L10n.t(.attachFailedError, language)): \(error.localizedDescription)")
        }
    }

    private func saveAttachment(_ result: NoteAttachmentImportResult) {
        let attachment = NoteAttachment(
            noteID: noteID,
            originalFileName: result.originalFileName,
            storedFileName: result.storedFileName,
            isImage: result.isImage,
            thumbnailData: result.thumbnailData
        )
        context.insert(attachment)
    }

    private func delete(_ attachment: NoteAttachment) {
        AttachmentStore.delete(storedFileName: attachment.storedFileName)
        context.delete(attachment)
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async { importFile(url) }
            }
        }
    }

    private func handlePaste(_ providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSImage.self) {
                _ = provider.loadObject(ofClass: NSImage.self) { image, _ in
                    guard let nsImage = image as? NSImage,
                          let tiff = nsImage.tiffRepresentation,
                          let rep = NSBitmapImageRep(data: tiff),
                          let pngData = rep.representation(using: .png, properties: [:]) else { return }
                    DispatchQueue.main.async {
                        do {
                            let name = "Screenshot-\(Int(Date().timeIntervalSince1970)).png"
                            let result = try AttachmentStore.importData(pngData, suggestedName: name, isImage: true)
                            saveAttachment(result)
                        } catch {
                            presentError("\(L10n.t(.attachFailedError, language)): \(error.localizedDescription)")
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    DispatchQueue.main.async { importFile(url) }
                }
            }
        }
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

/// Суретті бір басқанда толығырақ көрсететін жеңіл "zoom" беті — толық
/// QLPreviewPanel интеграциясының орнына (тұрақтырақ, аз тәуекел).
struct ImageZoomView: View {
    let url: URL
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            .padding(10)

            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding([.horizontal, .bottom], 16)
            } else {
                Text(L10n.t(.imageLoadFailed, language))
                    .foregroundStyle(.secondary)
                    .padding(40)
            }
        }
        .frame(minWidth: 420, minHeight: 320)
    }
}
