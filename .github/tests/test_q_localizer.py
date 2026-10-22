import json
import unittest
from pathlib import Path

BASE = Path(__file__).resolve().parents[2]


def needs_library(path):
    text = path.read_text(encoding="utf-8", errors="replace")
    return (
        "qLocalization" in text
        and "function lib.new(" not in text
        and "function qLocalization.new(" not in text
    )


class QLocalizerTests(unittest.TestCase):
    def test_needs_q_localizer_matches_the_script(self):
        catalog = json.loads((BASE / ".github" / "catalog.json").read_text(encoding="utf-8"))
        wrong = []
        for script in catalog["scripts"]:
            if script.get("external") or script["id"] == "q_localizer" or "package" in script:
                continue
            path = BASE / "scripts" / script["id"] / script.get("file", "")
            if path.suffix != ".lua" or not path.is_file():
                continue
            if needs_library(path) != script.get("needs_q_localizer", False):
                wrong.append(script["id"])
        self.assertEqual(wrong, [])


if __name__ == "__main__":
    unittest.main()
