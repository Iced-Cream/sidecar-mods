#!/usr/bin/env python3
"""tools/test_build_excludes.py - build.py refuses mutually exclusive mods in one image.

    .venv/bin/python tools/test_build_excludes.py

layout.validate skips overlaps between mods that declare `excludes`, so build.py must
refuse such a combination outright rather than rely on a cave or expect collision.
"""
import os
import sys
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build  # noqa: E402
import layout  # noqa: E402

EXCL = layout.load_excludes(Path(build.ROOT))


class Excludes(unittest.TestCase):
    def refused(self, mods):
        with self.assertRaises(SystemExit) as cm:
            build.check_excludes(set(mods), EXCL)
        self.assertIn("mutually exclusive", str(cm.exception))

    def test_the_user_slot_build_passes(self):
        build.check_excludes({"0014-hidden-machines", "0021-ext", "0022-looper",
                              "0023-teensy-drive"}, EXCL)

    def test_the_symmetric_map_is_used(self):
        # 0021 declares the exclusion; a map from 0002's side alone must still refuse.
        with self.assertRaises(SystemExit):
            build.check_excludes({"0002-euclid-accents", "0021-ext"},
                                 {"0002-euclid-accents": {"0021-ext"}})


class ParamExcludes(unittest.TestCase):
    """0021's user slots take over 0014's FUNC. GEN. and TEST records: refused with funcgen or test on."""

    def mods(self, **p0014):
        mods = build.load_mods({"0014-hidden-machines", "0021-ext", "0022-looper", "0023-teensy-drive"})
        mods["0014-hidden-machines"]["_params"].update(p0014)
        return mods, {m for m, d in mods.items() if d.get("enabled")}

    def test_funcgen_refused(self):
        with self.assertRaises(SystemExit) as cm:
            build.check_param_excludes(*self.mods(variants=1, funcgen=1, test=0))
        self.assertIn("funcgen=1", str(cm.exception))

    def test_test_refused(self):
        with self.assertRaises(SystemExit) as cm:
            build.check_param_excludes(*self.mods(variants=1, funcgen=0, test=1))
        self.assertIn("test=1", str(cm.exception))

    def test_us1_passes(self):
        build.check_param_excludes(*self.mods(variants=1, funcgen=0, test=0))

    def test_without_0021_passes(self):
        mods = build.load_mods({"0014-hidden-machines"})
        mods["0014-hidden-machines"]["_params"].update(funcgen=1, test=1)
        build.check_param_excludes(mods, {"0014-hidden-machines"})


class LinkedParams(unittest.TestCase):
    """`slots` once tied 0021's user slots to 0023's 12 B mailbox (td_pool_tab). Since 2026-11-10 0023 is a companion
    client in the area with no pool and no `slots`: only 0021 lists the param, so the check has nothing to tie."""
    ALL = {"0014-hidden-machines", "0021-ext", "0022-looper", "0023-teensy-drive"}

    def test_0023_has_no_slots(self):
        mods = build.load_mods(self.ALL)
        self.assertNotIn("slots", mods["0023-teensy-drive"]["_params"])
        self.assertNotIn("slots", mods["0023-teensy-drive"].get("linked_params", []))
        self.assertNotIn("slots", mods["0022-looper"]["_params"])

    def test_defaults_pass(self):
        mods = build.load_mods(self.ALL)
        build.check_linked_params(mods, {m for m, d in mods.items() if d.get("enabled")})

    def test_0021_slots_alone_passes(self):
        mods = build.load_mods({"0021-ext"})
        mods["0021-ext"]["_params"]["slots"] = 1
        build.check_linked_params(mods, {"0021-ext"})

    def test_0021_alone_slots_0_passes(self):
        build.check_linked_params(build.load_mods({"0021-ext"}), {"0021-ext"})


class SidecarCmds(unittest.TestCase):
    """The companion's table (mods/0032-sidecar): a client needs the companion, and ranges never overlap."""
    RUI = {"0021-ext", "0022-looper", "0023-teensy-drive", "0032-sidecar"}

    def test_rui_set_passes(self):
        mods = build.load_mods(self.RUI)
        mods["0021-ext"]["_params"]["slots"] = 1
        build.check_sc_cmds(mods, self.RUI)

    def test_client_without_companion_refused(self):
        only = {"0022-looper"}
        with self.assertRaises(SystemExit) as cm:
            build.check_sc_cmds(build.load_mods(only), only)
        self.assertIn("0032-sidecar", str(cm.exception))

    def test_overlap_refused(self):
        mods = build.load_mods(self.RUI)
        mods["0032-sidecar"]["_sc_cmds"].append({"first": 0x07, "last": 0x07, "handler": "sc_store_host"})
        with self.assertRaises(SystemExit) as cm:
            build.check_sc_cmds(mods, self.RUI)
        self.assertIn("overlap", str(cm.exception))

    def test_slots_picks_0021_range(self):
        mods = build.load_mods({"0021-ext"})
        self.assertEqual([(c["first"], c["last"]) for c in build.sc_cmds_of(mods["0021-ext"])], [(0x15, 0x17)])
        mods["0021-ext"]["_params"]["slots"] = 1
        self.assertEqual([(c["first"], c["last"]) for c in build.sc_cmds_of(mods["0021-ext"])], [(0x15, 0x1d)])

    def test_companion_takes_fx_in(self):
        """The companion's own command, called directly: the store link's 51 (the Storage phase; the FX return's 26
        left on 2026-11-04)."""
        mods = build.load_mods({"0032-sidecar"})
        self.assertEqual([(c["first"], c["last"], c.get("handler")) for c in build.sc_cmds_of(mods["0032-sidecar"])],
                         [(0x51, 0x51, "sc_store_host")])
        build.check_sc_cmds(mods, {"0032-sidecar"})

    def test_entry_bytes(self):
        mods = build.load_mods(self.RUI)
        e = build.sc_contributions(mods["0023-teensy-drive"], {})[0]
        # an area client's handler: flags SC_DIRECT, the pointer a relocation to its symbol
        self.assertEqual(e["data"], "0e0e0100" + "00000000" + "00000000")
        self.assertEqual(e["relocs"], [[8, "abs32", "sym:td_sysex", 0]])
        mods["0022-looper"]["area"] = None
        e = build.sc_contributions(mods["0022-looper"], {"looper_host": 0x400a75ea})[0]
        self.assertEqual(e["data"], "07080100" + "00000000" + "400a75ea")


if __name__ == "__main__":
    unittest.main()
