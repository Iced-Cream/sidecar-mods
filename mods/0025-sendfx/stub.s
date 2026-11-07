| Mod 0025 - SEND FX 1 and 2 as graphs of the Sidecar's DSP library, a client of the companion.
| GENERATED from sfx.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that.
	.include "symbols.inc"
#NO_APP
	.file	"sfx.c"
	.text
	.align	2
	.type	sfx_graph, @function
sfx_graph:
	move.l %d2,-(%sp)
	move.l 8(%sp),%d0
	mov3q.l #6,%d1
	mov3q.l #5,%d2
	muls.l %d1,%d0
	move.l %d0,%a0
	add.l #sfx+52,%a0
	move.b (%a0),%d0
	mvz.b %d0,%d1
	cmp.l %d1,%d2
	jcc .L2
	clr.b %d0
.L2:
	mvz.b %d0,%d0
	move.l (%sp)+,%d2
	mulu.w #86,%d0
	move.l %d0,%a0
	add.l #sfx_types,%a0
	move.l %a0,%d0
	rts
	.size	sfx_graph, .-sfx_graph
	.align	2
	.type	sfx_lock_find, @function
sfx_lock_find:
	mvz.w sfx+330,%d1
	move.l %d2,-(%sp)
	lea sfx+332,%a0
	clr.l %d0
.L4:
	cmp.l %d1,%d0
	jlt .L7
	mov3q.l #-1,%d0
.L3:
	move.l (%sp)+,%d2
	rts
.L7:
	mvz.b (%a0),%d2
	cmp.l 8(%sp),%d2
	jne .L5
	mvz.b 1(%a0),%d2
	cmp.l 12(%sp),%d2
	jeq .L3
.L5:
	addq.l #1,%d0
	addq.l #3,%a0
	jra .L4
	.size	sfx_lock_find, .-sfx_lock_find
	.align	2
	.type	sfx_ends, @function
sfx_ends:
	lea (-12,%sp),%sp
	moveq #100,%d0
	movem.l #28,(%sp)
	move.l 16(%sp),%d2
	mov3q.l #1,%d4
	move.l 20(%sp),%d1
	move.l 24(%sp),%a1
	muls.l %d2,%d0
	move.l %d0,%a0
	mov3q.l #1,%d0
	add.l #sfx,%a0
	move.b 66(%a0),%d3
	and.l %d1,%d0
	cmp.l %d1,%d4
	jlt .L9
	move.b 68(%a0),%d1
	addq.l #6,%d1
	add.l %d1,%d1
	add.l %d0,%d1
	move.b %d1,(%a1)
	move.b 69(%a0),%d1
.L12:
	addq.l #6,%d1
	add.l %d1,%d1
	add.l %d1,%d0
	jra .L10
.L9:
	mov3q.l #3,%d4
	cmp.l %d1,%d4
	jlt .L11
	mvz.b %d3,%d3
	move.b 67(%a0,%d3.l),%d1
	lea sfx+52,%a0
	addq.l #6,%d1
	add.l %d1,%d1
	add.l %d0,%d1
	move.b %d1,(%a1)
	mov3q.l #6,%d1
	muls.l %d1,%d2
	tst.b 1(%a0,%d2.l)
	seq %d1
	add.l %d1,%d1
	sub.l %d1,%d0
.L10:
	move.l 28(%sp),%a0
	move.b %d0,(%a0)
	movem.l (%sp),#28
	lea (12,%sp),%sp
	rts
.L11:
	subq.l #4,%d1
	asr.l #1,%d1
	addq.l #2,%d1
	move.b %d1,(%a1)
	move.b 68(%a0),%d1
	jra .L12
	.size	sfx_ends, .-sfx_ends
	.align	2
	.type	sfx_reset_fx, @function
sfx_reset_fx:
	lea (-12,%sp),%sp
	movem.l #1036,(%sp)
	move.l 16(%sp),%d1
	moveq #100,%d2
	clr.b %d3
	clr.w %d0
	muls.l %d1,%d2
	lea sfx,%a2
	lea (%a2,%d2.l),%a0
	move.b %d3,154(%a0)
	move.w %d0,152(%a0)
	st %d3
	mvz.w #255,%d0
	move.l %d2,%a1
	add.l #sfx+132,%a1
	move.l %d0,65(%a2,%d2.l)
	clr.l %d0
	move.b %d3,69(%a0)
	move.l %d2,%a0
	add.l #sfx+72,%a0
.L14:
	clr.b %d3
	move.w #-1,(%a0)+
	move.b %d3,(%a1,%d0.l)
	addq.l #1,%d0
	moveq #20,%d3
	cmp.l %d0,%d3
	jne .L14
	move.l %d1,-(%sp)
	jsr sfx_graph
	add.l %d2,%a2
	tst.b 8(%a0)
	sne %d0
	lea sfx+8,%a0
	move.l (%a0),160(%a2)
	neg.l %d0
	add.l %d0,%d0
	move.b %d0,64(%a2)
	movem.l 4(%sp),#1036
	lea (16,%sp),%sp
	rts
	.size	sfx_reset_fx, .-sfx_reset_fx
	.text
.LC0:
	.string	"PRE"
.LC1:
	.string	"POST"
	.text
	.align	2
	.type	sfx_text, @function
sfx_text:
	lea (-16,%sp),%sp
	moveq #13,%d1
	move.l 20(%sp),%a1
	movem.l #1036,(%sp)
	move.l 4(%a1),%a0
	move.l %a0,%d0
	add.l #-560,%d0
	cmp.l %d0,%d1
	jcs .L31
	cmp.l #561,%a0
	jle .L32
	subq.l #2,%d0
	mov3q.l #6,%d2
	rems.l %d2,%d1:%d0
.L18:
	move.l 8(%a1),%d0
	asr.l #8,%d0
	cmp.l #561,%a0
	jle .L19
	mov3q.l #1,%d3
	cmp.l %d1,%d3
	jge .L20
.L19:
	tst.l %d0
	jge .L21
	clr.l %d0
.L21:
	lea (12,%sp),%a2
	clr.l %d1
	move.l %a2,%a0
.L23:
	moveq #10,%d3
	addq.l #1,%d1
	rems.l %d3,%d2:%d0
	divs.l %d3,%d0
	add.l #48,%d2
	move.b %d2,(%a2)+
	tst.l %d0
	jeq .L22
	mov3q.l #3,%d2
	cmp.l %d1,%d2
	jne .L23
.L22:
	add.l %d1,%a0
	clr.l %d0
.L24:
	move.l 12(%a1),%a2
	move.b -(%a0),(%a2,%d0.l)
	addq.l #1,%d0
	cmp.l %d1,%d0
	jne .L24
	clr.b %d3
	move.l 12(%a1),%a0
	move.b %d3,(%a0,%d1.l)
.L25:
	mov3q.l #1,%d0
.L16:
	movem.l (%sp),#1036
	lea (16,%sp),%sp
	rts
.L32:
	mov3q.l #2,%d1
	jra .L18
.L20:
	tst.l %d1
	jne .L26
	mov3q.l #5,%d2
	cmp.l %d0,%d2
	jcs .L27
	move.l %d0,%d1
.L27:
	moveq #86,%d3
	muls.l %d3,%d1
	move.l %d1,%a0
	add.l #sfx_types,%a0
.L28:
	clr.l %d0
.L29:
	move.b (%a0,%d0.l),%d1
	move.l 12(%a1),%a2
	add.l %d0,%a2
	tst.b %d1
	jne .L30
	clr.b (%a2)
	jra .L25
.L26:
	lea .LC0,%a0
	tst.l %d0
	jeq .L28
	lea .LC1,%a0
	jra .L28
.L30:
	move.b %d1,(%a2)
	addq.l #1,%d0
	jra .L29
.L31:
	clr.l %d0
	jra .L16
	.size	sfx_text, .-sfx_text
	.text
.LC2:
	.string	"SFX2"
.LC3:
	.string	"SFX1"
	.text
	.align	2
	.type	sfx_label, @function
sfx_label:
	move.l %d2,-(%sp)
	moveq #13,%d2
	move.l 8(%sp),%d0
	move.l %d0,%d1
	add.l #-560,%d1
	cmp.l %d1,%d2
	jcs .L42
	cmp.l #561,%d0
	jgt .L41
	lea .LC2,%a0
	cmp.l #560,%d0
	jne .L39
	lea .LC3,%a0
.L39:
	move.l (%sp)+,%d2
	move.l %a0,%d0
	rts
.L41:
	add.l #-562,%d0
	mov3q.l #6,%d2
	rems.l %d2,%d1:%d0
	lea sfx_lab,%a0
	move.l (%a0,%d1.l*4),%a0
	jra .L39
.L42:
	sub.l %a0,%a0
	jra .L39
	.size	sfx_label, .-sfx_label
	.align	2
	.type	sfx_key, @function
sfx_key:
	move.l %d3,-(%sp)
	moveq #13,%d3
	move.l %d2,-(%sp)
	move.l 12(%sp),%d1
	move.l %d1,%d0
	move.l 16(%sp),%d2
	add.l #-560,%d0
	cmp.l %d0,%d3
	jcs .L50
	cmp.l #561,%d1
	jgt .L46
	moveq #11,%d1
	cmp.l %d2,%d1
	jcs .L50
	add.l %d2,%d2
	add.l %d2,%d0
