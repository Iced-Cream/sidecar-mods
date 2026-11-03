| Mod 0022 - looper mode: TRK + REC, pads as clip slots, reported to the USB host.
| GENERATED from looper.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os, LP_SFX=1 and 0); edit looper.c.
	.ifne P_SFX
#NO_APP
	.file	"looper.c"
	.text
#APP
	  .section .lp2,"ax"
  .globl looper_uart
looper_uart:
  movel %sp@(8),%sp@-
  movel %sp@(8),%sp@-
  jsr looper_uart_drop
  addql #8,%sp
  tstl %d0
  jeq 1f
  rts
1:
  lea %sp@(-12),%sp
  moveml %d2-%d4,%sp@
  jmp 0x400019ec

	  .text
  .globl looper_pad
looper_pad:
  jsr looper_pad_skip
  tstl %d0
  jeq 1f
  moveq #1,%d0
  rts
1:
  lea %sp@(-76),%sp
  moveml %d2-%d5/%a2-%fp,%sp@
  jmp 0x400c78c8

#NO_APP
	.section	.lp2,"ax",@progbits
	.align	2
	.type	send6, @function
send6:
	moveq #-76,%d0
	link.w %fp,#-8
	move.b 11(%fp),-5(%fp)
	move.b 15(%fp),-4(%fp)
	move.b 19(%fp),-3(%fp)
	move.l #1100088672,-(%sp)
	move.b 23(%fp),-2(%fp)
	move.b 27(%fp),-1(%fp)
	move.b %d0,-6(%fp)
	jsr 1073746108
	moveq #1,%d0
	pea -6(%fp)
	mov3q.l #6,-(%sp)
	move.b %d0,mod_call
	jsr 1073748452
	clr.b %d0
	move.l #1100088672,-(%sp)
	move.b %d0,mod_call
	jsr 1073746414
	lea (16,%sp),%sp
	unlk %fp
	rts
	.size	send6, .-send6
	.align	2
	.type	paint, @function
paint:
	mvz.b looper+1,%d1
	move.l %d2,-(%sp)
	move.l 8(%sp),%d0
	move.l %d0,%a0
	add.l #slot_state,%a0
	muls.w #12,%d1
	mov3q.l #3,%d2
	move.b (%a0,%d1.l),%d1
	subq.l #1,%d1
	mvz.b %d1,%d1
	cmp.l %d1,%d2
	jcs .L7
	lea (CSWTCH.9),%a0
	mvs.b (%a0,%d1.l),%d1
.L3:
	mov3q.l #3,%d2
	cmp.l %d0,%d2
	jlt .L4
	add.l #80,%d0
.L5:
	move.l %d1,-(%sp)
	move.l %d1,-(%sp)
	move.l %d1,-(%sp)
	move.l %d1,-(%sp)
	move.l %d0,-(%sp)
	jsr send6
	lea (20,%sp),%sp
	move.l (%sp)+,%d2
	rts
.L7:
	clr.l %d1
	jra .L3
.L4:
	mov3q.l #7,%d2
	cmp.l %d0,%d2
	jlt .L6
	add.l #72,%d0
	jra .L5
.L6:
	add.l #64,%d0
	jra .L5
	.size	paint, .-paint
	.text
	.align	2
	.type	report, @function
report:
	link.w %fp,#-8
	move.l #-260222380,%d0
	moveq #127,%d1
	move.l %d0,-8(%fp)
	move.b 15(%fp),%d0
	move.b 11(%fp),-4(%fp)
	and.l %d1,%d0
	move.b %d0,-3(%fp)
	move.b 19(%fp),%d0
	and.l %d1,%d0
	mov3q.l #1,%d1
	move.b %d0,-2(%fp)
	moveq #-9,%d0
	move.b %d0,-1(%fp)
	cmp.l 1094562388.l,%d1
	jne .L8
	move.l 1094562704,%a0
	mov3q.l #4,%d0
.L10:
	tst.l %a0
	jeq .L8
	move.l 52(%a0),%a0
	subq.l #1,%d0
	tst.l %d0
	jne .L10
	move.l #1123449384,-(%sp)
	jsr 1073746332
	addq.l #4,%sp
	tst.l %d0
	jeq .L8
	mvz.w #4027,%d0
	cmp.l 1094562392.l,%d0
	jlt .L12
	pea -8(%fp)
	pea 8.w
	jsr 1073752544
	addq.l #8,%sp
