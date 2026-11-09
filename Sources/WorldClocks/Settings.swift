import AppKit
import SwiftUI

struct ClockChoice: Codable, Identifiable {
  var id: String
  var label: String
  var name: String
  var timeZone: String
  var inMenuBar: Bool
  static let defaults = [
    ClockChoice(
      id: "SF", label: "SF", name: "San Francisco", timeZone: "America/Los_Angeles", inMenuBar: true
    ),
    ClockChoice(
      id: "NY", label: "NY", name: "New York", timeZone: "America/New_York", inMenuBar: true),
    ClockChoice(
      id: "LDN", label: "LDN", name: "London", timeZone: "Europe/London", inMenuBar: false),
  ]
  var city: City {
    City(
      id: id, name: name, zone: TimeZone(identifier: timeZone)!,
      label: label.isEmpty ? String(name.prefix(3)).uppercased() : label)
  }
}
final class ClockSettings: ObservableObject {
  static let shared = ClockSettings()
  private let defaults: UserDefaults
  @Published var choices: [ClockChoice] {
    didSet {
      defaults.set(try! JSONEncoder().encode(choices), forKey: "clockChoices")
      NotificationCenter.default.post(name: .clockSettingsChanged, object: self)
    }
  }
  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    if let data = defaults.data(forKey: "clockChoices"),
      let saved = try? JSONDecoder().decode([ClockChoice].self, from: data),
      (1...6).contains(saved.count), Set(saved.map(\.id)).count == saved.count,
      saved.allSatisfy({ TimeZone(identifier: $0.timeZone) != nil })
    {
      choices = saved
    } else {
      choices = ClockChoice.defaults
    }
  }
  var cities: [City] { choices.map(\.city) }
}
extension Notification.Name {
  static let clockSettingsChanged = Notification.Name("ClockSettingsChanged")
}
