import SwiftUI
import SwiftData
import HypeCheckKit

/// Manual fallback used when a page is JS-only / blocked, and as the
/// reviewer-friendly demo path (no share sheet required).
struct ManualEntryView: View {
    @Bindable var vm: AnalysisViewModel
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context

    @State private var urlText = ""
    @State private var title = ""
    @State private var brand = ""
    @State private var price = ""
    @State private var rating = ""
    @State private var reviews = ""
    @State private var details = ""
    @State private var mode: Mode = .url

    enum Mode: String, CaseIterable { case url = "From link", manual = "Enter details" }

    var body: some View {
        Form {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if mode == .url {
                Section("Product link") {
                    TextField("https://…", text: $urlText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }
                Button("Analyze") {
                    guard let url = URL(string: urlText.trimmingCharacters(in: .whitespaces)) else { return }
                    router.screen = .analyzing(url: url, sharedText: nil)
                    router.path.removeAll()
                }
                .disabled(URL(string: urlText) == nil)
            } else {
                Section("Required") {
                    TextField("Title", text: $title)
                    TextField("Price (e.g. 29.99)", text: $price)
                        .keyboardType(.decimalPad)
                }
                Section("Optional") {
                    TextField("Brand", text: $brand)
                    TextField("Rating 0–5", text: $rating)
                        .keyboardType(.decimalPad)
                    TextField("Review count", text: $reviews)
                        .keyboardType(.numberPad)
                    TextField("Description / specs", text: $details, axis: .vertical)
                        .lineLimit(3...8)
                }
                Button("Analyze") { runManual() }
                    .disabled(title.isEmpty)
            }
        }
        .navigationTitle("Check a product")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: vm.state) { _, new in
            if case .done = new { router.path = [.history] }
        }
    }

    private func runManual() {
        let product = ProductData(
            sourceURL: URL(string: urlText) ?? URL(string: "https://manual.entry")!,
            title: title,
            brand: brand.isEmpty ? nil : brand,
            price: Decimal(string: price),
            currency: "USD",
            rating: Double(rating),
            reviewCount: Int(reviews),
            productDescription: details)
        vm.runManual(product, context: context)
    }
}
