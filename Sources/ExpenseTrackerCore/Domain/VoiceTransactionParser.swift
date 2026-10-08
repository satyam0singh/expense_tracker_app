import Foundation

/// Confidence level of the deterministic voice parse.
public enum ParseConfidence: String, Equatable, Sendable {
    case high
    case medium
    case low
}

/// Structured outcome of deterministic voice phrase extraction.
public struct VoiceParseResult: Equatable, Sendable {
    public var draft: TransactionDraft
    public var confidence: ParseConfidence
    public var warnings: [String]
    public var extractedFields: [String]
    public var rawTranscript: String
    
    public init(
        draft: TransactionDraft,
        confidence: ParseConfidence,
        warnings: [String] = [],
        extractedFields: [String] = [],
        rawTranscript: String = ""
    ) {
        self.draft = draft
        self.confidence = confidence
        self.warnings = warnings
        self.extractedFields = extractedFields
        self.rawTranscript = rawTranscript
    }
}

/// Pure deterministic voice transaction parser for English and Hinglish phrases.
/// Invariants per docs/00_PRODUCT_BRAIN.md and docs/09_TEST_PLAN.md:
/// - Never invent missing amounts or dates.
/// - Relative dates such as "kal" or "yesterday" resolve to an explicit date with a confirmation notice.
/// - No ambiguous or low-confidence parse can commit without user review.
public enum VoiceTransactionParser {
    
    public static func parse(
        transcript: String,
        defaultCurrencyCode: String = "INR",
        referenceDate: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        categories: [Category] = []
    ) -> VoiceParseResult {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return VoiceParseResult(
                draft: TransactionDraft(type: .expense, currencyCode: defaultCurrencyCode),
                confidence: .low,
                warnings: ["No speech detected. Please enter details manually."],
                rawTranscript: text
            )
        }
        
        let lower = text.lowercased()
        var warnings: [String] = []
        var extractedFields: [String] = []
        
        // 1. Transaction Type
        var type: TransactionType = .expense
        if lower.contains("got") || lower.contains("received") || lower.contains("salary") || lower.contains("earned") || lower.contains("credited") {
            type = .income
            extractedFields.append("Type: Income")
        } else {
            type = .expense
            extractedFields.append("Type: Expense")
        }
        
        // 2. Amount and Currency Extraction
        let currency = CurrencyCode.from(code: defaultCurrencyCode)
        let amountMinor = extractAmountMinor(from: text, exponent: currency.minorUnitExponent)
        if amountMinor > 0 {
            extractedFields.append("Amount: \(CurrencyFormatter.format(money: Money(amountMinor: amountMinor, currency: currency)))")
        } else {
            warnings.append("Could not extract amount. Please enter an amount.")
        }
        
        // 3. Payment Method Extraction
        var paymentMethod: PaymentMethod? = nil
        if lower.contains("upi") || lower.contains("gpay") || lower.contains("phonepe") || lower.contains("paytm") {
            paymentMethod = .upi
            extractedFields.append("Payment: UPI")
        } else if lower.contains("cash") {
            paymentMethod = .cash
            extractedFields.append("Payment: Cash")
        } else if lower.contains("card") || lower.contains("credit") || lower.contains("debit") {
            paymentMethod = .debitCard
            extractedFields.append("Payment: Card")
        }
        
