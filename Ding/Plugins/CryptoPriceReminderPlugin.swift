import SwiftUI

/// Fires when a crypto pair's price crosses a threshold (edge-triggered).
///
/// Config keys: `symbol` (e.g. "BTCUSDT"), `op` ("above" | "below"), `threshold`.
/// Price source: Binance public ticker (no auth required).
struct CryptoPriceReminderPlugin: ReminderPlugin {
    let id = "crypto_price"
    let displayName = "Crypto Price"
    let iconSystemName = "bitcoinsign.circle"

    func defaultConfig() -> [String: String] {
        ["symbol": "BTCUSDT", "op": "above", "threshold": ""]
    }

    func summary(_ config: [String: String]) -> String {
        let symbol = (config["symbol"] ?? "?").uppercased()
        let arrow = config["op"] == "below" ? "≤" : "≥"
        let threshold = config["threshold"] ?? ""
        return threshold.isEmpty ? "\(symbol) price alert" : "\(symbol) \(arrow) \(threshold)"
    }

    func configView(_ config: Binding<[String: String]>) -> AnyView {
        AnyView(CryptoConfigView(config: config))
    }

    func evaluate(_ reminder: Reminder, _ ctx: EvalContext) async -> EvalOutcome {
        let symbol = (reminder.config["symbol"] ?? "").uppercased()
        guard !symbol.isEmpty,
              let threshold = Double(reminder.config["threshold"] ?? "") else { return .none }
        guard let price = await PriceCache.shared.price(for: symbol) else { return .none }

        let above = reminder.config["op"] != "below"
        let met = above ? price >= threshold : price <= threshold

        if met && !reminder.triggered {
            let result = TriggerResult(
                title: reminder.title.isEmpty ? "\(symbol) price alert" : reminder.title,
                body: "\(symbol) is \(Self.format(price)) — \(above ? "above" : "below") \(Self.format(threshold))."
            )
            return .fire(result)
        } else if !met && reminder.triggered {
            // Price moved back across the threshold; re-arm for the next crossing.
            return .rearm
        }
        return .none
    }

    private static func format(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

/// Caches recent prices per symbol to avoid hitting the API on every tick.
actor PriceCache {
    static let shared = PriceCache()

    private struct Entry { let price: Double; let at: Date }
    private struct Ticker: Decodable { let price: String }

    private var cache: [String: Entry] = [:]
    private let ttl: TimeInterval = 20

    func price(for symbol: String) async -> Double? {
        if let entry = cache[symbol], Date().timeIntervalSince(entry.at) < ttl {
            return entry.price
        }
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/price?symbol=\(symbol)") else {
            return nil
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200,
                  let price = Double(try JSONDecoder().decode(Ticker.self, from: data).price)
            else { return nil }
            cache[symbol] = Entry(price: price, at: Date())
            return price
        } catch {
            return nil
        }
    }
}

/// Config editor for `CryptoPriceReminderPlugin`.
private struct CryptoConfigView: View {
    @Binding var config: [String: String]

    var body: some View {
        TextField("Symbol (e.g. BTCUSDT)", text: binding("symbol"))
            .textFieldStyle(.roundedBorder)

        Picker("Condition", selection: binding("op")) {
            Text("Above ≥").tag("above")
            Text("Below ≤").tag("below")
        }
        .pickerStyle(.segmented)

        TextField("Threshold (USDT)", text: binding("threshold"))
            .textFieldStyle(.roundedBorder)
    }

    private func binding(_ key: String) -> Binding<String> {
        Binding(
            get: { config[key] ?? "" },
            set: { config[key] = $0 }
        )
    }
}
