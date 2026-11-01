"""Build an arena-only, hash-gated copy; never launches the game or edits Steam files."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
SOURCE_HASH = "047c5ab003e3e017a709c02757e119c81e0327760169512110fd276b19241e68"
RUNNER_HASH = "b882cc1879ad8f24c63fa6e4f47a8fef9a01065ee61ad6220beed9932b04e7ed"
GAME = Path(os.environ.get('DELTARUNE_DIR', r"C:\Program Files (x86)\Steam\steamapps\common\DELTARUNE"))
CLI = Path(os.environ.get('UTMT_CLI', str(ROOT / "tools/utmt-0.9.2.0/UndertaleModCli.exe")))


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def run_cli(*args):
    env = dict(os.environ, DR_PVP_ROOT=str(ROOT))
    subprocess.run([str(CLI), *map(str, args)], env=env, check=True)


def validate_rules(rules):
    for key, value in rules.items():
        if key == "version":
            continue
        if not isinstance(value, (int, float)) or isinstance(value, bool) or not math.isfinite(value) or value <= 0:
            raise ValueError(f"Invalid positive numeric rule: {key}")
        if (key.endswith('_ticks') or key in ('tick_rate', 'max_turns', 'bullet_limit')) and int(value) != value:
            raise ValueError(f"Require whole ticks/counts: {key}")
    if rules["tick_rate"] != 30 or rules["max_turns"] % 2:
        raise ValueError("Require 30 ticks and an even turn limit for equal full-length matches.")
    if rules["arena_left"] >= rules["arena_right"] or rules["arena_top"] >= rules["arena_bottom"]:
        raise ValueError("Invalid arena bounds")
    if rules['energy_cost'] > rules['energy_resume'] or rules['energy_resume'] > rules['energy_max']:
        raise ValueError('Energy recovery threshold must cover one shot and fit maximum energy')
    if rules['strategy_warning_ticks'] + 30 >= rules['dodge_ticks']:
        raise ValueError('Attack turn is too short for strategic warning')
    if rules['bullet_limit'] < 20 or rules['bullet_limit'] > 512:
        raise ValueError('Projectile budget must be between 20 and 512')
    if rules['graze_radius'] <= rules['soul_radius'] + rules['projectile_radius']:
        raise ValueError('Graze radius must exceed collision radius')


def main():
    global GAME, CLI
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rebuild", action="store_true", help="Replace this project's generated play/data.win and build outputs")
    parser.add_argument('--game', type=Path, default=GAME, help='Steam DELTARUNE installation directory')
    parser.add_argument('--cli', type=Path, default=CLI, help='UndertaleModCli 0.9.2.0 executable')
    args = parser.parse_args()
    GAME, CLI = args.game.resolve(), args.cli.resolve()
    if ROOT == GAME or ROOT.is_relative_to(GAME):
        raise ValueError('Keep the mod outside the original game directory')
    source = GAME / "chapter2_windows/data.win"
    runner = GAME / "DELTARUNE.exe"
    if not CLI.is_file():
        raise SystemExit(f"Required portable analysis tool not found: {CLI}")
    if digest(source) != SOURCE_HASH or digest(runner) != RUNNER_HASH:
        raise SystemExit("Unsupported game build. No outputs were changed.")
    rules = json.loads((ROOT / "rules.json").read_text())
    validate_rules(rules)
    if not re.fullmatch(r"\d+\.\d+\.\d+", rules["version"]):
        raise ValueError("Invalid version for generated output directory")
    (ROOT / 'build').mkdir(exist_ok=True)
    subprocess.run(['node', str(ROOT / 'tests/controller.test.cjs')], check=True)
    subprocess.run([sys.executable, str(ROOT / 'tests/build_test.py')], check=True)
    play = ROOT / f"play-v{rules['version']}"
    build = ROOT / "build"
    target = play / "data.win"
    if target.exists() and not args.rebuild:
        raise SystemExit(f"{target} exists; use --rebuild to replace this version's generated outputs only.")
    build.mkdir(exist_ok=True)
    play.mkdir(exist_ok=True)
    header = ["// Generated from rules.json. Do not hand-edit."]
    for key, value in rules.items():
        header.append(f"{'mod_version' if key == 'version' else key} = {json.dumps(value)};")
    (build / "rules-header.gml").write_text("\n".join(header) + "\n", encoding="utf-8")

    # Check the baseline serializer without a patch, on an owned scratch output.
    roundtrip = build / "roundtrip.win"
    if not roundtrip.exists():
        run_cli("load", source, "--output", roundtrip)
    if digest(roundtrip) != SOURCE_HASH:
        raise SystemExit("No-change round trip is not byte-identical; inspect compatibility before building.")
    patched = build / "patched.win"
    if patched.exists() and not args.rebuild:
        raise SystemExit("build/patched.win exists; use --rebuild for generated outputs.")
    # CLI script errors may return success: never accept an older scratch output/report.
    if patched.exists():
        patched.unlink()
    verification = build / 'verification.json'
    if verification.exists():
        verification.unlink()
    command = ["load", source, "--scripts", ROOT / "patch.csx", "--output", patched]
    if args.rebuild:
        command.append("--overwrite")
    run_cli(*command)
    if not patched.is_file():
        raise ValueError('Compiler did not produce a fresh archive')
    run_cli("load", patched, "--scripts", ROOT / "verify.csx")
    if not verification.is_file() or not json.loads(verification.read_text())['archive_reopened']:
        raise ValueError('Verifier did not produce a fresh successful report')

    # Only the runner, this new archive and the embedded sound bank are needed by this arena.
    shutil.copy2(runner, play / "DELTARUNE_Local_PvP.exe")
    shutil.copy2(GAME / "chapter2_windows/audiogroup1.dat", play / "audiogroup1.dat")
    shutil.copy2(GAME / "mus/battle.ogg", play / "battle.ogg")
    shutil.copy2(patched, target)
    (play / "options.ini").write_text("[Windows]\nSleepMargin=30\nUsex64=True\n", encoding="ascii")
    if digest(source) != SOURCE_HASH or digest(runner) != RUNNER_HASH:
        raise SystemExit("Source identity changed during build; stop and investigate.")
    manifest = {
        "version": rules["version"], "source": str(source), "source_sha256": SOURCE_HASH,
        "runner_sha256": RUNNER_HASH, "patched_sha256": digest(target),
        "rules": rules, "play_directory": str(play), "roundtrip_byte_identical": True, "steam_originals_unchanged": True,
        "source_files": {str(p.relative_to(ROOT)): digest(p) for p in [ROOT / "patch.csx", ROOT / "verify.csx", ROOT / "rules.json", ROOT / "assets/manifest.json", *sorted((ROOT / "gml").glob("*.gml"))]},
        "staged_assets": {name: digest(play / name) for name in ["audiogroup1.dat", "battle.ogg"]},
        "runtime_tested": False,
    }
    (build / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Built {target}\nStatic verification passed. The game has NOT been launched.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print(f"BUILD FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
