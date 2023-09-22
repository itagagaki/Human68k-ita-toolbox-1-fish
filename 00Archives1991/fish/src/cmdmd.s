* cmdmd.s
* This contains built-in command 'mkdir'.
*
* Itagaki Fumihiko 04-Nov-90  Create.

.include doscall.h

.xref for1str
.xref test_drive_path_perror
.xref pre_perror
.xref perror
.xref too_few_args
.xref bad_arg

.text

*****************************************************************
*								*
*	make directory command					*
*								*
*	mkdir name ...						*
*								*
*****************************************************************
.xdef cmd_md

cmd_md:
		move.w	d0,d1
		beq	too_few_args

		moveq	#0,d2
		subq.w	#1,d1
loop:
		cmp.b	#':',1(a0)
		bne	drive_ok

		tst.b	2(a0)
		beq	md_bad_arg

		bsr	test_drive_path_perror
		bne	keep
drive_ok:
		move.l	a0,-(a7)
		DOS	_MKDIR
		addq.l	#4,a7
		tst.l	d0
		bpl	next

		bsr	perror
keep:
		moveq	#1,d2
next:
		bsr	for1str
		dbra	d1,loop

		move.l	d2,d0
		rts

md_bad_arg:
		bsr	pre_perror
		bsr	bad_arg
		bra	keep

.end
