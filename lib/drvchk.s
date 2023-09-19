* drvchk.s
* Itagaki Fumihiko 04-Jan-91  Create.

.include doscall.h
.include error.h

.xref toupper

.text

*****************************************************************
* drvchkp - パス名がドライブ名を持っているならば
*           そのディスク・ドライブを検査する
*
* CALL
*      A0     パス名
*
* RETURN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*
* DIAGNOSTIC
*      エラーならば以下の負数コードを返す．
*
*           EBADDRVNAME
*           ENODRV
*           ENOMEDIA
*           EBADMEDIA
*           EDRVNOTREADY
*
*      さもなくば 0 を返す．
*****************************************************************
.xdef drvchkp

drvchkp:
		move.b	(a0),d0
		beq	ok_return

		cmpi.b	#':',1(a0)
		bne	ok_return
*****************************************************************
* drvchk - ディスク・ドライブを検査する
*
* CALL
*      D0.B   ドライブ名
*
* RETURN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*
* DIAGNOSTIC
*      エラーならば以下の負数コードを返す．
*
*           EBADDRVNAME
*           ENODRV
*           ENOMEDIA
*           EBADMEDIA
*           EDRVNOTREADY
*
*      さもなくば 0 を返す．
*****************************************************************
.xdef drvchk

drvchk:
		movem.l	d1-d2,-(a7)
		move.l	#EBADDRVNAME,d2
		jsr	toupper
		sub.b	#'A',d0
		blo	drvchk_done		* ドライブ名が無効

		cmp.b	#'Z'-'A',d0
		bhi	drvchk_done		* ドライブ名が無効

		moveq	#0,d1
		move.b	d0,d1			* D1.W : ドライブ番号（A=0, B=1, ...)
		DOS	_CURDRV
		move.w	d0,-(a7)
		DOS	_CHGDRV
		addq.l	#2,a7
		move.l	#ENODRV,d2
		cmp.w	d0,d1
		bhs	drvchk_done		* ドライブが無い

		move.w	d1,d0
		addq.w	#1,d0
		move.w	d0,-(a7)
		DOS	_DRVCTRL
		addq.l	#2,a7
		move.l	#ENOMEDIA,d2
		btst	#1,d0
		beq	drvchk_done		* メディアが無い

		move.l	#EBADMEDIA,d2
		btst	#0,d0
		bne	drvchk_done		* メディア誤挿入

		move.l	#EDRVNOTREADY,d2
		btst	#2,d0
		bne	drvchk_done		* ドライブ・ノット・レディ

		moveq	#0,d2
drvchk_done:
		move.l	d2,d0
		movem.l	(a7)+,d1-d2
		rts

ok_return:
		moveq	#0,d0
		rts

.end
