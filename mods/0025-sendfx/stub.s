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
	.align	2
	.type	sfx_track, @function
sfx_track:
	jsr 1075313162
	move.l %d0,-(%sp)
	jsr 1074455698
	move.l %d0,-(%sp)
	jsr 1074489662
	addq.l #8,%sp
	moveq #12,%d1
	cmp.l %d0,%d1
	jcc .L16
	mov3q.l #-1,%d0
.L16:
	rts
	.size	sfx_track, .-sfx_track
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
	jcs .L34
	cmp.l #561,%a0
	jle .L35
	subq.l #2,%d0
	mov3q.l #6,%d2
	rems.l %d2,%d1:%d0
.L21:
	move.l 8(%a1),%d0
	asr.l #8,%d0
	cmp.l #561,%a0
	jle .L22
	mov3q.l #1,%d3
	cmp.l %d1,%d3
	jge .L23
.L22:
	tst.l %d0
	jge .L24
	clr.l %d0
.L24:
	lea (12,%sp),%a2
	clr.l %d1
	move.l %a2,%a0
.L26:
	moveq #10,%d3
	addq.l #1,%d1
	rems.l %d3,%d2:%d0
	divs.l %d3,%d0
	add.l #48,%d2
	move.b %d2,(%a2)+
	tst.l %d0
	jeq .L25
	mov3q.l #3,%d2
	cmp.l %d1,%d2
	jne .L26
.L25:
	add.l %d1,%a0
	clr.l %d0
.L27:
	move.l 12(%a1),%a2
	move.b -(%a0),(%a2,%d0.l)
	addq.l #1,%d0
	cmp.l %d1,%d0
	jne .L27
	clr.b %d3
	move.l 12(%a1),%a0
	move.b %d3,(%a0,%d1.l)
.L28:
	mov3q.l #1,%d0
.L19:
	movem.l (%sp),#1036
	lea (16,%sp),%sp
	rts
.L35:
	mov3q.l #2,%d1
	jra .L21
.L23:
	tst.l %d1
	jne .L29
	mov3q.l #5,%d2
	cmp.l %d0,%d2
	jcs .L30
	move.l %d0,%d1
.L30:
	moveq #86,%d3
	muls.l %d3,%d1
	move.l %d1,%a0
	add.l #sfx_types,%a0
.L31:
	clr.l %d0
.L32:
	move.b (%a0,%d0.l),%d1
	move.l 12(%a1),%a2
	add.l %d0,%a2
	tst.b %d1
	jne .L33
	clr.b (%a2)
	jra .L28
.L29:
	lea .LC0,%a0
	tst.l %d0
	jeq .L31
	lea .LC1,%a0
	jra .L31
.L33:
	move.b %d1,(%a2)
	addq.l #1,%d0
	jra .L32
.L34:
	clr.l %d0
	jra .L19
	.size	sfx_text, .-sfx_text
	.align	2
	.type	sfx_on_voice, @function
sfx_on_voice:
	jsr sfx_track
	moveq #11,%d1
	cmp.l %d0,%d1
	scc %d0
	mvs.b %d0,%d0
	neg.l %d0
	rts
	.size	sfx_on_voice, .-sfx_on_voice
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
	jcs .L49
	cmp.l #561,%d1
	jgt .L45
	moveq #11,%d1
	cmp.l %d2,%d1
	jcs .L49
	add.l %d2,%d2
	add.l %d2,%d0
.L43:
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	rts
.L45:
	add.l #-562,%d1
	moveq #12,%d3
	cmp.l %d2,%d3
	jne .L49
	mov3q.l #6,%d2
	rems.l %d2,%d0:%d1
	divs.l %d2,%d1
	mov3q.l #1,%d3
	cmp.l %d0,%d3
	jge .L49
	addq.l #6,%d1
	lsl.l #2,%d1
	move.l %d0,%a0
	lea -2(%a0,%d1.l),%a0
	move.l %a0,%d0
	jra .L43
.L49:
	mov3q.l #-1,%d0
	jra .L43
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
	jge .L51
.L53:
	mov3q.l #-1,%d0
.L50:
	move.l (%sp)+,%d2
	rts
.L51:
	jsr sc_pat_index
	tst.l %d0
	jlt .L53
	move.l 16(%sp),-(%sp)
	move.l %d2,-(%sp)
	jsr sfx_lock_find
	addq.l #8,%sp
	tst.l %d0
	jlt .L53
	move.l %d0,%d1
	add.l %d1,%d1
	move.l %d1,%a0
	add.l %d0,%a0
	add.l #sfx+334,%a0
	mvz.b (%a0),%d0
	lsl.l #8,%d0
	jra .L50
	.size	sfx_lock_get, .-sfx_lock_get
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
	jcc .L55
.L58:
	sub.l %a0,%a0
.L54:
	movem.l (%sp),#3100
	move.l %a0,%d0
	lea (20,%sp),%sp
	rts
.L55:
	cmp.l #561,%d0
	jgt .L57
	jsr sfx_track
	moveq #11,%d2
	cmp.l %d0,%d2
	jcs .L58
	add.l %d0,%d0
	moveq #127,%d1
	move.l %d1,(%a2)
	lea 28(%a3,%d0.l),%a0
