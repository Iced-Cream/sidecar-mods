| Mod 0023 - teensy-drive: the Sidecar's card as a folder SIDECAR in the file browser, a client of the companion.
| GENERATED from teensy_drive.c by build.sh (m68k-elf-gcc -mcpu=5475 -Os); edit that.
	.include "symbols.inc"
#NO_APP
	.file	"teensy_drive.c"
	.text
#APP
	  .pushsection .td,"ax"
  .align 2
  .globl td_readdir_entry
td_readdir_entry:
  jmp td_readdir
  .globl td_readdir_stock
td_readdir_stock:
  lea %sp@(-24),%sp
  moveml %d2-%d5/%a2-%a3,%sp@
  jmp 0x4007c0bc
  .globl td_resolve_entry
td_resolve_entry:
  jmp td_resolve
  .globl td_resolve_stock
td_resolve_stock:
  lea %sp@(-16),%sp
  moveml %d2-%d3/%a2-%a3,%sp@
  jmp 0x4008050c
  .globl td_exists_entry
td_exists_entry:
  jmp td_exists
  .globl td_exists_stock
td_exists_stock:
  movel %d2,%sp@-
  movel %sp@(8),%d1
  jmp 0x400807d8
  .globl td_size_entry
td_size_entry:
  jmp td_size
  .globl td_size_stock
td_size_stock:
  lea %sp@(-32),%sp
  moveml %d2-%d5/%a2,%sp@
  jmp 0x40080918
td_tname:
  lea td_teensy,%a1
1:
  moveb %a1@+,%d1
  jeq 2f
  moveb %a0@+,%d0
  oril #0x20,%d0
  oril #0x20,%d1
  cmpb %d1,%d0
  jeq 1b
3:
  moveq #0,%d0
  rts
2:
  moveb %a0@,%d0
  jeq 4f
  cmpib #47,%d0
  jne 3b
4:
  moveq #-1,%d0
  rts
  .globl td_link_entry
td_link_entry:
  moveq #2,%d0
  cmpl %sp@(4),%d0
  jne 5f
  moveal %sp@(8),%a0
  bsr td_tname
  jne 6f
5:
  lea %sp@(-56),%sp
  moveml %d2-%d7/%a2-%fp,%sp@
  jmp 0x4007b424
  .globl td_mkdir_entry
td_mkdir_entry:
  movel %sp@(4),%d0
  jeq 7f
  moveal %d0,%a0
  moveb %a0@+,%d0
  cmpib #47,%d0
  jne 7f
  bsr td_tname
  jeq 7f
6:
  moveq #-1,%d0
  rts
7:
  linkw %fp,#-24
  moveml %d2-%d3/%a2-%a3,%sp@
  jmp 0x4007c1e4
  .globl td_count_entry
td_count_entry:
  jmp td_count
  .globl td_count_stock
td_count_stock:
  movel %a2,%sp@-
  movel %d2,%sp@-
  tstl 0x41843c70
  jmp 0x400808c0
  .globl td_ref_entry
td_ref_entry:
  movel %a0,%sp@-
  movel %sp@(12),%sp@-
  movel %sp@(12),%sp@-
  movel %sp@(8),%sp@-
  jsr td_ref
  lea %sp@(12),%sp
  moveal %sp@+,%a0
  tstl %d0
  jeq 1f
  movel %a0,%d0
  rts
1:
  linkw %fp,#-16
  moveal %fp@(8),%a1
  jmp 0x4007e6a0
  .popsection
  .pushsection .td3,"ax"
  .align 2
  .globl td_path_entry
td_path_entry:
  movel %sp@(4),%d0
  andil #0xFF000000,%d0
  cmpil #0x7E000000,%d0
  jne 1f
  moveq #0,%d0
  rts
1:
  lea %sp@(-324),%sp
  moveml %d2-%d7/%a2-%fp,%sp@
  jmp 0x4007c648
  .globl td_check_entry
td_check_entry:
  movel %sp@(4),%d0
  jeq 1f
  moveal %d0,%a0
  movel %a0@,%d0
  andil #0xFF000000,%d0
  cmpil #0x7E000000,%d0
  jne 1f
  moveq #-1,%d0
  rts
1:
  lea %sp@(-24),%sp
  moveml %d2/%a2-%fp,%sp@
  jmp 0x40080068
  .globl td_mkdir_guard
