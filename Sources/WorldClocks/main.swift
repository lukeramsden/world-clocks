import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = ClockDelegate()
app.delegate = delegate
app.run()