.L62:
	add.l #sfx,%a0
	jra .L54
.L57:
	add.l #-562,%d0
	move.l %d0,%d2
	mov3q.l #6,%d3
	rems.l %d3,%d1:%d2
	tst.l %d1
	jeq .L60
	mov3q.l #1,%d4
	cmp.l %d1,%d4
	jne .L61
	mov3q.l #1,%a0
.L59:
	move.l %d0,%d3
	mov3q.l #6,%d4
	rems.l %d4,%d2:%d3
	move.l %a0,(%a2)
	move.l %d1,%a1
	sub.l %d2,%d0
	lea 52(%a1,%d0.l),%a0
	jra .L62
.L60:
	mov3q.l #5,%a0
	jra .L59
.L61:
	move.w #127,%a0
	jra .L59
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
	jeq .L65
	mvz.b (%a0),%d0
	move.l 12(%fp),%a0
	lsl.l #8,%d0
	move.l %d0,(%a0)
	mov3q.l #1,%d0
.L63:
	unlk %fp
	rts
.L65:
	clr.l %d0
	jra .L63
	.size	sfx_get, .-sfx_get
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
	jeq .L80
	tst.l 20(%fp)
	jeq .L68
	lsl.l #3,%d3
.L68:
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
	jge .L69
	add.l #255,%d3
.L69:
	asr.l #8,%d3
	jne .L70
	add.l %d4,%d0
	move.l %d0,%a0
	move.l %d1,270(%a0)
.L71:
	mov3q.l #1,%d0
.L66:
	movem.l -20(%fp),#60
	unlk %fp
	rts
.L70:
	move.l %d0,%a1
	add.l %d4,%a1
	move.l %d1,%d4
	and.l #-2147483393,%d4
	tst.l %d1
	jge .L72
	subq.l #1,%d4
	or.l #-256,%d4
	addq.l #1,%d4
.L72:
	move.l %d4,270(%a1)
	mvz.b (%a0),%d4
	move.l %d4,%d1
	add.l %d3,%d1
	tst.l %d1
	jlt .L81
	move.l -4(%fp),%d3
	cmp.l %d3,%d1
	jge .L73
	move.l %d1,%d3
.L73:
	cmp.l %d4,%d3
	jeq .L71
	move.b %d3,(%a0)
	cmp.l #561,%d2
	jgt .L76
	jsr sfx_track
	mov3q.l #1,%d1
	add.l %d0,%d0
	add.l %d5,%d0
	lsl.l %d0,%d1
	or.l %d1,sfx+264
.L77:
	lea sfx+8,%a0
	mov3q.l #1,sfx+20
	move.l (%a0),sfx+16
	jra .L71
.L81:
	clr.l %d3
	jra .L73
.L76:
	add.l #-562,%d2
	mov3q.l #6,%d3
	rems.l %d3,%d1:%d2
	divs.l %d3,%d2
	tst.l %d1
	jne .L78
	move.l %d0,%a0
	moveq #100,%d1
	moveq #1,%d3
	clr.b %d0
	muls.l %d1,%d2
	add.l %d2,%a0
	move.b %d3,64(%a0)
	move.b %d0,154(%a0)
	jra .L77
.L78:
	subq.l #1,%d1
	tst.l %d1
	jne .L79
	moveq #100,%d0
	muls.l %d0,%d2
	move.l %d2,%a0
	add.l #sfx+153,%a0
	move.b #1,(%a0)
	jra .L77
.L79:
	moveq #3,%d1
	add.l %d2,%d0
	move.l %d0,%a0
	move.b %d1,268(%a0)
	jra .L77
.L80:
	clr.l %d0
	jra .L66
	.size	sfx_delta, .-sfx_delta
	.align	2
	.type	sfx_op, @function
sfx_op:
	move.l 8(%sp),-(%sp)
	move.l 8(%sp),-(%sp)
	jsr sc_link_send
	addq.l #8,%sp
	tst.l %d0
	jne .L86
	addq.l #1,sfx+1236
.L85:
	rts
.L86:
	addq.l #1,sfx+1232
	mov3q.l #1,%d0
	jra .L85
	.size	sfx_op, .-sfx_op
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
	jlt .L89
	mov3q.l #1,%d2
	and.l %d4,%d2
.L90:
	moveq #100,%d0
	muls.l %d2,%d0
	lea sfx,%a0
	lea (%a0,%d0.l),%a2
	move.b 64(%a2),%d5
	jne .L91
	moveq #23,%d1
	cmp.l %d4,%d1
	jlt .L92
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
	jpl .L108
.L91:
	mov3q.l #1,%d0
	jra .L88
.L89:
	move.l %d4,%d2
	add.l #-24,%d2
	asr.l #2,%d2
	jra .L90
.L92:
	move.l %d2,-(%sp)
	jsr sfx_graph
	addq.l #4,%sp
	mov3q.l #3,%d0
	and.l %d0,%d4
	mov3q.l #6,%d1
	muls.l %d1,%d4
	lea (%a0,%d4.l),%a1
	tst.w 66(%a1)
	jeq .L91
	move.b 62(%a1),%d0
	mvz.b 66(%a2),%d1
	mvz.b %d0,%d5
	cmp.l %d5,%d1
	jls .L91
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
	jra .L96
