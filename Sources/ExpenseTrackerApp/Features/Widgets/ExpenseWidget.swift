import SwiftUI
import ExpenseTrackerCore

#if canImport(WidgetKit)
import WidgetKit

/// Timeline entry holding a snapshot of budget and spend metrics.
public struct ExpenseWidgetEntry: TimelineEntry {
    public let date: Date
    public let snapshot: WidgetSnapshot
    
    public init(date: Date, snapshot: WidgetSnapshot) {
        self.date = date
        self.snapshot = snapshot
    }
}

/// Supplies timeline entries to WidgetKit by reading the shared WidgetDataStore snapshot.
public struct ExpenseWidgetTimelineProvider: TimelineProvider {
    private let dataStore: WidgetDataStoreProtocol
    
    public init(dataStore: WidgetDataStoreProtocol = WidgetDataStore()) {
        self.dataStore = dataStore
    }
    
    public func placeholder(in context: Context) -> ExpenseWidgetEntry {
        ExpenseWidgetEntry(date: Date(), snapshot: .placeholder)
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (ExpenseWidgetEntry) -> Void) {
        if context.isPreview {
            completion(ExpenseWidgetEntry(date: Date(), snapshot: .placeholder))
            return
        }
        Task {
            let loaded = await dataStore.loadSnapshot() ?? .placeholder
            completion(ExpenseWidgetEntry(date: Date(), snapshot: loaded))
        }
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<ExpenseWidgetEntry>) -> Void) {
        Task {
            let loaded = await dataStore.loadSnapshot() ?? .placeholder
            let entry = ExpenseWidgetEntry(date: Date(), snapshot: loaded)
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

/// Renders the appropriate SwiftUI layout based on the widget family.
public struct ExpenseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    public let entry: ExpenseWidgetEntry
    
    public init(entry: ExpenseWidgetEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        switch family {
        case .systemSmall:
            SmallBudgetWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            MediumBudgetWidgetView(snapshot: entry.snapshot)
        case .accessoryCircular:
            AccessoryCircularBudgetView(snapshot: entry.snapshot)
        case .accessoryRectangular:
            AccessoryRectangularBudgetView(snapshot: entry.snapshot)
        default:
            SmallBudgetWidgetView(snapshot: entry.snapshot)
        }
    }
}

/// WidgetKit declaration supporting Small, Medium, and Lock Screen accessories.
public struct ExpenseWidget: Widget {
    public static let kind: String = "ExpenseTrackerWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: ExpenseWidgetTimelineProvider()) { entry in
            ExpenseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget & Safe-to-Spend")
        .description("Track remaining budget and daily safe-to-spend at a glance.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
#endif
