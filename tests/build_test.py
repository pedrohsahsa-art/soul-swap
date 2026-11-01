"""Reject tuning mistakes that could freeze recovery or invalidate simulation budgets."""
import importlib.util
import json
from pathlib import Path
import unittest

root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('pvp_build', root / 'build.py')
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


class RuleValidation(unittest.TestCase):
    def setUp(self):
        self.rules = json.loads((root / 'rules.json').read_text())

    def test_current_rules(self):
        build.validate_rules(self.rules)

    def test_invalid_tuning(self):
        for key, value in [('energy_regen', float('nan')), ('soul_speed', float('inf')),
                           ('dodge_ticks', 1.5), ('energy_resume', 101), ('energy_resume', 1),
                           ('bullet_limit', 10000), ('graze_radius', 1), ('max_turns', 3),
                           ('dodge_ticks', 30), ('arena_right', 10), ('hit_damage', True)]:
            with self.subTest(key=key, value=value):
                changed = dict(self.rules, **{key: value})
                with self.assertRaises(ValueError):
                    build.validate_rules(changed)


if __name__ == '__main__':
    unittest.main()