.L108:
	mvs.w %d0,%d0
	mvs.w 74(%a0,%d2.l*2),%d1
	addq.l #8,%d4
	addq.l #1,%d0
	cmp.l %d1,%d0
	jne .L102
	mov3q.l #2,%d1
.L95:
	mvz.w #8192,%d0
	moveq #126,%d2
	cmp.l %d6,%d2
	jcs .L96
	muls.l %d6,%d6
	moveq #13,%d2
	move.l %d6,%d0
	lsl.l %d2,%d0
	mvz.w #16129,%d6
	add.l #8064,%d0
	divu.l %d6,%d0
.L96:
	moveq #127,%d2
	add.l %d5,%d1
	and.l %d0,%d2
	move.l %d0,%d7
	lsr.l #7,%d7
	mvz.b %d1,%d6
	lea sfx_op,%a2
	lea (42,%sp),%a4
	lea (38,%sp),%a3
.L101:
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
	jeq .L97
	mov3q.l #4,-(%sp)
	move.l %a3,-(%sp)
.L110:
	jsr (%a2)
	addq.l #8,%sp
	tst.l %d0
	jne .L98
	clr.l %d0
.L88:
	movem.l (%sp),#7420
	lea (48,%sp),%sp
	rts
.L102:
	mov3q.l #1,%d1
	jra .L95
.L97:
	mov3q.l #6,-(%sp)
	move.l %a4,-(%sp)
	jra .L110
.L98:
	move.l %d5,%d0
	addq.l #1,%d0
	move.b %d0,%d5
	mvz.b %d0,%d0
	cmp.l %d0,%d6
	jne .L101
	addq.l #1,sfx+1252
	jra .L91
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
	jne .L112
	tst.l %d0
	jlt .L113
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
.L122:
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
.L118:
	addq.l #3,%a0
	cmp.l %d1,%d2
	jgt .L119
	tst.w %d0
	jeq .L121
	mulu.w #3,%d0
	addq.l #1,%d0
.L120:
	move.l %d0,-(%sp)
	pea (b.1)
	pea 25.w
	jsr sc_pat_put
	lea (12,%sp),%sp
.L113:
	mov3q.l #1,%d0
	jra .L111
.L112:
	tst.l %d0
	jge .L115
	move.w sfx+330,%d1
	mvz.w %d1,%d0
	cmp.l #299,%d0
	jls .L116
	addq.l #1,sfx+1256
	clr.l %d0
.L111:
	movem.l (%sp),#60
	lea (16,%sp),%sp
	rts
.L116:
	addq.l #1,%d1
	move.w %d1,sfx+330
	move.l %d0,%d1
	add.l %d1,%d1
	move.l %d1,%a0
	add.l %d0,%a0
	add.l #sfx,%a0
	move.b %d2,332(%a0)
	move.b %d3,333(%a0)
.L115:
	move.l %d0,%d1
	add.l %d1,%d1
	move.l %d1,%a0
	add.l %d0,%a0
	add.l #sfx+334,%a0
	move.b %d4,(%a0)
	clr.l -(%sp)
	move.l %d4,-(%sp)
	jra .L122
.L119:
	move.b (%a1),-2(%a0)
	move.b 1(%a1),-1(%a0)
	move.b 2(%a1),(%a0)
	addq.l #1,%d1
	addq.l #3,%a1
	jra .L118
.L121:
	clr.l %d0
	jra .L120
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
	jlt .L125
	jsr sc_pat_index
	tst.l %d0
	jlt .L125
	mov3q.l #-1,20(%sp)
	move.l %d3,16(%sp)
	move.l %d2,12(%sp)
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	jra sfx_lock_put
.L125:
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
	jlt .L129
	jsr sc_pat_index
	tst.l %d0
	jlt .L129
	move.l %d3,%d0
	asr.l #8,%d0
	cmp.l #32767,%d3
	jle .L131
	moveq #127,%d0
.L132:
	move.l %d4,20(%sp)
	move.l %d2,16(%sp)
	movem.l (%sp),#28
	move.l %d0,24(%sp)
	lea (12,%sp),%sp
	jra sfx_lock_put
.L131:
	tst.l %d0
	jge .L132
	clr.l %d0
	jra .L132
.L129:
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
	jge .L134
.L136:
	mov3q.l #-1,%d0
.L133:
	movem.l (%sp),#60
	lea (16,%sp),%sp
	rts
.L134:
	jsr sc_pat_index
	tst.l %d0
	jlt .L136
	move.l %d4,-(%sp)
	move.l %d3,-(%sp)
	jsr sfx_lock_find
	addq.l #8,%sp
	lea sfx,%a0
	tst.l %d0
	jge .L137
	moveq #23,%d0
	cmp.l %d3,%d0
	jlt .L138
	mvz.b 28(%a0,%d3.l),%d1
.L140:
	add.l #-560,%d2
	lsl.l #2,%d2
	add.l %d2,%a0
	move.l 32(%sp),%d2
	add.l 270(%a0),%d2
	move.l %d2,%d0
	and.l #-2147483393,%d0
	tst.l %d2
	jge .L141
	subq.l #1,%d0
	or.l #-256,%d0
	addq.l #1,%d0
.L141:
	move.l %d0,270(%a0)
	tst.l %d2
	jge .L142
	add.l #255,%d2