.L12:
	move.l #1123449384,-(%sp)
	jsr 1073746414
	addq.l #4,%sp
.L8:
	unlk %fp
	rts
	.size	report, .-report
	.section	.lp3,"ax",@progbits
	.align	2
	.type	paint_all, @function
paint_all:
	lea (-16,%sp),%sp
	movem.l #1052,(%sp)
	clr.l %d2
	tst.b looper.l
	jeq .L31
	lea paint,%a2
.L25:
	move.l %d2,-(%sp)
	jsr (%a2)
	addq.l #1,%d2
	addq.l #4,%sp
	moveq #12,%d0
	cmp.l %d2,%d0
	jne .L25
.L23:
	movem.l (%sp),#1052
	lea (16,%sp),%sp
	rts
.L31:
	lea send6,%a2
.L24:
	mvz.w %d2,%d0
	lsl.l #2,%d0
	move.l %d0,%a0
	add.l #1123774345,%a0
	mvs.b 1(%a0),%d0
	mvs.b 3(%a0),%d4
	mvs.b 2(%a0),%d3
	mvs.b (%a0),%d1
	move.l %d0,%a1
	mov3q.l #3,%d0
	cmp.l %d2,%d0
	jlt .L27
	move.l %d2,%d0
	add.l #80,%d0
.L28:
	move.l %d4,-(%sp)
	move.l %d3,-(%sp)
	move.l %a1,-(%sp)
	move.l %d1,-(%sp)
	move.l %d0,-(%sp)
	jsr (%a2)
	addq.l #1,%d2
	lea (20,%sp),%sp
	moveq #12,%d0
	cmp.l %d2,%d0
	jne .L24
	move.l #1100088672,-(%sp)
	moveq #18,%d2
	jsr 1073746108
	moveq #1,%d0
	addq.l #4,%sp
	move.l #1100088628,%a2
	move.b %d0,mod_call
.L30:
	mvz.b (%a2,%d2.l),%d0
	move.l %d0,-(%sp)
	move.l %d2,-(%sp)
	jsr 1074355124
	addq.l #1,%d2
	addq.l #8,%sp
	moveq #21,%d0
	cmp.l %d2,%d0
	jne .L30
	clr.b %d0
	move.l #1100088672,-(%sp)
	move.b %d0,mod_call
	jsr 1073746414
	addq.l #4,%sp
	jra .L23
.L27:
	mov3q.l #7,%d0
	cmp.l %d2,%d0
	jlt .L29
	move.l %d2,%d0
	add.l #72,%d0
	jra .L28
.L29:
	move.l %d2,%d0
	add.l #64,%d0
	jra .L28
	.size	paint_all, .-paint_all
	.align	2
	.globl	looper_uart_drop
	.type	looper_uart_drop, @function
looper_uart_drop:
	move.l %d2,-(%sp)
	move.l 12(%sp),%a0
	tst.b looper.l
	jne .L36
.L40:
	clr.l %d0
	jra .L35
.L36:
	tst.b mod_call.l
	jne .L40
	mov3q.l #1,%d0
	cmp.l 8(%sp),%d0
	jge .L40
	move.b (%a0),%d0
	mov3q.l #4,%d1
	add.l #80,%d0
	mvz.b %d0,%d0
	cmp.l %d0,%d1
	jcs .L40
	move.b 1(%a0),%d1
	mov3q.l #1,%d0
	moveq #11,%d2
	add.l #-72,%d1
	mvz.b %d1,%d1
	cmp.l %d1,%d2
	jcs .L40
.L35:
	move.l (%sp)+,%d2
	rts
	.size	looper_uart_drop, .-looper_uart_drop
	.align	2
	.globl	looper_sel
	.type	looper_sel, @function
looper_sel:
	move.l %d2,-(%sp)
	move.l 8(%sp),%d0
	move.l 12(%sp),%d1
	tst.b looper.l
	jeq .L42
	tst.b mod_call.l
	jne .L42
	move.l %d0,%a0
	mov3q.l #2,%d2
	lea (-18,%a0),%a0
	cmp.l %a0,%d2
	jcc .L41
.L42:
	move.l %d1,12(%sp)
	move.l %d0,8(%sp)
	move.l (%sp)+,%d2
	jmp 1074355124
