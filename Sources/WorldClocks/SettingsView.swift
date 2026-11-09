import AppKit
import SwiftUI

struct ZoneChooser: View {
  let choose: (String) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var query = ""
  @FocusState private var searching: Bool
  private var matches: [String] {
    TimeZone.knownTimeZoneIdentifiers.filter {
      query.isEmpty
        || $0.replacingOccurrences(of: "_", with: " ").localizedCaseInsensitiveContains(query)
        || (query.localizedCaseInsensitiveContains("san francisco") && $0 == "America/Los_Angeles")
    }
  }
  var body: some View {
    VStack(spacing: 12) {
      TextField("Search cities or time zones", text: $query).textFieldStyle(.roundedBorder)
        .focused($searching)
      List(matches, id: \.self) { zone in
        Button {
          choose(zone)
          dismiss()
        } label: {
          HStack {
            Text(zone.replacingOccurrences(of: "_", with: " "))
            Spacer()
          }.contentShape(Rectangle()).padding(.vertical, 4)
        }.buttonStyle(.plain)
      }
      HStack {
        Spacer()
        Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
      }
    }.padding(16).frame(width: 420, height: 390)
      .onAppear { searching = true }
  }
}
struct ClockSettingsView: View {
  @ObservedObject var settings: ClockSettings
  @State private var editing: String?
  var body: some View {
    VStack(spacing: 0) {
      Form {
        ForEach($settings.choices) { $choice in
          Section {
            HStack {
              TextField("Label", text: $choice.label)
                .onChange(of: choice.label) { _, value in
                  if value.count > 5 { choice.label = String(value.prefix(5)) }
                }
              Button {
                settings.choices.removeAll { $0.id == choice.id }
              } label: {
                Image(systemName: "minus.circle")
              }
              .buttonStyle(.borderless)
              .disabled(settings.choices.count == 1)
              .accessibilityLabel("Remove \(choice.name)")
            }
            LabeledContent("City") {
              Button(choice.name) { editing = choice.id }
            }
            Toggle("Show in menu bar", isOn: $choice.inMenuBar)
          }
        }
      }.formStyle(.grouped)
      HStack {
        Button("Restore defaults") { settings.choices = ClockChoice.defaults }
        Spacer()
        Button {
          let choice = ClockChoice(
            id: UUID().uuidString, label: "TYO", name: "Tokyo", timeZone: "Asia/Tokyo",
            inMenuBar: false)
          settings.choices.append(choice)
          editing = choice.id
        } label: {
          Label("Add city", systemImage: "plus")
        }
        .disabled(settings.choices.count >= 6)
      }.padding(16)
    }.frame(width: 460, height: 510)
      .sheet(isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) {
        ZoneChooser { zone in
          guard let index = settings.choices.firstIndex(where: { $0.id == editing }) else { return }
          let name = zone.split(separator: "/").last!.replacingOccurrences(of: "_", with: " ")
          settings.choices[index].timeZone = zone
          settings.choices[index].name = name
          settings.choices[index].label =
            zone == "America/Los_Angeles"
            ? "LA" : String(name.filter(\.isLetter).prefix(3)).uppercased()
        }
      }
  }
}
