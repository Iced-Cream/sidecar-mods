/* SPDX-License-Identifier: GPL-2.0-or-later */
/* a4_seq.c - the A4's half of the Sidecar sequencer's edit route: the Rytm's 0026 "1032" / "1033" (mods/0026-remote-ui,
 * rui.c) cut to the A4, on core-a4mk2 0.8's events, with no sites. Its step ticks and TRANSPORT / PATTERN / SWITCH /
 * TEMPO / MUTES / POS are the A4 companion's (sidecar-core companion-a4 clock.c); this file is the UI.
 *   host -> A4  2E 01 <mask lo7> <mask hi5> <flags> [...]   the seq tracks (bit t: A4 track t, synth 0..3 only); any 2E turns
 *                                                         the reports on; forgotten when the port goes down
 *               34 01 <mode> [<c1> .. <c16>]                the trig LEDs: mode 1 the host's (palette 0..111), 0 stock's
 *               2F 01 <p1> .. <p4>                          the PAGE LEDs (palette, 7F stock's)
 *   A4 -> host  2D 01 08 <on> <track | 7F>                  SEQMODE: reports on, the current track a seq track, GRID REC on
 *               2D 01 0A <op> <pattern> <track | 7F> <ok> <src> <a0> <a1> <a2>   EDIT (the Rytm's ops: 1..3 pattern
 *                                                         copy / paste / clear, 5..7 track, 9..11 page, 13..15 trigs;
 *                                                         src 0 stock's, after it ran; src 1 seq mode's own gesture, which
 *                                                         stock never sees; a0..a2 the held trigs, 21 bits, a0 the low 7)
 *               31 <hi> <lo> <down> / 32 <enc> <d + 64> <func>   in seq mode with the Sidecar's page closed: T1..T16 and
 *                                                         PAGE the host's (stock never sees them), FUNC both sides', the
 *                                                         encoders A..H while a host trig is held. Key codes are the
 *                                                         Rytm's (the same numbers for these keys)
 * And on a seq track, live recording writes nothing (ev_live_rec), as on the Rytm.
 * Tasks: a4_seq_rx in the MIDI task (copies and returns); everything else in the UI task, sent at its tick's end. */
#include "a4.h"
#include "analog-four-mk2/ui.h"
#include "analog-four-mk2/leds.h"
#include "analog-four-mk2/keys.h"
#include "analog-four-mk2/moments.h"

#define K_TRIGS   16
#define K_PAGE    0x84          /* the Rytm's PAGE code: the same on the A4 (a4_remote.c) */
#define SQ_NQ     16
#define TRACKS    6

int a4_remote_open(void);       /* a4_remote.c: the Sidecar's page is on the screen */

/* the MIDI task's */
static volatile uint32_t sq_mask, sq_on, sq_resync, sq_led_mode, sq_led_new, sq_pled_new;
static volatile uint8_t sq_led[K_TRIGS], sq_pled[4];
volatile uint32_t a4_seq_msgs, a4_seq_bad, a4_seq_drop, a4_seq_refused;   /* to look at in the emulator */

/* the UI task's */
static uint32_t grid, func, held, page_held, mode_sent = 0xff, mode_trk = 0xff, was_up;
static uint8_t owner[K_TRIGS / 8 + 1], page_owner;
static struct { uint8_t n, m[16]; } q[SQ_NQ];
static uint8_t qh, qt;

/* ---- the MIDI task: the companion's router (sc_cmds, 2E..2F and 34, direct) ---- */
int a4_seq_rx(const uint8_t *d, int32_t len);
int a4_seq_rx(const uint8_t *d, int32_t len)
{
    const uint8_t *b = d + 6;
    int32_t n = len - 7, i;
    if (len < 8 || d[5] != 1) {
        ++a4_seq_bad;
        return 1;
    }
    ++a4_seq_msgs;
    switch (d[4]) {
    case 0x2E:
        if (n < 3)
            break;
        sq_mask = (uint32_t)(b[0] & 0x0F);              /* synth tracks only: FX and CV have no voice of the Sidecar's */
        if (b[2] & 2)
            sq_resync = 1;
        if (!sq_on)
            sq_resync = 1;
        sq_on = 1;
        break;
    case 0x34:
        sq_led_mode = b[0] == 1 && n >= 17;
        if (sq_led_mode)
            for (i = 0; i < K_TRIGS; ++i)
                sq_led[i] = b[1 + i];
        sq_led_new = 1;
        break;
    case 0x2F:
        if (n < 4)
            break;
        for (i = 0; i < 4; ++i)
            sq_pled[i] = b[i];
        sq_pled_new = 1;
        break;
    default:
        ++a4_seq_bad;
    }
    return 1;
}

