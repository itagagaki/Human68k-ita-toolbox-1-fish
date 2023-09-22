* stat.s
* Itagaki Fumihiko 07-Mar-91  Create.

.include doscall.h
.include limits.h

.xref test_drive_path
.xref includes_dos_wildcard
.xref tailptr
.xref memmove_inc
.xref strcpy
.xref stricmp
.xref dos_allfile

.text

****************************************************************
* stat - ファイルの情報を得る
*
* CALL
*      A0     ファイル名の先頭アドレス
*      A1     statbuf
*
* RETURN
*      (A1)   情報が書き込まれる
*      D0.L   成功すれば正，さもなくば負
*      CCR    TST.L D0
*****************************************************************
.xdef stat

searchnamebuf = -(MAXPATH+1)
pad = searchnamebuf-(searchnamebuf.MOD.2)

stat:
		link	a6,#pad
		movem.l	a1-a3,-(a7)
		movea.l	a1,a3			* A3 : statbuf
		bsr	test_drive_path
		bne	stat_fail

		bsr	includes_dos_wildcard	* Human68k のワイルドカードを含んで
		bne	stat_fail		* いるならば無効

		movea.l	a0,a1			* A1 : top of search filename
		bsr	tailptr
		cmp.l	#MAXHEAD,d0
		bhi	stat_fail

		movea.l	a0,a2
		lea	searchnamebuf(a6),a0
		bsr	memmove_inc
		lea	dos_allfile,a1
		bsr	strcpy
		move.w	#$3f,-(a7)		* すべてのエントリを検索する
		pea	searchnamebuf(a6)
		move.l	a3,-(a7)
		DOS	_FILES
		lea	10(a7),a7
		movea.l	a2,a0
		lea	30(a3),a1
stat_loop:
		tst.l	d0
		bmi	stat_fail

		bsr	stricmp
		beq	stat_ok

		move.l	a3,-(a7)
		DOS	_NFILES
		addq.l	#4,a7
		bra	stat_loop

stat_fail:
		moveq	#-1,d0
		bra	stat_return

stat_ok:
		moveq	#0,d0
stat_return:
		movem.l	(a7)+,a1-a3
		unlk	a6
		rts
****************************************************************

.end