.L142:
	asr.l #8,%d2
	add.l %d1,%d2
	cmp.l #128,%d2
	jlt .L143
	moveq #127,%d2
.L144:
	move.l %d2,-(%sp)
	move.l %d4,-(%sp)
	move.l %d3,-(%sp)
	jsr sfx_lock_put
	lea (12,%sp),%sp
	tst.l %d0
	jeq .L136
	move.l %d2,%d0
	lsl.l #8,%d0
	jra .L133
.L138:
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
	jra .L140
.L137:
	move.l %d0,%d1
	add.l %d1,%d1
	move.l %d1,%a1
	add.l %d0,%a1
	add.l #sfx+334,%a1
	mvz.b (%a1),%d1
	jra .L140
.L143:
	tst.l %d2
	jge .L144
	clr.l %d2
	jra .L144
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
	jeq .L149
	cmp.l sfx+4.l,%d4
	jeq .L149
	move.l %d4,sfx+4
	clr.l %d0
	lea sfx+28,%a3
.L150:
	lea (%a3,%d0.l),%a0
	moveq #36,%d1
	addq.l #1,%d0
	move.b (%a0),-37(%fp,%d0.l)
	cmp.l %d0,%d1
	jne .L150
	pea 36.w
	moveq #36,%d4
	move.l %a3,-(%sp)
	pea 25.w
	jsr sc_kit_get
	lea (12,%sp),%sp
	cmp.l %d0,%d4
	jeq .L151
	clr.l %d0
.L152:
	clr.b %d5
	moveq #36,%d6
	move.b %d5,(%a3,%d0.l)
	addq.l #1,%d0
	cmp.l %d0,%d6
	jne .L152
	moveq #5,%d0
	moveq #1,%d4
	move.l #1077952576,%d1
	move.l %d1,sfx+54
	move.l %d1,sfx+60
	move.b %d0,sfx+52
	move.b %d4,sfx+58
.L151:
	lea sfx+28,%a0
	clr.l %d0
.L154:
	tst.b (%a0)+
	jge .L153
	moveq #127,%d5
	move.b %d5,-1(%a0)
.L153:
	addq.l #1,%d0
	moveq #36,%d6
	cmp.l %d0,%d6
	jne .L154
	mvz.b sfx+52,%d0
	mov3q.l #5,%d1
	cmp.l %d0,%d1
	jcc .L155
	clr.b %d4
	move.b %d4,sfx+52
.L155:
	mvz.b sfx+58,%d0
	mov3q.l #5,%d5
	cmp.l %d0,%d5
	jcc .L156
	clr.b %d6
	move.b %d6,sfx+58
.L156:
	mvz.b sfx+52,%d1
	mvz.b sfx+65,%d0
	clr.l sfx+20
	mov3q.l #1,sfx+24
	cmp.l %d1,%d0
	jeq .L157
.L159:
	moveq #1,%d0
	clr.b %d1
	move.b %d0,sfx+64
	move.b %d1,sfx+154
.L158:
	mvz.b sfx+58,%d1
	mvz.b sfx+165,%d0
	cmp.l %d1,%d0
	jeq .L162
.L164:
	moveq #1,%d0
	clr.b %d1
	move.b %d0,sfx+164
	move.b %d1,sfx+254
.L163:
	move.l #16777215,%a0
	move.l %a0,sfx+264
	tst.l %d3
	jne .L167
.L181:
	cmp.l sfx.l,%d2
	jne .L168
.L169:
	tst.l %d2
	jeq .L148
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
.L237:
	move.b (%a3),%d0
	move.l %d0,%d1
	subq.l #3,%d1
	mvz.b %d1,%d1
	lsr.l #1,%d1
	jne .L185
	move.l sfx+8,%d1
	move.l %d1,%a0
	sub.l 96(%a3),%a0
	moveq #90,%d4
	cmp.l %a0,%d4
	jcc .L185
	move.b #6,(%a3)
	move.l %d1,96(%a3)
.L186:
	move.l sfx+8,%d0
	moveq #90,%d1
	sub.l 96(%a3),%d0
	cmp.l %d0,%d1
	jcc .L187
	move.b #1,(%a3)
	clr.b %d3
	jra .L357
.L157:
	mvz.b sfx+64,%d0
	subq.l #6,%d0
	tst.l %d0
	jeq .L159
	mvz.b sfx+53,%d1
	mvz.b -11(%fp),%d0
	cmp.l %d1,%d0
	jne .L160
.L161:
	moveq #3,%d5
	move.b %d5,sfx+268
	jra .L158
.L160:
	moveq #1,%d6
	move.b %d6,sfx+153
	jra .L161
.L162:
	mvz.b sfx+164,%d0
	subq.l #6,%d0
	tst.l %d0
	jeq .L164
	mvz.b sfx+59,%d1
	mvz.b -5(%fp),%d0
	cmp.l %d1,%d0
	jne .L165
.L166:
	moveq #3,%d5
	move.b %d5,sfx+269
	jra .L163
.L165:
	moveq #1,%d6
	move.b %d6,sfx+253
	jra .L166