.L44:
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	rts
.L46:
	add.l #-562,%d1
	moveq #12,%d3
	cmp.l %d2,%d3
	jne .L50
	mov3q.l #6,%d2
	rems.l %d2,%d0:%d1
	divs.l %d2,%d1
	mov3q.l #1,%d3
	cmp.l %d0,%d3
	jge .L50
	addq.l #6,%d1
	lsl.l #2,%d1
	move.l %d0,%a0
	lea -2(%a0,%d1.l),%a0
	move.l %a0,%d0
	jra .L44
.L50:
	mov3q.l #-1,%d0
	jra .L44
	.size	sfx_key, .-sfx_key
	.align	2
	.type	sfx_lock_get, @function
sfx_lock_get:
	move.l %d2,-(%sp)
	move.l 12(%sp),-(%sp)
	move.l 12(%sp),-(%sp)
	jsr sfx_key
	addq.l #8,%sp
	move.l %d0,%d2
	tst.l %d0
	jge .L52
.L54:
	mov3q.l #-1,%d0
.L51:
	move.l (%sp)+,%d2
	rts
.L52:
	jsr sc_pat_index
	tst.l %d0
	jlt .L54
	move.l 16(%sp),-(%sp)
	move.l %d2,-(%sp)
	jsr sfx_lock_find
	addq.l #8,%sp
	tst.l %d0
	jlt .L54
	move.l %d0,%d1
	add.l %d1,%d1
	move.l %d1,%a0
	add.l %d0,%a0
	add.l #sfx+334,%a0
	mvz.b (%a0),%d0
	lsl.l #8,%d0
	jra .L51
	.size	sfx_lock_get, .-sfx_lock_get
	.text
.LC4:
	.string	"SEND TO SFX2"
.LC5:
	.string	"SEND TO SFX1"
	.text
	.align	2
	.type	sfx_name, @function
sfx_name:
	move.l %d2,-(%sp)
	moveq #13,%d2
	move.l 8(%sp),%d0
	move.l %d0,%d1
	add.l #-560,%d1
	cmp.l %d1,%d2
	jcs .L58
	cmp.l #561,%d0
	jgt .L57
	lea .LC4,%a0
	cmp.l #560,%d0
	jne .L55
	lea .LC5,%a0
.L55:
	move.l (%sp)+,%d2
	move.l %a0,%d0
	rts
.L57:
	mov3q.l #6,%d2
	add.l #-562,%d0
	rems.l %d2,%d1:%d0
	divs.l %d2,%d0
	lea sfx_nam,%a0
	muls.l %d2,%d0
	add.l %d1,%d0
	move.l (%a0,%d0.l*4),%a0
	jra .L55
.L58:
	sub.l %a0,%a0
	jra .L55
	.size	sfx_name, .-sfx_name
	.align	2
	.type	sfx_op, @function
sfx_op:
	move.l 8(%sp),-(%sp)
	move.l 8(%sp),-(%sp)
	jsr sc_link_send
	addq.l #8,%sp
	tst.l %d0
	jne .L61
	addq.l #1,sfx+1236
.L60:
	rts
.L61:
	addq.l #1,sfx+1232
	mov3q.l #1,%d0
	jra .L60
	.size	sfx_op, .-sfx_op
	.align	2
	.type	sfx_val, @function
sfx_val:
	lea (-20,%sp),%sp
	moveq #13,%d1
	movem.l #3100,(%sp)
	move.l 24(%sp),%d0
	move.l %d0,%a3
	move.l 28(%sp),%a2
	lea (-560,%a3),%a3
	cmp.l %a3,%d1
	jcc .L64
.L67:
	sub.l %a0,%a0
.L63:
	movem.l (%sp),#3100
	move.l %a0,%d0
	lea (20,%sp),%sp
	rts
.L64:
	cmp.l #561,%d0
	jgt .L66
	jsr core_current_track
	moveq #11,%d2
	cmp.l %d0,%d2
	jcs .L67
	add.l %d0,%d0
	moveq #127,%d1
	move.l %d1,(%a2)
	lea 28(%a3,%d0.l),%a0
.L71:
	add.l #sfx,%a0
	jra .L63
.L66:
	add.l #-562,%d0
	move.l %d0,%d2
	mov3q.l #6,%d3
	rems.l %d3,%d1:%d2
	tst.l %d1
	jeq .L69
	mov3q.l #1,%d4
	cmp.l %d1,%d4
	jne .L70
	mov3q.l #1,%a0
.L68:
	move.l %d0,%d3
	mov3q.l #6,%d4
	rems.l %d4,%d2:%d3
	move.l %a0,(%a2)
	move.l %d1,%a1
	sub.l %d2,%d0
	lea 52(%a1,%d0.l),%a0
	jra .L71
.L69:
	mov3q.l #5,%a0
	jra .L68
.L70:
	move.w #127,%a0
	jra .L68
	.size	sfx_val, .-sfx_val
	.align	2
	.type	sfx_get, @function
sfx_get:
	link.w %fp,#-4
	pea -4(%fp)
	move.l 8(%fp),-(%sp)
	jsr sfx_val
	addq.l #8,%sp
	tst.l %a0
	jeq .L74
	mvz.b (%a0),%d0
	move.l 12(%fp),%a0
	lsl.l #8,%d0
	move.l %d0,(%a0)
	mov3q.l #1,%d0
.L72:
	unlk %fp
	rts
.L74:
	clr.l %d0
	jra .L72
	.size	sfx_get, .-sfx_get
	.align	2
	.type	sfx_on_voice, @function
sfx_on_voice:
	jsr core_current_track
	moveq #12,%d1
	cmp.l %d0,%d1
	jcc .L76
	mov3q.l #-1,%d0
.L76:
	moveq #11,%d1
	cmp.l %d0,%d1
	scc %d0
	mvs.b %d0,%d0
	neg.l %d0
	rts
	.size	sfx_on_voice, .-sfx_on_voice
	.align	2
	.type	sfx_delta, @function
sfx_delta:
	link.w %fp,#-20
	movem.l #60,(%sp)
	move.l 12(%fp),%d2
	pea -4(%fp)
	move.l 16(%fp),%d3
	move.l %d2,-(%sp)
	jsr sfx_val
	addq.l #8,%sp
	tst.l %a0
	jeq .L93
	tst.l 20(%fp)
	jeq .L80
	lsl.l #3,%d3
.L80:
	move.l %d2,%d5
	add.l #-560,%d5
	move.l %d5,%d4
	move.l #sfx,%d0
	lsl.l #2,%d4
	move.l %d3,%d1
	move.l %d0,%a1
	add.l %d4,%a1
	add.l 270(%a1),%d1
	move.l %d1,%d3
	tst.l %d1
	jge .L81
	add.l #255,%d3
.L81:
	asr.l #8,%d3
	jne .L82
	add.l %d4,%d0
	move.l %d0,%a0
	move.l %d1,270(%a0)
.L83:
	mov3q.l #1,%d0
.L78:
	movem.l -20(%fp),#60
	unlk %fp
	rts
.L82:
	move.l %d0,%a1
	add.l %d4,%a1
	move.l %d1,%d4
	and.l #-2147483393,%d4
	tst.l %d1
	jge .L84
	subq.l #1,%d4
	or.l #-256,%d4
	addq.l #1,%d4
.L84:
	move.l %d4,270(%a1)
	mvz.b (%a0),%d4
	move.l %d4,%d1
	add.l %d3,%d1
	tst.l %d1
	jlt .L94
	move.l -4(%fp),%d3
	cmp.l %d3,%d1
	jge .L85
	move.l %d1,%d3
.L85:
	cmp.l %d4,%d3
	jeq .L83
	move.b %d3,(%a0)
	cmp.l #561,%d2
	jgt .L88
	jsr core_current_track
	moveq #12,%d1
	cmp.l %d0,%d1
	jcc .L89
	mov3q.l #-1,%d0
.L89:
	add.l %d0,%d0
	mov3q.l #1,%d1
	add.l %d5,%d0
	lsl.l %d0,%d1
	or.l %d1,sfx+264
.L90:
	lea sfx+8,%a0
	mov3q.l #1,sfx+20
	move.l (%a0),sfx+16
	jra .L83
.L94:
	clr.l %d3
	jra .L85
.L88:
	add.l #-562,%d2
	mov3q.l #6,%d3
	rems.l %d3,%d1:%d2
	divs.l %d3,%d2
	tst.l %d1
	jne .L91
	move.l %d0,%a0
	moveq #100,%d1
	moveq #1,%d3
	clr.b %d0
	muls.l %d1,%d2
	add.l %d2,%a0
	move.b %d3,64(%a0)
	move.b %d0,154(%a0)
	jra .L90
.L91:
	subq.l #1,%d1
	tst.l %d1
	jne .L92
	moveq #100,%d0
	muls.l %d0,%d2
	move.l %d2,%a0
	add.l #sfx+153,%a0
	move.b #1,(%a0)
	jra .L90
.L92:
	moveq #3,%d1
	add.l %d2,%d0
	move.l %d0,%a0
	move.b %d1,268(%a0)
	jra .L90
