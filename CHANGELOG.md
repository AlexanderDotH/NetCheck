# Changelog

All notable changes to NetCheck are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Earlier versions are described on the [GitHub releases page](https://github.com/vincentlauriat/NetCheck/releases).

## [Unreleased]

### Added

- English and German translations alongside French, covering menus, settings, diagnostics, quality labels, errors, guidance, accessibility text, and permission prompts.
- Language picker in Preferences: System default, English, Deutsch, or Français. The choice applies immediately to the menu and all open windows without interrupting running diagnostics, and is kept across launches.
- Traceroute shows country borders, country names, and cities on the globe.
- Traceroute hop list: click a hop to highlight it on the map and see its IP address, country, and provider.
- Traceroute "Show entire route" button to frame the whole route again after moving the map.

### Changed

- Traceroute draws the full route at once instead of flying to each hop. The map frames the whole route and grows with it as hops arrive, and the result is ready as soon as the trace completes instead of after a long animation.
- Hops in the same place are combined into one numbered marker (for example "9–13"), with the origin in green and the destination in red.
- Traceroute uses the destination set in Preferences, and its address field, Trace button, and progress indicator share one control bar.
- Feature windows open at a fixed default size instead of resizing to their content, which sometimes made them over 1,500 points tall.
- Feature windows use a soft tinted gradient instead of the animated background bubbles, which showed through cards as stripes.
- The Wi-Fi Finder signal waves stay within their area instead of covering the title.
- The Wi-Fi Finder Geiger sound control is now a switch.
- Speed Test shows "—" and plain labels before the first measurement instead of "RPM — —".
- Dragging on the Traceroute map moves the globe instead of the window.

### Fixed

- Window titles and content no longer overlap the window buttons and title bar.
- Wi-Fi Diagnostics no longer shows a negative SNR when macOS does not report a noise measurement.
- Wi-Fi Diagnostics shows the 2.4 GHz band with the decimal separator of the selected language instead of always "2,4 GHz".
- Traceroute shows hops that do not answer as "* * *" instead of skipping them.
- Traceroute no longer turns error output or incomplete lines into bogus hops.
- Traceroute keeps the Apple Maps attribution, zoom, and compass controls visible above the hop list and control bar.
