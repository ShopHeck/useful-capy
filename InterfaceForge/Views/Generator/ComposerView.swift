import SwiftUI

struct ComposerView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @State private var path: [AppRoute] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepRail(activeStep: viewModel.selectedStep)
                    .padding(.horizontal, -16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe the component")
                        .font(.largeTitle.weight(.black))
                    Text("Use normal words. InterfaceForge picks a matching local template, adds your style, and prepares export-ready code.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                GlassCard(radius: 30) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What do you want to make?")
                            .font(.headline)
                        TextEditor(text: $viewModel.prompt)
                            .frame(minHeight: 116)
                            .padding(12)
                            .scrollContentBackground(.hidden)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(alignment: .topLeading) {
                                if viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Example: A friendly pricing card for my design course")
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 20)
                                        .padding(.leading, 18)
                                        .allowsHitTesting(false)
                                }
                            }
                            .accessibilityLabel("Describe your component")

                        Text("Quick starts")
                            .font(.subheadline.weight(.bold))
                        FlowLayout(spacing: 8) {
                            ForEach(viewModel.quickStartPrompts, id: \.self) { prompt in
                                Chip(title: prompt, isSelected: viewModel.prompt == prompt) {
                                    viewModel.useQuickStart(prompt)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                TemplatePicker()
                    .padding(.horizontal)

                StyleControlsView()
                    .padding(.horizontal)

                if viewModel.isGenerating {
                    GenerationProgressView()
                        .padding(.horizontal)
                } else {
                    PrimaryButton(title: "Generate interface", systemImage: "wand.and.stars", theme: viewModel.configuration.theme) {
                        Task { await viewModel.generate() }
                    }
                    .padding(.horizontal)
                }

                if viewModel.generatedDesign != nil, !viewModel.isGenerating {
                    NavigationLink(value: AppRoute.preview) {
                        Label("Open interactive preview", systemImage: "play.rectangle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Open interactive preview")
                }
            }
            .padding(.vertical, 18)
        }
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(theme: viewModel.configuration.theme)
        .onAppear { viewModel.selectedStep = .describe }
    }
}

struct TemplatePicker: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Template")
                    .font(.headline)
                Spacer()
                Text("Auto if none selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DesignTemplate.all) { template in
                        Button {
                            viewModel.selectedTemplate = template
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Image(systemName: template.iconName)
                                    .font(.title2)
                                    .foregroundStyle(viewModel.configuration.theme.gradient)
                                Text(template.title)
                                    .font(.headline)
                                Text(template.shortDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(width: 180, alignment: .leading)
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(viewModel.selectedTemplate?.id == template.id ? viewModel.configuration.theme.accent : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Template \(template.title)")
                    }
                }
            }
        }
    }
}

struct StyleControlsView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Customize")
                        .font(.headline)
                    Spacer()
                    Label("Live updates", systemImage: "bolt.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(viewModel.configuration.theme.accent)
                }

                Picker("Color theme", selection: $viewModel.configuration.theme) {
                    ForEach(ColorTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Color theme")

                Picker("Visual style", selection: $viewModel.configuration.visualStyle) {
                    ForEach(VisualStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .accessibilityLabel("Visual style")

                Picker("Motion level", selection: $viewModel.configuration.motionLevel) {
                    ForEach(MotionLevel.allCases) { motion in
                        Text(motion.rawValue).tag(motion)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Motion level")

                Picker("Export format", selection: $viewModel.configuration.outputType) {
                    ForEach(OutputType.allCases) { outputType in
                        Text(outputType.rawValue).tag(outputType)
                    }
                }
                .accessibilityLabel("Target platform or output type")
            }
        }
    }
}

struct GenerationProgressView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @State private var sparkle = false

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(viewModel.configuration.theme.gradient)
                        .scaleEffect(sparkle ? 1.16 : 0.9)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: sparkle)
                    VStack(alignment: .leading) {
                        Text("Generating locally")
                            .font(.headline)
                        Text(viewModel.progressMessage)
                            .foregroundStyle(.secondary)
                    }
                }
                ProgressView(value: viewModel.generationProgress)
                    .tint(viewModel.configuration.theme.accent)
            }
        }
        .onAppear { sparkle = true }
        .accessibilityLabel("Generation progress")
    }
}
