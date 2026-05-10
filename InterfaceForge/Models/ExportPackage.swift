import Foundation

struct ExportFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let contents: String
}

struct ExportPackage: Identifiable, Hashable {
    let id = UUID()
    let packageName: String
    let outputType: OutputType
    let files: [ExportFile]
    let beginnerGuide: String

    var combinedText: String {
        files.map { file in
            "// MARK: \(file.name)\n\n\(file.contents)"
        }
        .joined(separator: "\n\n")
    }
}