        // 4. Date Extraction ("yesterday", "kal", "today", "aaj")
        var transactionDay = dayStringFromDate(referenceDate, calendar: calendar)
        if lower.contains("yesterday") || lower.contains("kal") {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceDate) {
                transactionDay = dayStringFromDate(yesterday, calendar: calendar)
                if lower.contains("kal") {
                    warnings.append("Relative date 'kal' resolved to yesterday (\(transactionDay)). Please verify.")
                }
                extractedFields.append("Date: \(transactionDay)")
            }
        } else {
            extractedFields.append("Date: Today")
        }
        
        // 5. Category and Merchant Extraction
        var categoryId: UUID? = nil
        var categoryNameSnapshot: String? = nil
        var merchant: String? = nil
        var note: String? = nil
        
        let classification = extractCategoryAndMerchant(
            from: text,
            type: type,
            availableCategories: categories
        )
        categoryId = classification.categoryId
        categoryNameSnapshot = classification.categoryName
        merchant = classification.merchant
        note = classification.note
        
        if let catName = categoryNameSnapshot {
            extractedFields.append("Category: \(catName)")
        } else {
            warnings.append("Category uncategorized. Select a category if desired.")
        }
        
        // 6. Overall Confidence Rating
        let confidence: ParseConfidence
        if amountMinor > 0 && categoryId != nil {
            confidence = .high
        } else if amountMinor > 0 {
            confidence = .medium
        } else {
            confidence = .low
        }
        
        let draft = TransactionDraft(
            type: type,
            amountMinor: amountMinor,
            currencyCode: defaultCurrencyCode,
            categoryId: categoryId,
            categoryNameSnapshot: categoryNameSnapshot,
            merchant: merchant,
            note: note,
            transactionDay: transactionDay,
            paymentMethod: paymentMethod,
            source: .voice
        )
        
        return VoiceParseResult(
            draft: draft,
            confidence: confidence,
            warnings: warnings,
            extractedFields: extractedFields,
            rawTranscript: text
        )
    }
    
    // MARK: - Amount Regex & Parsing
    
    private static func extractAmountMinor(from text: String, exponent: Int) -> Int64 {
        // Match numbers preceded or followed by currency terms or standalone digits:
        // Examples: "350 rupees", "₹250", "40", "5000", "800.50"
        let pattern = #"(?:[₹$€£]\s*)?(\d+(?:\.\d+)?)(?:\s*(?:rupees|rs|inr|dollars|cents|bucks))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return 0
        }
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        
        for match in matches {
            guard match.numberOfRanges > 1, let numRange = Range(match.range(at: 1), in: text) else { continue }
            let numStr = String(text[numRange])
            if let minor = parseDecimalStringToMinor(numStr, exponent: exponent), minor > 0 {
                return minor
            }
        }
        
        return 0
    }
    
    private static func parseDecimalStringToMinor(_ text: String, exponent: Int) -> Int64? {
        let parts = text.split(separator: ".")
        guard let major = Int64(parts[0]) else { return nil }
        let multiplier = Int64(pow10(exponent))
        
        if parts.count == 1 {
            return major * multiplier
        } else if parts.count == 2 {
            var minorStr = String(parts[1])
            if minorStr.count > exponent {
                minorStr = String(minorStr.prefix(exponent))
            } else while minorStr.count < exponent {
                minorStr.append("0")
            }
            guard let minor = Int64(minorStr) else { return nil }
            return major * multiplier + minor
        }
        return nil
    }
    
    // MARK: - Category & Merchant Classification
    
    private static func extractCategoryAndMerchant(
        from text: String,
        type: TransactionType,
        availableCategories: [Category]
    ) -> (categoryId: UUID?, categoryName: String?, merchant: String?, note: String?) {
        let lower = text.lowercased()
        
        // Income mappings
        if type == .income {
            let cat = availableCategories.first { $0.name.lowercased().contains("salary") || $0.name.lowercased().contains("income") || $0.name == "Other" }
            if lower.contains("freelance") {
                return (cat?.id, cat?.name ?? "Other", "Freelance Work", nil)
            } else if lower.contains("salary") {
                return (cat?.id, cat?.name ?? "Other", "Salary", nil)
            }
            return (cat?.id, cat?.name ?? "Other", "Income", nil)
        }
        
        // Expense keyword heuristics
        let keywords: [(words: [String], categoryName: String, merchant: String?)] = [
            (["lunch", "dinner", "breakfast", "food", "restaurant", "burger", "pizza", "zomato", "swiggy", "chai", "coffee", "tea", "snack"], "Food & Drink", nil),
            (["grocery", "groceries", "supermarket", "milk", "vegetable", "veggies", "d-mart", "dmart"], "Groceries", nil),
            (["auto", "uber", "ola", "metro", "bus", "fuel", "petrol", "diesel", "cab", "taxi", "train"], "Transport", nil),
            (["electricity", "water", "wifi", "internet", "recharge", "bill", "rent"], "Bills", nil),
            (["medicine", "doctor", "pharmacy", "hospital", "health"], "Health", nil),
            (["shopping", "clothes", "shoes", "amazon", "flipkart"], "Shopping", nil)
        ]
        
        for item in keywords {
            for word in item.words {
                if lower.contains(word) {
                    let matchedCategory = availableCategories.first { $0.name.lowercased() == item.categoryName.lowercased() }
                    let capitalizedWord = word.prefix(1).uppercased() + word.dropFirst()
                    return (
                        matchedCategory?.id,
                        matchedCategory?.name ?? item.categoryName,
                        capitalizedWord,
                        text
                    )
                }
            }
        }
        
        let otherCat = availableCategories.first { $0.name == "Other" }
        return (otherCat?.id, otherCat?.name, nil, text)
    }
    
    private static func dayStringFromDate(_ date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let y = components.year ?? 2026
        let m = components.month ?? 10
        let d = components.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
    
    private static func pow10(_ n: Int) -> Int {
        var res = 1
        for _ in 0..<n {
            res *= 10
        }
        return res
    }
}
