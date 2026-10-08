import Foundation

/// Filter options for exporting transaction records to CSV.
public struct CSVExportOptions: Sendable, Equatable {
    public var startDay: String? // Inclusive: YYYY-MM-DD
    public var endDay: String?   // Inclusive: YYYY-MM-DD
    public var types: Set<TransactionType>?
    public var includeNotes: Bool
    public var includeMerchant: Bool
    
    public init(
        startDay: String? = nil,
        endDay: String? = nil,
        types: Set<TransactionType>? = nil,
        includeNotes: Bool = true,
        includeMerchant: Bool = true
    ) {
        self.startDay = startDay
        self.endDay = endDay
        self.types = types
        self.includeNotes = includeNotes
        self.includeMerchant = includeMerchant
    }
}

/// Pure domain utility to generate RFC 4180 compliant CSV exports for transactions.
/// Strictly uses integer minor unit arithmetic for decimal formatting; never uses Float or Double.
public enum CSVExporter {
    
    /// Standard CSV column headers
    public static let headers = ["Date", "Type", "Amount", "Currency", "Category", "Merchant", "Note", "Payment Method"]
    
    /// Filters a list of transactions based on provided options.
    public static func filter(
        transactions: [Transaction],
        options: CSVExportOptions
    ) -> [Transaction] {
        return transactions.filter { tx in
            if tx.isDeleted { return false }
            
            if let startDay = options.startDay, tx.transactionDay < startDay {
                return false
            }
            if let endDay = options.endDay, tx.transactionDay > endDay {
                return false
            }
            if let types = options.types, !types.contains(tx.type) {
                return false
            }
            return true
        }
        .sorted { $0.transactionDay > $1.transactionDay }
    }
    
    /// Generates RFC 4180 compliant CSV string from transactions and category mapping.
    public static func generateCSV(
        transactions: [Transaction],
        categoryNames: [UUID: String] = [:],
        options: CSVExportOptions = .init()
    ) -> String {
        let filtered = filter(transactions: transactions, options: options)
        
        var lines: [String] = []
        // Header line
        lines.append(headers.joined(separator: ","))
        
        // Data lines
        for tx in filtered {
            let date = tx.transactionDay
            let type = tx.type.rawValue.capitalized
            
            let currency = CurrencyCode.from(code: tx.currencyCode)
            let amount = formatDecimal(amountMinor: tx.amountMinor, exponent: currency.minorUnitExponent)
            let currencyCode = tx.currencyCode
            
            let category: String
            if let snapshot = tx.categoryNameSnapshot, !snapshot.isEmpty {
                category = snapshot
            } else if let catId = tx.categoryId, let name = categoryNames[catId] {
                category = name
            } else {
                category = "Uncategorized"
            }
            
            let merchant = options.includeMerchant ? (tx.merchant ?? "") : ""
            let note = options.includeNotes ? (tx.note ?? "") : ""
            let paymentMethod = tx.paymentMethod?.rawValue.uppercased() ?? ""
            
            let row = [
                escapeField(date),
                escapeField(type),
                escapeField(amount),
                escapeField(currencyCode),
                escapeField(category),
                escapeField(merchant),
                escapeField(note),
                escapeField(paymentMethod)
            ].joined(separator: ",")
            
            lines.append(row)
        }
        
        // RFC 4180 specifies CRLF as line delimiter
        return lines.joined(separator: "\r\n") + "\r\n"
    }
    
    /// Generates UTF-8 encoded Data for CSV export.
    public static func generateCSVData(
        transactions: [Transaction],
        categoryNames: [UUID: String] = [:],
        options: CSVExportOptions = .init()
    ) -> Data? {
        let csvString = generateCSV(transactions: transactions, categoryNames: categoryNames, options: options)
        return csvString.data(using: .utf8)
    }
    
    /// Escapes an individual field according to RFC 4180.
    /// If the field contains a comma, quote, or newline (CR/LF), it is enclosed in double quotes,
    /// and any internal double quotes are escaped by doubling them ("").
    public static func escapeField(_ value: String) -> String {
        let needsQuoting = value.contains(",") || value.contains("\"") || value.contains(where: { $0.isNewline })
        if needsQuoting {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return value
    }
    
    /// Formats integer minor units into standard decimal string without using floating-point math.
    public static func formatDecimal(amountMinor: Int64, exponent: Int) -> String {
        if exponent <= 0 {
            return "\(amountMinor)"
        }
        
        let isNegative = amountMinor < 0
        let absAmount = abs(amountMinor)
        
        var divisor: Int64 = 1
        for _ in 0..<exponent {
            divisor *= 10
        }
        
        let units = absAmount / divisor
        let fraction = absAmount % divisor
        let fractionFormat = "%0*lld"
        let fractionString = String(format: fractionFormat, exponent, fraction)
        
        let prefix = isNegative ? "-" : ""
        return "\(prefix)\(units).\(fractionString)"
    }
}
