* drvchk.s
* Itagaki Fumihiko 04-Jan-91  Create.

.include doscall.h
.include error.h

.xref toupper

.text
*****************************************************************
* drvchkp - パス名のディスク・ドライブが読み込み可能かどうかを検査する
*
* CALL
*      A0     パス名
*      D0.L   MSB: 1 なら書き込みに対してのチェックも行う
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
*****************************************************************
* drvchk - ディスク・ドライブが読み込み可能かどうかを検査する
*
* CALL
*      D0.L   下位バイト: ドライブ名
*             MSB: 1 なら書き込みに対してのチェックも行う
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
.xdef drvchk

drvchkp:
		move.b	(a0),d0
		beq	drvchk_current

		cmpi.b	#':',1(a0)
		beq	drvchk
drvchk_current:
		swap	d0
		move.w	d0,-(a7)
		DOS	_CURDRV
		add.b	#'A',d0
		swap	d0
		move.w	(a7)+,d0
		swap	d0
drvchk:
		movem.l	d1-d3,-(a7)
		move.l	d0,d3
		move.l	#EBADDRVNAME,d1
		jsr	toupper
		sub.b	#'A',d0
		blo	drvchk_done		* ドライブ名が無効

		cmp.b	#'Z'-'A',d0
		bhi	drvchk_done		* ドライブ名が無効

		moveq	#0,d2
		move.b	d0,d2			* D1.W : ドライブ番号（A=0, B=1, ...)
		DOS	_CURDRV
		move.w	d0,-(a7)
		DOS	_CHGDRV
		addq.l	#2,a7
		move.l	#ENODRV,d1
		cmp.w	d0,d2
		bhs	drvchk_done		* ドライブが無い

		move.w	d2,d0
		addq.w	#1,d0
		move.w	d0,-(a7)
		DOS	_DRVCTRL
		addq.l	#2,a7
		move.l	#ENOMEDIA,d1
		btst	#1,d0
		beq	drvchk_done		* メディアが無い

		move.l	#EBADMEDIA,d1
		btst	#0,d0
		bne	drvchk_done		* メディア誤挿入

		move.l	#EDRVNOTREADY,d1
		btst	#2,d0
		bne	drvchk_done		* ドライブ・ノット・レディ

		btst	#31,d3
		beq	drvchk_ok

		move.l	#EWRITEPROTECTED,d1
		btst	#3,d0				* write protect
		bne	drvchk_done
drvchk_ok:
		moveq	#0,d1
drvchk_done:
		move.l	d1,d0
		movem.l	(a7)+,d1-d3
		rts

.end