.L167:
	cmp.l sfx+326.l,%d3
	jeq .L176
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
	jge .L173
	mvz.b (b.0),%d1
	cmp.l %d1,%d3
	jne .L173
	clr.b %d1
	sub.l %a1,%a1
	lea b.0+1,%a3
	mov3q.l #3,%d6
.L175:
	cmp.l %d0,%d6
	jlt .L178
	tst.b %d1
	jeq .L173
	move.w %a1,sfx+330
	jra .L173
.L149:
	tst.l %d3
	jne .L167
.L176:
	tst.l sfx+24
	jne .L181
.L148:
	movem.l -116(%fp),#15612
	unlk %fp
	rts
.L179:
	move.b (%a3),%d7
	mvz.b %d7,%d4
	lsr.l #5,%d4
	jne .L177
	move.b 1(%a3),%d5
	mvz.b %d5,%d4
	move.l %d4,%a0
	moveq #63,%d4
	cmp.l %a0,%d4
	jcs .L177
	move.b 2(%a3),%d4
	jmi .L177
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
.L177:
	addq.l #3,%d6
	addq.l #3,%a3
	jra .L175
.L178:
	mvz.w %a1,%d3
	cmp.l #300,%d3
	jne .L179
	tst.b %d1
	jeq .L173
	move.w %d3,sfx+330
.L173:
	move.w #256,%d4
	clr.w %d5
	move.w %d4,sfx+155
	move.w %d5,sfx+158
	move.w %d4,sfx+255
	move.w %d5,sfx+258
	jra .L176
.L168:
	move.l %d2,(%a2)
	tst.l %d2
	jeq .L183
	addq.l #1,sfx+1244
.L183:
	clr.l -(%sp)
	lea sfx_reset_fx,%a2
	jsr (%a2)
	mov3q.l #1,-(%sp)
	jsr (%a2)
	addq.l #8,%sp
	jra .L169
.L284:
	mov3q.l #1,%d2
	jra .L237
.L185:
	subq.l #1,%d0
	mvz.b %d0,%d0
	mov3q.l #5,%d5
	cmp.l %d0,%d5
	jcs .L187
	move.w .L188(%pc,%d0.l*2),%d0
	ext.l %d0
	jmp %pc@(2,%d0:l)
	.balignw 2,0x284c
.L188:
	.word .L193-.L188
	.word .L192-.L188
	.word .L280-.L188
	.word .L190-.L188
	.word .L189-.L188
	.word .L186-.L188
.L189:
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
.L194:
	move.b 2(%a3),%d1
	move.b 90(%a3),%d4
	mvz.b %d1,%d0
	mvz.b %d4,%d3
	move.l %d0,%a0
	lea (11,%a0),%a0
	cmp.l %d3,%a0
	jge .L236
	moveq #1,%d5
	clr.b %d6
	clr.w %d0
	clr.b (%a3)
	move.b %d5,91(%a3)
	move.b %d6,92(%a3)
	move.w %d0,94(%a3)
	jra .L187
.L193:
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
.L195:
	mvz.b 2(%a3),%d0
	cmp.l %d3,%d0
	jgt .L199
	move.l %fp,%d3
	add.l #-36,%d3
	lea sfx_op,%a5
.L200:
	move.b 90(%a3),%d0
	moveq #11,%d5
	mvz.b %d0,%d1
	cmp.l %d1,%d5
	jcc .L202
	move.l %d2,-(%sp)
	addq.l #1,sfx+1248
	jsr sfx_reset_fx
	addq.l #4,%sp
.L187:
	lea (100,%a3),%a3
	lea (100,%a4),%a4
	addq.l #6,-56(%fp)
	addq.l #1,-64(%fp)
	tst.l %d2
	jeq .L284
	lea sfx+64,%a3
	clr.l %d3
.L263:
	tst.b (%a3)
	jne .L239
	tst.b 2(%a3)
	jeq .L239
	move.l %d3,%d4
	add.l %d4,%d4
	lea sfx_graph,%a5
	move.b %d4,-61(%fp)
	clr.l %d4
.L241:
	mvz.b 2(%a3),%d0
	cmp.l %d4,%d0
	jgt .L250
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
.L258:
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
	jcs .L251
	mulu.w %d0,%d0
	moveq #13,%d4
	mvz.w #16129,%d1
	lsl.l %d4,%d0
	move.l %d0,%d4
	add.l #8064,%d4
	divu.l %d1,%d4
.L251:
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
	jne .L286
	moveq #2,%d0
.L252:
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
	jeq .L253
	cmp.l -48(%fp),%d5
	jne .L287
	moveq #8,%d0
.L254:
	move.l %d0,-(%sp)
	pea -36(%fp)
	move.l %d1,-68(%fp)
	jsr sfx_op
	addq.l #8,%sp
	move.l -68(%fp),%d1
	tst.l %d0
	jeq .L249
	cmp.l -48(%fp),%d5
	jeq .L256
	move.w %a4,%d5
	jmi .L256
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
	jeq .L249
.L256:
	not.l %d7
	and.l %d7,sfx+264
.L253:
	addq.l #2,%d6
	tst.b -53(%fp)
	jeq .L259
	moveq #24,%d0
