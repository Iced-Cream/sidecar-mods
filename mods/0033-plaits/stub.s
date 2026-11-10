| Mod 0033 - PLAITS, a Pi voice machine on slot 44, a client of the companion's voice service.
| GENERATED from plaits.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that.
	.include "symbols.inc"
#NO_APP
	.file	"plaits.c"
	.text
	.align	2
	.type	pl_engine, @function
pl_engine:
	move.l 16(%sp),-(%sp)
	move.l 16(%sp),-(%sp)
	move.l 16(%sp),-(%sp)
	move.l 16(%sp),-(%sp)
	pea pl_voice
	jsr sc_voice_engine
	lea (20,%sp),%sp
	rts
	.size	pl_engine, .-pl_engine
	.align	2
	.type	pl_text, @function
pl_text:
	mvz.w #409,%d0
	move.l 4(%sp),%a1
	cmp.l 4(%a1),%d0
	jne .L8
	move.l 8(%a1),%d0
	move.l %d0,%d1
	move.l 12(%a1),%a0
	asr.l #8,%d1
	cmp.l #32767,%d0
	jle .L4
	moveq #127,%d1
.L5:
	move.l %d1,%d0
	lsl.l #4,%d0
	lea pl_models,%a1
	add.l %d1,%d0
	asr.l #7,%d0
	move.l (%a1,%d0.l*4),%a1
.L6:
	move.b (%a1)+,%d0
	jne .L7
	clr.b (%a0)
	mov3q.l #1,%d0
.L2:
	rts
.L4:
	tst.l %d1
	jge .L5
	clr.l %d1
	jra .L5
.L7:
	move.b %d0,(%a0)+
	jra .L6
.L8:
	clr.l %d0
	jra .L2
	.size	pl_text, .-pl_text
	.globl	pl_params
	.text
	.align	2
	.type	pl_params, @object
	.size	pl_params, 20
pl_params:
	.long	409
	.long	409
	.long	0
	.long	0
	.long	pl_text
	.text
.LC0:
	.string	"VCF"
.LC1:
	.string	"PHAS"
.LC2:
	.string	"TERR"
.LC3:
	.string	"SMCH"
.LC4:
	.string	"CHIP"
.LC5:
	.string	"VA"
.LC6:
	.string	"SHAP"
.LC7:
	.string	"FM2"
.LC8:
	.string	"GRAN"
.LC9:
	.string	"HARM"
.LC10:
	.string	"WTBL"
.LC11:
	.string	"CHRD"
.LC12:
	.string	"SPCH"
.LC13:
	.string	"SWRM"
.LC14:
	.string	"PART"
.LC15:
	.string	"STRG"
.LC16:
	.string	"MODL"
	.text
	.align	2
	.type	pl_models, @object
	.size	pl_models, 68
pl_models:
	.long	.LC0
	.long	.LC1
	.long	.LC2
	.long	.LC3
	.long	.LC4
	.long	.LC5
	.long	.LC6
	.long	.LC7
	.long	.LC8
	.long	.LC9
	.long	.LC10
	.long	.LC11
	.long	.LC12
	.long	.LC13
	.long	.LC14
	.long	.LC15
	.long	.LC16
	.globl	pl_machine
	.text
.LC17:
	.string	"PLAITS"
.LC18:
	.string	"PLTS"
.LC19:
	.string	"Level"
.LC20:
	.string	"LEV"
.LC21:
	.string	"Engine"
.LC22:
	.string	"ENG"
.LC23:
	.string	"Harmonics"
.LC24:
	.string	"HRM"
.LC25:
	.string	"Timbre"
.LC26:
	.string	"TIM"
.LC27:
	.string	"Morph"
.LC28:
	.string	"MOR"
.LC29:
	.string	"Decay"
.LC30:
	.string	"DEC"
.LC31:
	.string	"LPG Colour"
.LC32:
	.string	"LPG"
.LC33:
	.string	"Tune"
.LC34:
	.string	"TUN"
	.text
	.align	2
	.type	pl_machine, @object
	.size	pl_machine, 116
pl_machine:
	.long	44
	.long	pl_engine
	.byte	-1
	.byte	-1
	.word	0
	.long	.LC17
	.long	.LC18
	.long	.LC19
	.long	.LC20
	.byte	0
	.byte	127
	.byte	100
	.byte	0
	.long	.LC21
	.long	.LC22
	.byte	0
	.byte	127
	.byte	0
	.byte	0
	.long	.LC23
	.long	.LC24
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC25
	.long	.LC26
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC27
	.long	.LC28
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC29
	.long	.LC30
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC31
	.long	.LC32
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC33
	.long	.LC34
	.byte	32
	.byte	96
	.byte	64
	.byte	1
	.align	2
	.type	pl_voice, @object
	.size	pl_voice, 12
pl_voice:
	.byte	68
	.byte	8
	.byte	1
	.byte	0
	.long	.LC17
	.long	0
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
| the blob, shipped by the companion's code service (sc_code entry in mod.toml)
	.section .payload,"a"
	.balign 4
	.global pl_scx
pl_scx:
	.incbin "plaits.scx"
