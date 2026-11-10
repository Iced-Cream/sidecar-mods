| Mod 0035 - DSP SAMPLE, a Pi voice machine on slot 45, a client of the companion's voice service.
| GENERATED from dspsample.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that.
	.include "symbols.inc"
#NO_APP
	.file	"dspsample.c"
	.text
	.align	2
	.type	dss_p2text, @function
dss_p2text:
	lea (-16,%sp),%sp
	mov3q.l #1,%d1
	move.l 20(%sp),%a0
	movem.l #1036,(%sp)
	move.l 4(%a0),%d0
	sub.l #__knobs,%d0
	cmp.l %d0,%d1
	jcs .L8
	move.l 8(%a0),%d1
	asr.l #8,%d1
	move.l 12(%a0),%a0
	lea dss_p2bip,%a2
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
	.size	dss_p2text, .-dss_p2text
	.align	2
	.type	dss_p2label, @function
dss_p2label:
	move.l 4(%sp),%d0
	mov3q.l #1,%d1
	sub.l #__knobs,%d0
	cmp.l %d0,%d1
	jcs .L21
	lea dss_p2lab,%a0
	move.l (%a0,%d0.l*4),%a0
.L19:
	move.l %a0,%d0
	rts
.L21:
	sub.l %a0,%a0
	jra .L19
	.size	dss_p2label, .-dss_p2label
	.align	2
	.type	dss_p2long, @function
dss_p2long:
	move.l 4(%sp),%d0
	mov3q.l #1,%d1
	sub.l #__knobs,%d0
	cmp.l %d0,%d1
	jcs .L24
	lea dss_p2name,%a0
	move.l (%a0,%d0.l*4),%a0
.L22:
	move.l %a0,%d0
	rts
.L24:
	sub.l %a0,%a0
	jra .L22
	.size	dss_p2long, .-dss_p2long
	.align	2
	.type	dss_engine, @function
dss_engine:
	move.l 16(%sp),-(%sp)
	move.l 16(%sp),-(%sp)
	move.l 16(%sp),-(%sp)
	move.l 16(%sp),-(%sp)
	pea dss_voice
	jsr sc_voice_engine
	lea (20,%sp),%sp
	rts
	.size	dss_engine, .-dss_engine
	.align	2
	.type	dss_p2delta, @function
dss_p2delta:
	move.l 8(%sp),%d0
	sub.l #__knobs,%d0
	move.l %d0,8(%sp)
	move.l #dss_voice,%d0
	move.l %d0,4(%sp)
	jra sc_voice_p2_turn
	.size	dss_p2delta, .-dss_p2delta
	.align	2
	.type	dss_p2get, @function
dss_p2get:
	move.l 8(%sp),-(%sp)
	move.l 8(%sp),%d0
	sub.l #__knobs,%d0
	move.l %d0,-(%sp)
	pea dss_voice
	jsr sc_voice_p2_get
	lea (12,%sp),%sp
	rts
	.size	dss_p2get, .-dss_p2get
	.align	2
	.type	dss_num.isra.0, @function
dss_num.isra.0:
	lea (-16,%sp),%sp
	move.l 24(%sp),%d0
	movem.l #1036,(%sp)
	move.l 20(%sp),%a1
	tst.l %d0
	jge .L29
	clr.l %d0
.L29:
	lea (12,%sp),%a0
	clr.l %d1
	move.l %a0,%a2
.L31:
	moveq #10,%d3
	addq.l #1,%d1
	rems.l %d3,%d2:%d0
	divs.l %d3,%d0
	add.l #48,%d2
	move.b %d2,(%a0)+
	tst.l %d0
	jeq .L30
	mov3q.l #3,%d2
	cmp.l %d1,%d2
	jne .L31
.L30:
	move.l %a1,%a0
	move.l %d1,%d0
.L32:
	subq.l #1,%d0
	move.b (%a2,%d0.l),(%a0)+
	tst.l %d0
	jne .L32
	clr.b %d3
	move.b %d3,(%a1,%d1.l)
	movem.l (%sp),#1036
	lea (16,%sp),%sp
	rts
	.size	dss_num.isra.0, .-dss_num.isra.0
	.text
.LC0:
	.string	"OFF"
.LC1:
	.string	"ON"
	.text
	.align	2
	.type	dss_text, @function
dss_text:
	lea (-16,%sp),%sp
	move.l 20(%sp),%a0
	movem.l #3084,(%sp)
	move.l 4(%a0),%d0
	move.l 8(%a0),%d2
	asr.l #8,%d2
	move.l 12(%a0),%a2
	cmp.l #420,%d0
	jne .L39
.L47:
	move.l %d2,-(%sp)
	move.l %a2,-(%sp)
	jsr (dss_num.isra.0)
	addq.l #8,%sp
	jra .L40
.L39:
	cmp.l #421,%d0
	jne .L41
	lea .LC0,%a0
	tst.l %d2
	jeq .L43
	lea .LC1,%a0
.L43:
	move.b (%a0)+,%d0
	jne .L44
	clr.b (%a2)
.L40:
	mov3q.l #1,%d0
.L38:
	movem.l (%sp),#3084
	lea (16,%sp),%sp
	rts
.L44:
	move.b %d0,(%a2)+
	jra .L43
.L41:
	cmp.l #417,%d0
	jne .L53
	lea .LC0,%a3
	tst.l %d2
	jle .L55
	move.l %d2,%d3
	subq.l #1,%d3
	move.l %d3,-(%sp)
	jsr sc_sample_name
	move.l %d3,-(%sp)
	move.l %a0,%a3
	jsr sc_sample_state
	addq.l #8,%sp
	tst.l %a3
	jeq .L47
	tst.b (%a3)
	jeq .L47
	subq.l #4,%d0
	lsr.l #1,%d0
	jne .L55
	move.b #33,(%a2)
	mov3q.l #1,%a1
