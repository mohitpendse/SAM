//
//  SignUpView.swift
//  ASM
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var store: ASMStore
    @State private var name = ""
    @State private var email = ""
    @State private var code = ""
    @State private var isVerifying = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.asmInk)
                    Text("ASM")
                        .font(.system(size: 22, weight: .bold))
                }
                .padding(.top, 36)

                Spacer()

                Text(isVerifying ? "Verification" : "Welcome,")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.asmInk)
                    .frame(maxWidth: 420, alignment: .leading)

                Text(isVerifying ? "Check your inbox." : "to a new way to study.")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.asmMutedInk)
                    .frame(maxWidth: 400, alignment: .leading)

                Spacer()
            }
            .padding(.horizontal, 56)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.asmCanvas)

            .frame(width: 500)
            .frame(maxHeight: .infinity)
            .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.asmLine))
            .padding(.vertical, 36)
            .padding(.trailing, 36)

            VStack(alignment: .leading, spacing: 14) {
                Spacer()

                if isVerifying {
                    Image(systemName: "envelope")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.asmMutedInk)
                        .frame(maxWidth: .infinity)
                    Text("Tap the magic link in the email sent to")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.asmMutedInk)
                    Text(email)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .fontWeight(.semibold)
                    field("Enter 6-digit code", text: $code)
                    Button {
                        store.createAccount(name: name.isEmpty ? "Student" : name, email: email)
                    } label: {
                        Text("Submit code")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    Button("Use a different email") {
                        isVerifying = false
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.asmMutedInk)
                    .frame(maxWidth: .infinity)
                } else {
                    Button("Continue with Google", systemImage: "g.circle.fill") {}
                        .buttonStyle(SecondaryButtonStyle())
                    Button("Continue with Apple", systemImage: "apple.logo") {}
                        .buttonStyle(SecondaryButtonStyle())
                    Divider().overlay(Color.asmLine)
                    field("Student or personal email", text: $email)
                    Button {
                        isVerifying = true
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Spacer()
            }
            .padding(.horizontal, 34)
            .frame(width: 400)
        }
        .background(Color.asmCanvas)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.asmMutedInk)
            TextField(title, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 17, weight: .medium))
                .padding(12)
                .background(Color.asmMist, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.asmLine))
        }
    }

    private func showcaseCard(_ icon: String, _ title: String, _ detail: String, _ color: Color, x: CGFloat, y: CGFloat) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            Text(title).font(.system(size: 14, weight: .semibold))
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(Color.asmMutedInk)
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(width: 170, height: 150)
        .background(Color.asmCanvas, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.asmLine))
        .offset(x: x, y: y)
    }
}