.L93:
	clr.l %d0
	jra .L78
	.size	sfx_delta, .-sfx_delta
	.align	2
	.type	sfx_lock_send, @function
sfx_lock_send:
	lea (-48,%sp),%sp
	moveq #23,%d0
	movem.l #7420,(%sp)
	move.l 52(%sp),%d4
	move.l 56(%sp),%d3
	move.l 60(%sp),%d6
	cmp.l %d4,%d0
	jlt .L100
	mov3q.l #1,%d2
	and.l %d4,%d2
.L101:
	moveq #100,%d0
	muls.l %d2,%d0
	lea sfx,%a0
	lea (%a0,%d0.l),%a2
	move.b 64(%a2),%d5
	jne .L102
	moveq #23,%d1
	cmp.l %d4,%d1
	jlt .L103
	move.l %d4,%d0
	asr.l #1,%d0
	lea sfx_voice,%a1
	moveq #50,%d1
	muls.l %d1,%d2
	mvz.b (%a1,%d0.l),%d0
	addq.l #2,%d0
	add.l %d0,%d0
	add.l %d0,%d2
	move.w 72(%a0,%d2.l*2),%d0
	jpl .L119
.L102:
	mov3q.l #1,%d0
	jra .L99
.L100:
	move.l %d4,%d2
	add.l #-24,%d2
	asr.l #2,%d2
	jra .L101
.L103:
	move.l %d2,-(%sp)
	jsr sfx_graph
	addq.l #4,%sp
	mov3q.l #3,%d0
	and.l %d0,%d4
	mov3q.l #6,%d1
	muls.l %d1,%d4
	lea (%a0,%d4.l),%a1
	tst.w 66(%a1)
	jeq .L102
	move.b 62(%a1),%d0
	mvz.b 66(%a2),%d1
	mvz.b %d0,%d5
	cmp.l %d5,%d1
	jls .L102
	add.l %d2,%d2
	lea 62(%a0,%d4.l),%a0
	move.b 63(%a1),%d5
	move.l %d2,%d4
	add.l %d0,%d4
	mvz.w 2(%a0),%d1
	mvz.w 4(%a0),%d0
	sub.l %d1,%d0
	muls.l %d6,%d0
	moveq #127,%d6
	add.l #63,%d0
	divu.l %d6,%d0
	add.l %d1,%d0
	mov3q.l #1,%d1
	jra .L107
.L119:
	mvs.w %d0,%d0
	mvs.w 74(%a0,%d2.l*2),%d1
	addq.l #8,%d4
	addq.l #1,%d0
	cmp.l %d1,%d0
	jne .L113
	mov3q.l #2,%d1
.L106:
	mvz.w #8192,%d0
	moveq #126,%d2
	cmp.l %d6,%d2
	jcs .L107
	muls.l %d6,%d6
	moveq #13,%d2
	move.l %d6,%d0
	lsl.l %d2,%d0
	mvz.w #16129,%d6
	add.l #8064,%d0
	divu.l %d6,%d0
.L107:
	moveq #127,%d2
	add.l %d5,%d1
	and.l %d0,%d2
	move.l %d0,%d7
	lsr.l #7,%d7
	mvz.b %d1,%d6
	lea sfx_op,%a2
	lea (42,%sp),%a4
	lea (38,%sp),%a3
.L112:
	moveq #18,%d0
	moveq #19,%d1
	move.b %d4,43(%sp)
	move.b %d3,44(%sp)
	move.b %d5,45(%sp)
	move.b %d7,46(%sp)
	move.b %d2,47(%sp)
	move.b %d4,39(%sp)
	move.b %d3,40(%sp)
	move.b %d5,41(%sp)
	move.b %d0,42(%sp)
	move.b %d1,38(%sp)
	tst.l 64(%sp)
	jeq .L108
	mov3q.l #4,-(%sp)
	move.l %a3,-(%sp)
.L121:
	jsr (%a2)
	addq.l #8,%sp
	tst.l %d0
	jne .L109
	clr.l %d0
.L99:
	movem.l (%sp),#7420
	lea (48,%sp),%sp
	rts
.L113:
	mov3q.l #1,%d1
	jra .L106
.L108:
	mov3q.l #6,-(%sp)
	move.l %a4,-(%sp)
	jra .L121
.L109:
	move.l %d5,%d0
	addq.l #1,%d0
	move.b %d0,%d5
	mvz.b %d0,%d0
	cmp.l %d0,%d6
	jne .L112
	addq.l #1,sfx+1252
	jra .L102
	.size	sfx_lock_send, .-sfx_lock_send
	.align	2
	.type	sfx_lock_put, @function
sfx_lock_put:
	lea (-16,%sp),%sp
	movem.l #60,(%sp)
	move.l 24(%sp),%d3
	move.l 20(%sp),%d2
	move.l 28(%sp),%d4
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	jsr sfx_lock_find
	addq.l #8,%sp
	mov3q.l #-1,%d1
	cmp.l %d4,%d1
	jne .L123
	tst.l %d0
	jlt .L124
	move.w sfx+330,%d4
	lea sfx,%a1
	mvz.w %d4,%d5
	subq.l #1,%d4
	move.w %d4,sfx+330
	subq.l #1,%d5
	move.l %d5,%d1
	add.l %d1,%d1
	move.l %d1,%a0
	move.l %d0,%d1
	add.l %d1,%d1
	add.l %d5,%a0
	add.l %a1,%a0
	add.l %d1,%d0
	add.l %d0,%a1
	move.b 332(%a0),332(%a1)
	move.b 333(%a0),333(%a1)
	move.b 334(%a0),334(%a1)
	mov3q.l #1,-(%sp)
	clr.l -(%sp)
.L133:
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	jsr sfx_lock_send
	lea (16,%sp),%sp
	moveq #1,%d0
	lea sfx+332,%a1
	clr.l %d1
	lea (b.1),%a0
	move.b %d0,(b.1)
	move.w sfx+330,%d0
	mvz.w %d0,%d2
.L129:
	addq.l #3,%a0
	cmp.l %d1,%d2
	jgt .L130
	tst.w %d0
	jeq .L132
	mulu.w #3,%d0
	addq.l #1,%d0
.L131:
	move.l %d0,-(%sp)
	pea (b.1)
	pea 25.w
	jsr sc_pat_put
	lea (12,%sp),%sp
.L124:
	mov3q.l #1,%d0
	jra .L122
.L123:
	tst.l %d0
	jge .L126
	move.w sfx+330,%d1
	mvz.w %d1,%d0
	cmp.l #299,%d0
	jls .L127
	addq.l #1,sfx+1256
	clr.l %d0
.L122:
	movem.l (%sp),#60
	lea (16,%sp),%sp
	rts
.L127:
	addq.l #1,%d1
	move.w %d1,sfx+330
	move.l %d0,%d1
	add.l %d1,%d1
	move.l %d1,%a0
	add.l %d0,%a0
	add.l #sfx,%a0
	move.b %d2,332(%a0)
	move.b %d3,333(%a0)
.L126:
	move.l %d0,%d1
	add.l %d1,%d1
	move.l %d1,%a0
	add.l %d0,%a0
	add.l #sfx+334,%a0
	move.b %d4,(%a0)
	clr.l -(%sp)
	move.l %d4,-(%sp)
	jra .L133
.L130:
	move.b (%a1),-2(%a0)
	move.b 1(%a1),-1(%a0)
	move.b 2(%a1),(%a0)
	addq.l #1,%d1
	addq.l #3,%a1
	jra .L129
.L132:
	clr.l %d0
	jra .L131
	.size	sfx_lock_put, .-sfx_lock_put
	.align	2
	.type	sfx_lock_clear, @function
sfx_lock_clear:
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	move.l 20(%sp),%d3
	move.l 16(%sp),-(%sp)
	move.l 16(%sp),-(%sp)
	jsr sfx_key
	addq.l #8,%sp
	move.l %d0,%d2
	tst.l %d0
	jlt .L136
	jsr sc_pat_index
	tst.l %d0
	jlt .L136
	mov3q.l #-1,20(%sp)
	move.l %d3,16(%sp)
	move.l %d2,12(%sp)
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	jra sfx_lock_put
.L136:
	move.l (%sp)+,%d2
	clr.l %d0
	move.l (%sp)+,%d3
	rts
	.size	sfx_lock_clear, .-sfx_lock_clear
	.align	2
	.type	sfx_lock_set, @function
sfx_lock_set:
	lea (-12,%sp),%sp
	movem.l #28,(%sp)
	move.l 24(%sp),%d4
	move.l 28(%sp),%d3
	move.l 20(%sp),-(%sp)
	move.l 20(%sp),-(%sp)
	jsr sfx_key
	addq.l #8,%sp
	move.l %d0,%d2
	tst.l %d0
	jlt .L140
	jsr sc_pat_index
	tst.l %d0
	jlt .L140
	move.l %d3,%d0
	asr.l #8,%d0
	cmp.l #32767,%d3
	jle .L142
	moveq #127,%d0
.L143:
	move.l %d4,20(%sp)
	move.l %d2,16(%sp)
	movem.l (%sp),#28
	move.l %d0,24(%sp)
	lea (12,%sp),%sp
	jra sfx_lock_put
.L142:
	tst.l %d0
	jge .L143
	clr.l %d0
	jra .L143
