import SwiftUI

struct LoadingView: View {
    let state: AnalysisViewModel.State

    var body: some View {
        VStack(spacing: 28) {
            switch state {
            case .failed(let msg, _):
                FailureView(message: msg)
            default:
                ProgressView()
                    .controlSize(.large)
                Text(label)
                    .font(.headline)
                    .contentTransition(.opacity)
                Text("Reading the page on your device — nothing is uploaded.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .navigationTitle("Analyzing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var label: String {
        switch state {
        case .fetching: return "Fetching the listing…"
        case .reading: return "Reading product details…"
        case .scoring: return "Scoring against the hype…"
        default: return "Working…"
        }
    }
}

private struct FailureView: View {
    let message: String
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("Couldn't analyze automatically")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Enter details manually") {
                router.screen = .home
                router.path.append(.manualEntry)
            }
            .buttonStyle(.borderedProminent)
            Button("Back home") { router.screen = .home }
        }
    }
}