.L260:
	cmp.l %d0,%d6
	jne .L258
	tst.b 89(%a3)
	jeq .L239
	move.l %fp,%d5
	move.l %fp,%d6
	lea (12,%a3),%a4
	mov3q.l #2,%d4
	add.l #-41,%d5
	add.l #-42,%d6
	lea sfx_ends,%a5
.L262:
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
	jlt .L261
	mov3q.l #6,-(%sp)
	pea -36(%fp)
	jsr sfx_op
	addq.l #8,%sp
	tst.l %d0
	jeq .L249
.L261:
	subq.l #2,%d4
	tst.l %d4
	jeq .L288
	clr.b %d4
	move.b %d4,89(%a3)
.L239:
	lea (100,%a3),%a3
	addq.l #1,-60(%fp)
	addq.l #6,-52(%fp)
	tst.l %d3
	jeq .L289
.L249:
	move.l %fp,%d5
	sub.l %a4,%a4
	add.l #-36,%d5
	lea sfx_op,%a3
.L279:
	move.b 2(%a2),%d3
	tst.b 91(%a2)
	jeq .L265
	tst.b (%a2)
	jne .L265
	move.l %a4,%d7
	move.w %a4,%d6
	add.l %d7,%d7
	mvz.b %d3,%d3
	move.w #24,%a5
	add.l #12,%d3
.L267:
	move.b 92(%a2),%d0
	mvz.b %d0,%d1
	move.l %d1,%a0
	cmp.l %d3,%d1
	jge .L271
	tst.l %a5
	jne .L272
.L271:
	move.l #sfx_lock_send,%d7
.L273:
	move.w 94(%a2),%d0
	mvz.w sfx+330,%d1
	mvz.w %d0,%d6
	cmp.l %d6,%d1
	jls .L277
	tst.l %a5
	jgt .L278
.L277:
	mvz.b 92(%a2),%d0
	cmp.l %d3,%d0
	jlt .L265
	cmp.l %d6,%d1
	jhi .L265
	clr.b %d0
	move.b %d0,91(%a2)
.L265:
	lea (100,%a2),%a2
	tst.l %a4
	jeq .L290
	tst.l sfx+20
	jeq .L148
	move.l sfx+8,%d0
	moveq #11,%d1
	sub.l sfx+16,%d0
	cmp.l %d0,%d1
	jcc .L148
	pea 36.w
	pea sfx+28
	pea 25.w
	jsr sc_kit_put
	lea (12,%sp),%sp
	tst.l %d0
	jeq .L148
	clr.l sfx+20
	jra .L148
.L199:
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
	jlt .L196
	mov3q.l #3,-(%sp)
	move.l %d7,-(%sp)
	jsr (%a5)
	addq.l #8,%sp
	tst.l %d0
	jeq .L187
	mov3q.l #2,-(%sp)
	move.l %d4,-(%sp)
	jsr (%a5)
	addq.l #8,%sp
	tst.l %d0
	jeq .L187
	st %d0
	move.l -72(%fp),%a0
	move.b %d0,-1(%a0)
.L196:
	addq.l #1,%d3
	jra .L195
.L202:
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
	jeq .L187
	move.b 90(%a3),%d0
	addq.l #1,%d0
	move.b %d0,90(%a3)
	jra .L200
.L192:
	move.w #9599,%d4
	move.l %d2,-(%sp)
	jsr sfx_graph
	mvz.b 3(%a3),%d3
	addq.l #4,%sp
	move.l %fp,%d5
	add.l #-36,%d5
	lea sfx_op,%a5
	move.l %a0,-48(%fp)
.L203:
	move.l -48(%fp),%a0
	move.b 8(%a0),%d0
	mvz.b %d0,%d1
	cmp.l %d3,%d1
	jgt .L208
	move.b %d0,2(%a3)
	move.l -56(%fp),%a1
	move.b (%a1),1(%a3)
	move.b #3,(%a3)
.L356:
	lea sfx+8,%a0
	move.l (%a0),96(%a3)
	jra .L187
.L208:
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
.L204:
	move.b 6(%a0,%d0.l),%d1
	jeq .L205
	move.b %d1,-36(%fp,%d0.l)
	addq.l #1,%d0
	moveq #12,%d1
	cmp.l %d0,%d1
	jne .L204
.L205:
	move.l %d0,-(%sp)
	move.l %d5,-(%sp)
	jsr (%a5)
	addq.l #1,%d3
	addq.l #8,%sp
	tst.l %d0
	jeq .L187
	move.b %d3,3(%a3)
	jra .L203
.L212:
	move.l -48(%fp),%a1
	move.b 68(%a1),%d0
	jmi .L209
	mvs.b %d0,%d0
.L210:
	move.l -48(%fp),%a0
	addq.l #1,%d3
	move.b %d0,68(%a0)
.L211:
	addq.l #1,%d4
	addq.l #1,-48(%fp)
.L191:
	mvz.b 2(%a3),%d0
	cmp.l %d4,%d0
	jgt .L212
	cmp.l %d3,%d0
	jne .L187
	clr.b %d0
	move.b #4,(%a3)
	move.b %d0,88(%a3)
	jra .L356
.L209:
	move.l -48(%fp),%a0
	mvz.b 70(%a0),%d0
	move.l %d0,-(%sp)
	pea 37.w
	jsr (%a5)
	addq.l #8,%sp
	cmp.l #-256,%d0
	jeq .L211
	tst.l %d0
	jge .L210
	addq.l #1,sfx+1240
	move.b #6,(%a3)
	lea sfx+8,%a1
	move.l (%a1),96(%a3)
	jra .L187
