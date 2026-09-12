<div align="center">

# QuickNote for Omarchy

A lightning-fast, sticky note plugin designed natively for the Omarchy shell.

</div>

## Preview

![QuickNote Preview](preview.png)

## Features

- **Floating Sticky Notes**: Right-click the icon to spawn notes directly on your desktop.
- **7 Independent Tabs**: Quickly switch between multiple notes (`Ctrl+B`).
- **Interactive Checkboxes**: Click on `[ ]` or `[x]` in your text to instantly toggle them.
- **Run in Terminal**: Highlight text and press `Ctrl+T` to run it in Bash.
- **Save to File**: Press `Ctrl+S` to export notes to a specific file.
- **Drag & Drop**: Easily drop text files or snippets straight into your notes.
- **Clickable Links**: Click any URL to instantly open it in your browser.
- **Quick Typing Test**: Press `Ctrl+K` to start a quick typing test on your note.

### Keyboard Shortcuts
*(Press `Ctrl+H` at any time while the panel is open to view this)*

| Shortcut | Action |
|----------|--------|
| `Ctrl+P` | Pin/Unpin the current tab to your desktop as a sticky note |
| `Ctrl+B` | Cycle to the next buffer |
| `Ctrl+T` | Run selected text (or entire buffer) in terminal |
| `Ctrl+R` | Clear the entire buffer |
| `Ctrl+S` | Open the "Save as:" prompt |
| `Ctrl+H` | Show the shortcut help overlay |
| `Ctrl+K` | Start typing test |
| `Ctrl++` / `Ctrl+-` | Increase / Decrease editor font size |
| `Escape` | Close the panel or hide the active overlay |

## Installation

```bash
omarchy plugin add https://github.com/Pilpup/quick-note --enable
```

## Update

```bash
omarchy plugin update my.quicknote
```

## Uninstallation

```bash
omarchy plugin remove my.quicknote
```

## Development & Building from Source

If you want to contribute to the code and build it manually from the `main` branch:

```bash
git clone https://github.com/Pilpup/quick-note
cd quick-note

# Compile the C++ binaries in-place
./build.sh
```