/* ---- the UI task ---- */

static void put(const uint8_t *a, uint32_t n)           /* F0 7D 52 54 a[0..n-1] F7 */
{
    uint32_t i;
    if ((uint8_t)(qh - qt) >= SQ_NQ || n > 11) {
        ++a4_seq_drop;
        return;
    }
    q[qh % SQ_NQ].m[0] = 0xF0, q[qh % SQ_NQ].m[1] = 0x7D, q[qh % SQ_NQ].m[2] = 0x52, q[qh % SQ_NQ].m[3] = 0x54;
    for (i = 0; i < n; ++i)
        q[qh % SQ_NQ].m[4 + i] = a[i] & 0x7F;
    q[qh % SQ_NQ].m[4 + n] = 0xF7;
    q[qh % SQ_NQ].n = (uint8_t)(n + 5);
    qh = (uint8_t)(qh + 1);
}

static void key31(uint32_t c, uint32_t down)
{
    uint8_t a[5] = {0x31, 1, (uint8_t)(c >> 7), (uint8_t)(c & 0x7F), (uint8_t)down};
    put(a, 5);
}

/* seq mode: the reports on, the current track a seq track, GRID REC armed */
static int seqmode(int32_t *trk)
{
    int32_t t = core_current_track();
    *trk = t;
    return sq_on && grid && t >= 0 && t < 4 && (sq_mask >> t & 1);
}

static void edit(uint32_t op, int32_t track, uint32_t ok, uint32_t src, uint32_t arg)
{
    int32_t p = core_current_pattern();
    uint8_t a[11] = {0x2D, 1, 0x0A, (uint8_t)op, (uint8_t)(p >= 0 && p < 128 ? p : 0), (uint8_t)(track >= 0 && track < TRACKS ? track : 0x7F),
                     (uint8_t)ok, (uint8_t)src, (uint8_t)arg, (uint8_t)(arg >> 7), (uint8_t)(arg >> 14)};
    put(a, 11);
}

/* ev_tick: the port, SEQMODE, the queue */
void a4_seq_tick(void);
void a4_seq_tick(void)
{
    int32_t t;
    uint32_t on;
    if (!a4_usb_up()) {
        if (was_up) {                                   /* the Pi forgets: so does this */
            was_up = 0, sq_on = 0, sq_mask = 0, sq_led_mode = 0, sq_led_new = 1;
            mode_sent = 0xff, qt = qh;
        }
        return;
    }
    was_up = 1;
    on = (uint32_t)seqmode(&t);
    if (sq_on && (sq_resync || on != mode_sent || (on && (uint32_t)t != mode_trk))) {
        uint8_t a[5] = {0x2D, 1, 0x08, (uint8_t)on, (uint8_t)(on ? t : 0x7F)};
        sq_resync = 0;
        put(a, 5);
        mode_sent = on, mode_trk = (uint32_t)t;
    }
    while (qt != qh) {
        if (!a4_usb_send(q[qt % SQ_NQ].m, q[qt % SQ_NQ].n))
            return;
        qt = (uint8_t)(qt + 1);
    }
}

/* ev_mode: GRID REC armed or not */
void a4_seq_mode(int mode, int old, int now);
void a4_seq_mode(int mode, int old, int now)
{
    (void)old;
    if (mode == MODE_GRID_REC)
        grid = now != 0;
}

/* ev_key, before a4_remote's (order 49): in seq mode with the page closed, T1..T16 and PAGE the host's, FUNC both
 * sides'; a held host trig or PAGE + RECORD / STOP / PLAY (with FUNC or not) the host's copy / paste / clear */
