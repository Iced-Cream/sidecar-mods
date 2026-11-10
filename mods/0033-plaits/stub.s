| Mod 0033 - PLAITS, a Pi voice machine on slot 44, a client of the companion's voice service.
| GENERATED from plaits.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that.
	.include "symbols.inc"
#NO_APP
	.file	"plaits.c"
	.text
	.align	2
	.type	pl_p2text, @function
pl_p2text:
	lea (-16,%sp),%sp
	mov3q.l #6,%d1
	move.l 20(%sp),%a0
	movem.l #1036,(%sp)
	move.l 4(%a0),%d0
	sub.l #__knobs,%d0
	cmp.l %d0,%d1
	jcs .L8
	move.l 8(%a0),%d1
	asr.l #8,%d1
	move.l 12(%a0),%a0
	lea pl_p2bip,%a2
	lea (1,%a0),%a1
	tst.b (%a2,%d0.l)
	jeq .L9
	move.l %d1,%d0
	add.l #-64,%d0
	tst.l %d0
	jge .L4
	move.b #45,(%a0)
	moveq #64,%d0
	sub.l %d1,%d0
.L18:
	move.l %a1,%a0
.L3:
	lea (12,%sp),%a1
	clr.l %d1
	move.l %a1,%a2
.L6:
	moveq #10,%d3
	addq.l #1,%d1
	rems.l %d3,%d2:%d0
	divs.l %d3,%d0
	add.l #48,%d2
	move.b %d2,(%a1)+
	tst.l %d0
	jeq .L5
	mov3q.l #3,%d2
	cmp.l %d1,%d2
	jne .L6
.L5:
	move.l %a0,%a1
	move.l %d1,%d0
.L7:
	subq.l #1,%d0
	move.b (%a2,%d0.l),(%a1)+
	tst.l %d0
	jne .L7
	clr.b %d3
	mov3q.l #1,%d0
	move.b %d3,(%a0,%d1.l)
.L1:
	movem.l (%sp),#1036
	lea (16,%sp),%sp
	rts
.L4:
	tst.l %d0
	jeq .L3
	move.b #43,(%a0)
	jra .L18
.L9:
	move.l %d1,%d0
	jra .L3
.L8:
	clr.l %d0
	jra .L1
	.size	pl_p2text, .-pl_p2text
	.align	2
	.type	pl_p2label, @function
pl_p2label:
	move.l 4(%sp),%d0
	mov3q.l #6,%d1
	sub.l #__knobs,%d0
	cmp.l %d0,%d1
	jcs .L21
	lea pl_p2lab,%a0
	move.l (%a0,%d0.l*4),%a0
.L19:
	move.l %a0,%d0
	rts
.L21:
	sub.l %a0,%a0
	jra .L19
	.size	pl_p2label, .-pl_p2label
	.align	2
	.type	pl_p2long, @function
pl_p2long:
	move.l 4(%sp),%d0
	mov3q.l #6,%d1
	sub.l #__knobs,%d0
	cmp.l %d0,%d1
	jcs .L24
	lea pl_p2name,%a0
	move.l (%a0,%d0.l*4),%a0
.L22:
	move.l %a0,%d0
	rts
.L24:
	sub.l %a0,%a0
	jra .L22
	.size	pl_p2long, .-pl_p2long
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
	.type	pl_p2delta, @function
pl_p2delta:
	move.l #pl_voice,%d0
	sub.l #__knobs,8(%sp)
	move.l %d0,4(%sp)
	jra sc_voice_p2_turn
	.size	pl_p2delta, .-pl_p2delta
	.align	2
	.type	pl_p2get, @function
pl_p2get:
	move.l 8(%sp),-(%sp)
	move.l 8(%sp),%d0
	sub.l #__knobs,%d0
	move.l %d0,-(%sp)
	pea pl_voice
	jsr sc_voice_p2_get
	lea (12,%sp),%sp
	rts
	.size	pl_p2get, .-pl_p2get
	.align	2
	.type	pl_text, @function
pl_text:
	mvz.w #409,%d0
	move.l 4(%sp),%a1
	cmp.l 4(%a1),%d0
	jne .L34
	move.l 8(%a1),%d0
	move.l %d0,%d1
	move.l 12(%a1),%a0
	asr.l #8,%d1
	cmp.l #32767,%d0
	jle .L30
	moveq #127,%d1
.L31:
	move.l %d1,%d0
	lsl.l #4,%d0
	lea pl_models,%a1
	add.l %d1,%d0
	asr.l #7,%d0
	move.l (%a1,%d0.l*4),%a1
