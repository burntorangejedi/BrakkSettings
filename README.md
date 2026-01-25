# BrakkSettings - World of Warcraft Configuration Repository

Welcome to **BrakkSettings**, a comprehensive collection of World of Warcraft addon configurations, custom code extensions, and development utilities for the my various World of Warcraft characters.

## 📁 Repository Structure

### 🔧 **Addons/** - Custom Code & Extensions
Custom Lua code and modifications for extending or enhancing existing World of Warcraft addons.

- **Autobar/** - Enhancements and customizations for the Autobar addon
- **EnhanceQualityOfLife/** - Custom scripts and modifications for quality-of-life improvements
- **Macros/** - Macro profiles organized by function (DPS, Healer, etc.)
- **MoarFonts/** - Custom font resources and configurations
- **SharedMedia_MyMedia/** - Custom media assets (backgrounds, borders, fonts, sounds, statusbars)

### 📋 **Profiles/** - Addon Configuration Files
Saved profiles and configurations for various World of Warcraft addons. Each subfolder contains preset configurations for a specific addon.

**Included Profiles:**
- Baganator - Inventory management
- Bartender - Action bar configuration
- Better Blizzard Frames - UI frame customizations
- BigWigs - Boss encounter alerts (multiple profiles)
- Cell - Raid frame configurations
- Chattynator - Chat customization
- Chonky Character Sheet - Character sheet layout
- Details - Damage meter configurations
- Edit Mode - UI layout presets (multiple profiles for different setups)
- EnhanceQOL - Quality of life settings
- Foe's Catchy Cast Bar - Cast bar styling
- OmniCD - Cooldown tracking
- Opie - Radial menu bindings
- Plater - Nameplate customization
- Platynator - Nameplate styling
- Sensei Class Resource Bar - Resource bar configurations
- TipTac - Tooltip customization

### 🐍 **Scripts/** - Development & Automation Tools
Python scripts and Lua utilities to assist with addon development and management.

- **python/**
  - `pull_item_ids.py` - Script to extract and organize WoW item IDs
  - `knowledge_items.lua` - Lua data file for item knowledge storage

## 📊 Current Setup

See [addons.md](addons.md) for a complete list of all currently enabled addons with CurseForge links and organization by category.

**Quick Stats:**
- **Total Enabled Addons:** 87
- **Boss Mods:** BigWigs + LittleWigs (full suites)
- **UI Customization:** Complete custom UI setup with multiple profiles
- **Development Scripts:** Python and Lua utilities for addon work

## 🚀 Usage

### Applying Profiles
Import addon profiles from the `Profiles/` directory into your corresponding addon configuration folders in WoW.

### Using Custom Addons
Deploy custom code from `Addons/` to your WoW addons directory to extend or modify addon functionality.

### Running Development Scripts
Python scripts in `Scripts/python/` can be used to generate addon data, extract item information, and assist with addon development workflows.

## 📝 Maintenance

This repository is kept in sync with the character configuration from World of Warcraft. Profile updates and configuration changes are regularly committed to maintain a complete backup and version history of the character's addon setup.

**Last Updated:** January 23, 2026

---

For detailed information about specific addons and their purposes, refer to [addons.md](addons.md).

## Addons Summary Generator

- Purpose: Generate Addons.md by reading your WoW AddOns directory and optional AddOns.txt (enabled states). Links to any matching profiles in this repo.

- Setup:
  - Copy Scripts/python/config.example.json to Scripts/python/config.json and set paths for `wow_addons_dir` and `wow_addons_txt_path` (optional).
  - Optionally set `profile_aliases` to map addon names to profile folder names for better matching.
  - Or pass `--addons-dir` and `--addons-txt` on the command line.

- Run (PowerShell):

```powershell
python .\Scripts\python\generate_addons_md.py --config .\Scripts\python\config.json --copy-addons-txt
```

- Output:
  - Creates Addons.md in the repo root, formatted as a table with columns: Addon, Description, Source, Profiles.
  - Optionally copies AddOns.txt into Scripts/python for reference.
### Options

- `--workspace-root`: Set the repo root explicitly (use `.` when running from the root).
- `--addons-dir`: Override the WoW AddOns directory.
- `--addons-txt`: Provide AddOns.txt for enabled/disabled filtering.
- `--output`: Set a custom output path for Addons.md.
- `--copy-addons-txt`: Copy AddOns.txt into Scripts/python for reference.


- Notes:
  - CurseForge links are detected from `.toc` fields `X-Website` or `X-Curse-Project-Slug`. If missing, a CurseForge search link is provided.
  - Enabled/disabled filtering only applies when `AddOns.txt` is provided; otherwise all discovered addons are listed.
  - Profile matching uses addon `Title`, the addon folder name, punctuation-insensitive equality, and any `profile_aliases` entries. Fuzzy substring matches are avoided to keep similar addons (e.g., Plater vs Platynator) separate.
  - The script prints an info line when no profile folder is found for an addon.
  - The addon named "Edit Mode" is intentionally skipped.