td_mkdir_guard:
  movel %a4@(4),%d0
  jeq 1f
  moveal %d0,%a0
  tstb %a0@
  jne 2f
1:
  moveq #-1,%d0
  rts
2:
  jmp 0x4007c1dc
  .popsection

	  .pushsection .td3,"ax"
  .align 2
  .globl td_load_entry
td_load_entry:
  moveal %sp@(8),%a0
  movel %a0@,%d0
  cmpil #0x7E504F4F,%d0
  jne 2f
  moveq #1,%d0
  rts
2:
  andil #0xFF000000,%d0
  cmpil #0x7E000000,%d0
  jne 3f
  moveq #0,%d0
  rts
3:
  linkw %fp,#-28
  moveml %d2-%d4/%a2,%sp@
  jmp 0x400b71a2
  .popsection

#NO_APP
	.align	2
	.type	td_name, @function
td_name:
	move.l 4(%sp),%a0
	clr.l %d0
	move.l 8(%sp),%a1
.L2:
	move.b (%a1,%d0.l),%d1
	jeq .L3
	move.b %d1,(%a0,%d0.l)
	addq.l #1,%d0
	cmp.l #255,%d0
	jne .L2
.L3:
	clr.b %d1
	move.b %d1,(%a0,%d0.l)
	rts
	.size	td_name, .-td_name
	.align	2
	.type	td_file_size, @function
td_file_size:
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	move.l 12(%sp),%d0
	tst.b td_cache+8.l
	jeq .L15
	moveq #12,%d3
	move.l %d0,%d1
	lsr.l %d3,%d1
	mvz.w td_cache,%d2
	and.l #1023,%d1
	cmp.l %d2,%d1
	jne .L15
	move.l %d0,%d1
	clr.l %d0
	and.l #4095,%d1
	mvz.w td_cache+6,%d2
	lea td_ents,%a0
	move.l %a0,%a1
.L10:
	cmp.l %d2,%d0
	jcc .L15
	cmp.l #512,%d0
	jne .L12
.L15:
	clr.l %d0
	jra .L8
.L12:
	tst.b (%a0)
	jne .L11
	mvz.w 2(%a0),%d3
	cmp.l %d3,%d1
	jne .L11
	lsl.l #5,%d0
	move.l 4(%a1,%d0.l),%d0
.L8:
	move.l (%sp)+,%d2
	move.l (%sp)+,%d3
	rts
.L11:
	addq.l #1,%d0
	lea (32,%a0),%a0
	jra .L10
	.size	td_file_size, .-td_file_size
	.align	2
	.globl	td_tick
	.type	td_tick, @function
td_tick:
	move.l td_now,%d0
	addq.l #1,%d0
	move.l %d0,td_now
	rts
	.size	td_tick, .-td_tick
	.align	2
	.globl	td_ask
	.type	td_ask, @function
td_ask:
	link.w %fp,#-8
	move.l #-260222380,%d1
	move.l %d2,-(%sp)
	moveq #13,%d2
	move.l %d1,-8(%fp)
	move.l 8(%fp),%d0
	move.l %d0,%d1
	lsr.l #7,%d1
	lea (12,%fp),%a0
	move.w %d0,td_cache
	move.l (%a0),td_cache+12
	pea -8(%fp)
	pea 8.w
	move.b %d2,-4(%fp)
	moveq #127,%d2
	and.l %d2,%d1
	move.l #-65536,%d2
	move.l %d2,td_cache+4
	move.b %d1,-3(%fp)
	moveq #127,%d1
	and.l %d0,%d1
	clr.b %d0
	move.b %d1,-2(%fp)
	moveq #-9,%d1
	move.b %d0,td_cache+8
	move.b %d1,-1(%fp)
	jsr core_midi_try_send
	move.l -12(%fp),%d2
	addq.l #8,%sp
	unlk %fp
	rts
	.size	td_ask, .-td_ask
	.align	2
	.globl	td_sysex
	.type	td_sysex, @function
