.include doscall.h
.include chrcode.h

.xref iscntrl
.xref issjis
.xref strlen
.xref try_enlarge_ddata
.xref str_newline

.text

*****************************************************************
* isttyin - 入力が端末であるかどうかを調べる
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   下位バイトは端末ならば $FF, さもなくば $00
*             上位は破壊
*      CCR    TST.B D0
*****************************************************************
.xdef isttyin

isttyin:
		move.w	d0,-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		and.b	#$81,d0
		cmp.b	#$81,d0
		seq	d0
		tst.b	d0
		rts
****************************************************************
* isblkdev - キャラクタ・デバイスかどうかを調べる
*
* CALL
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   下位バイトはブロック・デバイスならば $00，キャラクタ・デバイスならば $80
*             上位は破壊
*      CCR    TST.B D0
*****************************************************************
.xdef isblkdev

isblkdev:
		move.w	d0,-(a7)
		clr.w	-(a7)
		DOS	_IOCTRL
		addq.l	#4,a7
		and.b	#$80,d0
		rts
*****************************************************************
* free, xfree - 確保したメモリを解放する
*
* CALL
*      D0.L   メモリ・ブロックの先頭アドレス
*
* RETURN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*
* DESCRIPTION
*      xfree では、D0.L == 0 のときには何もしない
*****************************************************************
.xdef xfree
.xdef free

xfree:
		tst.l	d0
		beq	free_return
free:
		move.l	d0,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
		tst.l	d0
free_return:
		rts
*****************************************************************
* xfreep - 確保したメモリを解放する
*
* CALL
*      A0     メモリ・ブロックの先頭アドレスが格納されているポインタのアドレス
*
* RETURN
*      D0.L   エラー・コード
*      (A0)   エラーでなければクリアされる
*      CCR    TST.L D0
*
* DESCRIPTION
*      (A0) == 0 のときには何もしない
*****************************************************************
.xdef xfreep

xfreep:
		move.l	(a0),d0
		bsr	xfree
		bne	xfreep_return

		clr.l	(a0)
xfreep_return:
		rts
*****************************************************************
* malloc - メモリを確保する
*
* CALL
*      D0.L   確保するバイト数
*
* RETURN
*      D0.L   確保したメモリ・ブロックの先頭アドレス
*             0 は確保できなかったことを示す
*      CCR    TST.L D0
*****************************************************************
.xdef malloc

malloc:
		move.l	d0,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bpl	malloc_done

		moveq	#0,d0
malloc_done:
		rts
*****************************************************************
* xmalloc - メモリを確保する
*           シェルの動的メモリの直下は避ける
*
* CALL
*      D0.L   確保するバイト数
*
* RETURN
*      D0.L   確保したメモリ・ブロックの先頭アドレス
*             0 は確保できなかったことを示す
*      CCR    TST.L D0
*****************************************************************
.xdef xmalloc

xmalloc:
		movem.l	d1-d3,-(a7)
		move.l	d0,d1				*  D1.L : 要求量
		moveq	#1,d2				*  必要最小ブロックを探す
		bsr	try_xmalloc
		bpl	xmalloc_done

		moveq	#0,d2				*  下位から探す
		bsr	try_xmalloc
		bpl	xmalloc_done

		move.l	d1,-(a7)
		move.w	#2,-(a7)			*  上位から探す
		DOS	_MALLOC2
		addq.l	#6,a7
		tst.l	d0
		bpl	xmalloc_done

		moveq	#0,d0
xmalloc_done:
		movem.l	(a7)+,d1-d3
		tst.l	d0
		rts

try_xmalloc:
		move.l	d1,-(a7)
		move.w	d2,-(a7)
		DOS	_MALLOC2
		addq.l	#6,a7
		move.l	d0,d3
		bmi	try_xmalloc_fail

		bsr	try_enlarge_ddata
		exg	d0,d3
		bpl	try_xmalloc_return

		bsr	free
		moveq	#-1,d0
try_xmalloc_return:
		rts

try_xmalloc_fail:
		moveq	#0,d0
		rts
