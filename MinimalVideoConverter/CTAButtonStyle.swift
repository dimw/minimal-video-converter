import SwiftUI

struct CTAButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor)
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
            .opacity(configuration.isPressed ? 0.7 : (isEnabled ? 1 : 0.5))
            .disabled(!isEnabled)
    }
}