.L41:
	move.l (%sp)+,%d2
	rts
	.size	looper_sel, .-looper_sel
	.section	.lp4,"ax",@progbits
	.align	2
	.globl	looper_host
	.type	looper_host, @function
looper_host:
	lea (-12,%sp),%sp
	moveq #8,%d1
	movem.l #1036,(%sp)
	move.l 16(%sp),%a0
	mvz.b 4(%a0),%d0
	cmp.l %d0,%d1
	jne .L45
	move.b mutes_held,%d0
	tst.b 5(%a0)
	jeq .L46
	tst.b %d0
	jne .L47
	moveq #1,%d0
	move.l #-2147422824,%a0
	move.l (%a0),mutes_kept
	move.b %d0,mutes_held
	mvz.w #4095,%d0
.L48:
	moveq #24,%d2
	move.l %d0,%d1
	lsr.l %d2,%d1
	move.l %d0,-2147422824
	move.b %d1,1093765527
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.b %d1,1093765528
	move.l %d0,%d1
	lsr.l #8,%d1
	move.b %d1,1093765529
	move.b %d0,1093765530
.L47:
	movem.l (%sp),#1036
	mov3q.l #1,%d0
	lea (12,%sp),%sp
	rts
.L46:
	tst.b %d0
	jeq .L47
	clr.b %d1
	move.l mutes_kept,%d0
	move.b %d1,mutes_held
	jra .L48
.L45:
	mov3q.l #7,%d3
	cmp.l %d0,%d3
	jne .L47
	cmp.l 20(%sp),%d3
	jge .L47
	mvz.b 5(%a0),%d0
	moveq #95,%d1
	cmp.l %d0,%d1
	jcs .L47
	lea slot_state,%a1
	lea (6,%a0),%a2
	move.b (%a2),(%a1,%d0.l)
	tst.b looper.l
	jeq .L47
	mvz.b 5(%a0),%d0
	moveq #19,%d3
	move.w %d0,%d1
	mulu.w #43691,%d1
	move.l %d1,%d2
	lsr.l %d3,%d2
	move.l %d2,%a0
	mvz.b looper+1,%d2
	cmp.l %d2,%a0
	jne .L47
	move.w %a0,%d1
	muls.w #12,%d1
	sub.l %d1,%d0
	mvz.b %d0,%d0
	move.l %d0,-(%sp)
	jsr paint
	addq.l #4,%sp
	jra .L47
	.size	looper_host, .-looper_host
	.text
	.align	2
	.globl	looper_pad_skip
	.type	looper_pad_skip, @function
looper_pad_skip:
	mvz.b looper,%d0
	rts
	.size	looper_pad_skip, .-looper_pad_skip
	.align	2
	.globl	looper_key
	.type	looper_key, @function
looper_key:
	subq.l #4,%sp
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	move.l 20(%sp),%a1
	mov3q.l #1,%d1
	move.l 16(%sp),8(%sp)
	move.l 12(%a1),%a0
	and.l 16(%a1),%d1
	cmp.l #134,%a0
	jne .L54
	move.b %d1,looper+2
.L55:
	tst.b looper.l
	jeq .L60
	move.l %a0,%d0
	add.l #-66,%d0
	lsr.l #1,%d0
	jne .L60
	tst.l %d1
	jeq .L53
	move.b looper+1,%d0
	moveq #66,%d1
	cmp.l %a0,%d1
	jne .L61
	mvz.b %d0,%d1
	mov3q.l #6,%d2
	cmp.l %d1,%d2
	jcs .L63
	move.l %d0,%d1
	addq.l #1,%d1
.L74:
	move.b %d1,%d0
	move.b %d1,looper+1
.L63:
	mvz.b %d0,%d0
	move.l %d0,-(%sp)
	mov3q.l #1,-(%sp)
	jra .L76
.L54:
	moveq #80,%d2
	cmp.l %a0,%d2
	jne .L56
	tst.l %d1
	jeq .L57
	tst.b looper+2.l
	jeq .L55
	move.b looper,%d0
	mov3q.l #1,%d1
	moveq #1,%d2
	eor.l %d1,%d0
	mvz.b looper+1,%d1
	move.b %d2,looper+3
	move.l %d1,-(%sp)
	move.b %d0,looper
	mvz.b %d0,%d0
	move.l %d0,-(%sp)
.L76:
	mov3q.l #5,-(%sp)
	jsr report
	lea (12,%sp),%sp
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	addq.l #4,%sp
	jra paint_all
