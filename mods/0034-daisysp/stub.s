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
	.type	ds_p2text, @function
ds_p2text:
	lea (-16,%sp),%sp
	mov3q.l #2,%d1
	move.l 20(%sp),%a0
	movem.l #1036,(%sp)
	move.l 4(%a0),%d0
	sub.l #__knobs,%d0
	cmp.l %d0,%d1
	jcs .L13
	move.l 8(%a0),%d1
	asr.l #8,%d1
	move.l 12(%a0),%a0
	lea ds_p2bip,%a2
	lea (1,%a0),%a1
	tst.b (%a2,%d0.l)
	jeq .L14
	move.l %d1,%d0
	add.l #-64,%d0
	tst.l %d0
	jge .L9
	move.b #45,(%a0)
	moveq #64,%d0
	sub.l %d1,%d0
.L23:
	move.l %a1,%a0
.L8:
	lea (12,%sp),%a1
	clr.l %d1
	move.l %a1,%a2
.L11:
	moveq #10,%d3
	addq.l #1,%d1
	rems.l %d3,%d2:%d0
	divs.l %d3,%d0
	add.l #48,%d2
	move.b %d2,(%a1)+
	tst.l %d0
	jeq .L10
	mov3q.l #3,%d2
	cmp.l %d1,%d2
	jne .L11
.L10:
	move.l %a0,%a1
	move.l %d1,%d0
.L12:
	subq.l #1,%d0
	move.b (%a2,%d0.l),(%a1)+
	tst.l %d0
	jne .L12
	clr.b %d3
	mov3q.l #1,%d0
	move.b %d3,(%a0,%d1.l)
.L6:
	movem.l (%sp),#1036
	lea (16,%sp),%sp
	rts
.L9:
	tst.l %d0
	jeq .L8
	move.b #43,(%a0)
	jra .L23
.L14:
	move.l %d1,%d0
	jra .L8
.L13:
	clr.l %d0
	jra .L6
	.size	ds_p2text, .-ds_p2text
	.align	2
	.type	ds_p2label, @function
ds_p2label:
	move.l 4(%sp),%d0
	mov3q.l #2,%d1
	sub.l #__knobs,%d0
	cmp.l %d0,%d1
	jcs .L26
	lea ds_p2lab,%a0
	move.l (%a0,%d0.l*4),%a0
.L24:
	move.l %a0,%d0
	rts
.L26:
	sub.l %a0,%a0
	jra .L24
	.size	ds_p2label, .-ds_p2label
	.align	2
	.type	ds_p2long, @function
ds_p2long:
	move.l 4(%sp),%d0
	mov3q.l #2,%d1
	sub.l #__knobs,%d0
	cmp.l %d0,%d1
	jcs .L29
	lea ds_p2name,%a0
	move.l (%a0,%d0.l*4),%a0
.L27:
	move.l %a0,%d0
	rts
.L29:
	sub.l %a0,%a0
	jra .L27
	.size	ds_p2long, .-ds_p2long
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
	.type	ds_p2delta, @function
ds_p2delta:
	move.l 8(%sp),%d0
	sub.l #__knobs,%d0
	move.l %d0,8(%sp)
	move.l #ds_voice,%d0
	move.l %d0,4(%sp)
	jra sc_voice_p2_turn
	.size	ds_p2delta, .-ds_p2delta
	.align	2
	.type	ds_p2get, @function
ds_p2get:
	move.l 8(%sp),-(%sp)
	move.l 8(%sp),%d0
	sub.l #__knobs,%d0
	move.l %d0,-(%sp)
	pea ds_voice
	jsr sc_voice_p2_get
	lea (12,%sp),%sp
	rts
	.size	ds_p2get, .-ds_p2get
	.align	2
	.type	ds_text, @function
ds_text:
	move.l 4(%sp),%a1
	move.l 4(%a1),%d1
	move.l 8(%a1),%d0
	asr.l #8,%d0
	cmp.l #450,%d1
	jne .L34
	move.l %d0,%d1
	add.l %d1,%d1
	add.l %d1,%d0
	moveq #-127,%d1
	cmp.l %d0,%d1
	jgt .L43
	cmp.l #383,%d0
	jgt .L44
	tst.l %d0
	jge .L36
	add.l #127,%d0
.L36:
	asr.l #7,%d0
