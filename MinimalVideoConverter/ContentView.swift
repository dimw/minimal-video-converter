import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {

    @EnvironmentObject var model: ConverterModel

    @State private var isImporterPresented = false
    @State var isDraggingOver = false

    var body: some View {
        ZStack {

            Color.clear
                .contentShape(Rectangle())
                .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
                    handleDrop(providers: providers)
                }

            VStack {

                Button(action: {
                    isImporterPresented = true
                }) {
                    VStack {
                        Image(systemName: "folder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                        Text("Select a video file...")
                    }
                    .padding()
                }

                Text(model.selectedFileURL?.lastPathComponent ?? "No file selected")
                    .foregroundStyle(model.selectedFileURL == nil ? .secondary : .primary)
                    .padding()
                    .fileImporter(
                        isPresented: $isImporterPresented,
                        allowedContentTypes: [.movie],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            model.selectedFileURL = urls.first
                        case .failure(let error):
                            print("Failed to import file: \(error.localizedDescription)")
                        }
                    }

                Picker("Export Format", selection: $model.selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                            .padding(.horizontal, 8)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 8)

                Picker("Resolution", selection: $model.resolution) {
                    ForEach(ResolutionScale.allCases) { scale in
                        Text(scale.rawValue).tag(scale)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 8)

                Picker("Speed", selection: $model.speed) {
                    ForEach(PlaybackSpeed.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 8)

                Toggle("Remove audio", isOn: $model.removeAudio)
                    .toggleStyle(.checkbox)
                    .padding(.bottom, 8)

                Button(action: {
                    if model.isExporting {
                        model.stopConversion()
                    } else if let url = model.selectedFileURL {
                        Task { await model.convert(inputURL: url) }
                    }
                }) {
                    ZStack {
                        Text("Convert")
                            .font(.headline)
                            .opacity(model.isExporting ? 0 : 1)
                        if model.isExporting {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 4)
                                Text("Stop")
                                    .font(.headline)
                            }
                        }
                    }
                }
                .buttonStyle(CTAButtonStyle(isEnabled: model.selectedFileURL != nil))

            }.padding()

            if isDraggingOver {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .opacity(0.95)
                    )
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        Text("Drop video here")
                            .font(.headline)
                    )
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDraggingOver)
        .frame(width: 400)
    }

    // MARK: - Drop handling

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    DispatchQueue.main.async {
                        if let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil),
                           url.pathExtension.lowercased().matchesAny(of: ["mp4", "mov", "m4v"]) {
                            self.model.selectedFileURL = url
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}

extension String {
    func matchesAny(of extensions: [String]) -> Bool {
        extensions.contains { self.lowercased() == $0.lowercased() }
    }
}


#Preview {
    ContentView()
        .environmentObject(ConverterModel())
}

#Preview {
    ContentView()
        .environmentObject(ConverterModel())
        .preferredColorScheme(.light)
        .frame(width: 400, height: 300)
        .padding()
}
