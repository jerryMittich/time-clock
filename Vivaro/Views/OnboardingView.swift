import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "location.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(.tint)
            Text("Hands-free time clock")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 16) {
                feature("mappin.and.ellipse", "Add your workplaces on the map.")
                feature("figure.walk.arrival", "Vivaro clocks you in when you arrive and out when you leave.")
                feature("chart.bar.fill", "See hours, overtime and earnings, and export to CSV.")
                feature("lock.fill", "Your data stays on your iPhone.")
            }
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
                Text("Get started").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }

    private func feature(_ icon: String, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36)
            Text(text)
        }
    }
}
