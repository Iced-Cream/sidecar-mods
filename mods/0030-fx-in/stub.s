| Mod 0030 - FX in: delay + reverb return on Overbridge IN L/R, switched by the host (26 / 27).
| GENERATED from fxin.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit fxin.c.
	.include "symbols.inc"
#NO_APP
	.file	"fxin.c"
	.text
#APP
	.text
	.align	2
	.globl	fxin_ob
	.if	fx_reverb_out != fx_delay_out - 256
	.error	"fxin_ob reads the reverb at fx_delay_out - 256"
	.endif
fxin_ob:
	move.l	fxin_word,%d0
	cmp.l	#0x46584931,%d0
	bne.w	2f
	lea	-12(%sp),%sp
	movem.l	%d2-%d4,(%sp)
	move.l	%macsr,%d4
	move.l	#0xa0,%macsr
	movclr.l %acc0,%d0
	movclr.l %acc1,%d0
	move.l	fx_return_gain_pre,%d1
	add.l	fx_return_gain_post,%d1
	move.l	fx_return_gain_pre+4,%d2
	add.l	fx_return_gain_post+4,%d2
	lea	fx_delay_out,%a0
	lea	0x80007440+40,%a1
	moveq	#32,%d3
1:	move.l	(%a0),%d0
	mac.l	%d0,%d1,-256(%a0),%d0,%acc0
	mac.l	%d0,%d2,%acc0
	mac.l	%d0,%d2,4(%a0),%d0,%acc0
	mac.l	%d0,%d1,-252(%a0),%d0,%acc1
	mac.l	%d0,%d2,%acc1
	mac.l	%d0,%d2,%acc1
	addq.l	#8,%a0
	movclr.l %acc0,%d0
	move.l	%d0,(%a1)+
	movclr.l %acc1,%d0
	move.l	%d0,(%a1)
	lea	44(%a1),%a1
	subq.l	#1,%d3
	bne.s	1b
	move.l	%d4,%macsr
	movem.l	(%sp),%d2-%d4
	lea	12(%sp),%sp
2:	jmp	ob_in_write

#NO_APP
	.align	2
	.type	try_send, @function
try_send:
	mov3q.l #1,%d0
	cmp.l 1094562388.l,%d0
	jne .L2
	move.l #1123449384,-(%sp)
	jsr 1073746332
	addq.l #4,%sp
	tst.l %d0
	jeq .L1
	move.l 1094562704,%a0
	clr.l %d0
.L4:
	tst.l %a0
	jeq .L5
	move.l 52(%a0),%a0
	addq.l #1,%d0
	mov3q.l #4,%d1
	cmp.l %d0,%d1
	jne .L4
.L5:
	mvz.w #4027,%d1
	cmp.l 1094562392.l,%d1
	jlt .L7
	subq.l #4,%d0
	tst.l %d0
	jeq .L8
.L7:
	move.l #1123449384,-(%sp)
	jsr 1073746414
	addq.l #4,%sp
.L2:
	clr.l %d0
.L1:
	rts
.L8:
	move.l 4(%sp),-(%sp)
	move.l 12(%sp),-(%sp)
	jsr 1073752544
	move.l #1123449384,-(%sp)
	jsr 1073746414
	lea (12,%sp),%sp
	mov3q.l #1,%d0
	jra .L1
	.size	try_send, .-try_send
	.align	2
	.globl	fxin_host
	.type	fxin_host, @function
fxin_host:
	mov3q.l #6,%d0
	cmp.l 8(%sp),%d0
	jge .L16
	move.l 4(%sp),%a0
	mov3q.l #1,%d1
	mvz.b 5(%a0),%d0
	cmp.l %d0,%d1
	jcs .L16
	add.l #1180191024,%d0
	move.l %d0,fxin_word
.L16:
	move.w fxin_req,%d0
	addq.l #1,%d0
	move.w %d0,fxin_req
	mov3q.l #1,%d0
	rts
	.size	fxin_host, .-fxin_host
	.text
.LC0:
	.string	"\360}RT'"
	.ascii	"\367"
	.text
	.align	2
	.globl	fxin_tick
	.type	fxin_tick, @function
fxin_tick:
	link.w %fp,#-44
	movem.l #1036,(%sp)
	move.w fxin_req,%d2
	move.l 1094562388,%d1
	move.l %d1,-32(%fp)
	mov3q.l #1,%d1
	cmp.l -32(%fp),%d1
	seq %d0
	neg.l %d0
	tst.b st+2.l
	jne .L18
	move.w %d2,st
	move.b %d1,st+2
.L18:
	mov3q.l #1,%d1
	tst.b st+3.l
	jne .L19
	cmp.l -32(%fp),%d1
	jne .L21
	moveq #1,%d1
	move.b %d1,st+4
	jra .L21
