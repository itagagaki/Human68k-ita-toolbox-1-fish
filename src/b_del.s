*****************************************************************
*								*
*	file delete command					*
*								*
*	DEL [delete file(s)] <switch>				*
*	ERASE [delete file(s)] <switch>				*
*								*
*	switch list						*
*		-i	confirm interactive			*
*								*
*****************************************************************

.include doscall.h
.include ../src/misc2.h

.xref test_drive_path_perror
.xref makenaxt
.xref files
.xref enputs
.xref tailptr
.xref strcpy
.xref ask_yes
.xref bad_arg
.xref msg_nofile
.xref msg_nodir
.xref msg_maxfiles
.xref work_area

.xdef cmd_del

.text

sure_name = -280
interactive = -2+sure_name

cmd_del:
		link	a6,#interactive
		movea.l	a0,a2
		move.w	d0,d1
		sf	interactive(a6)
sw_lp:
		tst.w	d1
		beq	del_nn

		cmpi.b	#'-',(a2)
		bne	del_nn

		subq.w	#1,d1
		addq.l	#1,a2
sw_lp1:
		move.b	(a2)+,d0
		beq	sw_lp

		cmp.b	#'i',d0
		bne	del_errp

		st	interactive(a6)
		bra	sw_lp1

del_nn:
		cmp.w	#1,d1
		bne	del_errp

		movea.l	a2,a0
		bsr	test_drive_path_perror
		bne	del_error_return
del_nnn:
		bsr	makenaxt
*****************************************************************
*								*
*	make file list						*
*								*
*****************************************************************
del_go:
		movea.l	a2,a0
		move.l	work_area,a1	*allocated work
		bsr	files
		cmp.l	#-1,d0
		beq	del_err_dir

		cmp.w	#MAXFILES,d0
		bls	max_del_ok

		lea	msg_maxfiles,a0
		bsr	enputs
*****************************************************************
*								*
*	file delete						*
*								*
*****************************************************************
max_del_ok:
		movea.l	a2,a0
		bsr	tailptr
		movea.l	work_area,a1
		moveq	#0,d2
del_lp0:
		tst.b	(a1)
		beq	del_end

		move.b	FNAMELEN+EXTLEN+2(a1),d0
		and.b	#$1f,d0
		bne	del_next

		move.b	#'.',FNAMELEN(a1)
		bsr	strcpy
		moveq	#1,d2
		tst.b	interactive(a6)
		beq	do_remove

		move.l	a2,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		move.l	a0,-(a7)
		lea	msg_confirm,a0
		bsr	ask_yes
		move.l	(a7)+,a0
		beq	del_next
do_remove:
		move.l	a2,-(a7)
		DOS	_DELETE
		addq.l	#4,a7
del_next:
		lea	FNAMELEN+EXTLEN+11(a1),a1
		bra	del_lp0

del_end:
		tst.b	d2
		beq	del_nofile
del_exit:
		moveq	#0,d0
del_return:
		unlk	a6
		rts

del_nofile:
		lea	msg_nofile,a0
error1:
		bsr	enputs
del_error_return:
		moveq	#1,d0
		bra	del_return

del_err_dir:
		lea	msg_nodir,a0
		bra	error1

del_errp:
		bsr	bad_arg
		bra	del_return

.data

msg_confirm:	dc.b	'ÇçÌèúÇµÇ‹Ç∑Ç©ÅH ',0

.end