int32_t a4_seq_key(void *brain, void *ev);
int32_t a4_seq_key(void *brain, void *ev)
{
    uint32_t c = *(uint32_t *)((uint8_t *)ev + 12), down = *(uint32_t *)((uint8_t *)ev + 16) & 1;
    int32_t t;
    (void)brain;
    if (c == KEYID_FUNC)
        func = down;
    if (!down) {                                        /* a release goes where its press went */
        if (c < K_TRIGS && (owner[c / 8] >> (c & 7) & 1)) {
            owner[c / 8] &= (uint8_t)~(1u << (c & 7));
            held &= ~(1u << c);
            key31(c, 0);
            return 1;
        }
        if (c == K_PAGE && page_owner) {
            page_owner = 0, page_held = 0;
            key31(c, 0);
            return 1;
        }
        if (c == KEYID_FUNC && sq_on && mode_sent == 1)
            key31(c, 0);
        return 0;
    }
    if (a4_remote_open() || !seqmode(&t))
        return 0;
    if (c < K_TRIGS) {
        owner[c / 8] |= (uint8_t)(1u << (c & 7));
        held |= 1u << c;
        key31(c, 1);
        return 1;
    }
    if (c == K_PAGE) {
        page_owner = 1, page_held = 1;
        key31(c, 1);
        return 1;
    }
    if (c == KEYID_FUNC) {                              /* both sides': stock keeps its combos */
        key31(c, 1);
        return 0;
    }
    if ((held || page_held) && (c == KEYID_RECORD || c == KEYID_STOP || c == KEYID_PLAY)) {
        uint32_t k = c == KEYID_RECORD ? 0 : c == KEYID_STOP ? 1 : 2;
        edit(page_held && !held ? 9 + k : 13 + k, t, 1, 1, held);
        return 1;
    }
    return 0;
}

/* ev_enc: A..H while a host trig is held in seq mode (page closed) */
int32_t a4_seq_enc(void *brain, void *ev);
int32_t a4_seq_enc(void *brain, void *ev)
{
    uint32_t e = *(uint32_t *)((uint8_t *)ev + 12);
    int32_t d = *(int32_t *)((uint8_t *)ev + 16), t;
    uint8_t a[5];
    (void)brain;
    if (!held || e >= 8 || a4_remote_open() || !seqmode(&t))
        return 0;
    d = d < -63 ? -63 : d > 63 ? 63 : d;
    a[0] = 0x32, a[1] = 1, a[2] = (uint8_t)e, a[3] = (uint8_t)(d + 64), a[4] = (uint8_t)(func ? 1 : 0);
    put(a, 5);
    return 1;
}

/* ev_key_leds: the host's trig LEDs (34 mode 1) and PAGE LEDs in seq mode. The A4's trig keys light in one colour:
 * off (palette 0, and 2, the steps past the track's length), on (every other colour). Stock's other modes (its
 * playhead's blink, a lock trig's) are not mapped yet. */
void a4_seq_leds(void *mgr);
void a4_seq_leds(void *mgr)
{
    uint32_t i;
    int32_t t;
    if (!sq_on || a4_remote_open() || !seqmode(&t))
        return;
    if (sq_led_mode)
        for (i = 0; i < K_TRIGS; ++i)
            core_led_set(mgr, i, sq_led[i] == 0 || sq_led[i] == 2 ? LED_OFF : LED_ON);
    for (i = 0; i < 4; ++i)
        if (sq_pled[i] != 0x7F)
            core_led_set(mgr, 0x60 + i, sq_pled[i] ? LED_ON : LED_OFF);
}

/* ev_clip: stock's copy / paste / clear, reported after they ran (src 0) on what the Sidecar keeps too: patterns, and
 * a seq track's sequence, page and trigs */
int a4_seq_clip(unsigned pre, const struct core_clip *c);
int a4_seq_clip(unsigned pre, const struct core_clip *c)
{
    uint32_t base;
    int32_t trk;
    if (pre || !sq_on || c->op > CLIP_CLEAR)
        return 0;
    switch (c->kind) {
    case CLIP_PATTERN: base = 1; trk = -1; break;
    case CLIP_TRACK:   base = 5; trk = c->track; break;
    case CLIP_PAGE:    base = 9; trk = core_current_track(); break;
    case CLIP_TRIGS:   base = 13; trk = core_current_track(); break;
    default: return 0;
    }
    if (trk >= 0 && (trk >= 4 || !(sq_mask >> trk & 1)))
        return 0;
    edit(base + c->op, trk, 1, 0, 0);
    return 0;
}

/* ev_live_rec: on a seq track live recording writes nothing (the Sidecar records it) */
int a4_seq_live(unsigned track, unsigned what);
int a4_seq_live(unsigned track, unsigned what)
{
    (void)what;
    if (sq_on && track < 4 && (sq_mask >> track & 1)) {
        ++a4_seq_refused;
        return 1;
    }
    return 0;
}
