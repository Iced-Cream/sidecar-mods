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
	.globl	pl_machine
	.text
.LC0:
	.string	"PLAITS"
.LC1:
	.string	"PLTS"
.LC2:
	.string	"Level"
.LC3:
	.string	"LEV"
.LC4:
	.string	"Engine"
.LC5:
	.string	"ENG"
.LC6:
	.string	"Harmonics"
.LC7:
	.string	"HRM"
.LC8:
	.string	"Timbre"
.LC9:
	.string	"TIM"
.LC10:
	.string	"Morph"
.LC11:
	.string	"MOR"
.LC12:
	.string	"Decay"
.LC13:
	.string	"DEC"
.LC14:
	.string	"LPG Colour"
.LC15:
	.string	"LPG"
.LC16:
	.string	"Tune"
.LC17:
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
	.long	.LC0
	.long	.LC1
	.long	.LC2
	.long	.LC3
	.byte	0
	.byte	127
	.byte	100
	.byte	0
	.long	.LC4
	.long	.LC5
	.byte	0
	.byte	127
	.byte	0
	.byte	0
	.long	.LC6
	.long	.LC7
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC8
	.long	.LC9
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC10
	.long	.LC11
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC12
	.long	.LC13
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC14
	.long	.LC15
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC16
	.long	.LC17
	.byte	32
	.byte	96
	.byte	64
	.byte	1
	.align	2
	.type	pl_voice, @object
	.size	pl_voice, 8
pl_voice:
	.byte	68
	.byte	8
	.byte	1
	.byte	0
	.long	.LC0
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
| the blob, shipped by the companion's code service (sc_code entry in mod.toml)
	.section .payload,"a"
	.balign 4
	.global pl_scx
pl_scx:
	.incbin "plaits.scx"