td_sysex:
	lea (-36,%sp),%sp
	moveq #13,%d0
	movem.l #7420,(%sp)
	move.l 44(%sp),%d3
	move.l 40(%sp),%a0
	cmp.l %d3,%d0
	jge .L31
	mvz.b 4(%a0),%d0
	moveq #14,%d1
	cmp.l %d0,%d1
	jne .L31
	mvz.b 5(%a0),%d0
	mvz.b 6(%a0),%d2
	mvz.w td_cache,%d1
	lsl.l #7,%d0
	or.l %d2,%d0
	cmp.l %d1,%d0
	jeq .L20
.L29:
	mov3q.l #1,%d0
.L18:
	movem.l (%sp),#7420
	lea (36,%sp),%sp
	rts
.L20:
	mvz.b 9(%a0),%d1
	mvz.b 7(%a0),%d2
	mvz.b 10(%a0),%d0
	clr.b %d4
	lsl.l #7,%d1
	lsl.l #7,%d2
	or.l %d0,%d1
	mvz.b 8(%a0),%d0
	move.b %d4,td_cache+9
	or.l %d2,%d0
	mvz.b 12(%a0),%d2
	and.l #1023,%d0
	move.w %d0,td_cache+2
	mvz.b 11(%a0),%d0
	lsl.l #7,%d0
	or.l %d2,%d0
	cmp.l #512,%d0
	jls .L21
	mvz.w #512,%d0
.L21:
	move.w %d0,td_cache+4
	move.l %d1,%d0
	subq.l #1,%d3
	lsl.l #5,%d0
	move.l #td_ents,%d5
	move.l %d0,%a1
	moveq #13,%d0
	add.l #td_ents,%a1
.L22:
	move.l %d0,%d2
	addq.l #7,%d2
	cmp.l %d2,%d3
	jgt .L28
.L23:
	moveq #1,%d1
	move.b %d1,td_cache+8
	jra .L29
.L28:
	cmp.l #511,%d1
	jhi .L23
	move.b (%a0,%d0.l),(%a1)
	moveq #21,%d6
	moveq #14,%d7
	sub.l %a2,%a2
	mvz.b 1(%a0,%d0.l),%d4
	mvz.b 2(%a0,%d0.l),%d2
	lsl.l #7,%d4
	or.l %d4,%d2
	move.w %d2,2(%a1)
	mvz.b 3(%a0,%d0.l),%d2
	mvz.b 4(%a0,%d0.l),%d4
	lsl.l %d6,%d2
	move.l %d1,%d6
	lsl.l %d7,%d4
	lsl.l #5,%d6
	or.l %d4,%d2
	mvz.b 6(%a0,%d0.l),%d4
	move.l %d6,%a3
	sub.l %d0,%a3
	add.l #td_ents,%a3
	or.l %d4,%d2
	mvz.b 5(%a0,%d0.l),%d4
	lsl.l #7,%d4
	or.l %d4,%d2
	move.l %d2,4(%a1)
	mvz.b 7(%a0,%d0.l),%d4
	move.l %d0,%d2
	addq.l #8,%d2
	move.l %d2,%d0
.L24:
	cmp.l %a2,%d4
	jls .L25
	moveq #23,%d7
	cmp.l %a2,%d7
	jeq .L25
	cmp.l %d3,%d0
	jlt .L26
.L25:
	clr.b %d0
	move.l %d5,%a3
	add.l %d6,%a3
	addq.l #1,%d1
	move.b %d0,8(%a2,%a3.l)
	move.l %d4,%d0
	add.l %d2,%d0
	mvz.w td_cache+6,%d2
	cmp.l %d1,%d2
	jcc .L27
	move.w %d1,td_cache+6
.L27:
	lea (32,%a1),%a1
	jra .L22
.L26:
	lea (%a0,%d0.l),%a4
	addq.l #1,%a2
	move.b (%a4),(%a3,%d0.l)
	addq.l #1,%d0
	jra .L24
.L31:
	clr.l %d0
	jra .L18
	.size	td_sysex, .-td_sysex
	.align	2
	.globl	td_readdir
	.type	td_readdir, @function
