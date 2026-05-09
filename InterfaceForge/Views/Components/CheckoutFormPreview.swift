import SwiftUI

struct CheckoutFormPreview: View {
    let design: GeneratedDesign
    @State private var email = ""
    @State private var project = ""
    @State private var submitted = false

    var body: some View {
        GlassCard(radius: design.configuration.visualStyle.cornerRadius) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(design.headline)
                            .font(.title.weight(.black))
                        Text(design.subheadline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "lock.shield.fill")
                        .font(.largeTitle)
                        .foregroundStyle(design.configuration.theme.gradient)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.caption.weight(.bold))
                    TextField("you@example.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(14)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(validationBorder(isValid: emailIsValid || email.isEmpty))
                        .accessibilityLabel("Email address")
                    if !email.isEmpty {
                        Label(emailIsValid ? "Looks good" : "Add an @ symbol to make this a real email", systemImage: emailIsValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(emailIsValid ? .green : .orange)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Project details")
                        .font(.caption.weight(.bold))
                    TextField("Tell us what you want to build", text: $project, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                        .padding(14)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(validationBorder(isValid: project.count >= 8 || project.isEmpty))
                        .accessibilityLabel("Project details")
                }

                Button {
                    withAnimation(design.configuration.motionLevel.spring) {
                        submitted = emailIsValid && project.count >= 8
                    }
                } label: {
                    Label(submitted ? "Request ready to send" : "Check form", systemImage: submitted ? "checkmark.circle.fill" : "paperplane.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .foregroundStyle(.white)
                        .background(design.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Check form")
            }
        }
    }

    private var emailIsValid: Bool {
        email.contains("@") && email.contains(".")
    }

    private func validationBorder(isValid: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(isValid ? Color.clear : Color.orange, lineWidth: 1.5)
    }
}