.L46:
	sub.l %a1,%a3
.L49:
	move.b (%a3,%a1.l),%d0
	jeq .L50
	mvs.b %d0,%d1
	moveq #46,%d2
	cmp.l %d1,%d2
	jeq .L50
	mov3q.l #7,%d1
	cmp.l %a1,%d1
	jne .L51
.L50:
	clr.b %d2
	move.b %d2,(%a2,%a1.l)
	jra .L40
.L55:
	sub.l %a1,%a1
	jra .L46
.L51:
	move.b %d0,(%a2,%a1.l)
	addq.l #1,%a1
	jra .L49
.L53:
	clr.l %d0
	jra .L38
	.size	dss_text, .-dss_text
	.globl	dss_look1
	.text
	.align	2
	.type	dss_look1, @object
	.size	dss_look1, 24
dss_look1:
	.long	__knobs+1
	.long	__knobs+1
	.long	408
	.long	0
	.long	0
	.long	32512
	.globl	dss_look0
	.align	2
	.type	dss_look0, @object
	.size	dss_look0, 24
dss_look0:
	.long	__knobs
	.long	__knobs
	.long	40
	.long	0
	.long	0
	.long	32512
	.globl	dss_p2names
	.align	2
	.type	dss_p2names, @object
	.size	dss_p2names, 32
dss_p2names:
	.long	__knobs
	.long	__knobs+1
	.long	0
	.long	0
	.long	0
	.long	0
	.long	dss_p2label
	.long	dss_p2long
	.globl	dss_p2params
	.align	2
	.type	dss_p2params, @object
	.size	dss_p2params, 20
dss_p2params:
	.long	__knobs
	.long	__knobs+1
	.long	dss_p2get
	.long	dss_p2delta
	.long	dss_p2text
	.globl	dss_params
	.align	2
	.type	dss_params, @object
	.size	dss_params, 20
dss_params:
	.long	417
	.long	421
	.long	0
	.long	0
	.long	dss_text
	.globl	dss_machine
	.text
.LC2:
	.string	"DSP SAMPLE"
.LC3:
	.string	"DSPS"
.LC4:
	.string	"Level"
.LC5:
	.string	"LEV"
.LC6:
	.string	"Sample"
.LC7:
	.string	"SMP"
.LC8:
	.string	"Tune"
.LC9:
	.string	"TUN"
.LC10:
	.string	"Start"
.LC11:
	.string	"STA"
.LC12:
	.string	"End"
.LC13:
	.string	"END"
.LC14:
	.string	"Loop"
.LC15:
	.string	"LOP"
	.text
	.align	2
	.type	dss_machine, @object
	.size	dss_machine, 116
dss_machine:
	.long	45
	.long	dss_engine
	.byte	-1
	.byte	-1
	.word	0
	.long	.LC2
	.long	.LC3
	.long	.LC4
	.long	.LC5
	.byte	0
	.byte	127
	.byte	100
	.byte	0
	.long	.LC6
	.long	.LC7
	.byte	0
	.byte	127
	.byte	0
	.byte	0
	.long	.LC8
	.long	.LC9
	.byte	40
	.byte	88
	.byte	64
	.byte	1
	.long	.LC10
	.long	.LC11
	.byte	0
	.byte	127
	.byte	0
	.byte	0
	.long	0
	.long	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.long	0
	.long	0
	.byte	0
	.byte	0
	.byte	0
	.byte	0
	.long	.LC12
	.long	.LC13
	.byte	0
	.byte	127
	.byte	127
	.byte	0
	.long	.LC14
	.long	.LC15
	.byte	0
	.byte	1
	.byte	0
	.byte	0
	.text
.LC16:
	.string	"SAMPLE"
	.text
	.align	2
	.type	dss_voice, @object
	.size	dss_voice, 32
dss_voice:
	.byte	69
	.byte	6
	.byte	0
	.byte	35
	.long	.LC16
	.long	0
	.long	dss_words
	.long	dss_page2
	.long	dss_p2def
	.byte	2
	.string	""
	.string	""
	.string	""
	.zero	4
	.globl	dss_page2
	.text
.LC17:
	.string	"DSP SAMPLE 2"
	.text
	.align	2
	.type	dss_page2, @object
	.size	dss_page2, 40
dss_page2:
	.long	19
	.long	.LC17
	.long	__knobs
	.long	__knobs+1
	.long	0
	.long	0
	.long	0
	.long	0
	.long	0
	.long	0
	.type	dss_p2bip, @object
	.size	dss_p2bip, 2
dss_p2bip:
	.string	"\001"
	.text
.LC18:
	.string	"Fine Tune"
.LC19:
	.string	"Velocity"
	.text
	.align	2
	.type	dss_p2name, @object
	.size	dss_p2name, 8
dss_p2name:
	.long	.LC18
	.long	.LC19
	.text
.LC20:
	.string	"FIN"
.LC21:
	.string	"VEL"
	.text
	.align	2
	.type	dss_p2lab, @object
	.size	dss_p2lab, 8
dss_p2lab:
	.long	.LC20
	.long	.LC21
	.type	dss_p2def, @object
	.size	dss_p2def, 2
dss_p2def:
	.string	"@"
	.type	dss_words, @object
	.size	dss_words, 6
dss_words:
	.string	""
	.ascii	"\001\002\003\006\007"
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