*****************************************************************
* xmallocp - メモリを確保する
*            シェルの動的メモリの直下は避ける
*
* CALL
*      D0.L   確保するバイト数
*      A0     確保したメモリ・ブロックの先頭アドレスを格納するポインタのアドレス
*
* RETURN
*      D0.L   確保したメモリ・ブロックの先頭アドレス
*             0 は確保できなかったことを示す
*      (A0)   D0.L
*      CCR    TST.L D0
*
* DESCRIPTION
*      (A0) != 0 ならば malloc せず、(A0) を持って帰る
*****************************************************************
.xdef xmallocp

xmallocp:
		tst.l	(a0)
		bne	xmallocp_return

		bsr	xmalloc
		move.l	d0,(a0)
xmallocp_return:
		move.l	(a0),d0
		rts
*****************************************************************
* JustFitMalloc - メモリを必要最小ブロックから確保する
*
* CALL
*      D0.L   確保するバイト数
*
* RETURN
*      D0.L   確保したメモリ・ブロックの先頭アドレス
*             0 は確保できなかったことを示す
*
*      CCR    TST.L D0
*****************************************************************
.xdef JustFitMalloc

JustFitMalloc:
		move.l	d0,-(a7)			*  要求量
		move.w	#1,-(a7)			*  必要最小ブロックから
		DOS	_MALLOC2
		addq.l	#6,a7
		tst.l	d0
		bpl	JustFitMalloc_return

		moveq	#0,d0
JustFitMalloc_return:
		rts
*****************************************************************
* xcputs -
*
* CALL
*      A0     points string
*      A1     function pointer prints normal character
*      A2     function pointer prints conroll character
*****************************************************************
xcputs:
		movem.l	d0/a0,-(a7)
xcputs_loop:
		move.b	(a0)+,d0
		beq	xcputs_done

		bsr	issjis
		beq	xcputs_sjis

		jsr	(a2)
		bra	xcputs_loop

xcputs_sjis:
		tst.b	(a0)
		beq	xcputs_done

		jsr	(a1)
		move.b	(a0)+,d0
		jsr	(a1)
		bra	xcputs_loop

xcputs_done:
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
.xdef cputc
.xdef putc

cputc:
		bsr	iscntrl
		bne	putc

		move.l	d0,-(a7)
		moveq	#'^',d0
		bsr	putc
		move.l	(a7),d0
		add.b	#$40,d0
		and.b	#$7f,d0
		bsr	putc
		move.l	(a7)+,d0
		rts

