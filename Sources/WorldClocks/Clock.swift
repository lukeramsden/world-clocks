import AppKit
import SwiftUI

struct City: Identifiable {
  let id: String
  let name: String
  let zone: TimeZone
  var label: String? = nil
  var shortName: String { label ?? id }
}
private var formatters: [String: DateFormatter] = [:]
func formatted(_ date: Date, _ city: City, _ pattern: String) -> String {
  let key = city.zone.identifier + pattern
  if let formatter = formatters[key] { return formatter.string(from: date) }
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_GB")
  formatter.timeZone = city.zone
  formatter.dateFormat = pattern
  formatters[key] = formatter
  return formatter.string(from: date)
}
func dayHours(_ date: Date, _ city: City) -> [Date] {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = city.zone
  let start = calendar.startOfDay(for: date)
  let end = calendar.date(byAdding: .day, value: 1, to: start)!
  return stride(from: start.timeIntervalSince1970, to: end.timeIntervalSince1970, by: 3600).map(
    Date.init(timeIntervalSince1970:))
}
