import argparse
import json
import os
from pathlib import Path
import re
from typing import Dict, List, Optional, Tuple


def load_config(config_path: Optional[Path]) -> Dict[str, object]:
    cfg: Dict[str, object] = {}
    if config_path and config_path.exists():
        try:
            cfg = json.loads(config_path.read_text(encoding="utf-8"))
        except Exception:
            pass
    # Env overrides
    env_addons_dir = os.environ.get("WOW_ADDONS_DIR")
    env_addons_txt = os.environ.get("WOW_ADDONS_TXT")
    if env_addons_dir:
        cfg["wow_addons_dir"] = env_addons_dir
    if env_addons_txt:
        cfg["wow_addons_txt_path"] = env_addons_txt
    # Normalize optional profile aliases
    aliases = cfg.get("profile_aliases")
    if isinstance(aliases, dict):
        # Ensure all values are lists of strings
        norm_aliases: Dict[str, List[str]] = {}
        for k, v in aliases.items():
            if isinstance(v, str):
                norm_aliases[k] = [v]
            elif isinstance(v, list):
                norm_aliases[k] = [str(x) for x in v]
        cfg["profile_aliases"] = norm_aliases
    return cfg


def parse_addons_txt(path: Path) -> Dict[str, bool]:
    """Best-effort parser for WoW AddOns.txt (enabled/disabled states).
    Returns mapping of addon folder name -> enabled bool.

    Supports lines like:
    - MyAddon: enabled / MyAddon: disabled
    - MyAddon=1 / MyAddon=0
    - enabled MyAddon / disabled MyAddon
    - plain addon names (assume enabled)
    """
    states: Dict[str, bool] = {}
    if not path.exists():
        return states
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        enabled = True
        name = line

        # Patterns
        m = re.match(r"^(.*?)\s*:\s*(enabled|disabled)$", line, re.I)
        if m:
            name = m.group(1).strip()
            enabled = m.group(2).lower() == "enabled"
        else:
            m = re.match(r"^(.*?)\s*=\s*([01])$", line)
            if m:
                name = m.group(1).strip()
                enabled = m.group(2) == "1"
            else:
                m = re.match(r"^(enabled|disabled)\s+(.*)$", line, re.I)
                if m:
                    enabled = m.group(1).lower() == "enabled"
                    name = m.group(2).strip()
        # normalize
        name = name.strip()
        if name:
            states[name] = enabled
    return states


def parse_toc(toc_path: Path) -> Dict[str, str]:
    info: Dict[str, str] = {}
    if not toc_path.exists():
        return info
    for raw in toc_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.strip()
        if not line.startswith("## "):
            continue
        m = re.match(r"^##\s*([^:]+):\s*(.*)$", line)
        if m:
            key = m.group(1).strip()
            val = m.group(2).strip()
            # Strip WoW color codes: |cffHHHHHH or |r
            # Strip WoW texture codes: |T<digits>:<digits>:<digits>:<digits>:<digits>|t
            val = re.sub(r"\|c[a-fA-F0-9]{8}|\|r|\|T\d+:\d+:\d+:\d+:\d+\|t", "", val).strip()
            info[key] = val
    return info


def discover_addons(addons_dir: Path) -> List[Tuple[str, Path, Dict[str, str]]]:
    results: List[Tuple[str, Path, Dict[str, str]]] = []
    if not addons_dir.exists():
        return results
    for child in addons_dir.iterdir():
        if not child.is_dir():
            continue
        toc_files = list(child.glob("*.toc"))
        toc = toc_files[0] if toc_files else None
        info = parse_toc(toc) if toc else {}
        name = (info.get("Title") or "").strip() or child.name
        # Skip addons with invalid names (only punctuation/whitespace)
        if not re.search(r"[a-zA-Z0-9]", name):
            continue
        results.append((name, child, info))
    
    # Filter: remove addon variants (e.g., ElvUI_Config when ElvUI exists)
    # Keep only addons that are not X_Y if X alone also exists
    folder_names = {child.name for _, child, _ in results}
    filtered: List[Tuple[str, Path, Dict[str, str]]] = []
    for name, child, info in results:
        folder = child.name
        if "_" in folder:
            base = folder.split("_")[0]
            if base in folder_names:
                # This is a variant; skip it
                print(f"[filter] Skipping variant '{folder}' (base '{base}' exists)")
                continue
        filtered.append((name, child, info))
    return filtered


def curseforge_url_from_toc(info: Dict[str, str], fallback_name: str) -> str:
    website = info.get("X-Website") or info.get("X-Curse-Project-URL")
    if website:
        return website
    slug = info.get("X-Curse-Project-Slug")
    if slug:
        return f"https://www.curseforge.com/wow/addons/{slug}"
    # As a fallback, provide a search link
    return f"https://www.curseforge.com/wow/addons/search?search={re.sub(r'\s+', '+', fallback_name.strip())}"


def _normalize(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())


