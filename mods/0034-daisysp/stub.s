| Mod 0034 - DAISYSP, a Pi voice machine on slot 51, a client of the companion's voice service.
| GENERATED from daisysp.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that.
	.include "symbols.inc"
#NO_APP
	.file	"daisysp.c"
	.text
	.align	2
	.type	ds_input, @function
ds_input:
	move.l 4(%sp),%a0
	mvz.b 10(%a0),%d1
	mulu.w #11,%d1
	move.l %d1,%d0
	asr.l #7,%d0
	cmp.l #1407,%d1
	jgt .L4
	mov3q.l #2,%d1
	cmp.l %d0,%d1
	jlt .L2
	mov3q.l #-1,%d0
	jra .L1
.L4:
	moveq #10,%d0
.L2:
	subq.l #1,%d0
.L1:
	rts
	.size	ds_input, .-ds_input
	.align	2
	.type	ds_engine, @function
ds_engine:
	move.l 16(%sp),-(%sp)
	move.l 16(%sp),-(%sp)
	move.l 16(%sp),-(%sp)
	move.l 16(%sp),-(%sp)
	pea ds_voice
	jsr sc_voice_engine
	lea (20,%sp),%sp
	rts
	.size	ds_engine, .-ds_engine
	.align	2
	.type	ds_text, @function
ds_text:
	move.l 4(%sp),%a1
	move.l 4(%a1),%d1
	move.l 8(%a1),%d0
	asr.l #8,%d0
	cmp.l #450,%d1
	jne .L8
	move.l %d0,%d1
	add.l %d1,%d1
	add.l %d1,%d0
	moveq #-127,%d1
	cmp.l %d0,%d1
	jgt .L17
	cmp.l #383,%d0
	jgt .L18
	tst.l %d0
	jge .L10
	add.l #127,%d0
.L10:
	asr.l #7,%d0
.L9:
	lea ds_models,%a0
.L22:
	move.l (%a0,%d0.l*4),%a0
	move.l 12(%a1),%a1
.L15:
	move.b (%a0)+,%d0
	jne .L16
	clr.b (%a1)
	mov3q.l #1,%d0
.L7:
	rts
.L17:
	clr.l %d0
	jra .L9
.L18:
	mov3q.l #2,%d0
	jra .L9
.L8:
	cmp.l #454,%d1
	jne .L19
	moveq #11,%d1
	muls.l %d1,%d0
	moveq #-127,%d1
	cmp.l %d0,%d1
	jgt .L20
	cmp.l #1407,%d0
	jgt .L21
	tst.l %d0
	jge .L14
	add.l #127,%d0
.L14:
	asr.l #7,%d0
.L13:
	lea ds_inputs,%a0
	jra .L22
.L20:
	clr.l %d0
	jra .L13
.L21:
	moveq #10,%d0
	jra .L13
.L16:
	move.b %d0,(%a1)+
	jra .L15
.L19:
	clr.l %d0
	jra .L7
	.size	ds_text, .-ds_text
	.globl	ds_params
	.text
	.align	2
	.type	ds_params, @object
	.size	ds_params, 20
ds_params:
	.long	450
	.long	454
	.long	0
	.long	0
	.long	ds_text
	.text
.LC0:
	.string	"INT"
.LC1:
	.string	"NAT"
.LC2:
	.string	"NOIS"
.LC3:
	.string	"BD"
.LC4:
	.string	"SD"
.LC5:
	.string	"RS"
.LC6:
	.string	"BT"
.LC7:
	.string	"LT"
.LC8:
	.string	"MT"
.LC9:
	.string	"CH"
.LC10:
	.string	"CY"
	.text
	.align	2
	.type	ds_inputs, @object
	.size	ds_inputs, 44
ds_inputs:
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
	.text
.LC11:
	.string	"MODL"
.LC12:
	.string	"STRG"
.LC13:
	.string	"RESN"
	.text
	.align	2
	.type	ds_models, @object
	.size	ds_models, 12
ds_models:
	.long	.LC11
	.long	.LC12
	.long	.LC13
	.globl	ds_machine
	.text
.LC14:
	.string	"DAISYSP"
.LC15:
	.string	"DSP"
.LC16:
	.string	"Level"
.LC17:
	.string	"LEV"
.LC18:
	.string	"Engine"
.LC19:
	.string	"ENG"
.LC20:
	.string	"Structure"
.LC21:
	.string	"STR"
.LC22:
	.string	"Brightness"
.LC23:
	.string	"BRI"
.LC24:
	.string	"Damping"
.LC25:
	.string	"DMP"
.LC26:
	.string	"Input"
.LC27:
	.string	"INP"
.LC28:
	.string	"Excite"
.LC29:
	.string	"EXC"
.LC30:
	.string	"Tune"
.LC31:
	.string	"TUN"
	.text
	.align	2
	.type	ds_machine, @object
	.size	ds_machine, 116
ds_machine:
	.long	51
	.long	ds_engine
	.byte	-1
	.byte	-1
	.word	0
	.long	.LC14
	.long	.LC15
	.long	.LC16
	.long	.LC17
	.byte	0
	.byte	127
	.byte	100
	.byte	0
	.long	.LC18
	.long	.LC19
	.byte	0
	.byte	127
	.byte	0
	.byte	0
	.long	.LC20
	.long	.LC21
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC22
	.long	.LC23
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC24
	.long	.LC25
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC26
	.long	.LC27
	.byte	0
	.byte	127
	.byte	0
	.byte	0
	.long	.LC28
	.long	.LC29
	.byte	0
	.byte	127
	.byte	64
	.byte	0
	.long	.LC30
	.long	.LC31
	.byte	32
	.byte	96
	.byte	64
	.byte	1
	.align	2
	.type	ds_voice, @object
	.size	ds_voice, 12
ds_voice:
	.byte	81
	.byte	8
	.byte	1
	.byte	0
	.long	.LC14
	.long	ds_input
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
| the blob, shipped by the companion's code service (sc_code entry in mod.toml)
	.section .payload,"a"
	.balign 4
	.global ds_scx
ds_scx:
	.incbin "daisysp.scx"
