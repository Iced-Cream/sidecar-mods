"""Where the suites run: the emulators' commands and the Overbridge link's addresses. By default as on a Mac or Linux box,
analog-emu and the Sidecar emulator side by side on 127.0.0.1. On Windows with the Sidecar emulator built in WSL:

    A4_ENGINE_WSL=1        the engine runs through `wsl -e`, its paths given as /mnt/<drive>/...
    A4_LINK_LISTEN=0.0.0.0 where dtboot listens (default 127.0.0.1)
    A4_LINK_HOST=IP        where the engine connects: from WSL, the Windows host (default 127.0.0.1)

Nothing here changes what a test does or checks."""
import os, re, shutil

WSL = bool(os.environ.get("A4_ENGINE_WSL"))
LISTEN = os.environ.get("A4_LINK_LISTEN", "127.0.0.1")
CONNECT = os.environ.get("A4_LINK_HOST", "127.0.0.1")


def copy(src, dst):
    """A card image copied (the Mac's `cp -c` clones it)."""
    shutil.copyfile(src, dst)


def wsl_path(p):
    p = os.path.abspath(p) if re.match(r"^[A-Za-z]:[\\/]", p) or not p.startswith("/") else p
    m = re.match(r"^([A-Za-z]):[\\/](.*)$", p)
    return f"/mnt/{m.group(1).lower()}/{m.group(2).replace(chr(92), '/')}" if m else p


def engine_cmd(engine_dir, args):
    """The Sidecar emulator's command: core/build/sidecar_emu in engine_dir (a WSL path when A4_ENGINE_WSL), args whose
    values may be paths on this machine."""
    if not WSL:
        return [os.path.join(engine_dir, "core/build/sidecar_emu"), *args]
    out = []
    for x in args:
        out.append(wsl_path(x) if isinstance(x, str) and re.match(r"^[A-Za-z]:[\\/]", x) else x)
    return ["wsl", "-e", engine_dir.rstrip("/") + "/core/build/sidecar_emu", *out]