.L140:
	movem.l (%sp),#28
	clr.l %d0
	lea (12,%sp),%sp
	rts
	.size	sfx_lock_set, .-sfx_lock_set
	.align	2
	.type	sfx_lock_turn, @function
sfx_lock_turn:
	lea (-16,%sp),%sp
	movem.l #60,(%sp)
	move.l 20(%sp),%d2
	move.l 28(%sp),%d4
	move.l 24(%sp),-(%sp)
	move.l %d2,-(%sp)
	jsr sfx_key
	addq.l #8,%sp
	move.l %d0,%d3
	tst.l %d0
	jge .L145
.L147:
	mov3q.l #-1,%d0
.L144:
	movem.l (%sp),#60
	lea (16,%sp),%sp
	rts
.L145:
	jsr sc_pat_index
	tst.l %d0
	jlt .L147
	move.l %d4,-(%sp)
	move.l %d3,-(%sp)
	jsr sfx_lock_find
	addq.l #8,%sp
	lea sfx,%a0
	tst.l %d0
	jge .L148
	moveq #23,%d0
	cmp.l %d3,%d0
	jlt .L149
	mvz.b 28(%a0,%d3.l),%d1
.L151:
	add.l #-560,%d2
	lsl.l #2,%d2
	add.l %d2,%a0
	move.l 32(%sp),%d2
	add.l 270(%a0),%d2
	move.l %d2,%d0
	and.l #-2147483393,%d0
	tst.l %d2
	jge .L152
	subq.l #1,%d0
	or.l #-256,%d0
	addq.l #1,%d0
.L152:
	move.l %d0,270(%a0)
	tst.l %d2
	jge .L153
	add.l #255,%d2
.L153:
	asr.l #8,%d2
	add.l %d1,%d2
	cmp.l #128,%d2
	jlt .L154
	moveq #127,%d2
.L155:
	move.l %d2,-(%sp)
	move.l %d4,-(%sp)
	move.l %d3,-(%sp)
	jsr sfx_lock_put
	lea (12,%sp),%sp
	tst.l %d0
	jeq .L147
	move.l %d2,%d0
	lsl.l #8,%d0
	jra .L144
.L149:
	move.l %d3,%d1
	add.l #-24,%d1
	move.l %d1,%d0
	asr.l #2,%d0
	mov3q.l #3,%d5
	and.l %d5,%d1
	mov3q.l #6,%d5
	muls.l %d5,%d0
	move.l %d0,%a1
	add.l #sfx+54,%a1
	mvz.b (%a1,%d1.l),%d1
	jra .L151
.L148:
	move.l %d0,%d1
	add.l %d1,%d1
	move.l %d1,%a1
	add.l %d0,%a1
	add.l #sfx+334,%a1
	mvz.b (%a1),%d1
	jra .L151
.L154:
	tst.l %d2
	jge .L155
	clr.l %d2
	jra .L155
	.size	sfx_lock_turn, .-sfx_lock_turn
	.align	2
	.globl	sfx_tick
	.type	sfx_tick, @function
sfx_tick:
	link.w %fp,#-116
	movem.l #15612,(%sp)
	jsr sc_link_epoch
	lea sfx,%a2
	move.l %d0,%d2
	jsr sc_kit_gen
	move.l %d0,%d4
	jsr sc_pat_gen
	addq.l #1,sfx+8
	move.l %d0,%d3
	tst.l %d4
	jeq .L160
	cmp.l sfx+4.l,%d4
	jeq .L160
	move.l %d4,sfx+4
	clr.l %d0
	lea sfx+28,%a3
.L161:
	lea (%a3,%d0.l),%a0
	moveq #36,%d1
	addq.l #1,%d0
	move.b (%a0),-37(%fp,%d0.l)
	cmp.l %d0,%d1
	jne .L161
	pea 36.w
	moveq #36,%d4
	move.l %a3,-(%sp)
	pea 25.w
	jsr sc_kit_get
	lea (12,%sp),%sp
	cmp.l %d0,%d4
	jeq .L162
	clr.l %d0
.L163:
	clr.b %d5
	moveq #36,%d6
	move.b %d5,(%a3,%d0.l)
	addq.l #1,%d0
	cmp.l %d0,%d6
	jne .L163
	moveq #5,%d0
	moveq #1,%d4
	move.l #1077952576,%d1
	move.l %d1,sfx+54
	move.l %d1,sfx+60
	move.b %d0,sfx+52
	move.b %d4,sfx+58
.L162:
	lea sfx+28,%a0
	clr.l %d0
.L165:
	tst.b (%a0)+
	jge .L164
	moveq #127,%d5
	move.b %d5,-1(%a0)
.L164:
	addq.l #1,%d0
	moveq #36,%d6
	cmp.l %d0,%d6
	jne .L165
	mvz.b sfx+52,%d0
	mov3q.l #5,%d1
	cmp.l %d0,%d1
	jcc .L166
	clr.b %d4
	move.b %d4,sfx+52
.L166:
	mvz.b sfx+58,%d0
	mov3q.l #5,%d5
	cmp.l %d0,%d5
	jcc .L167
	clr.b %d6
	move.b %d6,sfx+58
.L167:
	mvz.b sfx+52,%d1
	mvz.b sfx+65,%d0
	clr.l sfx+20
	mov3q.l #1,sfx+24
	cmp.l %d1,%d0
	jeq .L168
.L170:
	moveq #1,%d0
	clr.b %d1
	move.b %d0,sfx+64
	move.b %d1,sfx+154
.L169:
	mvz.b sfx+58,%d1
	mvz.b sfx+165,%d0
	cmp.l %d1,%d0
	jeq .L173
.L175:
	moveq #1,%d0
	clr.b %d1
	move.b %d0,sfx+164
	move.b %d1,sfx+254
.L174:
	move.l #16777215,%a0
	move.l %a0,sfx+264
	tst.l %d3
	jne .L178
.L192:
	cmp.l sfx.l,%d2
	jne .L179
.L180:
	tst.l %d2
	jeq .L159
	lea sfx,%a1
	clr.l %d2
	move.l %a1,-60(%fp)
	lea sfx+52,%a1
	move.l %a1,-52(%fp)
	lea sfx,%a1
	move.l %a1,-64(%fp)
	lea sfx+64,%a2
	lea sfx+52,%a1
	move.l %a1,-56(%fp)
	lea sfx,%a4
	move.l %a2,%a3
.L248:
	move.b (%a3),%d0
	move.l %d0,%d1
	subq.l #3,%d1
	mvz.b %d1,%d1
	lsr.l #1,%d1
	jne .L196
	move.l sfx+8,%d1
	move.l %d1,%a0
	sub.l 96(%a3),%a0
	moveq #90,%d4
	cmp.l %a0,%d4
	jcc .L196
	move.b #6,(%a3)
	move.l %d1,96(%a3)
.L197:
	move.l sfx+8,%d0
	moveq #90,%d1
	sub.l 96(%a3),%d0
	cmp.l %d0,%d1
	jcc .L198
	move.b #1,(%a3)
	clr.b %d3
	jra .L368
.L168:
	mvz.b sfx+64,%d0
	subq.l #6,%d0
	tst.l %d0
	jeq .L170
	mvz.b sfx+53,%d1
	mvz.b -11(%fp),%d0
	cmp.l %d1,%d0
	jne .L171
.L172:
	moveq #3,%d5
	move.b %d5,sfx+268
	jra .L169
.L171:
	moveq #1,%d6
	move.b %d6,sfx+153
	jra .L172
.L173:
	mvz.b sfx+164,%d0
	subq.l #6,%d0
	tst.l %d0
	jeq .L175
	mvz.b sfx+59,%d1
	mvz.b -5(%fp),%d0
	cmp.l %d1,%d0
	jne .L176
.L177:
	moveq #3,%d5
	move.b %d5,sfx+269
	jra .L174
.L176:
	moveq #1,%d6
	move.b %d6,sfx+253
	jra .L177
.L178:
	cmp.l sfx+326.l,%d3
	jeq .L187
	pea 901.w
	pea (b.0)
	move.l %d3,sfx+326
	pea 25.w
	jsr sc_pat_get
	lea (12,%sp),%sp
	mov3q.l #1,%d3
	clr.w %d1
	move.w %d1,sfx+330
	cmp.l %d0,%d3
	jge .L184
	mvz.b (b.0),%d1
	cmp.l %d1,%d3
	jne .L184
	clr.b %d1
	sub.l %a1,%a1
	lea b.0+1,%a3
	mov3q.l #3,%d6
.L186:
	cmp.l %d0,%d6
	jlt .L189
	tst.b %d1
	jeq .L184
	move.w %a1,sfx+330
	jra .L184
.L160:
	tst.l %d3
	jne .L178
.L187:
	tst.l sfx+24
	jne .L192
.L159:
	movem.l -116(%fp),#15612
	unlk %fp
	rts