.L57:
	tst.b looper+3.l
	jeq .L55
	clr.b %d0
	move.b %d0,looper+3
.L53:
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	addq.l #4,%sp
	rts
.L56:
	move.l %a0,%d2
	moveq #11,%d0
	add.l #-144,%d2
	cmp.l %d2,%d0
	jcs .L55
	mov3q.l #1,%d0
	lsl.l %d2,%d0
	tst.l %d1
	jeq .L59
	tst.b looper.l
	jeq .L60
	move.w looper+4,%d1
	mov3q.l #1,-(%sp)
	or.l %d1,%d0
	move.w %d0,looper+4
.L75:
	move.b looper+1,%d0
	muls.w #12,%d0
	lea 112(%a0,%d0.l),%a0
	move.l %a0,%d0
	mvz.b %d0,%d0
	move.l %d0,-(%sp)
	mov3q.l #6,-(%sp)
	jsr report
	lea (12,%sp),%sp
	jra .L53
.L59:
	move.w looper+4,%d2
	move.l %d0,%d3
	and.l %d2,%d3
	tst.w %d3
	jeq .L55
	not.l %d0
	and.l %d2,%d0
	clr.l -(%sp)
	move.w %d0,looper+4
	jra .L75
.L61:
	tst.b %d0
	jeq .L63
	move.l %d0,%d1
	subq.l #1,%d1
	jra .L74
.L60:
	move.l %a1,20(%sp)
	move.l 8(%sp),16(%sp)
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	addq.l #4,%sp
	jmp 1074398006
	.size	looper_key, .-looper_key
	.text
	.type	CSWTCH.9, @object
	.size	CSWTCH.9, 4
CSWTCH.9:
	.byte	63
	.byte	15
	.byte	47
	.byte	43
	.globl	mutes_kept
	.section	.lps,"aw"
	.align	2
	.type	mutes_kept, @object
	.size	mutes_kept, 4
mutes_kept:
	.zero	4
	.globl	mutes_held
	.type	mutes_held, @object
	.size	mutes_held, 1
mutes_held:
	.zero	1
	.globl	mod_call
	.type	mod_call, @object
	.size	mod_call, 1
mod_call:
	.zero	1
	.globl	slot_state
	.type	slot_state, @object
	.size	slot_state, 96
slot_state:
	.zero	96
	.globl	looper
	.align	2
	.type	looper, @object
	.size	looper, 8
looper:
	.zero	8
	.ident	"GCC: (GNU) 16.2.0"
	.else
#NO_APP
	.file	"looper.c"
	.text
#APP
	  .section .lp2,"ax"
  .globl looper_uart
looper_uart:
  movel %sp@(8),%sp@-
  movel %sp@(8),%sp@-
  jsr looper_uart_drop
  addql #8,%sp
  tstl %d0
  jeq 1f
  rts
1:
  lea %sp@(-12),%sp
  moveml %d2-%d4,%sp@
  jmp 0x400019ec

	  .text
  .globl looper_pad
looper_pad:
  jsr looper_pad_skip
  tstl %d0
  jeq 1f
  moveq #1,%d0
  rts
1:
  lea %sp@(-76),%sp
  moveml %d2-%d5/%a2-%fp,%sp@
  jmp 0x400c78c8

#NO_APP
	.section	.lp2,"ax",@progbits
	.align	2
	.type	send6, @function
send6:
	moveq #-76,%d0
	link.w %fp,#-8
	move.b 11(%fp),-5(%fp)
	move.b 15(%fp),-4(%fp)
	move.b 19(%fp),-3(%fp)
	move.l #1100088672,-(%sp)
	move.b 23(%fp),-2(%fp)
	move.b 27(%fp),-1(%fp)
	move.b %d0,-6(%fp)
	jsr 1073746108
	moveq #1,%d0
	pea -6(%fp)
	mov3q.l #6,-(%sp)
	move.b %d0,mod_call
	jsr 1073748452
	clr.b %d0
	move.l #1100088672,-(%sp)
	move.b %d0,mod_call
	jsr 1073746414
	lea (16,%sp),%sp
	unlk %fp
	rts
	.size	send6, .-send6
	.align	2
	.type	paint, @function