td_readdir:
	lea (-48,%sp),%sp
	movem.l #7180,(%sp)
	move.l 52(%sp),%a3
	move.l 56(%sp),%a2
	tst.l %a3
	jeq .L64
	tst.l %a2
	jeq .L64
	move.l (%a3),%d1
	move.l %d1,%d0
	and.l #-16777216,%d0
	cmp.l #2113929216,%d0
	jne .L37
	move.l 12(%a3),%d0
	move.l %d1,%d2
	move.l %d0,%d3
	addq.l #1,%d3
	and.l #1023,%d2
	move.l %d3,12(%a3)
	tst.l %d0
	jne .L38
	move.l td_now,%d3
	lea td_cache,%a4
	tst.b td_cache+8.l
	jeq .L39
	mvz.w (%a4),%d0
	cmp.l %d2,%d0
	jne .L39
	mvz.w td_cache+6,%d1
	mvz.w td_cache+4,%d0
	cmp.l %d1,%d0
	jls .L40
.L39:
	jsr core_usb_midi_up
	tst.l %d0
	jne .L41
	mvz.w (%a4),%d0
	cmp.l %d2,%d0
	jeq .L40
	clr.b %d0
	move.w %d2,(%a4)
	clr.l td_cache+4
	move.b %d0,td_cache+8
.L40:
	moveq #1,%d1
	move.l (%a3),%d0
	clr.l 16(%a2)
	clr.l 12(%a2)
	move.l %d0,(%a2)
	move.l %d0,8(%a2)
	move.w %d1,4(%a2)
	pea td_dot
.L79:
	pea 20(%a2)
	jsr td_name
.L77:
	addq.l #8,%sp
.L50:
	mov3q.l #1,%d0
	jra .L35
.L41:
	tst.b td_cache+9.l
	jeq .L43
	move.l %d3,%d0
	sub.l td_cache+16,%d0
	cmp.l #1199,%d0
	jhi .L43
	move.l %d3,%d0
	moveq #20,%d1
	sub.l td_cache+12,%d0
	cmp.l %d0,%d1
	jcs .L44
	mvz.w (%a4),%d0
	cmp.l %d2,%d0
	jeq .L40
.L44:
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	jsr td_ask
	addq.l #8,%sp
	jra .L40
.L43:
	mvz.w (%a4),%d0
	cmp.l %d2,%d0
	jne .L45
	tst.b td_cache+8.l
	jne .L45
	mvz.w td_cache+4,%d0
	cmp.l #65535,%d0
	jeq .L46
.L45:
	move.l %d3,-(%sp)
	move.l %d2,-(%sp)
	jsr td_ask
	addq.l #8,%sp
.L46:
	sub.l td_cache+12,%d3
	move.l %d3,%d0
	lsl.l #2,%d0
	add.l %d0,%d3
.L47:
	moveq #39,%d0
	cmp.l %d3,%d0
	jcc .L49
	moveq #1,%d1
	clr.w %d3
	move.l td_now,%d0
	move.l %d0,td_cache+16
	move.b %d1,td_cache+9
	move.w %d3,td_cache+4
	jra .L40
.L49:
	pea 10000.w
	jsr 1074367620
	addq.l #4,%sp
	tst.b td_cache+8.l
	jeq .L48
	mvz.w (%a4),%d0
	cmp.l %d2,%d0
	jne .L48
	mvz.w td_cache+6,%d1
	mvz.w td_cache+4,%d0
	cmp.l %d1,%d0
	jls .L40
.L48:
	addq.l #1,%d3
	jra .L47
.L38:
	mov3q.l #1,%d3
	cmp.l %d0,%d3
	jne .L51
	tst.l %d2
	jeq .L67
	tst.b td_cache+8.l
	jeq .L67
	mvz.w td_cache,%d0
	cmp.l %d2,%d0
	jne .L67
	mvz.w td_cache+2,%d0
	or.l #2113929216,%d0
.L52:
	move.l %d0,(%a2)
	moveq #1,%d0
	move.l %d1,8(%a2)
	clr.l 16(%a2)
	clr.l 12(%a2)
	move.w %d0,4(%a2)
	pea td_dotdot
	jra .L79
.L67:
	mov3q.l #2,%d0
	jra .L52
.L51:
	tst.b td_cache+8.l
	jne .L53
.L54:
	clr.l %d0
.L35:
	movem.l (%sp),#7180
	lea (48,%sp),%sp
	rts
.L53:
	mvz.w td_cache,%d3
	cmp.l %d2,%d3
	jne .L54
	mvz.w td_cache+6,%d3
	subq.l #2,%d0
	cmp.l %d0,%d3
	jls .L54
	cmp.l #511,%d0
	jhi .L54
	lsl.l #5,%d0
	sub.l %a0,%a0
	lea (23,%sp),%a1
	move.l %d0,%a3
	add.l #td_ents,%a3