putc:
		move.l	d0,-(a7)
		move.w	d0,-(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
		move.l	(a7)+,d0
		rts
*****************************************************************
.xdef ecputc
.xdef eputc

ecputc:
		cmp.b	#$20,d0
		bhs	eputc

		move.l	d0,-(a7)
		moveq	#'^',d0
		bsr	eputc
		move.l	(a7),d0
		add.b	#$40,d0
		bsr	eputc
		move.l	(a7)+,d0
		rts

eputc:
		move.l	d0,-(a7)
		move.l	#1,-(a7)
		pea	7(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		move.l	(a7)+,d0
		rts
****************************************************************
.xdef puts

puts:
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
		move.l	(a7)+,d0
		rts
****************************************************************
.xdef eputs

eputs:
		move.l	d0,-(a7)
		bsr	strlen
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		move.l	(a7)+,d0
		rts
****************************************************************
.xdef enputs
.xdef eput_newline

enputs:
		bsr	eputs
eput_newline:
		move.l	d0,-(a7)
		move.l	#2,-(a7)
		pea	str_newline
		move.w	#2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		move.l	(a7)+,d0
		rts
*****************************************************************
.xdef cputs

cputs:
		movem.l	a1-a2,-(a7)
		lea	putc(pc),a1
		lea	cputc(pc),a2
		bsr	xcputs
		movem.l	(a7)+,a1-a2
		rts
*****************************************************************
.xdef ecputs

ecputs:
		movem.l	a1-a2,-(a7)
		lea	eputc(pc),a1
		lea	ecputc(pc),a2
		bsr	xcputs
		movem.l	(a7)+,a1-a2
		rts
*****************************************************************
.xdef nputs
.xdef put_newline

nputs:
		bsr	puts
put_newline:
		movem.l	d0/a0,-(a7)
		lea	str_newline,a0
		bsr	puts
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
.xdef put_space

put_space:
		move.l	d0,-(a7)
		moveq	#$20,d0
		bsr	putc
		move.l	(a7)+,d0
		rts
*****************************************************************
.xdef put_tab

put_tab:
		move.l	d0,-(a7)
		move.w	#HT,d0
		bsr	putc
		move.l	(a7)+,d0
		rts
*****************************************************************
* putsex - エスケープ付き単語を出力する
*
* CALL
*      A0     単語のアドレス
*      A1     1文字出力ルーチンのアドレス
*
* RETURN
*      D0     \c があったならば 1，さもなくば 0
*      CCR    TST.L D0
*****************************************************************
.xdef putsex

putsex:
		movem.l	d1-d3/a0,-(a7)
		moveq	#0,d3
putsex_loop:
		move.b	(a0)+,d0
		beq	putsex_done

		bsr	issjis
		beq	putsex_sjis

		cmp.b	#'\',d0
		bne	putsex_normal

		move.b	(a0),d1
		cmp.b	#'\',d1
		beq	putsex_escape_1

		moveq	#BS,d0
		cmp.b	#'b',d1
		beq	putsex_escape_1

		moveq	#FS,d0
		cmp.b	#'f',d1
		beq	putsex_escape_1

		moveq	#CR,d0
		cmp.b	#'r',d1
		beq	putsex_escape_1

		moveq	#HT,d0
		cmp.b	#'t',d1
		beq	putsex_escape_1

		moveq	#VT,d0
		cmp.b	#'v',d1
		beq	putsex_escape_1

		cmp.b	#'n',d1
		beq	putsex_newline

		cmp.b	#'0',d1
		beq	putsex_octal

		moveq	#'\',d0
		cmp.b	#'c',d1
		bne	putsex_normal

		moveq	#1,d3
		bra	putsex_escape_2

putsex_newline:
		moveq	#CR,d0
		jsr	(a1)
		moveq	#LF,d0
putsex_escape_1:
		jsr	(a1)
putsex_escape_2:
		addq.l	#1,a0
		bra	putsex_loop

putsex_octal:
		addq.l	#1,a0
		moveq	#0,d0
		moveq	#2,d2
putsex_octal_1:
		move.b	(a0),d1
		sub.b	#'0',d1
		blo	putsex_normal

		cmp.b	#7,d1
		bhi	putsex_normal

		lsl.b	#3,d0
		add.b	d1,d0
		addq.l	#1,a0
		dbra	d2,putsex_octal_1

		bra	putsex_normal

putsex_sjis:
		jsr	(a1)
		move.b	(a0)+,d0
		beq	putsex_done
putsex_normal:
		jsr	(a1)
		bra	putsex_loop

putsex_done:
		move.l	d3,d0
		movem.l	(a7)+,d1-d3/a0
		rts
*****************************************************************
* putse - エスケープ付き単語を標準出力に出力する
*
* CALL
*      A0     単語のアドレス
*
* RETURN
*      D0     \c があったならば 1，さもなくば 0
*      CCR    TST.L D0
*****************************************************************
.xdef putse

putse:
		move.l	a1,-(a7)
		lea	putc(pc),a1
		bsr	putsex
		movea.l	(a7)+,a1
		rts
*****************************************************************
* eputse - エスケープ付き単語を標準エラー出力に出力する
*
* CALL
*      A0     単語のアドレス
*
* RETURN
*      D0     \c があったならば 1，さもなくば 0
*      CCR    TST.L D0
*****************************************************************
.xdef eputse

eputse:
		move.l	a1,-(a7)
		lea	eputc(pc),a1
		bsr	putsex
		movea.l	(a7)+,a1
		rts
*****************************************************************

.end
