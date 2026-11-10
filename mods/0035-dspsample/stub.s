| Mod 0035 - DSP SAMPLE, a Pi voice machine on slot 45, a client of the companion's voice service.
| GENERATED from dspsample.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that.
	.include "symbols.inc"
#NO_APP
	.file	"dspsample.c"
	.text
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
	.text
.LC0:
	.string	"OFF"
	.text
	.align	2
	.type	dss_text, @function
dss_text:
	lea (-12,%sp),%sp
	mvz.w #417,%d0
	move.l 16(%sp),%a0
	movem.l #3076,(%sp)
	cmp.l 4(%a0),%d0
	jne .L8
	move.l 8(%a0),%d2
	asr.l #8,%d2
	move.l 12(%a0),%a3
	lea .LC0,%a2
	tst.l %d2
	jle .L12
	subq.l #1,%d2
	move.l %d2,-(%sp)
	jsr sc_sample_name
	move.l %d2,-(%sp)
	move.l %a0,%a2
	jsr sc_sample_state
	addq.l #8,%sp
	tst.l %a2
	jeq .L11
	tst.b (%a2)
	jeq .L11
	subq.l #4,%d0
	lsr.l #1,%d0
	jne .L12
	move.b #33,(%a3)
	mov3q.l #1,%a1
.L4:
	sub.l %a1,%a2
.L5:
	move.b (%a2,%a1.l),%d0
	jeq .L6
	mvs.b %d0,%d1
	moveq #46,%d2
	cmp.l %d1,%d2
	jeq .L6
	mov3q.l #7,%d1
	cmp.l %a1,%d1
	jne .L7
.L6:
	clr.b %d2
	mov3q.l #1,%d0
	move.b %d2,(%a3,%a1.l)
.L2:
	movem.l (%sp),#3076
	lea (12,%sp),%sp
	rts
.L12:
	sub.l %a1,%a1
	jra .L4
.L7:
	move.b %d0,(%a3,%a1.l)
	addq.l #1,%a1
	jra .L5
.L8:
	clr.l %d0
	jra .L2
.L11:
	mov3q.l #2,%d0
	jra .L2
	.size	dss_text, .-dss_text
	.globl	dss_params
	.text
	.align	2
	.type	dss_params, @object
	.size	dss_params, 20
dss_params:
	.long	417
	.long	417
	.long	0
	.long	0
	.long	dss_text
	.globl	dss_machine
	.text
.LC1:
	.string	"DSP SAMPLE"
.LC2:
	.string	"DSPS"
.LC3:
	.string	"Level"
.LC4:
	.string	"LEV"
.LC5:
	.string	"Sample"
.LC6:
	.string	"SMP"
.LC7:
	.string	"Tune"
.LC8:
	.string	"TUN"
.LC9:
	.string	"Start"
.LC10:
	.string	"STA"
.LC11:
	.string	"End"
.LC12:
	.string	"END"
.LC13:
	.string	"Loop"
.LC14:
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
	.long	.LC1
	.long	.LC2
	.long	.LC3
	.long	.LC4
	.byte	0
	.byte	127
	.byte	100
	.byte	0
	.long	.LC5
	.long	.LC6
	.byte	0
	.byte	127
	.byte	0
	.byte	0
	.long	.LC7
	.long	.LC8
	.byte	40
	.byte	88
	.byte	64
	.byte	1
	.long	.LC9
	.long	.LC10
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
	.long	.LC11
	.long	.LC12
	.byte	0
	.byte	127
	.byte	127
	.byte	0
	.long	.LC13
	.long	.LC14
	.byte	0
	.byte	1
	.byte	0
	.byte	0
	.text
.LC15:
	.string	"SAMPLE"
	.text
	.align	2
	.type	dss_voice, @object
	.size	dss_voice, 16
dss_voice:
	.byte	69
	.byte	6
	.byte	0
	.byte	0
	.long	.LC15
	.long	0
	.long	dss_words
	.type	dss_words, @object
	.size	dss_words, 6
dss_words:
	.string	""
	.ascii	"\001\002\003\006\007"
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
