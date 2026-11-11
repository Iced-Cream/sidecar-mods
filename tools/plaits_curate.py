#!/usr/bin/env python3
"""tools/plaits_curate.py VOICE_H KEEP... - a blob's Plaits with only the engines it plays (decided 2026-11-11: each
voice blob carries only the code it needs). Every engine member of plaits::Voice (plaits/dsp/voice.h, eurorack
08460a6) not named in KEEP becomes a NullEngine (silence, no memory), so the engine numbers stay Plaits' own and the
linker's --gc-sections drops the engine's code and its tables (built with -ffunction-sections -fdata-sections).
KEEP names members as voice.h does, e.g. six_op_engine_. Upstream's teensy/setup_plaits_lib.sh curates the same way."""
import re
import sys

path, keep = sys.argv[1], set(sys.argv[2:])
src = open(path).read()
members = re.findall(r"^  (\w+Engine) (\w+_engine_);$", src, re.M)
names = {m for _, m in members}
unknown = keep - names
if unknown:
    sys.exit(f"plaits_curate: no engine member {sorted(unknown)} in {path}")
for cls, m in members:
    if m not in keep:
        src = src.replace(f"  {cls} {m};", f"  NullEngine {m};   // not in this blob (tools/plaits_curate.py)")
src = src.replace('#include "plaits/dsp/engine/engine.h"\n',
                  '#include "plaits/dsp/engine/engine.h"\n#include "plaits/dsp/engine/null_engine.h"\n', 1)
if "null_engine.h" not in src:
    sys.exit("plaits_curate: engine.h include not found")
open(path, "w").write(src)
open(path.replace("voice.h", "engine/null_engine.h"), "w").write('''// tools/plaits_curate.py: an engine left out of this blob (silence), holding its number.
#pragma once
#include <string.h>
#include "plaits/dsp/engine/engine.h"
namespace plaits {
class NullEngine : public Engine {
 public:
  virtual void Init(stmlib::BufferAllocator* allocator) { (void)allocator; }
  virtual void Reset() {}
  virtual void LoadUserData(const uint8_t* user_data) { (void)user_data; }
  // the setters voice.cc calls on SPEECH and CHIPTUNE, when they are left out
  void set_prosody_amount(float) {}
  void set_speed(float) {}
  void set_envelope_shape(float) {}
  virtual void Render(const EngineParameters& parameters, float* out, float* aux, size_t size,
                      bool* already_enveloped) {
    (void)parameters;
    (void)already_enveloped;
    memset(out, 0, size * sizeof(float));
    memset(aux, 0, size * sizeof(float));
  }
};
}  // namespace plaits
''')
print(f"plaits_curate: kept {sorted(keep)}, {len(members) - len(keep)} engines null")