.L32:
	move.b (%a1)+,%d0
	jne .L33
	clr.b (%a0)
	mov3q.l #1,%d0
.L28:
	rts
.L30:
	tst.l %d1
	jge .L31
	clr.l %d1
	jra .L31
.L33:
	move.b %d0,(%a0)+
	jra .L32
.L34:
	clr.l %d0
	jra .L28
	.size	pl_text, .-pl_text
	.globl	pl_look3
	.text
	.align	2
	.type	pl_look3, @object
	.size	pl_look3, 24
pl_look3:
	.long	__knobs+5
	.long	__knobs+6
	.long	408
	.long	0
	.long	0
	.long	32512
	.globl	pl_look2
	.align	2
	.type	pl_look2, @object
	.size	pl_look2, 24
pl_look2:
	.long	__knobs+4
	.long	__knobs+4
	.long	40
	.long	0
	.long	0
	.long	32512
	.globl	pl_look1
	.align	2
	.type	pl_look1, @object
	.size	pl_look1, 24
pl_look1:
	.long	__knobs+3
	.long	__knobs+3
	.long	408
	.long	0
	.long	0
	.long	32512
	.globl	pl_look0
	.align	2
	.type	pl_look0, @object
	.size	pl_look0, 24
pl_look0:
	.long	__knobs
	.long	__knobs+2
	.long	40
	.long	0
	.long	0
	.long	32512
	.globl	pl_p2names
	.align	2
	.type	pl_p2names, @object
	.size	pl_p2names, 32
pl_p2names:
	.long	__knobs
	.long	__knobs+6
	.long	0
	.long	0
	.long	0
	.long	0
	.long	pl_p2label
	.long	pl_p2long
	.globl	pl_p2params
	.align	2
	.type	pl_p2params, @object
	.size	pl_p2params, 20
pl_p2params:
	.long	__knobs
	.long	__knobs+6
	.long	pl_p2get
	.long	pl_p2delta
	.long	pl_p2text
	.globl	pl_params
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
	.size	pl_voice, 28
pl_voice:
	.byte	68
	.byte	8
	.byte	1
	.byte	33
	.long	.LC17
	.long	0
	.long	0
	.long	pl_page2
	.long	pl_p2def
	.byte	7
	.string	""
	.string	""
	.string	""
	.globl	pl_page2
	.text
.LC35:
	.string	"PLAITS PAGE 2"
	.text
	.align	2
	.type	pl_page2, @object
	.size	pl_page2, 40
pl_page2:
	.long	19
	.long	.LC35
	.long	__knobs
	.long	__knobs+1
	.long	__knobs+2
	.long	__knobs+3
	.long	__knobs+4
	.long	__knobs+5
	.long	__knobs+6
	.long	0
	.type	pl_p2bip, @object
	.size	pl_p2bip, 7
pl_p2bip:
	.string	"\001\001\001"
	.string	"\001"
	.string	""
	.text
.LC36:
	.string	"Timbre Mod"
.LC37:
	.string	"Morph Mod"
.LC38:
	.string	"Freq Mod"
.LC39:
	.string	"Aux Mix"
.LC40:
	.string	"Fine Tune"
.LC41:
	.string	"Velocity"
.LC42:
	.string	"Glide"
	.text
	.align	2
	.type	pl_p2name, @object
	.size	pl_p2name, 28
pl_p2name:
	.long	.LC36
	.long	.LC37
	.long	.LC38
	.long	.LC39
	.long	.LC40
	.long	.LC41
	.long	.LC42
	.text
.LC43:
	.string	"TMD"
.LC44:
	.string	"MMD"
.LC45:
	.string	"FM"
.LC46:
	.string	"AUX"
.LC47:
	.string	"FIN"
.LC48:
	.string	"VEL"
.LC49:
	.string	"GLD"
	.text
	.align	2
	.type	pl_p2lab, @object
	.size	pl_p2lab, 28
pl_p2lab:
	.long	.LC43
	.long	.LC44
	.long	.LC45
	.long	.LC46
	.long	.LC47
	.long	.LC48
	.long	.LC49
	.type	pl_p2def, @object
	.size	pl_p2def, 7
pl_p2def:
	.string	"@@@"
	.string	"@"
	.string	""
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
| the blob, shipped by the companion's code service (sc_code entry in mod.toml)
	.section .payload,"a"
	.balign 4
	.global pl_scx
pl_scx:
	.incbin "plaits.scx"