.L19:
	cmp.l -32(%fp),%d1
	jeq .L21
	move.l #1180191025,%a0
	cmp.l fxin_word.l,%a0
	jne .L21
	move.l #1180191024,%a1
	move.l %a1,fxin_word
.L21:
	move.b %d0,st+3
	mvz.w st,%d1
	mvz.w %d2,%d0
	cmp.l %d1,%d0
	jne .L22
	tst.b st+4.l
	jeq .L23
.L22:
	mov3q.l #7,-(%sp)
	pea .LC0
	move.l %fp,%d3
	add.l #-16,%d3
	move.l %d3,-(%sp)
	jsr memcpy
	lea (12,%sp),%sp
	mov3q.l #7,-(%sp)
	move.l %d3,-(%sp)
	move.l #1180191025,%a0
	cmp.l fxin_word.l,%a0
	seq %d0
	neg.l %d0
	move.b %d0,-11(%fp)
	jsr try_send
	addq.l #8,%sp
	tst.l %d0
	jeq .L23
	clr.b %d0
	move.w %d2,st
	move.b %d0,st+4
.L23:
	mov3q.l #1,%d1
	cmp.l -32(%fp),%d1
	jne .L17
	move.b st+5,%d2
	mvz.b %d2,%d0
	move.w %d2,%a1
	moveq #19,%d2
	move.l %d0,-32(%fp)
	cmp.l %d0,%d2
	jcs .L26
	clr.l %d1
.L26:
	sub.l %a0,%a0
	move.l #stem_voice,%d2
.L29:
	mvz.b (%a0,%d2.l),%d0
	add.l #1076433208,%d0
	move.l %d0,%a2
	mvz.b (%a2),%d0
	lea lfo_track_array,%a2
	muls.w #42,%d0
	mvs.w 76(%a2,%d0.l*2),%d0
	tst.l %d0
	jlt .L34
	add.l #128,%d0
	asr.l #8,%d0
	cmp.l #128,%d0
	jne .L28
	moveq #127,%d0
	jra .L28
.L34:
	clr.l %d0
.L28:
	move.b %d0,-26(%fp,%a0.l)
	addq.l #1,%a0
	moveq #8,%d0
	cmp.l %a0,%d0
	jne .L29
	mvz.b -2147457946,%d0
	moveq #127,%d2
	move.l #-260222380,%a0
	lsr.l #7,%d0
	move.b %d0,-18(%fp)
	move.b -2147457946,%d0
	move.l %a0,-16(%fp)
	sub.l %a0,%a0
	and.l %d2,%d0
	moveq #-9,%d2
	move.b %d0,-17(%fp)
	moveq #80,%d0
	move.b %d2,-1(%fp)
	move.l #st+6,%d2
	move.b %d0,-12(%fp)
.L30:
	move.b -26(%fp,%a0.l),%d3
	move.b (%a0,%d2.l),%d0
	addq.l #1,%a0
	move.b %d3,-12(%a0,%fp.l)
	eor.l %d3,%d0
	tst.b %d0
	sne %d0
	mvs.b %d0,%d0
	neg.l %d0
	or.l %d0,%d1
	moveq #10,%d0
	cmp.l %a0,%d0
	jne .L30
	move.l -32(%fp),%d0
	cmp.l #255,%d0
	jeq .L31
	move.l %a1,%d0
	addq.l #1,%d0
	move.b %d0,st+5
.L31:
	tst.l %d1
	jeq .L17
	pea 16.w
	pea -16(%fp)
	jsr try_send
	addq.l #8,%sp
	tst.l %d0
	jeq .L17
	clr.l %d0
.L33:
	lea -26(%fp,%d0.l),%a1
	move.l %d2,%a0
	moveq #10,%d1
	move.b (%a1),(%a0,%d0.l)
	addq.l #1,%d0
	cmp.l %d0,%d1
	jne .L33
	clr.b %d2
	move.b %d2,st+5
.L17:
	movem.l -44(%fp),#1036
	unlk %fp
	rts
	.size	fxin_tick, .-fxin_tick
	.text
	.type	stem_voice, @object
	.size	stem_voice, 8
stem_voice:
	.base64	"AAIHAQMFBAY="
	.section	.bss,"aw",@nobits
	.align	2
	.type	st, @object
	.size	st, 16
st:
	.zero	16
	.globl	fxin_req
	.align	2
	.type	fxin_req, @object
	.size	fxin_req, 2
fxin_req:
	.zero	2
	.globl	fxin_word
	.align	4
	.type	fxin_word, @object
	.size	fxin_word, 4
fxin_word:
	.zero	4
	.ident	"GCC: (GNU) 16.2.0"