.L190:
	move.b (%a3),%d7
	mvz.b %d7,%d4
	lsr.l #5,%d4
	jne .L188
	move.b 1(%a3),%d5
	mvz.b %d5,%d4
	move.l %d4,%a0
	moveq #63,%d4
	cmp.l %a0,%d4
	jcs .L188
	move.b 2(%a3),%d4
	jmi .L188
	move.l %d3,%d1
	addq.l #1,%a1
	add.l %d1,%d1
	move.l %d1,%a0
	add.l %d3,%a0
	add.l %a2,%a0
	move.b %d7,332(%a0)
	move.b %d5,333(%a0)
	move.b %d4,334(%a0)
	moveq #1,%d1
.L188:
	addq.l #3,%d6
	addq.l #3,%a3
	jra .L186
.L189:
	mvz.w %a1,%d3
	cmp.l #300,%d3
	jne .L190
	tst.b %d1
	jeq .L184
	move.w %d3,sfx+330
.L184:
	move.w #256,%d4
	clr.w %d5
	move.w %d4,sfx+155
	move.w %d5,sfx+158
	move.w %d4,sfx+255
	move.w %d5,sfx+258
	jra .L187
.L179:
	move.l %d2,(%a2)
	tst.l %d2
	jeq .L194
	addq.l #1,sfx+1244
.L194:
	clr.l -(%sp)
	lea sfx_reset_fx,%a2
	jsr (%a2)
	mov3q.l #1,-(%sp)
	jsr (%a2)
	addq.l #8,%sp
	jra .L180
.L295:
	mov3q.l #1,%d2
	jra .L248
.L196:
	subq.l #1,%d0
	mvz.b %d0,%d0
	mov3q.l #5,%d5
	cmp.l %d0,%d5
	jcs .L198
	move.w .L199(%pc,%d0.l*2),%d0
	ext.l %d0
	jmp %pc@(2,%d0:l)
	.balignw 2,0x284c
.L199:
	.word .L204-.L199
	.word .L203-.L199
	.word .L291-.L199
	.word .L201-.L199
	.word .L200-.L199
	.word .L197-.L199
.L200:
	move.l %d2,%d6
	moveq #100,%d0
	add.l %d6,%d6
	move.b %d2,-45(%fp)
	muls.l %d2,%d0
	moveq #50,%d7
	muls.l %d2,%d7
	lea sfx,%a5
	move.l %fp,%d5
	add.l #-36,%d5
	lea (%a5,%d0.l),%a1
	move.b %d6,-73(%fp)
	move.l %a1,-72(%fp)
.L205:
	move.b 2(%a3),%d1
	move.b 90(%a3),%d4
	mvz.b %d1,%d0
	mvz.b %d4,%d3
	move.l %d0,%a0
	lea (11,%a0),%a0
	cmp.l %d3,%a0
	jge .L247
	moveq #1,%d5
	clr.b %d6
	clr.w %d0
	clr.b (%a3)
	move.b %d5,91(%a3)
	move.b %d6,92(%a3)
	move.w %d0,94(%a3)
	jra .L198
.L204:
	move.l %d2,%d5
	move.l %fp,%d7
	move.b %d2,-45(%fp)
	add.l %d5,%d5
	move.w #12581,%d6
	lea (68,%a4),%a0
	clr.l %d3
	move.l %fp,%d4
	add.l #-36,%d7
	move.l %a0,-72(%fp)
	lea sfx_op,%a5
	add.l #-41,%d4
.L206:
	mvz.b 2(%a3),%d0
	cmp.l %d3,%d0
	jgt .L210
	move.l %fp,%d3
	add.l #-36,%d3
	lea sfx_op,%a5
.L211:
	move.b 90(%a3),%d0
	moveq #11,%d5
	mvz.b %d0,%d1
	cmp.l %d1,%d5
	jcc .L213
	move.l %d2,-(%sp)
	addq.l #1,sfx+1248
	jsr sfx_reset_fx
	addq.l #4,%sp
.L198:
	lea (100,%a3),%a3
	lea (100,%a4),%a4
	addq.l #6,-56(%fp)
	addq.l #1,-64(%fp)
	tst.l %d2
	jeq .L295
	lea sfx+64,%a3
	clr.l %d3
.L274:
	tst.b (%a3)
	jne .L250
	tst.b 2(%a3)
	jeq .L250
	move.l %d3,%d4
	add.l %d4,%d4
	lea sfx_graph,%a5
	move.b %d4,-61(%fp)
	clr.l %d4
.L252:
	mvz.b 2(%a3),%d0
	cmp.l %d4,%d0
	jgt .L261
	tst.l %d3
	seq %d0
	moveq #50,%d1
	muls.l %d3,%d1
	lea sfx_voice,%a5
	move.l %d3,%d6
	move.l %d1,-64(%fp)
	move.l %d0,%d4
	neg.l %d4
	move.b %d4,-53(%fp)
.L269:
	mvz.b (%a5)+,%d0
	lea sfx,%a0
	moveq #126,%d1
	lea sfx+28,%a1
	mvz.w #8192,%d4
	addq.l #2,%d0
	add.l %d0,%d0
	add.l -64(%fp),%d0
	move.w 72(%a0,%d0.l*2),%d5
	move.w 74(%a0,%d0.l*2),%a4
	mvz.b (%a1,%d6.l),%d0
	cmp.l %d0,%d1
	jcs .L262
	mulu.w %d0,%d0
	moveq #13,%d4
	mvz.w #16129,%d1
	lsl.l %d4,%d0
	move.l %d0,%d4
	add.l #8064,%d4
	divu.l %d1,%d4
.L262:
	clr.b %d1
	moveq #17,%d0
	mvs.w %d5,%d5
	addq.l #1,%d5
	move.b %d1,-34(%fp)
	mvs.w %a4,%d1
	move.b %d0,-36(%fp)
	move.l %d6,%d0
	addq.l #8,%d0
	move.b %d0,-35(%fp)
	move.l %d1,-48(%fp)
	cmp.l %d1,%d5
	jne .L297
	moveq #2,%d0
.L263:
	mov3q.l #1,%d7
	move.l %d4,%d1
	lsr.l #7,%d1
	lsl.l %d6,%d7
	move.b %d0,-33(%fp)
	moveq #127,%d0
	and.l %d0,%d4
	move.b %d1,-32(%fp)
	move.b %d1,-30(%fp)
	move.l %d7,%d0
	and.l sfx+264,%d0
	move.b %d4,-31(%fp)
	move.b %d4,-29(%fp)
	tst.l %d0
	jeq .L264
	cmp.l -48(%fp),%d5
	jne .L298
	moveq #8,%d0
.L265:
	move.l %d0,-(%sp)
	pea -36(%fp)
	move.l %d1,-68(%fp)
	jsr sfx_op
	addq.l #8,%sp
	move.l -68(%fp),%d1
	tst.l %d0
	jeq .L260
	cmp.l -48(%fp),%d5
	jeq .L267
	move.w %a4,%d5
	jmi .L267
	move.w #8997,%a0
	mov3q.l #5,-(%sp)
	pea -41(%fp)
	move.b %d5,-39(%fp)
	move.b %d1,-38(%fp)
	move.b %d4,-37(%fp)
	move.w %a0,-41(%fp)
	jsr sfx_op
	addq.l #8,%sp
	tst.l %d0
	jeq .L260
.L267:
	not.l %d7
	and.l %d7,sfx+264
.L264:
	addq.l #2,%d6
	tst.b -53(%fp)
	jeq .L270
	moveq #24,%d0
.L271:
	cmp.l %d0,%d6
	jne .L269
	tst.b 89(%a3)
	jeq .L250
	move.l %fp,%d5
	move.l %fp,%d6
	lea (12,%a3),%a4
	mov3q.l #2,%d4
	add.l #-41,%d5
	add.l #-42,%d6
	lea sfx_ends,%a5
.L273:
	move.l %d5,-(%sp)
	move.l %d6,-(%sp)
	move.l %d4,-(%sp)
	move.l %d3,-(%sp)
	jsr (%a5)
	lea (16,%sp),%sp
	moveq #33,%d0
	move.b -42(%fp),-32(%fp)
	move.b -41(%fp),-31(%fp)
	move.b %d0,-36(%fp)
	move.l sfx+12,%d0
	move.l %d0,%d1
	addq.l #1,%d1
	move.l %d1,sfx+12
	moveq #127,%d1
	and.l %d1,%d0
	move.b %d0,-35(%fp)
	moveq #37,%d0
	move.b %d0,-34(%fp)
	move.w (%a4)+,%d0
	move.b %d0,-33(%fp)
	tst.w %d0
	jlt .L272
	mov3q.l #6,-(%sp)
	pea -36(%fp)
	jsr sfx_op
	addq.l #8,%sp
	tst.l %d0
	jeq .L260
.L272:
	subq.l #2,%d4
	tst.l %d4
	jeq .L299
	clr.b %d4
	move.b %d4,89(%a3)
.L250:
	lea (100,%a3),%a3
	addq.l #1,-60(%fp)
	addq.l #6,-52(%fp)
	tst.l %d3
	jeq .L300
.L260:
	move.l %fp,%d5
	sub.l %a4,%a4
	add.l #-36,%d5
	lea sfx_op,%a3
.L290:
	move.b 2(%a2),%d3
	tst.b 91(%a2)
	jeq .L276
	tst.b (%a2)
	jne .L276
	move.l %a4,%d7
	move.w %a4,%d6
	add.l %d7,%d7
	mvz.b %d3,%d3
	move.w #24,%a5
	add.l #12,%d3
