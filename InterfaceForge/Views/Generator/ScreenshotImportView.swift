import SwiftUI
import PhotosUI

/// Lets users import a screenshot or take a photo of a UI, then uses GPT-4o vision
/// to generate a component description that feeds into the generator.
struct ScreenshotImportView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var showCamera = false

    private let visionService = VisionService()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    GradientIconBadge(
                        systemImage: "camera.viewfinder",
                        theme: viewModel.configuration.theme,
                        size: 56
                    )
                    Text("Screenshot to Component")
                        .font(.system(.title2, design: .rounded, weight: .black))
                    Text("Take a photo or pick a screenshot of any UI. AI will analyze it and create a matching component prompt.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)

                // Image picker area
                if let image = selectedImage {
                    // Show selected image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(viewModel.configuration.theme.accent.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: viewModel.configuration.theme.accent.opacity(0.15), radius: 20, y: 10)

                    if isAnalyzing {
                        HStack(spacing: 10) {
                            ProgressView()
                                .tint(viewModel.configuration.theme.accent)
                            Text("Analyzing screenshot...")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else {
                        HStack(spacing: 12) {
                            PrimaryButton(
                                title: "Analyze & Generate",
                                systemImage: "sparkles",
                                theme: viewModel.configuration.theme
                            ) {
                                Task { await analyzeImage(image) }
                            }
                        }

                        Button("Choose a different image") {
                            selectedImage = nil
                            selectedItem = nil
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    }
                } else {
                    // Import options
                    VStack(spacing: 14) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Choose from Photos", systemImage: "photo.on.rectangle")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 54)
                                .foregroundStyle(.white)
                                .background(viewModel.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }

                        Button {
                            showCamera = true
                        } label: {
                            Label("Take a Photo", systemImage: "camera.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 54)
                                .foregroundStyle(viewModel.configuration.theme.accent)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(viewModel.configuration.theme.accent.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }

                    InfoCallout(
                        title: "How it works",
                        message: "The image is sent to your configured AI provider (GPT-4o or compatible vision model) to identify the UI structure. The result becomes your component prompt — no image data is stored.",
                        systemImage: "eye.fill",
                        theme: viewModel.configuration.theme
                    )
                }

                if let error = analysisError {
                    InfoCallout(
                        title: "Analysis failed",
                        message: error,
                        systemImage: "exclamationmark.triangle.fill",
                        theme: viewModel.configuration.theme
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .appBackground(theme: viewModel.configuration.theme)
        .navigationTitle("Screenshot Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
                    .font(.subheadline.weight(.semibold))
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
                .ignoresSafeArea()
        }
    }

    private func analyzeImage(_ image: UIImage) async {
        isAnalyzing = true
        analysisError = nil

        let result = visionService.analyze(
            image: image,
            apiKey: viewModel.aiAPIKey,
            endpoint: viewModel.aiEndpoint,
            model: viewModel.aiModel
        )

        let visionResult = await result

        if let error = visionResult.error {
            analysisError = error
            isAnalyzing = false
            return
        }

        // Set the prompt and optionally the template
        viewModel.prompt = visionResult.componentDescription

        if let templateID = visionResult.suggestedTemplate {
            viewModel.selectedTemplate = DesignTemplate.all.first(where: { $0.id == templateID })
        }

        isAnalyzing = false
        dismiss()
    }
}

// MARK: - Camera view

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
