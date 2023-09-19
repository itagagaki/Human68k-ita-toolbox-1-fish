* stat.s
* Itagaki Fumihiko 07-Mar-91  Create.

.include doscall.h
.include limits.h
.include stat.h

.xref drvchkp
.xref contains_dos_wildcard
.xref headtail
.xref memmovi
.xref strcpy
.xref stricmp

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

searchnamebuf = -(((MAXPATH+1)+1)>>1<<1)

stat:
		link	a6,#searchnamebuf
		movem.l	a0-a3,-(a7)
		movea.l	a1,a3				*  A3 : statbuf
		bsr	drvchkp
		bmi	stat_fail

		bsr	contains_dos_wildcard		*  Human68k のワイルドカードを含んで
		bne	stat_fail			*  いるならば無効

		bsr	headtail
		cmp.l	#MAXHEAD,d0
		bhi	stat_fail

		movea.l	a1,a2				*  A2 : tail part of search pathname
		movea.l	a0,a1				*  A1 : top of search pathname
		lea	searchnamebuf(a6),a0
		bsr	memmovi
		lea	allfile,a1			*  "*.*" で検索する（さもなくば検索されないエントリがある）
		bsr	strcpy
		move.w	#MODEVAL_ALL,-(a7)		*  すべてのエントリを検索する
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
		movem.l	(a7)+,a0-a3
		unlk	a6
		rts
****************************************************************
.data

allfile:	dc.b	'*.*',0

.end