.L35:
	lea ds_models,%a0
.L48:
	move.l (%a0,%d0.l*4),%a0
	move.l 12(%a1),%a1
.L41:
	move.b (%a0)+,%d0
	jne .L42
	clr.b (%a1)
	mov3q.l #1,%d0
.L33:
	rts
.L43:
	clr.l %d0
	jra .L35
.L44:
	mov3q.l #2,%d0
	jra .L35
.L34:
	cmp.l #454,%d1
	jne .L45
	moveq #11,%d1
	muls.l %d1,%d0
	moveq #-127,%d1
	cmp.l %d0,%d1
	jgt .L46
	cmp.l #1407,%d0
	jgt .L47
	tst.l %d0
	jge .L40
	add.l #127,%d0
.L40:
	asr.l #7,%d0
.L39:
	lea ds_inputs,%a0
	jra .L48
.L46:
	clr.l %d0
	jra .L39
.L47:
	moveq #10,%d0
	jra .L39
.L42:
	move.b %d0,(%a1)+
	jra .L41
.L45:
	clr.l %d0
	jra .L33
	.size	ds_text, .-ds_text
	.globl	ds_look2
	.text
	.align	2
	.type	ds_look2, @object
	.size	ds_look2, 24
ds_look2:
	.long	__knobs+2
	.long	__knobs+2
	.long	408
	.long	0
	.long	0
	.long	32512
	.globl	ds_look1
	.align	2
	.type	ds_look1, @object
	.size	ds_look1, 24
ds_look1:
	.long	__knobs+1
	.long	__knobs+1
	.long	40
	.long	0
	.long	0
	.long	32512
	.globl	ds_look0
	.align	2
	.type	ds_look0, @object
	.size	ds_look0, 24
ds_look0:
	.long	__knobs
	.long	__knobs
	.long	408
	.long	0
	.long	0
	.long	32512
	.globl	ds_p2names
	.align	2
	.type	ds_p2names, @object
	.size	ds_p2names, 32
ds_p2names:
	.long	__knobs
	.long	__knobs+2
	.long	0
	.long	0
	.long	0
	.long	0
	.long	ds_p2label
	.long	ds_p2long
	.globl	ds_p2params
	.align	2
	.type	ds_p2params, @object
	.size	ds_p2params, 20
ds_p2params:
	.long	__knobs
	.long	__knobs+2
	.long	ds_p2get
	.long	ds_p2delta
	.long	ds_p2text
	.globl	ds_params
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
	.size	ds_voice, 32
ds_voice:
	.byte	81
	.byte	8
	.byte	1
	.byte	34
	.long	.LC14
	.long	ds_input
	.long	0
	.long	ds_page2
	.long	ds_p2def
	.byte	3
	.string	""
	.string	""
	.string	""
	.zero	4
	.globl	ds_page2
	.text
.LC32:
	.string	"EXCITER"
	.text
	.align	2
	.type	ds_page2, @object
	.size	ds_page2, 40
ds_page2:
	.long	19
	.long	.LC32
	.long	__knobs
	.long	__knobs+1
	.long	__knobs+2
	.long	0
	.long	0
	.long	0
	.long	0
	.long	0
	.type	ds_p2bip, @object
	.size	ds_p2bip, 3
ds_p2bip:
	.string	""
	.string	"\001"
	.text
.LC33:
	.string	"Exc Tone"
.LC34:
	.string	"Exc Decay"
.LC35:
	.string	"Exc Mix"
	.text
	.align	2
	.type	ds_p2name, @object
	.size	ds_p2name, 12
ds_p2name:
	.long	.LC33
	.long	.LC34
	.long	.LC35
	.text
.LC36:
	.string	"XTN"
.LC37:
	.string	"XDC"
.LC38:
	.string	"XMX"
	.text
	.align	2
	.type	ds_p2lab, @object
	.size	ds_p2lab, 12
ds_p2lab:
	.long	.LC36
	.long	.LC37
	.long	.LC38
	.type	ds_p2def, @object
	.size	ds_p2def, 3
ds_p2def:
	.string	"\177@"
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
| the blob, shipped by the companion's code service (sc_code entry in mod.toml)
	.section .payload,"a"
	.balign 4
	.global ds_scx
ds_scx:
	.incbin "daisysp.scx"
