# USB-C Speed

USB-C Speed is a macOS menu bar utility that shows the live connection status of USB, Thunderbolt, and USB4 devices. It helps identify when a cable, dock, or port is limiting a high-speed device.

![USB-C Speed](assets/sc-current.png)

## Features

- Shows USB devices, hubs, and their reported link speeds.
- Shows Thunderbolt / USB4 buses, port status, and current connection speeds.
- Expands device entries to reveal system-reported vendor, product, media, and power-allocation details.
- Refreshes automatically and sends macOS notifications when devices are connected or removed.
- Lives in the menu bar and shows battery level and charging status for connected Bluetooth devices.
- Registers as a login item after the first launch to keep monitoring device connections.

## Requirements

- macOS 26 or later

## Usage

Launch the app to inspect the full device tree in its main window. Click the bolt icon in the menu bar for a quick view of connected devices, then expand an item to inspect its details.

## Website

Visit the [USB-C Speed website](https://owenzhao.github.io/USB-C-Speed/) for an overview of the app, how it works, and information about its creator. The website automatically follows your system light or dark appearance.

## Development

Open `USB-C Speed.xcodeproj` in Xcode and run the app.

## License

See [LICENSE](LICENSE).
