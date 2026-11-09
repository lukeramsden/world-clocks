import AppKit
import QuartzCore
import SwiftUI

final class ClockPanel: NSPanel {
  var onDismiss: (() -> Void)?
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { false }
  override func cancelOperation(_ sender: Any?) { onDismiss?() }
}

final class ClockDelegate: NSObject, NSApplicationDelegate {
  private var item: NSStatusItem!
  private var timer: Timer?
  private var panel: ClockPanel!
  private var outsideMonitor: Any?
  private var localMonitor: Any?
  private var host: NSHostingView<Planner>!
  private var settingsWindow: NSWindow?
  func applicationDidFinishLaunching(_ notification: Notification) {
    item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    item.button?.target = self
    item.button?.action = #selector(handleClockClick)
    item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    host = NSHostingView(rootView: Planner(openSettings: { [weak self] in self?.showSettings() }))
    let size = host.fittingSize
    panel = ClockPanel(
      contentRect: NSRect(origin: .zero, size: size),
      styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = true
    panel.level = .popUpMenu
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    let material = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
    material.material = .popover
    material.blendingMode = .behindWindow
    material.state = .active
    material.wantsLayer = true
    material.layer?.cornerRadius = 12
    material.layer?.masksToBounds = true
    host.frame = material.bounds
    host.autoresizingMask = [.width, .height]
    material.addSubview(host)
    panel.contentView = material
    panel.onDismiss = { [weak self] in self?.closePanel() }
    outsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown])
    { [weak self] _ in self?.closePanel() }
    localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
      [weak self] event in
      if let self, self.panel.isVisible, event.window !== self.panel,
        event.window !== self.item.button?.window
      {
        self.closePanel()
      }
      return event
    }
    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: #selector(closePanel), name: NSWorkspace.activeSpaceDidChangeNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(settingsChanged), name: .clockSettingsChanged, object: nil)
    update()
    timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
      self?.update()
    }
    timer?.tolerance = 1
    if CommandLine.arguments.contains("--show-planner") {
      DispatchQueue.main.async { self.togglePlanner() }
    }
  }
  private func showSettings() {
    closePanel()
    if settingsWindow == nil {
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 460, height: 510), styleMask: [.titled, .closable],
        backing: .buffered, defer: false)
      window.title = "World Clocks Settings"
      window.isReleasedWhenClosed = false
      window.contentView = NSHostingView(rootView: ClockSettingsView(settings: .shared))
      window.center()
      settingsWindow = window
    }
    NSApp.activate(ignoringOtherApps: true)
    settingsWindow?.makeKeyAndOrderFront(nil)
  }
  @objc private func settingsChanged() { update() }
  @objc private func handleClockClick() {
    let event = NSApp.currentEvent
    if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
      closePanel()
      let menu = NSMenu()
      let quit = NSMenuItem(
        title: "Quit World Clocks", action: #selector(quitApp), keyEquivalent: "q")
      quit.target = self
      menu.addItem(quit)
      guard let button = item.button else { return }
      item.menu = menu
      button.performClick(nil)
      item.menu = nil
    } else {
      togglePlanner()
    }
  }
  @objc private func quitApp() { NSApp.terminate(nil) }
  @objc private func togglePlanner() {
    guard let button = item.button, let window = button.window else { return }
    if panel.isVisible {
      closePanel()
      return
    }
    host.layoutSubtreeIfNeeded()
    panel.setContentSize(host.fittingSize)
    let anchor = window.convertToScreen(button.convert(button.bounds, to: nil))
    let screen = window.screen ?? NSScreen.main!
    let visible = screen.visibleFrame
    let x = max(
      visible.minX + 8, min(anchor.maxX - panel.frame.width, visible.maxX - panel.frame.width - 8))
    let menuBottom = min(anchor.minY, visible.maxY)
    let y = max(visible.minY + 8, menuBottom - panel.frame.height - 6)
    panel.setFrameOrigin(NSPoint(x: x, y: y))
    panel.alphaValue = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 1 : 0
    button.highlight(true)
    panel.makeKeyAndOrderFront(nil)
    if panel.alphaValue == 0 {
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.14
        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        panel.animator().alphaValue = 1
      }
    }
  }
  @objc private func closePanel() {
    panel.orderOut(nil)
    item.button?.highlight(false)
  }
  private func update() {
    let now = Date()
    let choices = ClockSettings.shared.choices.filter(\.inMenuBar)
    item.button?.title = choices.map { "\($0.city.shortName) \(formatted(now, $0.city, "HH:mm"))" }
      .joined(separator: "  ")
    item.button?.image =
      choices.isEmpty
      ? NSImage(systemSymbolName: "clock", accessibilityDescription: "World Clocks") : nil
    item.button?.setAccessibilityLabel(
      "World Clocks. "
        + choices.map { "\($0.name) \(formatted(now, $0.city, "HH:mm"))" }.joined(separator: ", "))
    item.button?.toolTip = "Click to compare times"
  }
}
