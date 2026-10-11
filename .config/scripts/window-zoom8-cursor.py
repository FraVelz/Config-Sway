#!/usr/bin/env python3
"""Imprime: cx cy ox oy ow oh  (cursor + rect de la salida, coords Sway)."""
import os
import shutil
import subprocess
import sys

# GTK4 carga wayland antes que layer-shell si no se precarga.
_LS = "/usr/lib/libgtk4-layer-shell.so"
if _LS not in os.environ.get("LD_PRELOAD", "") and os.path.exists(_LS):
    os.environ["LD_PRELOAD"] = f"{_LS}:{os.environ.get('LD_PRELOAD', '')}"
    os.execv(sys.executable, [sys.executable, os.path.abspath(__file__), *sys.argv[1:]])

import gi

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")
from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell as LayerShell


def focused_output():
    try:
        import json

        outs = json.loads(subprocess.check_output(["swaymsg", "-t", "get_outputs"], text=True))
        active = [o for o in outs if o.get("active")]
        return next((o for o in active if o.get("focused")), active[0] if active else None)
    except Exception:
        return None


def main() -> int:
    out = focused_output()
    if not out:
        print("no-output", file=sys.stderr)
        return 2
    r = out["rect"]
    ox, oy, ow, oh = int(r["x"]), int(r["y"]), int(r["width"]), int(r["height"])

    result = {"xy": None}

    app = Gtk.Application(application_id="dev.fravelz.zoom8cursor")

    def activate(_app):
        win = Gtk.Window(application=app)
        win.set_decorated(False)
        win.set_default_size(ow, oh)

        LayerShell.init_for_window(win)
        LayerShell.set_layer(win, LayerShell.Layer.OVERLAY)
        LayerShell.set_namespace(win, "zoom8-probe")
        LayerShell.set_anchor(win, LayerShell.Edge.TOP, True)
        LayerShell.set_anchor(win, LayerShell.Edge.BOTTOM, True)
        LayerShell.set_anchor(win, LayerShell.Edge.LEFT, True)
        LayerShell.set_anchor(win, LayerShell.Edge.RIGHT, True)
        LayerShell.set_exclusive_zone(win, -1)
        LayerShell.set_keyboard_mode(win, LayerShell.KeyboardMode.NONE)
        try:
            LayerShell.set_monitor(win, None)
        except Exception:
            pass

        # Casi invisible, pero recibe el puntero (no input-region vacía).
        css = Gtk.CssProvider()
        css.load_from_data(b"window { background-color: rgba(0,0,0,0.01); }")
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        def accept(x, y):
            if result["xy"] is not None:
                return
            result["xy"] = (int(ox + x), int(oy + y))
            win.close()
            app.quit()

        motion = Gtk.EventControllerMotion()
        motion.connect("enter", lambda _c, x, y: accept(x, y))
        motion.connect("motion", lambda _c, x, y: accept(x, y))
        win.add_controller(motion)

        click = Gtk.GestureClick()
        click.connect("pressed", lambda *_: None)
        win.add_controller(click)

        win.present()

        def nudge():
            if shutil.which("swaymsg") and result["xy"] is None:
                subprocess.run(
                    ["swaymsg", "seat", "-", "cursor", "move", "1", "0"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )
                subprocess.run(
                    ["swaymsg", "seat", "-", "cursor", "move", "-1", "0"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    check=False,
                )
            return False

        def timeout():
            if result["xy"] is None:
                result["xy"] = (ox + ow // 2, oy + oh // 2)
            win.close()
            app.quit()
            return False

        GLib.timeout_add(40, nudge)
        GLib.timeout_add(350, timeout)

    app.connect("activate", activate)
    app.run([])

    cx, cy = result["xy"] or (ox + ow // 2, oy + oh // 2)
    print(cx, cy, ox, oy, ow, oh)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
