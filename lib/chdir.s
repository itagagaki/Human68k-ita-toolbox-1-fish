* chdir.s
* Itagaki Fumihiko 14-Jul-90  Create.

.include doscall.h

.xref toupper
.xref drvchkp

.text

****************************************************************
* chdir - change current working directory and/or drive.
*
* CALL
*      A0     string point
*
* RETURN
*      D0.L   DOS status code
*      CCR    TST.L D0
*****************************************************************
.xdef chdir

chdir:
		movem.l	d1-d2,-(a7)
		bclr	#31,d0
		jsr	drvchkp
		bmi	chdir_done

		moveq	#-1,d2
		moveq	#0,d0
		move.b	(a0),d0
		beq	chdir_dir

		cmpi.b	#':',1(a0)
		bne	chdir_dir

		jsr	toupper
		sub.b	#'A',d0
		move.w	d0,d1				*  D1.W : 移動先ドライブ番号
		DOS	_CURDRV
		move.w	d0,d2				*  D2.W : 現在のドライブ番号
		move.w	d1,-(a7)
		DOS	_CHGDRV
		addq.l	#2,a7
		tst.b	2(a0)
		beq	chdir_done
chdir_dir:
		move.l	a0,-(a7)
		DOS	_CHDIR
		addq.l	#4,a7
		tst.l	d0
		bpl	chdir_done

		cmp.w	#-1,d2
		beq	chdir_done

		move.l	d0,-(a7)
		move.w	d2,-(a7)
		DOS	_CHGDRV
		addq.l	#2,a7
		move.l	(a7)+,d0
chdir_done:
		movem.l	(a7)+,d1-d2
		tst.l	d0
		rts

.end