.L278:
	move.b 92(%a2),%d0
	mvz.b %d0,%d1
	move.l %d1,%a0
	cmp.l %d3,%d1
	jge .L282
	tst.l %a5
	jne .L283
.L282:
	move.l #sfx_lock_send,%d7
.L284:
	move.w 94(%a2),%d0
	mvz.w sfx+330,%d1
	mvz.w %d0,%d6
	cmp.l %d6,%d1
	jls .L288
	tst.l %a5
	jgt .L289
.L288:
	mvz.b 92(%a2),%d0
	cmp.l %d3,%d0
	jlt .L276
	cmp.l %d6,%d1
	jhi .L276
	clr.b %d0
	move.b %d0,91(%a2)
.L276:
	lea (100,%a2),%a2
	tst.l %a4
	jeq .L301
	tst.l sfx+20
	jeq .L159
	move.l sfx+8,%d0
	moveq #11,%d1
	sub.l sfx+16,%d0
	cmp.l %d0,%d1
	jcc .L159
	pea 36.w
	pea sfx+28
	pea 25.w
	jsr sc_kit_put
	lea (12,%sp),%sp
	tst.l %d0
	jeq .L159
	clr.l sfx+20
	jra .L159
.L210:
	move.l -72(%fp),%a1
	moveq #21,%d1
	move.w %d6,-36(%fp)
	move.b (%a1)+,%d0
	addq.l #1,-72(%fp)
	move.b %d1,-41(%fp)
	move.l %d3,%d1
	add.l %d5,%d1
	move.b %d0,-34(%fp)
	move.b %d1,-40(%fp)
	tst.b %d0
	jlt .L207
	mov3q.l #3,-(%sp)
	move.l %d7,-(%sp)
	jsr (%a5)
	addq.l #8,%sp
	tst.l %d0
	jeq .L198
	mov3q.l #2,-(%sp)
	move.l %d4,-(%sp)
	jsr (%a5)
	addq.l #8,%sp
	tst.l %d0
	jeq .L198
	st %d0
	move.l -72(%fp),%a0
	move.b %d0,-1(%a0)
.L207:
	addq.l #1,%d3
	jra .L206
.L213:
	addq.l #4,%d0
	move.b -45(%fp),%d4
	add.l %d0,%d0
	moveq #21,%d1
	mov3q.l #2,-(%sp)
	move.l %d3,-(%sp)
	add.l %d4,%d0
	move.b %d1,-36(%fp)
	move.b %d0,-35(%fp)
	jsr (%a5)
	addq.l #8,%sp
	tst.l %d0
	jeq .L198
	move.b 90(%a3),%d0
	addq.l #1,%d0
	move.b %d0,90(%a3)
	jra .L211
.L203:
	move.w #9599,%d4
	move.l %d2,-(%sp)
	jsr sfx_graph
	mvz.b 3(%a3),%d3
	addq.l #4,%sp
	move.l %fp,%d5
	add.l #-36,%d5
	lea sfx_op,%a5
	move.l %a0,-48(%fp)
.L214:
	move.l -48(%fp),%a0
	move.b 8(%a0),%d0
	mvz.b %d0,%d1
	cmp.l %d3,%d1
	jgt .L219
	move.b %d0,2(%a3)
	move.l -56(%fp),%a1
	move.b (%a1),1(%a3)
	move.b #3,(%a3)
.L367:
	lea sfx+8,%a0
	move.l (%a0),96(%a3)
	jra .L198
.L219:
	move.l sfx+12,%d0
	moveq #127,%d1
	move.l %d0,%d6
	addq.l #1,%d6
	move.l %d6,sfx+12
	and.l %d1,%d0
	moveq #48,%d6
	move.w %d4,-34(%fp)
	move.l -48(%fp),%a0
	move.b %d0,70(%a4,%d3.l)
	move.b %d0,-35(%fp)
	moveq #26,%d0
	move.b %d6,-36(%fp)
	muls.l %d3,%d0
	add.l %d0,%a0
	mov3q.l #4,%d0
.L215:
	move.b 6(%a0,%d0.l),%d1
	jeq .L216
	move.b %d1,-36(%fp,%d0.l)
	addq.l #1,%d0
	moveq #12,%d1
	cmp.l %d0,%d1
	jne .L215
.L216:
	move.l %d0,-(%sp)
	move.l %d5,-(%sp)
	jsr (%a5)
	addq.l #1,%d3
	addq.l #8,%sp
	tst.l %d0
	jeq .L198
	move.b %d3,3(%a3)
	jra .L214
.L223:
	move.l -48(%fp),%a1
	move.b 68(%a1),%d0
	jmi .L220
	mvs.b %d0,%d0
.L221:
	move.l -48(%fp),%a0
	addq.l #1,%d3
	move.b %d0,68(%a0)
.L222:
	addq.l #1,%d4
	addq.l #1,-48(%fp)
.L202:
	mvz.b 2(%a3),%d0
	cmp.l %d4,%d0
	jgt .L223
	cmp.l %d3,%d0
	jne .L198
	clr.b %d0
	move.b #4,(%a3)
	move.b %d0,88(%a3)
	jra .L367
.L220:
	move.l -48(%fp),%a0
	mvz.b 70(%a0),%d0
	move.l %d0,-(%sp)
	pea 37.w
	jsr (%a5)
	addq.l #8,%sp
	cmp.l #-256,%d0
	jeq .L222
	tst.l %d0
	jge .L221
	addq.l #1,sfx+1240
	move.b #6,(%a3)
	lea sfx+8,%a1
	move.l (%a1),96(%a3)
	jra .L198
.L291:
	move.l %a4,-48(%fp)
	clr.l %d3
	clr.l %d4
	lea sc_dsp_result,%a5
	jra .L202
.L201:
	tst.l %d2
	jeq .L225
	mvz.b sfx+64,%d0
	subq.l #4,%d0
	tst.l %d0
	jeq .L198
.L225:
	lea (132,%a4),%a0
	clr.l %d3
	move.l %a0,-48(%fp)
	move.l %a4,%d5
	clr.l %d4
	lea sc_route_result,%a5
.L231:
	move.l -48(%fp),%a1
	addq.l #1,-48(%fp)
	tst.b (%a1)+
	jeq .L229
	mvz.b -21(%a1),%d0
	move.l %d0,-(%sp)
	pea 37.w
	jsr (%a5)
	addq.l #8,%sp
	cmp.l #-256,%d0
	jne .L228
	addq.l #1,%d3
.L229:
	addq.l #1,%d4
	addq.l #2,%d5
	moveq #20,%d0
	cmp.l %d4,%d0
	jne .L231
	moveq #100,%d0
	muls.l %d2,%d0
	move.l #sfx,%d4
	move.l %fp,%d6
	move.l %d4,%d7
	add.l #-42,%d6
	lea (-36,%fp),%a5
	add.l %d0,%d7
.L232:
	move.b 88(%a3),%d0
	moveq #19,%d5
	mvz.b %d0,%d1
	move.l %d1,-48(%fp)
	cmp.l %d1,%d5
	jcs .L240
	moveq #11,%d1
	cmp.l %d3,%d1
	jlt .L198
	mov3q.l #1,%d1
	cmp.l -48(%fp),%d1
	jlt .L233
	mvz.b 2(%a3),%d1
	lsr.l #1,%d1
	jeq .L234
.L233:
	pea -41(%fp)
	move.l %d6,-(%sp)
	move.l -48(%fp),-(%sp)
	move.l %d2,-(%sp)
	jsr sfx_ends
	mvz.w #8192,%d0
	lea (16,%sp),%sp
	mov3q.l #3,%d5
	move.l -48(%fp),%d1
	subq.l #4,%d1
	move.l %d1,%d1
	jpl .L369
	addq.l #1,%d1
.L369:
	asr.l #1,%d1
	cmp.l -48(%fp),%d5
	jge .L235
	clr.l %d0
	lea sfx_voice,%a0
.L236:
	mvz.b (%a0,%d0.l),%d5
	cmp.l %d1,%d5
	jne .L238
	add.l %d0,%d0
	move.l %d4,%a0
	moveq #126,%d5
	add.l %d0,%a0
	mvz.b 28(%a0,%d2.l),%d1
	mvz.w #8192,%d0
	cmp.l %d1,%d5
	jcs .L235
	mulu.w %d1,%d1
	moveq #13,%d0
	mvz.w #16129,%d5
	lsl.l %d0,%d1
	move.l %d1,%d0
	add.l #8064,%d0
	divu.l %d5,%d0
.L235:
	move.l sfx+12,%d1
	moveq #127,%d5
	move.l %d1,%a0
	addq.l #1,%a0
	move.l -48(%fp),%a1
	add.l %d7,%a1
	and.l %d5,%d1
	moveq #32,%d5
	move.b -42(%fp),-33(%fp)
	move.b -41(%fp),-32(%fp)
	move.l %a0,sfx+12
	move.b %d1,112(%a1)
	move.b %d1,-35(%fp)
	moveq #37,%d1
	move.b %d5,-36(%fp)
	moveq #127,%d5
	mov3q.l #7,-(%sp)
	move.l %a5,-(%sp)
	move.l %a1,-68(%fp)
	move.b %d1,-34(%fp)
	move.l %d0,%d1
	lsr.l #7,%d1
	and.l %d5,%d0
	move.b %d1,-31(%fp)
	move.b %d0,-30(%fp)
	jsr sfx_op
	addq.l #8,%sp
	move.l -68(%fp),%a1
	tst.l %d0
	jeq .L198
	moveq #1,%d0
	addq.l #1,%d3
	move.b %d0,132(%a1)
	move.b 88(%a3),%d0
	addq.l #1,%d0
	jra .L237