.L55:
	move.b 8(%a3,%a0.l),%d3
	jeq .L56
	move.b %d3,(%a1,%a0.l)
	addq.l #1,%a0
	moveq #24,%d3
	cmp.l %a0,%d3
	jne .L55
.L56:
	clr.b %d3
	lea td_ents,%a4
	lea (20,%a2),%a3
	move.b %d3,23(%sp,%a0.l)
	move.w 2(%a4,%d0.l),%d3
	lea td_name,%a0
	tst.b (%a4,%d0.l)
	jeq .L58
	and.l #1023,%d3
	moveq #1,%d0
	or.l #2113929216,%d3
	move.w %d0,4(%a2)
	move.l %d3,(%a2)
.L78:
	move.l %d1,8(%a2)
	clr.l 16(%a2)
	clr.l 12(%a2)
	move.l %a1,-(%sp)
	move.l %a3,-(%sp)
	jsr (%a0)
	jra .L77
.L58:
	moveq #12,%d0
	and.l #4095,%d3
	lsl.l %d0,%d2
	or.l %d3,%d2
	clr.w %d3
	or.l #2122317824,%d2
	move.w %d3,4(%a2)
	move.l %d2,(%a2)
	jra .L78
.L37:
	subq.l #2,%d1
	tst.l %d1
	jne .L60
	move.l #2122219134,%d1
	cmp.l 12(%a3),%d1
	jeq .L54
.L60:
	move.l %a2,-(%sp)
	move.l %a3,-(%sp)
	jsr td_readdir_stock
	addq.l #8,%sp
	tst.l %d0
	jne .L35
	mov3q.l #2,%d3
	cmp.l (%a3),%d3
	jne .L54
	moveq #1,%d0
	move.l #2113929216,(%a2)
	mov3q.l #2,8(%a2)
	clr.l 16(%a2)
	clr.l 12(%a2)
	move.w %d0,4(%a2)
	pea td_teensy
	pea 20(%a2)
	jsr td_name
	move.l td_now,%d2
	move.l #2122219134,%d1
	move.l %d1,12(%a3)
	jsr core_usb_midi_up
	addq.l #8,%sp
	tst.l %d0
	jeq .L50
	tst.b td_cache+9.l
	jeq .L61
	move.l %d2,%d0
	sub.l td_cache+16,%d0
	cmp.l #1199,%d0
	jls .L50
.L61:
	tst.w td_cache.l
	jne .L62
	tst.b td_cache+8.l
	jne .L50
	mvz.w td_cache+4,%d0
	cmp.l #65535,%d0
	jne .L62
	move.l %d2,%d0
	sub.l td_cache+12,%d0
	lsr.l #3,%d0
	jeq .L50
.L62:
	move.l %d2,-(%sp)
	clr.l -(%sp)
	jsr td_ask
	jra .L77
.L64:
	mov3q.l #-1,%d0
	jra .L35
	.size	td_readdir, .-td_readdir
	.align	2
	.globl	td_resolve
	.type	td_resolve, @function
td_resolve:
	move.l 4(%sp),%d1
	move.l %d1,%d0
	and.l #-16777216,%d0
	cmp.l #2113929216,%d0
	jne .L81
	lea td_dir_node,%a0
	btst #23,%d1
	jeq .L80
	move.l %d1,-(%sp)
	jsr td_file_size
	addq.l #4,%sp
	lea td_file_node,%a0
	move.l %d0,td_file_node+8
	move.l %d0,td_file_node+4
.L80:
	move.l %a0,%d0
	rts
.L81:
	move.l %d1,4(%sp)
	jra td_resolve_stock
	.size	td_resolve, .-td_resolve
	.align	2
	.globl	td_exists
	.type	td_exists, @function
td_exists:
	move.l 4(%sp),%d0
	move.l %d0,%d1
	and.l #-16777216,%d1
	cmp.l #2113929216,%d1
	jeq .L85
	move.l %d0,4(%sp)
	jra td_exists_stock
.L85:
	mov3q.l #1,%d0
	rts
	.size	td_exists, .-td_exists
	.align	2
	.globl	td_size
	.type	td_size, @function