paint:
	mvz.b looper+1,%d1
	move.l %d2,-(%sp)
	move.l 8(%sp),%d0
	move.l %d0,%a0
	add.l #slot_state,%a0
	muls.w #12,%d1
	mov3q.l #3,%d2
	move.b (%a0,%d1.l),%d1
	subq.l #1,%d1
	mvz.b %d1,%d1
	cmp.l %d1,%d2
	jcs .L7
	lea (CSWTCH.9),%a0
	mvs.b (%a0,%d1.l),%d1
.L3:
	mov3q.l #3,%d2
	cmp.l %d0,%d2
	jlt .L4
	add.l #80,%d0
.L5:
	move.l %d1,-(%sp)
	move.l %d1,-(%sp)
	move.l %d1,-(%sp)
	move.l %d1,-(%sp)
	move.l %d0,-(%sp)
	jsr send6
	lea (20,%sp),%sp
	move.l (%sp)+,%d2
	rts
.L7:
	clr.l %d1
	jra .L3
.L4:
	mov3q.l #7,%d2
	cmp.l %d0,%d2
	jlt .L6
	add.l #72,%d0
	jra .L5
.L6:
	add.l #64,%d0
	jra .L5
	.size	paint, .-paint
	.text
	.align	2
	.type	report, @function
report:
	link.w %fp,#-8
	move.l #-260222380,%d0
	moveq #127,%d1
	move.l %d0,-8(%fp)
	move.b 15(%fp),%d0
	move.b 11(%fp),-4(%fp)
	and.l %d1,%d0
	move.b %d0,-3(%fp)
	move.b 19(%fp),%d0
	and.l %d1,%d0
	move.b %d0,-2(%fp)
	moveq #-9,%d0
	move.b %d0,-1(%fp)
	mov3q.l #4,%d0
	move.l 1094562704,%a0
.L10:
	tst.l %a0
	jeq .L8
	move.l 52(%a0),%a0
	subq.l #1,%d0
	tst.l %d0
	jne .L10
	jsr 1073752340
	pea -8(%fp)
	pea 8.w
	jsr 1073752544
	jsr 1073752356
	addq.l #8,%sp
.L8:
	unlk %fp
	rts
	.size	report, .-report
	.section	.lp3,"ax",@progbits
	.align	2
	.type	paint_all, @function
paint_all:
	lea (-16,%sp),%sp
	movem.l #1052,(%sp)
	clr.l %d2
	tst.b looper.l
	jeq .L24
	lea paint,%a2
.L18:
	move.l %d2,-(%sp)
	jsr (%a2)
	addq.l #1,%d2
	addq.l #4,%sp
	moveq #12,%d0
	cmp.l %d2,%d0
	jne .L18
.L16:
	movem.l (%sp),#1052
	lea (16,%sp),%sp
	rts
.L24:
	lea send6,%a2
.L17:
	mvz.w %d2,%d0
	lsl.l #2,%d0
	move.l %d0,%a0
	add.l #1123774345,%a0
	mvs.b 1(%a0),%d0
	mvs.b 3(%a0),%d4
	mvs.b 2(%a0),%d3
	mvs.b (%a0),%d1
	move.l %d0,%a1
	mov3q.l #3,%d0
	cmp.l %d2,%d0
	jlt .L20
	move.l %d2,%d0
	add.l #80,%d0
.L21:
	move.l %d4,-(%sp)
	move.l %d3,-(%sp)
	move.l %a1,-(%sp)
	move.l %d1,-(%sp)
	move.l %d0,-(%sp)
	jsr (%a2)
	addq.l #1,%d2
	lea (20,%sp),%sp
	moveq #12,%d0
	cmp.l %d2,%d0
	jne .L17
	move.l #1100088672,-(%sp)
	moveq #18,%d2
	jsr 1073746108
	moveq #1,%d0
	addq.l #4,%sp
	move.l #1100088628,%a2
	move.b %d0,mod_call
.L23:
	mvz.b (%a2,%d2.l),%d0
	move.l %d0,-(%sp)
	move.l %d2,-(%sp)
	jsr 1074355124
	addq.l #1,%d2
	addq.l #8,%sp
	moveq #21,%d0
	cmp.l %d2,%d0
	jne .L23
	clr.b %d0
	move.l #1100088672,-(%sp)
	move.b %d0,mod_call
	jsr 1073746414
	addq.l #4,%sp
	jra .L16
.L20:
	mov3q.l #7,%d0
	cmp.l %d2,%d0
	jlt .L22
	move.l %d2,%d0
	add.l #72,%d0
	jra .L21
