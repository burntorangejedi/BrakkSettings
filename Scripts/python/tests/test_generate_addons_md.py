import importlib.util
import tempfile
import unittest
from pathlib import Path


def load_module():
    spec = importlib.util.spec_from_file_location(
        "generate_addons_md",
        Path(__file__).resolve().parents[1] / "generate_addons_md.py",
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class GenerateAddonsMdTests(unittest.TestCase):
    def test_groups_dbm_components_into_single_entry(self):
        module = load_module()
        with tempfile.TemporaryDirectory() as tmpdir:
            addons_dir = Path(tmpdir) / "Addons"
            addons_dir.mkdir()
            for folder, title in [
                ("DBM-Core", "<DBM Core> Main Core"),
                ("DBM-Options", "<DBM Core> Options GUI"),
                ("DBM-StatusBar", "<DBM Core> Status Bar Timers"),
            ]:
                addon_dir = addons_dir / folder
                addon_dir.mkdir()
                (addon_dir / f"{folder}.toc").write_text(f"## Title: {title}\n", encoding="utf-8")

            addons = module.discover_addons(addons_dir)

            self.assertEqual(len(addons), 1)
            self.assertEqual(addons[0][0], "DBM")

    def test_search_urls_are_percent_encoded(self):
        module = load_module()
        url = module.curseforge_url_from_toc({}, "<DBM Extra> Spell Timers")
        self.assertIn("https://www.curseforge.com/wow/addons/search?search=", url)
        self.assertIn("%3CDBM", url)
        self.assertIn("%3E", url)


if __name__ == "__main__":
    unittest.main()
