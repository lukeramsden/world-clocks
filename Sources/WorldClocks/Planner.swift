import AppKit
import SwiftUI

struct Planner: View {
  @ObservedObject var settings = ClockSettings.shared
  var openSettings: () -> Void = {}
  private var cities: [City] { settings.cities }
  @State private var selected = Date()
  @State private var reference = "SF"
  private var source: City { cities.first { $0.id == reference } ?? cities[0] }
  private var hours: [Date] { dayHours(selected, source) }
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(spacing: 12) {
        Picker("Choose time in", selection: $reference) {
          ForEach(cities) { Text($0.name).tag($0.id) }
        }.labelsHidden().frame(width: 170)
          .accessibilityLabel("Time zone")
        DatePicker(
          "Date and time", selection: $selected, displayedComponents: [.date, .hourAndMinute]
        )
        .labelsHidden().environment(\.timeZone, source.zone)
        .accessibilityLabel("Date and time in \(source.name)")
        Spacer()
        Button("Now") { selected = Date() }
        Button(action: openSettings) { Image(systemName: "gearshape").frame(width: 24, height: 24) }
          .buttonStyle(.borderless).help("Settings")
          .accessibilityLabel("Settings")
      }
      HStack(spacing: 0) {
        ForEach(cities) { city in
          VStack(alignment: .leading, spacing: 5) {
            Text(city.name).font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
              .lineLimit(1)
            Text(formatted(selected, city, "h:mm a")).font(
              .system(size: cities.count > 3 ? 21 : 26, weight: .medium)
            ).monospacedDigit().lineLimit(1).minimumScaleFactor(0.75)
            Text(formatted(selected, city, "EEE d MMM · z")).font(.system(size: 12))
              .foregroundStyle(.secondary)
          }.frame(maxWidth: .infinity, alignment: .leading)
        }
      }.padding(.vertical, 4)
      VStack(alignment: .leading, spacing: 10) {
        ForEach(cities) { city in
          HStack(spacing: 8) {
            Text(city.shortName).font(.system(size: 12, weight: .semibold)).lineLimit(1)
              .minimumScaleFactor(0.7).frame(width: 35, alignment: .leading)
            HStack(spacing: 1) {
              ForEach(hours, id: \.self) { hour in
                let active = selected >= hour && selected < hour.addingTimeInterval(3600)
                HourCell(city: city, hour: hour, active: active) { selected = hour }
              }
            }
          }
        }
      }
      .overlay {
        GeometryReader { geometry in
          let width = geometry.size.width - 43
          let hourWidth = width / Double(hours.count)
          let position = selected.timeIntervalSince(hours[0]) / 3600 * hourWidth + hourWidth / 2
          Rectangle().fill(Color.accentColor.opacity(0.45))
            .frame(width: 1)
            .offset(x: 43 + min(width, position))
            .allowsHitTesting(false)
          TimelineInput(selected: selected, hours: hours) { selected = $0 }
            .padding(.leading, 43)
            .accessibilityHidden(true)
        }
      }
    }.padding(18).frame(width: 700)
      .controlSize(.regular)
      .onChange(of: settings.choices.map(\.id)) { _, ids in
        if !ids.contains(reference) { reference = ids[0] }
      }
  }
}
