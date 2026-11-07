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
    """0021's and 0023's `slots` go together (0021 calls 0023's td_pool_tab). Until the companion phase (2026-11-03)
    0022 listed it too, for its router; the router is 0032-sidecar's now and each client registers its own commands."""
    ALL = {"0014-hidden-machines", "0021-ext", "0022-looper", "0023-teensy-drive"}

    def mods(self, **slots):
        mods = build.load_mods(self.ALL)
        for who, v in slots.items():
            mods[who.replace("_", "-")]["_params"]["slots"] = v
        return mods, {m for m, d in mods.items() if d.get("enabled")}

    def test_defaults_agree(self):
        # every slots defaults to 0: the hardware builds stay the pre-slot image
        mods, en = self.mods()
        self.assertEqual({mods[m]["_params"]["slots"] for m in ("0021-ext", "0023-teensy-drive")}, {0})
        self.assertNotIn("slots", mods["0022-looper"]["_params"])
        build.check_linked_params(mods, en)

    def test_all_on_passes(self):
        build.check_linked_params(*self.mods(**{"0021_ext": 1, "0023_teensy_drive": 1}))

    def test_0021_without_0023_refused(self):
        # 0021 slots=1 reads td_pool_tab from the third mailbox word; 0023 slots=0 has 8 B there
        with self.assertRaises(SystemExit) as cm:
            build.check_linked_params(*self.mods(**{"0021_ext": 1}))
        self.assertIn("linked param slots", str(cm.exception))

    def test_a_disabled_mod_is_not_checked(self):
        # 0023 (not in the image) has slots=1; 0021 has 0
        mods = build.load_mods({"0021-ext", "0022-looper"})
        mods["0023-teensy-drive"]["_params"]["slots"] = 1
        build.check_linked_params(mods, {"0021-ext", "0022-looper"})

    def test_0021_slots_without_0023_refused(self):
        # review 2026-10-11: slots=1 needs every mod that lists slots in the image
        for only in ({"0021-ext"}, {"0021-ext", "0022-looper"}):
            mods = build.load_mods(only)
            mods["0021-ext"]["_params"]["slots"] = 1
            with self.assertRaises(SystemExit) as cm:
                build.check_linked_params(mods, only)
            self.assertIn("needs", str(cm.exception))

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
        self.assertEqual(e["data"], "0e0e0000" + b"TDRV".hex() + "401b9d18")
        mods["0022-looper"]["area"] = None
        e = build.sc_contributions(mods["0022-looper"], {"looper_host": 0x400a75ea})[0]
        self.assertEqual(e["data"], "07080100" + "00000000" + "400a75ea")


if __name__ == "__main__":
    unittest.main()