.L22:
	move.l %d2,%d0
	add.l #64,%d0
	jra .L21
	.size	paint_all, .-paint_all
	.align	2
	.globl	looper_uart_drop
	.type	looper_uart_drop, @function
looper_uart_drop:
	move.l %d2,-(%sp)
	move.l 12(%sp),%a0
	tst.b looper.l
	jne .L29
.L33:
	clr.l %d0
	jra .L28
.L29:
	tst.b mod_call.l
	jne .L33
	mov3q.l #1,%d0
	cmp.l 8(%sp),%d0
	jge .L33
	move.b (%a0),%d0
	mov3q.l #4,%d1
	add.l #80,%d0
	mvz.b %d0,%d0
	cmp.l %d0,%d1
	jcs .L33
	move.b 1(%a0),%d1
	mov3q.l #1,%d0
	moveq #11,%d2
	add.l #-72,%d1
	mvz.b %d1,%d1
	cmp.l %d1,%d2
	jcs .L33
.L28:
	move.l (%sp)+,%d2
	rts
	.size	looper_uart_drop, .-looper_uart_drop
	.align	2
	.globl	looper_sel
	.type	looper_sel, @function
looper_sel:
	move.l %d2,-(%sp)
	move.l 8(%sp),%d0
	move.l 12(%sp),%d1
	tst.b looper.l
	jeq .L35
	tst.b mod_call.l
	jne .L35
	move.l %d0,%a0
	mov3q.l #2,%d2
	lea (-18,%a0),%a0
	cmp.l %a0,%d2
	jcc .L34
.L35:
	move.l %d1,12(%sp)
	move.l %d0,8(%sp)
	move.l (%sp)+,%d2
	jmp 1074355124
.L34:
	move.l (%sp)+,%d2
	rts
	.size	looper_sel, .-looper_sel
	.section	.lp4,"ax",@progbits
	.align	2
	.globl	looper_host
	.type	looper_host, @function
looper_host:
	lea (-12,%sp),%sp
	moveq #8,%d1
	movem.l #1036,(%sp)
	move.l 16(%sp),%a0
	mvz.b 4(%a0),%d0
	cmp.l %d0,%d1
	jne .L38
	move.b mutes_held,%d0
	tst.b 5(%a0)
	jeq .L39
	tst.b %d0
	jne .L40
	moveq #1,%d0
	move.l #-2147422824,%a0
	move.l (%a0),mutes_kept
	move.b %d0,mutes_held
	mvz.w #4095,%d0
.L41:
	moveq #24,%d2
	move.l %d0,%d1
	lsr.l %d2,%d1
	move.l %d0,-2147422824
	move.b %d1,1093765527
	move.l %d0,%d1
	clr.w %d1
	swap %d1
	move.b %d1,1093765528
	move.l %d0,%d1
	lsr.l #8,%d1
	move.b %d1,1093765529
	move.b %d0,1093765530
.L40:
	movem.l (%sp),#1036
	mov3q.l #1,%d0
	lea (12,%sp),%sp
	rts
.L39:
	tst.b %d0
	jeq .L40
	clr.b %d1
	move.l mutes_kept,%d0
	move.b %d1,mutes_held
	jra .L41
.L38:
	mov3q.l #7,%d3
	cmp.l %d0,%d3
	jne .L40
	cmp.l 20(%sp),%d3
	jge .L40
	mvz.b 5(%a0),%d0
	moveq #95,%d1
	cmp.l %d0,%d1
	jcs .L40
	lea slot_state,%a1
	lea (6,%a0),%a2
	move.b (%a2),(%a1,%d0.l)
	tst.b looper.l
	jeq .L40
	mvz.b 5(%a0),%d0
	moveq #19,%d3
	move.w %d0,%d1
	mulu.w #43691,%d1
	move.l %d1,%d2
	lsr.l %d3,%d2
	move.l %d2,%a0
	mvz.b looper+1,%d2
	cmp.l %d2,%a0
	jne .L40
	move.w %a0,%d1
	muls.w #12,%d1
	sub.l %d1,%d0
	mvz.b %d0,%d0
	move.l %d0,-(%sp)
	jsr paint
	addq.l #4,%sp
	jra .L40
	.size	looper_host, .-looper_host
	.text
	.align	2
	.globl	looper_pad_skip
	.type	looper_pad_skip, @function
