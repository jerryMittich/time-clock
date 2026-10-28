import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "clock.badge.checkmark.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .frame(width: 128, height: 128)
                .glassCard(cornerRadius: 64)
            Text("Hands-free time clock")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 18) {
                feature("mappin.and.ellipse", "Add your workplaces on the map.")
                feature("figure.walk.arrival", "Timaro clocks you in when you arrive and out when you leave.")
                feature("hourglass", "Track breaks, overtime and your time account.")
                feature("sun.max.fill", "Plan vacation, including half days.")
                feature("lock.fill", "Your data stays on your iPhone.")
            }
            .padding(20)
            .glassCard(cornerRadius: 28)
            Spacer()
            Text("To track automatically, allow location access \"Always\" when asked.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                LocationMonitor.shared.requestAuthorization()
                NotificationService.requestAuthorization()
                onFinish()
            } label: {
                Text("Get started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .prominentButton()
            .controlSize(.large)
        }
        .padding(24)
        .background(AppBackground())
    }

    private func feature(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
            Text(text)
        }
    }
}