.L228:
	clr.b %d1
	move.l -48(%fp),%a0
	move.b %d1,-1(%a0)
	move.l sfx+8,%d1
	tst.l %d0
	jge .L230
	addq.l #1,sfx+1240
	move.b #6,(%a3)
	move.l %d1,96(%a3)
	jra .L198
.L230:
	move.l %d5,%a1
	move.w %d0,72(%a1)
	move.l %d1,96(%a3)
	jra .L229
.L234:
	addq.l #1,%d0
.L237:
	move.b %d0,88(%a3)
	jra .L232
.L238:
	addq.l #1,%d0
	moveq #12,%d5
	cmp.l %d0,%d5
	jne .L236
	clr.l %d0
	jra .L235
.L240:
	tst.l %d3
	jne .L198
	move.b #5,(%a3)
.L368:
	move.b %d3,90(%a3)
	jra .L198
.L247:
	cmp.l %d0,%d3
	jcc .L242
	move.l %d2,-(%sp)
	jsr sfx_graph
	moveq #12,%d0
	moveq #16,%d6
	move.l -72(%fp),%a1
	move.l %a0,%d1
	lea 68(%a1,%d3.l),%a0
	move.b %d0,-34(%fp)
	clr.b %d0
	move.b %d6,-36(%fp)
	move.b -73(%fp),%d6
	move.b (%a0),-33(%fp)
	move.b %d0,-32(%fp)
	moveq #26,%d0
	muls.l %d3,%d0
	add.l %d6,%d4
	move.b %d4,-35(%fp)
	move.l %d0,%a0
	lea 18(%a0,%d1.l),%a1
	move.b (%a1),-31(%fp)
	mov3q.l #6,(%sp)
	move.l %d5,-(%sp)
	jsr sfx_op
	addq.l #8,%sp
	tst.l %d0
	jeq .L198
	move.l -64(%fp),%a1
	mov3q.l #1,%d0
	lsl.l %d3,%d0
	move.b 268(%a1),%d1
	or.l %d1,%d0
	move.b %d0,268(%a1)
.L244:
	move.b 90(%a3),%d0
	addq.l #1,%d0
	move.b %d0,90(%a3)
	jra .L205
.L242:
	sub.l %d0,%d3
	lea sfx_voice,%a0
	mvz.b (%a0,%d3.l),%d0
	addq.l #2,%d0
	add.l %d0,%d0
	add.l %d7,%d0
	move.w 72(%a5,%d0.l*2),%a0
	mvs.w 74(%a5,%d0.l*2),%d0
	move.l %d0,%a1
	mvs.w %a0,%d0
	addq.l #1,%d0
	cmp.l %a1,%d0
	jne .L294
	moveq #2,%d0
.L245:
	moveq #16,%d6
	sub.l %d1,%d4
	move.l %d4,%d1
	addq.l #4,%d1
	add.l %d1,%d1
	move.b %d4,-34(%fp)
	move.w %a0,%d4
	mov3q.l #6,-(%sp)
	move.l %d5,-(%sp)
	move.b %d0,-31(%fp)
	move.b %d6,-36(%fp)
	move.b -45(%fp),%d6
	move.b %d4,-32(%fp)
	add.l %d6,%d1
	move.b %d1,-35(%fp)
	moveq #64,%d1
	move.b %d1,-33(%fp)
	jsr sfx_op
	addq.l #8,%sp
	tst.l %d0
	jeq .L198
	add.l %d3,%d3
	mov3q.l #1,%d0
	add.l %d2,%d3
	lsl.l %d3,%d0
	or.l %d0,sfx+264
	jra .L244
.L294:
	moveq #1,%d0
	jra .L245
.L300:
	move.l %d2,%d3
	jra .L274
.L261:
	move.l %d3,-(%sp)
	jsr (%a5)
	addq.l #4,%sp
	move.l -60(%fp),%a1
	moveq #26,%d0
	muls.l %d4,%d0
	mvz.b 268(%a1),%d1
	move.b 18(%a0,%d0.l),%d0
	btst %d4,%d1
	jeq .L253
	moveq #17,%d1
	clr.b %d5
	move.b %d0,-33(%fp)
	moveq #13,%d6
	sub.l %a4,%a4
	muls.l %d4,%d6
	mvz.b %d0,%d7
	lea (-32,%fp),%a1
	move.l %a1,-56(%fp)
	move.b %d1,-36(%fp)
	move.b -61(%fp),%d1
	move.b %d5,-34(%fp)
	add.l %d4,%d1
	move.b %d1,-35(%fp)
.L254:
	cmp.l %d7,%a4
	jlt .L258
	add.l %d7,%d7
	move.l %d7,%a0
	pea 4(%a0)
	pea -36(%fp)
	jsr sfx_op
	addq.l #8,%sp
	tst.l %d0
	jeq .L260
	move.l -60(%fp),%a1
	mov3q.l #1,%d0
	lsl.l %d4,%d0
	move.b 268(%a1),%d1
	not.l %d0
	and.l %d1,%d0
	move.b %d0,268(%a1)
.L253:
	addq.l #1,%d4
	jra .L252
.L258:
	move.l %d3,-(%sp)
	jsr (%a5)
	addq.l #4,%sp
	clr.l %d0
	lea (62,%a0),%a1
.L257:
	mvz.b (%a1),%d1
	cmp.l %d4,%d1
	jne .L255
	mvz.b 1(%a1),%d1
	cmp.l %a4,%d1
	jne .L255
	tst.w 4(%a1)
	jeq .L255
	mov3q.l #6,%d1
	muls.l %d0,%d1
	move.l -52(%fp),%a1
	mvz.b 2(%a1,%d0.l),%d0
	lea 62(%a0,%d1.l),%a0
	mvz.w 2(%a0),%d5
	mvz.w 4(%a0),%d1
	move.l %d5,%a0
	sub.l %d5,%d1
	muls.l %d1,%d0
	moveq #127,%d5
	add.l #63,%d0
	divu.l %d5,%d0
	add.l %a0,%d0
.L256:
	move.l %d0,%d1
	lsr.l #7,%d1
	move.l -56(%fp),%a1
	addq.l #2,%a1
	addq.l #1,%a4
	move.b %d1,-2(%a1)
	moveq #127,%d1
	and.l %d1,%d0
	move.b %d0,-1(%a1)
	move.l %a1,-56(%fp)
	jra .L254
.L255:
	addq.l #1,%d0
	addq.l #6,%a1
	mov3q.l #4,%d1
	cmp.l %d0,%d1
	jne .L257
	lea 10(%a4,%d6.l),%a1
	mvz.w (%a0,%a1.l*2),%d0
	jra .L256
.L297:
	moveq #1,%d0
	jra .L263
.L298:
	mov3q.l #6,%d0
	jra .L265
.L270:
	moveq #25,%d0
	jra .L271
.L299:
	mov3q.l #3,%d4
	jra .L273
.L301:
	move.l %d2,%a4
	jra .L290
.L283:
	move.b 2(%a2),%d1
	mvz.b %d1,%d4
	cmp.l %d4,%a0
	jcc .L279
	add.l %d7,%d0
.L280:
	moveq #19,%d1
	move.w #32639,%d4
	move.b %d0,-35(%fp)
	mov3q.l #4,-(%sp)
	move.l %d5,-(%sp)
	move.b %d1,-36(%fp)
	move.w %d4,-34(%fp)
	jsr (%a3)
	addq.l #8,%sp
	tst.l %d0
	jeq .L276
	move.b 92(%a2),%d0
	subq.l #1,%a5
	addq.l #1,%d0
	move.b %d0,92(%a2)
	jra .L278
.L279:
	addq.l #4,%d0
	sub.l %d1,%d0
	add.l %d0,%d0
	add.l %d6,%d0
	jra .L280
.L289:
	mulu.w #3,%d0
	moveq #23,%d4
	move.l %d0,%a0
	add.l #sfx+332,%a0
	move.b (%a0),%d0
	mvz.b %d0,%d1
	cmp.l %d1,%d4
	jlt .L285
	mov3q.l #1,%d6
	and.l %d6,%d0
.L286:
	cmp.l %a4,%d0
	jne .L287
	clr.l -(%sp)
	mvz.b 2(%a0),%d0
	move.l %d0,-(%sp)
	mvz.b 1(%a0),%d0
	move.l %d7,%a0
	move.l %d0,-(%sp)
	move.l %d1,-(%sp)
	jsr (%a0)
	lea (16,%sp),%sp
	tst.l %d0
	jeq .L276
	subq.l #2,%a5
.L287:
	move.w 94(%a2),%d0
	addq.l #1,%d0
	move.w %d0,94(%a2)
	jra .L284