td_size:
	move.l 4(%sp),%d0
	move.l %d0,%d1
	and.l #-16777216,%d1
	cmp.l #2113929216,%d1
	jne .L87
	btst #23,%d0
	jeq .L88
	move.l %d0,4(%sp)
	jra td_file_size
.L87:
	move.l %d0,4(%sp)
	jra td_size_stock
.L88:
	mov3q.l #-1,%d0
	rts
	.size	td_size, .-td_size
	.align	2
	.globl	td_count
	.type	td_count, @function
td_count:
	move.l 4(%sp),%d0
	move.l %d0,%d1
	and.l #-16777216,%d1
	cmp.l #2113929216,%d1
	jne .L90
	btst #23,%d0
	jeq .L91
	move.l %d0,4(%sp)
	jra td_file_size
.L90:
	move.l %d0,4(%sp)
	jra td_count_stock
.L91:
	mov3q.l #-1,%d0
	rts
	.size	td_count, .-td_count
	.align	2
	.globl	td_ref
	.type	td_ref, @function
td_ref:
	move.l %a2,-(%sp)
	move.l 16(%sp),%d0
	move.l 8(%sp),%a2
	move.l 12(%sp),%a1
	tst.l %d0
	jlt .L99
	lsl.l #3,%d0
	move.l 260(%a1),%a0
	add.l %d0,%a0
	cmp.l 264(%a1),%a0
	jcc .L99
	move.l (%a0),%a0
	tst.l %a0
	jeq .L99
	move.l (%a0),%d0
	move.l %d0,%d1
	and.l #-8388608,%d1
	cmp.l #2122317824,%d1
	jne .L99
	move.l %d0,%d1
	and.l #4095,%d1
	move.l %d0,(%a2)
	move.l %d0,4(%a2)
	clr.l 12(%a2)
	clr.l 8(%a2)
	move.l %d1,-(%sp)
	moveq #12,%d1
	lsr.l %d1,%d0
	and.l #1023,%d0
	move.l %d0,-(%sp)
	pea 35.w
	jsr sc_sample_add_ref
	lea (12,%sp),%sp
	tst.l %d0
	jlt .L94
	move.l #2119192399,(%a2)
	addq.l #1,td_adds
.L95:
	mov3q.l #1,%d0
.L92:
	move.l (%sp)+,%a2
	rts
.L94:
	addq.l #1,td_add_fails
	jra .L95
.L99:
	clr.l %d0
	jra .L92
	.size	td_ref, .-td_ref
	.globl	td_add_fails
	.section	.bss,"aw",@nobits
	.align	4
	.type	td_add_fails, @object
	.size	td_add_fails, 4
td_add_fails:
	.zero	4
	.globl	td_adds
	.align	4
	.type	td_adds, @object
	.size	td_adds, 4
td_adds:
	.zero	4
	.globl	td_file_node
	.text
	.align	2
	.type	td_file_node, @object
	.size	td_file_node, 128
td_file_node:
	.byte	0
	.byte	3
	.word	0
	.long	0
	.long	0
	.long	1
	.string	""
	.string	""
	.zero	110
	.globl	td_dir_node
	.align	2
	.type	td_dir_node, @object
	.size	td_dir_node, 128
td_dir_node:
	.byte	1
	.byte	1
	.word	0
	.long	0
	.long	0
	.long	0
	.string	""
	.string	""
	.zero	110
	.globl	td_teensy
	.text
	.type	td_teensy, @object
	.size	td_teensy, 8
td_teensy:
	.string	"SIDECAR"
	.type	td_dotdot, @object
	.size	td_dotdot, 3
td_dotdot:
	.string	".."
	.type	td_dot, @object
	.size	td_dot, 2
td_dot:
	.string	"."
	.section	.bss
	.align	4
	.type	td_now, @object
	.size	td_now, 4
td_now:
	.zero	4
	.align	4
	.type	td_ents, @object
	.size	td_ents, 16384
td_ents:
	.zero	16384
	.globl	td_cache
	.align	4
	.type	td_cache, @object
	.size	td_cache, 20
td_cache:
	.zero	20
	.ident	"GCC: (Ubuntu 13.3.0-6ubuntu2~24.04) 13.3.0"