looper_pad_skip:
	mvz.b looper,%d0
	rts
	.size	looper_pad_skip, .-looper_pad_skip
	.align	2
	.globl	looper_key
	.type	looper_key, @function
looper_key:
	subq.l #4,%sp
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	move.l 20(%sp),%a1
	mov3q.l #1,%d1
	move.l 16(%sp),8(%sp)
	move.l 12(%a1),%a0
	and.l 16(%a1),%d1
	cmp.l #134,%a0
	jne .L47
	move.b %d1,looper+2
.L48:
	tst.b looper.l
	jeq .L53
	move.l %a0,%d0
	add.l #-66,%d0
	lsr.l #1,%d0
	jne .L53
	tst.l %d1
	jeq .L46
	move.b looper+1,%d0
	moveq #66,%d1
	cmp.l %a0,%d1
	jne .L54
	mvz.b %d0,%d1
	mov3q.l #6,%d2
	cmp.l %d1,%d2
	jcs .L56
	move.l %d0,%d1
	addq.l #1,%d1
.L67:
	move.b %d1,%d0
	move.b %d1,looper+1
.L56:
	mvz.b %d0,%d0
	move.l %d0,-(%sp)
	mov3q.l #1,-(%sp)
	jra .L69
.L47:
	moveq #80,%d2
	cmp.l %a0,%d2
	jne .L49
	tst.l %d1
	jeq .L50
	tst.b looper+2.l
	jeq .L48
	move.b looper,%d0
	mov3q.l #1,%d1
	moveq #1,%d2
	eor.l %d1,%d0
	mvz.b looper+1,%d1
	move.b %d2,looper+3
	move.l %d1,-(%sp)
	move.b %d0,looper
	mvz.b %d0,%d0
	move.l %d0,-(%sp)
.L69:
	mov3q.l #5,-(%sp)
	jsr report
	lea (12,%sp),%sp
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	addq.l #4,%sp
	jra paint_all
.L50:
	tst.b looper+3.l
	jeq .L48
	clr.b %d0
	move.b %d0,looper+3
.L46:
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	addq.l #4,%sp
	rts
.L49:
	move.l %a0,%d2
	moveq #11,%d0
	add.l #-144,%d2
	cmp.l %d2,%d0
	jcs .L48
	mov3q.l #1,%d0
	lsl.l %d2,%d0
	tst.l %d1
	jeq .L52
	tst.b looper.l
	jeq .L53
	move.w looper+4,%d1
	mov3q.l #1,-(%sp)
	or.l %d1,%d0
	move.w %d0,looper+4
.L68:
	move.b looper+1,%d0
	muls.w #12,%d0
	lea 112(%a0,%d0.l),%a0
	move.l %a0,%d0
	mvz.b %d0,%d0
	move.l %d0,-(%sp)
	mov3q.l #6,-(%sp)
	jsr report
	lea (12,%sp),%sp
	jra .L46
.L52:
	move.w looper+4,%d2
	move.l %d0,%d3
	and.l %d2,%d3
	tst.w %d3
	jeq .L48
	not.l %d0
	and.l %d2,%d0
	clr.l -(%sp)
	move.w %d0,looper+4
	jra .L68
.L54:
	tst.b %d0
	jeq .L56
	move.l %d0,%d1
	subq.l #1,%d1
	jra .L67
.L53:
	move.l %a1,20(%sp)
	move.l 8(%sp),16(%sp)
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	addq.l #4,%sp
	jmp 1074398006
	.size	looper_key, .-looper_key
	.text
	.type	CSWTCH.9, @object
	.size	CSWTCH.9, 4
CSWTCH.9:
	.byte	63
	.byte	15
	.byte	47
	.byte	43
	.globl	mutes_kept
	.section	.lps,"aw"
	.align	2
	.type	mutes_kept, @object
	.size	mutes_kept, 4
mutes_kept:
	.zero	4
	.globl	mutes_held
	.type	mutes_held, @object
	.size	mutes_held, 1
mutes_held:
	.zero	1
	.globl	mod_call
	.type	mod_call, @object
	.size	mod_call, 1
mod_call:
	.zero	1
	.globl	slot_state
	.type	slot_state, @object
	.size	slot_state, 96
slot_state:
	.zero	96
	.globl	looper
	.align	2
	.type	looper, @object
	.size	looper, 8
looper:
	.zero	8
	.ident	"GCC: (GNU) 16.2.0"
	.endif
