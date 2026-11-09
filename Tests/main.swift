import AppKit

let cities = ClockChoice.defaults.map(\.city)

func testTimeConversion() {
  let iso = ISO8601DateFormatter()
  let winter = iso.date(from: "2026-11-09T19:00:00Z")!
  precondition(formatted(winter, cities[0], "HH:mm") == "11:00")
  precondition(formatted(winter, cities[1], "HH:mm") == "14:00")
  precondition(formatted(winter, cities[2], "HH:mm") == "19:00")
  let mismatch = iso.date(from: "2026-03-20T18:00:00Z")!
  precondition(formatted(mismatch, cities[0], "HH:mm") == "11:00")
  precondition(formatted(mismatch, cities[2], "HH:mm") == "18:00")
  precondition(dayHours(iso.date(from: "2026-03-08T12:00:00Z")!, cities[0]).count == 23)
  precondition(dayHours(iso.date(from: "2026-11-01T12:00:00Z")!, cities[0]).count == 25)
  let hours = dayHours(winter, cities[0])
  precondition(
    formatted(scrubbedDate(x: 11.5 * 26, width: 24 * 26, hours: hours), cities[0], "HH:mm")
      == "11:00")
  precondition(
    formatted(scrubbedDate(x: 12 * 26, width: 24 * 26, hours: hours), cities[0], "HH:mm") == "11:30"
  )
  precondition(scrubbedDate(x: -100, width: 624, hours: hours) == hours[0])
  precondition(
    formatted(scrubbedDate(x: 10000, width: 624, hours: hours), cities[0], "HH:mm") == "23:59")
  print("Passed: time conversion, DST, drag position, minute precision, edge clamping")
}

func testSettings() {
  let suite = "local.world-clocks.test." + UUID().uuidString
  let defaults = UserDefaults(suiteName: suite)!
  defer { defaults.removePersistentDomain(forName: suite) }
  let settings = ClockSettings(defaults: defaults)
  precondition(settings.choices.map(\.label) == ["SF", "NY", "LDN"])
  precondition(settings.choices.filter(\.inMenuBar).count == 2)
  settings.choices[0].timeZone = "Asia/Tokyo"
  settings.choices[0].name = "Tokyo"
  settings.choices[0].label = "TYO"
  settings.choices.append(
    ClockChoice(
      id: "SYD", label: "SYD", name: "Sydney", timeZone: "Australia/Sydney", inMenuBar: false))
  let restored = ClockSettings(defaults: defaults)
  precondition(restored.choices.count == 4)
  precondition(restored.cities[0].zone.identifier == "Asia/Tokyo")
  precondition(restored.cities[0].shortName == "TYO")
  let date = ISO8601DateFormatter().date(from: "2026-11-09T19:00:00Z")!
  _ = formatted(date, cities[0], "HH:mm")
  precondition(formatted(date, restored.cities[0], "HH:mm") == "04:00")
  settings.choices = ClockChoice.defaults
  precondition(ClockSettings(defaults: defaults).choices.map(\.label) == ["SF", "NY", "LDN"])
  print("Passed: defaults, saved cities and menu choices, timezone cache, restore defaults")
}

func testScrubbing() {
  let base = ISO8601DateFormatter().date(from: "2026-11-09T19:00:00Z")!
  let input = ScrubView(frame: NSRect(x: 0, y: 0, width: 624, height: 158))
  input.hours = dayHours(base, cities[0])
  input.selected = base
  var result = base
  input.change = {
    result = $0
    input.selected = $0
  }
  func mouse(_ type: NSEvent.EventType, _ x: Double) -> NSEvent {
    NSEvent.mouseEvent(
      with: type, location: NSPoint(x: x, y: 80), modifierFlags: [], timestamp: 0, windowNumber: 0,
      context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!
  }
  input.mouseDown(with: mouse(.leftMouseDown, 11.5 * 26))
  input.mouseDragged(with: mouse(.leftMouseDragged, 12 * 26))
  input.mouseUp(with: mouse(.leftMouseUp, 12 * 26))
  precondition(formatted(result, cities[0], "HH:mm") == "11:30")
  precondition(formatted(result, cities[1], "HH:mm") == "14:30")
  precondition(formatted(result, cities[2], "HH:mm") == "19:30")
  let before = result
  let cg = CGEvent(
    scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: 0, wheel2: -26, wheel3: 0)!
  input.scrollWheel(with: NSEvent(cgEvent: cg)!)
  precondition(result > before)
  precondition(result.timeIntervalSince(before) == 3600)
  print("Passed: native drag events update all cities; horizontal scroll advances one hour")
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
testTimeConversion()
testSettings()
testScrubbing()