.L280:
	move.l %a4,-48(%fp)
	clr.l %d3
	clr.l %d4
	lea sc_dsp_result,%a5
	jra .L191
.L190:
	tst.l %d2
	jeq .L214
	mvz.b sfx+64,%d0
	subq.l #4,%d0
	tst.l %d0
	jeq .L187
.L214:
	lea (132,%a4),%a0
	clr.l %d3
	move.l %a0,-48(%fp)
	move.l %a4,%d5
	clr.l %d4
	lea sc_route_result,%a5
.L220:
	move.l -48(%fp),%a1
	addq.l #1,-48(%fp)
	tst.b (%a1)+
	jeq .L218
	mvz.b -21(%a1),%d0
	move.l %d0,-(%sp)
	pea 37.w
	jsr (%a5)
	addq.l #8,%sp
	cmp.l #-256,%d0
	jne .L217
	addq.l #1,%d3
.L218:
	addq.l #1,%d4
	addq.l #2,%d5
	moveq #20,%d0
	cmp.l %d4,%d0
	jne .L220
	moveq #100,%d0
	muls.l %d2,%d0
	move.l #sfx,%d4
	move.l %fp,%d6
	move.l %d4,%d7
	add.l #-42,%d6
	lea (-36,%fp),%a5
	add.l %d0,%d7
.L221:
	move.b 88(%a3),%d0
	moveq #19,%d5
	mvz.b %d0,%d1
	move.l %d1,-48(%fp)
	cmp.l %d1,%d5
	jcs .L229
	moveq #11,%d1
	cmp.l %d3,%d1
	jlt .L187
	mov3q.l #1,%d1
	cmp.l -48(%fp),%d1
	jlt .L222
	mvz.b 2(%a3),%d1
	lsr.l #1,%d1
	jeq .L223
.L222:
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
	jpl .L358
	addq.l #1,%d1
.L358:
	asr.l #1,%d1
	cmp.l -48(%fp),%d5
	jge .L224
	clr.l %d0
	lea sfx_voice,%a0
.L225:
	mvz.b (%a0,%d0.l),%d5
	cmp.l %d1,%d5
	jne .L227
	add.l %d0,%d0
	move.l %d4,%a0
	moveq #126,%d5
	add.l %d0,%a0
	mvz.b 28(%a0,%d2.l),%d1
	mvz.w #8192,%d0
	cmp.l %d1,%d5
	jcs .L224
	mulu.w %d1,%d1
	moveq #13,%d0
	mvz.w #16129,%d5
	lsl.l %d0,%d1
	move.l %d1,%d0
	add.l #8064,%d0
	divu.l %d5,%d0
.L224:
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
	jeq .L187
	moveq #1,%d0
	addq.l #1,%d3
	move.b %d0,132(%a1)
	move.b 88(%a3),%d0
	addq.l #1,%d0
	jra .L226
.L217:
	clr.b %d1
	move.l -48(%fp),%a0
	move.b %d1,-1(%a0)
	move.l sfx+8,%d1
	tst.l %d0
	jge .L219
	addq.l #1,sfx+1240
	move.b #6,(%a3)
	move.l %d1,96(%a3)
	jra .L187
.L219:
	move.l %d5,%a1
	move.w %d0,72(%a1)
	move.l %d1,96(%a3)
	jra .L218
.L223:
	addq.l #1,%d0
.L226:
	move.b %d0,88(%a3)
	jra .L221
.L227:
	addq.l #1,%d0
	moveq #12,%d5
	cmp.l %d0,%d5
	jne .L225
	clr.l %d0
	jra .L224
.L229:
	tst.l %d3
	jne .L187
	move.b #5,(%a3)
.L357:
	move.b %d3,90(%a3)
	jra .L187
.L236:
	cmp.l %d0,%d3
	jcc .L231
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
	jeq .L187
	move.l -64(%fp),%a1
	mov3q.l #1,%d0
	lsl.l %d3,%d0
	move.b 268(%a1),%d1
	or.l %d1,%d0
	move.b %d0,268(%a1)
.L233:
	move.b 90(%a3),%d0
	addq.l #1,%d0
	move.b %d0,90(%a3)
	jra .L194
.L231:
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
	jne .L283
	moveq #2,%d0
.L234:
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
	jeq .L187
	add.l %d3,%d3
	mov3q.l #1,%d0
	add.l %d2,%d3
	lsl.l %d3,%d0
	or.l %d0,sfx+264
	jra .L233
.L283:
	moveq #1,%d0
	jra .L234
.L289:
	move.l %d2,%d3
	jra .L263
.L250:
	move.l %d3,-(%sp)
	jsr (%a5)
	addq.l #4,%sp
	move.l -60(%fp),%a1
	moveq #26,%d0
	muls.l %d4,%d0
	mvz.b 268(%a1),%d1
	move.b 18(%a0,%d0.l),%d0
	btst %d4,%d1
	jeq .L242
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
.L243:
	cmp.l %d7,%a4
	jlt .L247
	add.l %d7,%d7
	move.l %d7,%a0
	pea 4(%a0)
	pea -36(%fp)
	jsr sfx_op
	addq.l #8,%sp
	tst.l %d0
	jeq .L249
	move.l -60(%fp),%a1
	mov3q.l #1,%d0
	lsl.l %d4,%d0
	move.b 268(%a1),%d1
	not.l %d0
	and.l %d1,%d0
	move.b %d0,268(%a1)
