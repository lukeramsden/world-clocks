# World Clocks

A native macOS menu bar clock with a visual planner for calls across time zones.

Pick 11 am in San Francisco and see the same moment in New York and London. Drag across the timeline or scroll horizontally to find another time. Every city updates together.

![World Clocks showing 11 am in San Francisco, 2 pm in New York, and 7 pm in London](docs/screenshot.png)

## What it does

- Shows live clocks in the menu bar. SF and NY are visible by default.
- Opens aligned timelines for San Francisco, New York, and London.
- Scrubs to the minute with dragging or horizontal scrolling, including trackpad momentum.
- Converts dates with each city's daylight-saving rules. Shaded cells mark 9 am to 5 pm.
- Supports up to six cities, editable short labels, and a choice of which clocks appear in the menu bar.
- Saves settings locally. No account, network requests, or external dependencies.

The interface uses AppKit and SwiftUI, follows the system appearance, and respects Reduce Motion.

## Build and install

Requires macOS 14 or later and the Xcode Command Line Tools. If you need the tools, install them with `xcode-select --install`.

```sh
git clone https://github.com/lukeramsden/world-clocks.git
cd world-clocks
make build
```

The app is built at `.build/World Clocks.app`. Open it in Finder to run it, or install it in Applications:

```sh
make install
```

Then launch **World Clocks** from Applications. It runs in the menu bar without a Dock icon. Quit an existing copy before installing an update.

The build uses your Mac's architecture and a local ad-hoc signature. It is not a notarized distribution build. macOS 14 is the deployment target; development and testing were done on macOS 26.

## Use

Click the menu bar clock to open the planner. Choose a reference city and enter a date and time, click an hour, or drag across any timeline. Horizontal scrolling over the timeline changes the selected time too. All rows show the same instant, including when a city is on a different date.

**Now** returns to the current time. Click outside the planner or press Escape to dismiss it.

The cog opens a separate settings window. Add or remove cities, search time zones, change labels, and toggle menu bar visibility. Changes save automatically; **Restore defaults** brings back SF, NY, and LDN. If you hide every menu bar clock, a clock icon remains so you can still open the planner.

Right-click or Control-click the menu bar clock to quit. To start automatically, add the installed app to your macOS login items.

## Development

```sh
make test
```

The checks cover time-zone conversion, the weeks when US and UK daylight-saving dates differ, 23- and 25-hour days, minute-level drag positions, horizontal scroll events, and settings persistence. Tests use a separate preferences domain.

Source files are in `Sources/WorldClocks`: `AppDelegate.swift` owns the menu bar and windows, `Planner.swift` lays out the planner, `Timeline.swift` handles scrubbing, and the settings files manage configuration and its interface. `Clock.swift` handles date formatting and the day's timeline.