.L285:
	move.l %d1,%d0
	add.l #-24,%d0
	asr.l #2,%d0
	jra .L286
	.size	sfx_tick, .-sfx_tick
	.align	2
	.globl	sfx_diag
	.type	sfx_diag, @function
sfx_diag:
	move.l 4(%sp),%d0
	moveq #9,%d1
	cmp.l %d0,%d1
	jcs .L382
	move.l %d0,%d1
	add.l %d1,%d1
	move.w .L373(%pc,%d1.l),%d1
	ext.l %d1
	jmp %pc@(2,%d1:l)
	.balignw 2,0x284c
.L373:
	.word .L381-.L373
	.word .L380-.L373
	.word .L379-.L373
	.word .L378-.L373
	.word .L377-.L373
	.word .L376-.L373
	.word .L376-.L373
	.word .L375-.L373
	.word .L374-.L373
	.word .L372-.L373
.L381:
	move.l sfx+1232,%d0
.L370:
	rts
.L380:
	move.l sfx+1236,%d0
	jra .L370
.L379:
	move.l sfx+1240,%d0
	jra .L370
.L378:
	move.l sfx+1244,%d0
	jra .L370
.L377:
	move.l sfx+1248,%d0
	jra .L370
.L376:
	subq.l #5,%d0
	moveq #100,%d1
	muls.l %d1,%d0
	move.l %d0,%a0
	add.l #sfx+64,%a0
	mvz.b (%a0),%d0
	jra .L370
.L375:
	mvz.w sfx+330,%d0
	jra .L370
.L374:
	move.l sfx+1252,%d0
	jra .L370
.L372:
	move.l sfx+1256,%d0
	jra .L370
.L382:
	clr.l %d0
	jra .L370
	.size	sfx_diag, .-sfx_diag
	.globl	sfx_view_fx2
	.text
	.align	2
	.type	sfx_view_fx2, @object
	.size	sfx_view_fx2, 12
sfx_view_fx2:
	.long	6
	.long	18
	.long	0
	.globl	sfx_view_fx1
	.align	2
	.type	sfx_view_fx1, @object
	.size	sfx_view_fx1, 12
sfx_view_fx1:
	.long	5
	.long	17
	.long	0
	.globl	sfx_view_amp2
	.align	2
	.type	sfx_view_amp2, @object
	.size	sfx_view_amp2, 12
sfx_view_amp2:
	.long	3
	.long	16
	.long	sfx_on_voice
	.globl	sfx_locks
	.align	2
	.type	sfx_locks, @object
	.size	sfx_locks, 32
sfx_locks:
	.long	560
	.long	573
	.long	sfx_lock_get
	.long	sfx_lock_turn
	.long	sfx_lock_set
	.long	sfx_lock_clear
	.long	sfx_label
	.long	sfx_name
	.text
.LC6:
	.string	"SFX1 TYPE"
.LC7:
	.string	"SFX1 ROUTE"
.LC8:
	.string	"SFX1 PARAM 2"
.LC9:
	.string	"SFX1 PARAM 3"
.LC10:
	.string	"SFX1 PARAM 4"
.LC11:
	.string	"SFX1 PARAM 5"
.LC12:
	.string	"SFX2 TYPE"
.LC13:
	.string	"SFX2 ROUTE"
.LC14:
	.string	"SFX2 PARAM 2"
.LC15:
	.string	"SFX2 PARAM 3"
.LC16:
	.string	"SFX2 PARAM 4"
.LC17:
	.string	"SFX2 PARAM 5"
	.text
	.align	2
	.type	sfx_nam, @object
	.size	sfx_nam, 48
sfx_nam:
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
	.long	.LC17
	.text
.LC18:
	.string	"TYPE"
.LC19:
	.string	"ROUT"
.LC20:
	.string	"P2"
.LC21:
	.string	"P3"
.LC22:
	.string	"P4"
.LC23:
	.string	"P5"
	.text
	.align	2
	.type	sfx_lab, @object
	.size	sfx_lab, 24
sfx_lab:
	.long	.LC18
	.long	.LC19
	.long	.LC20
	.long	.LC21
	.long	.LC22
	.long	.LC23
	.globl	sfx_params
	.align	2
	.type	sfx_params, @object
	.size	sfx_params, 20
sfx_params:
	.long	560
	.long	573
	.long	sfx_get
	.long	sfx_delta
	.long	sfx_text
	.globl	sfx_page_fx2
	.text
.LC24:
	.string	"SEND FX 2"
	.text
	.align	2
	.type	sfx_page_fx2, @object
	.size	sfx_page_fx2, 40
sfx_page_fx2:
	.long	18
	.long	.LC24
	.long	568
	.long	569
	.long	570
	.long	571
	.long	572
	.long	573
	.long	0
	.long	0
	.globl	sfx_page_fx1
	.text
.LC25:
	.string	"SEND FX 1"
	.text
	.align	2
	.type	sfx_page_fx1, @object
	.size	sfx_page_fx1, 40
sfx_page_fx1:
	.long	17
	.long	.LC25
	.long	562
	.long	563
	.long	564
	.long	565
	.long	566
	.long	567
	.long	0
	.long	0
	.globl	sfx_page_amp2
	.text
.LC26:
	.string	"AMPLITUDE 2"
	.text
	.align	2
	.type	sfx_page_amp2, @object
	.size	sfx_page_amp2, 40
sfx_page_amp2:
	.long	16
	.long	.LC26
	.long	560
	.long	561
	.long	0
	.long	0
	.long	0
	.long	0
	.long	0
	.long	0
	.section	.bss,"aw",@nobits
	.type	b.0, @object
	.size	b.0, 901
b.0:
	.zero	901
	.type	b.1, @object
	.size	b.1, 901
b.1:
	.zero	901
	.align	4
	.type	sfx, @object
	.size	sfx, 1260
sfx:
	.zero	1260
	.text
	.align	2
	.type	sfx_types, @object
	.size	sfx_types, 516
sfx_types:
	.string	"OFF"
	.zero	4
	.byte	0
	.zero	1
	.string	""
	.zero	7
	.byte	0
	.zero	1
	.word	0
	.zero	14
	.zero	26
	.byte	0
	.byte	0
	.word	0
	.word	0
	.zero	18
	.string	"CHORUS"
	.zero	1
	.byte	1
	.zero	1
	.string	"DELAY"
	.zero	2
	.byte	8
	.zero	1
	.word	8200
	.word	1500
	.word	16383
	.word	0
	.word	0
	.word	3000
	.word	5000
	.word	12000
	.zero	26
	.byte	0
	.byte	0
	.word	7000
	.word	9800
	.byte	0
	.byte	5
	.word	0
	.word	16383
	.byte	0
	.byte	6
	.word	2000
	.word	9000
	.byte	0
	.byte	7
	.word	0
	.word	16383
	.string	"COMB"
	.zero	3
	.byte	1
	.zero	1
	.string	"DELAY"
	.zero	2
	.byte	8
	.zero	1
	.word	5700
	.word	12000
	.word	12000
	.word	0
	.word	0
	.word	0
	.word	6000
	.word	0
	.zero	26
	.byte	0
	.byte	0
	.word	3000
	.word	8200
	.byte	0
	.byte	1
	.word	4000
	.word	16000
	.byte	0
	.byte	2
	.word	4000
	.word	16383
	.byte	0
	.byte	3
	.word	0
	.word	9000
	.string	"CRUSH"
	.zero	2
	.byte	1
	.zero	1
	.string	"SHAPER"
	.zero	1
	.byte	5
	.zero	1
	.word	0
	.word	0
	.word	6000
	.word	9000
	.word	8192
	.zero	6
	.zero	26
	.byte	0
	.byte	1
	.word	0
	.word	16383
	.byte	0
	.byte	2
	.word	0
	.word	16383
	.byte	0
	.byte	3
	.word	0
	.word	16383
	.byte	0
	.byte	4
	.word	0
	.word	16383
	.string	"RINGMOD"
	.byte	1
	.zero	1
	.string	"MOD"
	.zero	4
	.byte	5
	.zero	1
	.word	0
	.word	9000
	.word	16383
	.word	0
	.word	0
	.zero	6
	.zero	26
	.byte	0
	.byte	1
	.word	4000
	.word	14000
	.byte	0
	.byte	2
	.word	0
	.word	16383
	.byte	0
	.byte	3
	.word	0
	.word	16383
	.byte	0
	.byte	4
	.word	0
	.word	16383
	.string	"ECHO"
	.zero	3
	.byte	2
	.zero	1
	.string	"DELAY"
	.zero	2
	.byte	8
	.zero	1
	.word	13000
	.word	7000
	.word	12000
	.word	1000
	.word	0
	.word	500
	.word	4000
	.word	0
	.string	"FILTER"
	.zero	1
	.byte	4
	.zero	1
	.word	0
	.word	11000
	.word	3000
	.word	0
	.zero	8
	.byte	0
	.byte	0
	.word	10500
	.word	15500
	.byte	0
	.byte	1
	.word	0
	.word	15000
	.byte	1
	.byte	1
	.word	4000
	.word	16383
	.byte	0
	.byte	7
	.word	0
	.word	16383
	.type	sfx_voice, @object
	.size	sfx_voice, 12
sfx_voice:
	.string	""
	.ascii	"\001\002\002\003\004\005\005\006\006\007\007"
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
