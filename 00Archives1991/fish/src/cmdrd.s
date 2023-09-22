* cmdrd.s
* This contains built-in command 'rmdir'.
*
* Itagaki Fumihiko 04-Nov-90  Create.

.include error.h
.include doscall.h

.xref for1str
.xref enputs
.xref test_drive_path_perror
.xref pre_perror
.xref perror
.xref too_few_args
.xref bad_arg

.text

*****************************************************************
*								*
*	remove directory command				*
*								*
*	rmdir name ...						*
*								*
*****************************************************************
.xdef cmd_rd

cmd_rd:
		move.w	d0,d1
		beq	too_few_args

		moveq	#0,d2
		subq.w	#1,d1
loop:
		cmp.b	#':',1(a0)
		bne	drive_ok

		tst.b	2(a0)
		beq	rd_bad_arg

		bsr	test_drive_path_perror
		bne	keep
drive_ok:
		move.l	a0,-(a7)
		DOS	_RMDIR
		addq.l	#4,a7
		tst.l	d0
		bpl	next

		cmp.l	#ENOFILE,d0
		beq	nodir

		cmp.l	#ENODIR,d0
		bne	error

		bsr	pre_perror
		lea	msg_notdir,a0
		bsr	enputs
		bra	keep

nodir:
		moveq	#ENODIR,d0
error:
		bsr	perror
keep:
		moveq	#1,d2
next:
		bsr	for1str
		dbra	d1,loop

		move.l	d2,d0
		rts

rd_bad_arg:
		bsr	pre_perror
		bsr	bad_arg
		bra	keep

.data

msg_notdir:	dc.b	'ディレクトリではありません',0

.end
