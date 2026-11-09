import AppKit
import SwiftUI

struct HourButtonStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
  }
}
struct HourCell: View {
  let city: City
  let hour: Date
  let active: Bool
  let select: () -> Void
  @State private var hovered = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private var working: Bool { (9..<17).contains(Int(formatted(hour, city, "H"))!) }
  var body: some View {
    Button(action: select) {
      VStack(spacing: 3) {
        Text(formatted(hour, city, "h")).font(.system(size: 11, weight: .medium)).monospacedDigit()
        Text(formatted(hour, city, "a").lowercased()).font(.system(size: 8))
      }
      .frame(maxWidth: .infinity).frame(height: 46)
      .foregroundStyle(active ? Color.white : Color.primary)
      .background {
        RoundedRectangle(cornerRadius: 5)
          .fill(
            active ? Color.accentColor : Color(nsColor: working ? .quaternaryLabelColor : .clear))
        if hovered && !active {
          RoundedRectangle(cornerRadius: 5).fill(Color(nsColor: .tertiaryLabelColor).opacity(0.3))
        }
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(HourButtonStyle())
    .onHover { hovered = $0 }
    .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovered)
    .help(formatted(hour, city, "EEE d MMM, h:mm a z"))
    .accessibilityLabel("\(city.name), \(formatted(hour, city, "EEE d MMM h:mm a z"))")
    .accessibilityAddTraits(active ? .isSelected : [])
  }
}
func scrubbedDate(x: Double, width: Double, hours: [Date]) -> Date {
  let hourWidth = width / Double(hours.count)
  let seconds = max(0, min(Double(hours.count) * 3600 - 60, (x / hourWidth - 0.5) * 3600))
  return hours[0].addingTimeInterval((seconds / 60).rounded() * 60)
}

struct TimelineInput: NSViewRepresentable {
  let selected: Date
  let hours: [Date]
  let change: (Date) -> Void
  func makeNSView(context: Context) -> ScrubView { ScrubView() }
  func updateNSView(_ view: ScrubView, context: Context) {
    view.selected = selected
    view.hours = hours
    view.change = change
  }
}
final class ScrubView: NSView {
  var selected = Date()
  var hours: [Date] = []
  var change: (Date) -> Void = { _ in }
  private var dragHours: [Date] = []
  private var scrollSeconds: Double = 0
  override var acceptsFirstResponder: Bool { false }
  override func resetCursorRects() { addCursorRect(bounds, cursor: .resizeLeftRight) }
  override func mouseDown(with event: NSEvent) {
    dragHours = hours
    updateDrag(event)
  }
  override func mouseDragged(with event: NSEvent) { updateDrag(event) }
  override func mouseUp(with event: NSEvent) {
    updateDrag(event)
    dragHours = []
  }
  private func updateDrag(_ event: NSEvent) {
    guard !dragHours.isEmpty, bounds.width > 0 else { return }
    let point = convert(event.locationInWindow, from: nil)
    change(scrubbedDate(x: point.x, width: bounds.width, hours: dragHours))
  }
  override func scrollWheel(with event: NSEvent) {
    guard abs(event.scrollingDeltaX) > 0, bounds.width > 0, !hours.isEmpty else {
      super.scrollWheel(with: event)
      return
    }
    if event.phase == .began { scrollSeconds = 0 }
    let delta = event.scrollingDeltaX * (event.hasPreciseScrollingDeltas ? 1 : 12)
    scrollSeconds -= delta / bounds.width * Double(hours.count) * 3600
    let minutes = (scrollSeconds / 60).rounded(.towardZero)
    if minutes != 0 {
      let next = selected.addingTimeInterval(minutes * 60)
      scrollSeconds -= minutes * 60
      selected = next
      change(next)
    }
  }
}
