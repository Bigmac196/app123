import SwiftUI
import SwiftData
import WorthItKit

struct HistoryView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var context
    @Query(sort: \CheckRecord.createdAt, order: .reverse)
    private var records: [CheckRecord]
    @State private var search = ""

    private var filtered: [CheckRecord] {
        guard !search.isEmpty else { return records }
        return records.filter {
            $0.title.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        List {
            if filtered.isEmpty {
                ContentUnavailableView("No checks yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Products you check will appear here."))
            }
            ForEach(filtered) { record in
                Button {
                    router.path.append(.historyDetail(record.id))
                } label: {
                    HistoryRow(record: record)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: delete)
        }
        .searchable(text: $search)
        .navigationTitle("History")
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(filtered[i]) }
        try? context.save()
    }
}

struct HistoryRow: View {
    let record: CheckRecord
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.verdict.symbolName)
                .foregroundStyle(Color(hex: record.verdict.tintHex))
                .font(.title3)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title.isEmpty ? "Untitled product" : record.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text("\(record.verdict.headline) · \(Int(record.score))/100")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