.L242:
	addq.l #1,%d4
	jra .L241
.L247:
	move.l %d3,-(%sp)
	jsr (%a5)
	addq.l #4,%sp
	clr.l %d0
	lea (62,%a0),%a1
.L246:
	mvz.b (%a1),%d1
	cmp.l %d4,%d1
	jne .L244
	mvz.b 1(%a1),%d1
	cmp.l %a4,%d1
	jne .L244
	tst.w 4(%a1)
	jeq .L244
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
.L245:
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
	jra .L243
.L244:
	addq.l #1,%d0
	addq.l #6,%a1
	mov3q.l #4,%d1
	cmp.l %d0,%d1
	jne .L246
	lea 10(%a4,%d6.l),%a1
	mvz.w (%a0,%a1.l*2),%d0
	jra .L245
.L286:
	moveq #1,%d0
	jra .L252
.L287:
	mov3q.l #6,%d0
	jra .L254
.L259:
	moveq #25,%d0
	jra .L260
.L288:
	mov3q.l #3,%d4
	jra .L262
.L290:
	move.l %d2,%a4
	jra .L279
.L272:
	move.b 2(%a2),%d1
	mvz.b %d1,%d4
	cmp.l %d4,%a0
	jcc .L268
	add.l %d7,%d0
.L269:
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
	jeq .L265
	move.b 92(%a2),%d0
	subq.l #1,%a5
	addq.l #1,%d0
	move.b %d0,92(%a2)
	jra .L267
.L268:
	addq.l #4,%d0
	sub.l %d1,%d0
	add.l %d0,%d0
	add.l %d6,%d0
	jra .L269
.L278:
	mulu.w #3,%d0
	moveq #23,%d4
	move.l %d0,%a0
	add.l #sfx+332,%a0
	move.b (%a0),%d0
	mvz.b %d0,%d1
	cmp.l %d1,%d4
	jlt .L274
	mov3q.l #1,%d6
	and.l %d6,%d0
.L275:
	cmp.l %a4,%d0
	jne .L276
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
	jeq .L265
	subq.l #2,%a5
.L276:
	move.w 94(%a2),%d0
	addq.l #1,%d0
	move.w %d0,94(%a2)
	jra .L273
.L274:
	move.l %d1,%d0
	add.l #-24,%d0
	asr.l #2,%d0
	jra .L275
	.size	sfx_tick, .-sfx_tick
	.align	2
	.globl	sfx_diag
	.type	sfx_diag, @function
sfx_diag:
	move.l 4(%sp),%d0
	moveq #9,%d1
	cmp.l %d0,%d1
	jcs .L371
	move.l %d0,%d1
	add.l %d1,%d1
	move.w .L362(%pc,%d1.l),%d1
	ext.l %d1
	jmp %pc@(2,%d1:l)
	.balignw 2,0x284c
.L362:
	.word .L370-.L362
	.word .L369-.L362
	.word .L368-.L362
	.word .L367-.L362
	.word .L366-.L362
	.word .L365-.L362
	.word .L365-.L362
	.word .L364-.L362
	.word .L363-.L362
	.word .L361-.L362
.L370:
	move.l sfx+1232,%d0
.L359:
	rts
.L369:
	move.l sfx+1236,%d0
	jra .L359
.L368:
	move.l sfx+1240,%d0
	jra .L359
.L367:
	move.l sfx+1244,%d0
	jra .L359
.L366:
	move.l sfx+1248,%d0
	jra .L359
.L365:
	subq.l #5,%d0
	moveq #100,%d1
	muls.l %d1,%d0
	move.l %d0,%a0
	add.l #sfx+64,%a0
	mvz.b (%a0),%d0
	jra .L359
.L364:
	mvz.w sfx+330,%d0
	jra .L359
.L363:
	move.l sfx+1252,%d0
	jra .L359
.L361:
	move.l sfx+1256,%d0
	jra .L359
.L371:
	clr.l %d0
	jra .L359
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
	.size	sfx_locks, 24
sfx_locks:
	.long	560
	.long	573
	.long	sfx_lock_get
	.long	sfx_lock_turn
	.long	sfx_lock_set
	.long	sfx_lock_clear
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
.LC2:
	.string	"SEND FX 2"
	.text
	.align	2
	.type	sfx_page_fx2, @object
	.size	sfx_page_fx2, 40
sfx_page_fx2:
	.long	18
	.long	.LC2
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
.LC3:
	.string	"SEND FX 1"
	.text
	.align	2
	.type	sfx_page_fx1, @object
	.size	sfx_page_fx1, 40
sfx_page_fx1:
	.long	17
	.long	.LC3
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
.LC4:
	.string	"AMPLITUDE 2"
	.text
	.align	2
	.type	sfx_page_amp2, @object
	.size	sfx_page_amp2, 40
sfx_page_amp2:
	.long	16
	.long	.LC4
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