def find_profiles_links(
    workspace_root: Path,
    addon_title: str,
    folder_name: str,
    aliases: Optional[Dict[str, List[str]]] = None,
) -> List[str]:
    profiles_dir = workspace_root / "Profiles"
    links: List[str] = []
    if not profiles_dir.exists():
        return links

    candidates: List[str] = [addon_title, folder_name]
    if aliases:
        for key in [addon_title, folder_name, _normalize(addon_title), _normalize(folder_name)]:
            # direct key
            if key in aliases:
                candidates.extend(aliases[key])
            # normalized key lookup
            for ak, vals in aliases.items():
                if _normalize(ak) == key:
                    candidates.extend(vals)

    # 1) Exact folder name match
    for cand in candidates:
        candidate_dir = profiles_dir / cand
        if candidate_dir.exists() and candidate_dir.is_dir():
            for f in sorted(candidate_dir.rglob("*")):
                if f.is_file():
                    links.append(f.relative_to(workspace_root).as_posix())
            if links:
                return links

    # 2) Case-insensitive direct match among subfolders
    for sub in profiles_dir.iterdir():
        if not sub.is_dir():
            continue
        for cand in candidates:
            if sub.name.lower() == str(cand).lower():
                for f in sorted(sub.rglob("*")):
                    if f.is_file():
                        links.append(f.relative_to(workspace_root).as_posix())
                if links:
                    return links

    # 3) Normalized equality (strip punctuation)
    norm_title = _normalize(addon_title)
    norm_folder = _normalize(folder_name)
    for sub in profiles_dir.iterdir():
        if not sub.is_dir():
            continue
        snorm = _normalize(sub.name)
        if snorm in (norm_title, norm_folder):
            for f in sorted(sub.rglob("*")):
                if f.is_file():
                    links.append(f.relative_to(workspace_root).as_posix())
            if links:
                return links

    # Note: no substring heuristics to avoid conflating similar addons (e.g., Plater vs Platynator)
    return links


def build_addons_md(
    workspace_root: Path,
    addons: List[Tuple[str, Path, Dict[str, str]]],
    enabled_map: Optional[Dict[str, bool]] = None,
    aliases: Optional[Dict[str, List[str]]] = None,
) -> str:
    lines: List[str] = []
    lines.append("# Addons in Use")
    lines.append("")
    lines.append("This document is auto-generated. Do not edit manually.")
    lines.append("")

    def is_enabled(name: str, folder: Path) -> bool:
        if not enabled_map:
            return True
        # Check by Title, then folder
        if name in enabled_map:
            return enabled_map[name]
        if folder.name in enabled_map:
            return enabled_map[folder.name]
        # Unknown — default enabled
        return True

    # Table header
    lines.append("| Addon | Description | Source | Profiles |")
    lines.append("|---|---|---|---|")

    # Sort by name for stability
    for name, folder, info in sorted(addons, key=lambda t: t[0].lower()):
        if not is_enabled(name, folder):
            continue
        # Permanently skip non-addon "Edit Mode"
        if _normalize(name) == "editmode" or _normalize(folder.name) == "editmode":
            continue
        description = info.get("Notes") or ""
        url = curseforge_url_from_toc(info, name)
        profiles = find_profiles_links(workspace_root, name, folder.name, aliases)
        if not profiles:
            print(f"[info] No profiles found for addon '{name}' (folder '{folder.name}')")
        # URL-encode spaces in profile paths for markdown links
        profiles_cell = "; ".join([f"[{p}]({p.replace(' ', '%20')})" for p in profiles]).rstrip("; ") if profiles else "none"
        # Row
        lines.append(f"| {name} | {description} | {url} | {profiles_cell} |")
    return "\n".join(lines).rstrip() + "\n"


def main():
    parser = argparse.ArgumentParser(
        description="Generate Addons.md from WoW AddOns and optional AddOns.txt state",
    )
    parser.add_argument(
        "--workspace-root",
        type=Path,
        default=None,
        help="Override workspace root (default: repo root inferred from script path)",
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help="Path to config.json containing wow_addons_dir and wow_addons_txt_path",
    )
    parser.add_argument(
        "--addons-dir",
        type=Path,
        default=None,
        help="Override path to WoW AddOns directory (Interface/AddOns)",
    )
    parser.add_argument(
        "--addons-txt",
        type=Path,
        default=None,
        help="Override path to AddOns.txt (enabled state)",
    )
    parser.add_argument(
        "--copy-addons-txt",
        action="store_true",
        help="Copy AddOns.txt into repo at Scripts/python/AddOns.txt",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Output path for Addons.md (default: workspace root / Addons.md)",
    )
    args = parser.parse_args()

    # Infer workspace root from script location: .../WoWDocs/Scripts/python/generate_addons_md.py
    # parents[2] should be WoWDocs
    inferred_root = Path(__file__).resolve().parents[2]
    workspace_root = args.workspace_root or inferred_root
    cfg = load_config(args.config)

    addons_dir = (
        args.addons_dir
        or Path(cfg.get("wow_addons_dir", ""))
        if cfg.get("wow_addons_dir")
        else None
    )
    addons_txt = (
        args.addons_txt
        or Path(cfg.get("wow_addons_txt_path", ""))
        if cfg.get("wow_addons_txt_path")
        else None
    )

    if addons_dir is None or not Path(addons_dir).exists():
        print("[warn] AddOns directory not provided or does not exist."
              " Use --addons-dir or set wow_addons_dir in config.")
        return 2

    enabled_map = parse_addons_txt(addons_txt) if addons_txt else None
    addons = discover_addons(Path(addons_dir))
    aliases = cfg.get("profile_aliases") if isinstance(cfg.get("profile_aliases"), dict) else None
    md = build_addons_md(workspace_root, addons, enabled_map, aliases)

    out_path = args.output or (workspace_root / "Addons.md")
    out_path.write_text(md, encoding="utf-8")
    print(f"Wrote {out_path}")

    if args.copy_addons_txt and addons_txt and Path(addons_txt).exists():
        dest = workspace_root / "Scripts" / "python" / "AddOns.txt"
        dest.write_text(Path(addons_txt).read_text(encoding="utf-8", errors="ignore"), encoding="utf-8")
        print(f"Copied AddOns.txt to {dest}")


if __name__ == "__main__":
    raise SystemExit(main())
