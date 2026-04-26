# nlt — Night Light Tool

> Your display was designed for daylight. Your eyes weren't.

It's 11pm. You're winding down, maybe reading an article or finishing up some light work before bed. You glance at your screen and it feels like staring into a lighthouse. The brightness is set for a noon office, the color temperature is a clinical cold white, and your eyes are paying for it.

**nlt** is a lightweight Bash script that lets you dial down your display brightness and apply a warm color filter in a single command — across all connected monitors simultaneously. No GUI, no background daemon, no configuration files. Just run it, and your screen becomes something your eyes can actually rest on.

---

Internal Links
- [Installation](#installation)
- [Usage](#usage)
- [Resetting filters](#reset)
- [Recommended Settings](#recommended-settings)
- [Behavior](#behavior)

---
## What It Does

- Detects **all connected displays** automatically via `xrandr` — works on single and multi-monitor setups without any manual configuration
- Sets **brightness** uniformly across every display
- Applies a **warm color temperature** using `redshift` to reduce blue light emission
- Optionally applies a **second temperature step** in one command, useful for transitions
- Validates all inputs before touching your display and **resets safely** if anything goes wrong
- Checks for **missing dependencies** on first run and offers to install them automatically, detecting your distro's package manager

---

## Dependencies

These two tools need to be present on your system. If they aren't, the script will detect this on launch, show you the exact install command for your distro, and offer to run it for you.

| Tool | Purpose | Package name |
|------|---------|--------------|
| `xrandr` | Sets display brightness | `x11-xserver-utils` (apt) · `xrandr` (dnf/pacman) |
| `redshift` | Applies color temperature filter | `redshift` (all distros) |

Supported package managers: `apt`, `dnf`, `pacman`, `zypper`, `apk`

---

## Installation

### 1. Download the script

```bash
curl -o nlt https://raw.githubusercontent.com/i-am-dev-dev/nlt/refs/heads/main/nlt.sh
```

### 2. Make it executable

```bash
chmod +x nlt
```

### 3. Move it into your local bin so it's available anywhere

```bash
mkdir -p ~/.local/bin
mv nlt ~/.local/bin/
```

### 4. Add `~/.local/bin` to your PATH (if not already there)

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

> If you use Zsh, replace `~/.bashrc` with `~/.zshrc`.

You can now run `nlt` from any directory without specifying a path.

---

## Usage

```bash
nlt <brightness> <temp1> [temp2]
```

| Argument | Type | Range | Description |
|----------|------|-------|-------------|
| `brightness` | float | 0.4 – 1.0 | Display brightness level |
| `temp1` | integer | 2500 – 4500 | Color temperature in Kelvin |
| `temp2` | integer | 2500 – 4500 | *(Optional)* A second temperature applied after temp1 |

Lower Kelvin = warmer/more orange. Higher Kelvin = cooler/more white.

```bash
nlt <command>
```

| Command     | Description   |
| ----------- | ------------- |
| -h / --help | shows help    |
| clear       | clear filters |
| night       | 0.8 3200 3200 |
| evening     | 0.8 3200      |
| read        | 0.7 2500 2500 |


---

## Recommended Settings

These are tried and tested presets for common situations. Use them as a starting point and adjust to taste.

### Daytime work — slight dimming, neutral warmth
```bash
nlt 0.9 4500
```
Takes the harsh edge off without changing the character of the display much. Good for long coding or writing sessions during the day.

---

### Reading — soft warmth, full brightness
```bash
nlt 1.0 3500
```
Keeps brightness up so text stays crisp, but shifts the tone warm to reduce eye strain. Good for articles, docs, or ebooks in the evening.

---

### Night work — dimmed with warm filter
```bash
nlt 0.8 3200 3200
```
The everyday night mode. Noticeably softer than default, easy on the eyes for general use, browsing, or light tasks after dark.

---

### Late night video — darker, warmer
```bash
nlt 0.7 2500
```
Best for watching videos or films at night. The deeper warmth stops the screen from dominating a dark room, and the lower brightness lets your eyes settle.

---

## Resetting

To restore your display to full brightness and remove the color filter:

```bash
nlt 1.0 4500
```

Or if you want to fully clear the redshift filter independently:

```bash
redshift -x
```

---

## Behavior

- The script resets display settings before applying new values.
- This prevents cumulative brightness reduction or incorrect color states.
- Invalid input also triggers a reset to ensure a usable display state.

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.
