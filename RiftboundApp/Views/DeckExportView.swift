import SwiftUI

struct DeckExportView: View {
    @ObservedObject var viewModel: DeckDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var exportJSON = ""
    @State private var showCopiedAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Export your deck as JSON to share with others")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ScrollView {
                    Text(exportJSON)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }

                VStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = exportJSON
                        showCopiedAlert = true
                    } label: {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }

                    ShareLink(item: exportJSON) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .navigationTitle("Export Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Copied!", isPresented: $showCopiedAlert) {
                Button("OK") { }
            }
            .task {
                do {
                    exportJSON = try viewModel.exportJSON()
                } catch {
                    exportJSON = "Error exporting deck: \(error.localizedDescription)"
                }
            }
        }
    }
}
