//
//  ParentPINSheet.swift
//  Sproutling
//
//  Sheet for entering or setting parent PIN
//

import SwiftUI

enum PINSheetMode {
    case verify
    case setup
    case change
}

struct ParentPINSheet: View {
    @EnvironmentObject var appState: AppState
    let mode: PINSheetMode
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var enteredPIN: String = ""
    @State private var confirmPIN: String = ""
    @State private var isConfirming: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var shakeOffset: CGFloat = 0

    private var title: String {
        switch mode {
        case .verify: return "Enter PIN"
        case .setup: return "Set Up PIN"
        case .change: return "Change PIN"
        }
    }

    private var subtitle: String {
        switch mode {
        case .verify:
            return "Enter your 4-digit parent PIN"
        case .setup:
            return isConfirming ? "Confirm your PIN" : "Create a 4-digit PIN"
        case .change:
            return isConfirming ? "Confirm your new PIN" : "Enter a new 4-digit PIN"
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    // Lock icon
                    lockIcon

                    // Subtitle
                    Text(subtitle)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    // PIN dots display
                    pinDotsView
                        .offset(x: shakeOffset)

                    // Error message
                    if showError {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }

                    // Number pad
                    numberPad

                    Spacer()
                }
                .padding(24)
                .padding(.top, 20)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }

    // MARK: - Lock Icon
    private var lockIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: .purple.opacity(0.4), radius: 12, y: 6)

            Image(systemName: mode == .verify ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
        }
    }

    // MARK: - PIN Dots View
    private var pinDotsView: some View {
        HStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { index in
                let currentPIN = isConfirming ? confirmPIN : enteredPIN
                let isFilled = index < currentPIN.count

                Circle()
                    .fill(isFilled ? Color.purple : Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.purple.opacity(0.5), lineWidth: 2)
                    )
                    .scaleEffect(isFilled ? 1.1 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isFilled)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("PIN entry. \(isConfirming ? confirmPIN.count : enteredPIN.count) of 4 digits entered")
    }

    // MARK: - Number Pad
    private var numberPad: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(1...3, id: \.self) { col in
                        let number = row * 3 + col
                        numberButton(number: number)
                    }
                }
            }

            // Bottom row: empty, 0, delete
            HStack(spacing: 24) {
                // Empty placeholder
                Circle()
                    .fill(Color.clear)
                    .frame(width: 72, height: 72)

                // Zero
                numberButton(number: 0)

                // Delete
                deleteButton
            }
        }
    }

    private func numberButton(number: Int) -> some View {
        Button(action: {
            addDigit(String(number))
        }) {
            Text("\(number)")
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                )
        }
        .buttonStyle(NumberPadButtonStyle())
        .accessibilityLabel("Number \(number)")
    }

    private var deleteButton: some View {
        Button(action: {
            deleteDigit()
        }) {
            Image(systemName: "delete.left.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 72, height: 72)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                )
        }
        .buttonStyle(NumberPadButtonStyle())
        .accessibilityLabel("Delete")
    }

    // MARK: - Actions
    private func addDigit(_ digit: String) {
        HapticFeedback.light()

        if isConfirming {
            guard confirmPIN.count < 4 else { return }
            confirmPIN += digit
            if confirmPIN.count == 4 {
                validateConfirmation()
            }
        } else {
            guard enteredPIN.count < 4 else { return }
            enteredPIN += digit
            if enteredPIN.count == 4 {
                handlePINComplete()
            }
        }
    }

    private func deleteDigit() {
        HapticFeedback.light()

        if isConfirming {
            if !confirmPIN.isEmpty {
                confirmPIN.removeLast()
            }
        } else {
            if !enteredPIN.isEmpty {
                enteredPIN.removeLast()
            }
        }
        showError = false
    }

    private func handlePINComplete() {
        switch mode {
        case .verify:
            if appState.verifyPIN(enteredPIN) {
                HapticFeedback.success()
                onSuccess()
            } else {
                showErrorAnimation(message: "Incorrect PIN. Try again.")
            }

        case .setup, .change:
            // Move to confirmation
            withAnimation {
                isConfirming = true
            }
        }
    }

    private func validateConfirmation() {
        if confirmPIN == enteredPIN {
            // PINs match, save it
            if appState.setPIN(enteredPIN) {
                HapticFeedback.success()
                onSuccess()
            } else {
                showErrorAnimation(message: "Failed to save PIN. Try again.")
            }
        } else {
            showErrorAnimation(message: "PINs don't match. Try again.")
            // Reset both PINs
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    enteredPIN = ""
                    confirmPIN = ""
                    isConfirming = false
                }
            }
        }
    }

    private func showErrorAnimation(message: String) {
        HapticFeedback.error()
        errorMessage = message
        withAnimation {
            showError = true
        }

        // Shake animation
        withAnimation(.default) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.default) {
                shakeOffset = -10
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.default) {
                shakeOffset = 10
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.default) {
                shakeOffset = 0
            }
        }

        // Clear PIN
        if mode == .verify {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                enteredPIN = ""
            }
        }
    }
}

// MARK: - Number Pad Button Style
struct NumberPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview("Verify Mode") {
    ParentPINSheet(
        mode: .verify,
        onSuccess: {},
        onCancel: {}
    )
    .environmentObject(AppState())
}

#Preview("Setup Mode") {
    ParentPINSheet(
        mode: .setup,
        onSuccess: {},
        onCancel: {}
    )
    .environmentObject(AppState())
}
