#!/usr/bin/env python3
"""Sincroniza el grupo de fcitx5 desde el perfil y/o activa un IM.

fcitx5-remote -s solo cambia entre IMs ya cargados en el grupo activo.
Editar ~/.config/fcitx5/profile no basta si el daemon ya está en marcha:
hay que empujar la lista por D-Bus.
"""
from __future__ import annotations

import argparse
import ast
import subprocess
import sys
from configparser import RawConfigParser

GDBUS = [
    "gdbus",
    "call",
    "--session",
    "--dest",
    "org.fcitx.Fcitx5",
    "--object-path",
    "/controller",
]


def gdbus(*args: str) -> str:
    return subprocess.check_output([*GDBUS, *args], text=True)


def group_info() -> tuple[str, list[tuple[str, str]]]:
    raw = gdbus(
        "--method",
        "org.fcitx.Fcitx.Controller1.InputMethodGroupInfo",
        "Default",
    )
    layout, items = ast.literal_eval(raw.strip())
    return layout, [(str(n), str(lay)) for n, lay in items]


def set_group(layout: str, items: list[tuple[str, str]]) -> None:
    gdbus(
        "--method",
        "org.fcitx.Fcitx.Controller1.SetInputMethodGroupInfo",
        "Default",
        layout,
        str(list(items)),
    )


def set_im(name: str) -> None:
    gdbus("--method", "org.fcitx.Fcitx.Controller1.SetCurrentIM", name)


def items_from_profile(path: str) -> tuple[str, list[tuple[str, str]]]:
    parser = RawConfigParser()
    parser.optionxform = str
    parsed = parser.read(path)
    if not parsed:
        raise FileNotFoundError(path)
    layout = parser.get("Groups/0", "Default Layout", fallback="latam")
    items: list[tuple[str, str]] = []
    i = 0
    while parser.has_section(f"Groups/0/Items/{i}"):
        name = parser.get(f"Groups/0/Items/{i}", "Name")
        im_layout = parser.get(f"Groups/0/Items/{i}", "Layout", fallback="")
        items.append((name, im_layout))
        i += 1
    return layout, items


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--profile", help="Ruta al profile de fcitx5 (sincroniza el grupo)")
    ap.add_argument("--switch", help="Unique name del IM a activar")
    args = ap.parse_args()
    if not args.profile and not args.switch:
        ap.error("indica --profile y/o --switch")

    if args.profile:
        layout, items = items_from_profile(args.profile)
        if items:
            set_group(layout, items)

    if args.switch:
        layout, items = group_info()
        names = [name for name, _ in items]
        if args.switch not in names:
            items = [*items, (args.switch, "")]
            set_group(layout, items)
        set_im(args.switch)
    return 0


if __name__ == "__main__":
    sys.exit(main())
