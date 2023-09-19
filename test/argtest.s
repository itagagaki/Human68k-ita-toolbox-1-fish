	.INCLUDE doscall.h

	.XREF DecodeHUPAIR


STACKSIZE	EQU	512

CR	EQU	$0d
LF	EQU	$0a


	.TEXT

start:						*  実行開始アドレス
		bra	start1			*  2 Byte
hupair_id:	dc.b	'#HUPAIR',0		*  このプログラムがHUPAIR準拠であることを示す
start1:
		lea	stack_bottom,a7
		movea.l	a0,a5			*  A5 := プログラムのメモリ管理ポインタ
	*
	*  コマンドラインが HUPAIR encoded であるかどうかを調べる
	*
		lea	-8(a2),a0		*  A0 := コマンドラインの先頭アドレス-8
		lea	hupair_id(pc),a1	*  A1 := HUPAIR ID のアドレス
		moveq	#7,d0
check_loop:
		cmpm.b	(a0)+,(a1)+
		dbne	d0,check_loop

		lea	msg_hupair_encoded,a0
		beq	check_done

		lea	msg_not_hupair_encoded,a0
check_done:
		move.l	a0,-(a7)
		DOS	_PRINT
		addq.l	#4,a7
	*
	*  HUPAIR decode を行う
	*
		movea.l	a7,a1			*  A1 := 引数並びを格納するエリアの先頭アドレス
		lea	1(a2),a0		*  A0 := コマンドラインの文字列の先頭アドレス
		bsr	strlen			*  D0.L に A0 が示す文字列の長さを求め，
		add.l	a1,d0			*    格納エリアの容量を
		cmp.l	8(a5),d0		*    チェックする．
		bhs	insufficient_memory

		bsr	DecodeHUPAIR		*  デコードする．

		*  ここで，D0.W は引数の数．A1 が示すエリアには，D0.W が示す個数だけ，
		*  単一の引数（$00で終端された文字列）が隙間無く並んでいる．
	*
	*  引数列を表示する
	*
		move.w	d0,d1			*  D1.w : 引数の数
		bra	print_start

loop1:
		moveq	#'>',d0
		bsr	putc
loop2:
		clr.w	d0
		move.b	(a1)+,d0
		beq	continue

		bsr	putc
		bra	loop2

continue:
		moveq	#'<',d0
		bsr	putc
		moveq	#CR,d0
		bsr	putc
		moveq	#LF,d0
		bsr	putc
print_start:
		dbra	d1,loop1
	*
	*  終了
	*
		clr.w	-(a7)
		DOS	_EXIT2
*
*  「メモリが足りません」と表示して終了する
*
insufficient_memory:
		pea	msg_insufficient_memory
		DOS	_PRINT
		addq.l	#4,a7
		move.w	#1,-(a7)
		DOS	_EXIT2
**
**  サブルーチン putc - 文字 D0.W を出力する
**
putc:
		move.w	d0,-(a7)
		DOS	_PUTCHAR
		addq.l	#2,a7
		rts
**
**  サブルーチン strlen - 文字列 A0 の長さを D0.L に得る
**
strlen:
		move.l	a0,-(a7)
		move.l	a0,d0
loop:
		tst.b	(a0)+
		bne	loop

		subq.l	#1,a0
		sub.l	a0,d0
		neg.l	d0
		movea.l	(a7)+,a0
		rts


	.DATA

msg_insufficient_memory:
		dc.b	'argtest: メモリが足りません',CR,LF,0

msg_hupair_encoded:
		dc.b	'コマンドラインは間違いなく HUPAIR encoded です',CR,LF,0

msg_not_hupair_encoded:
		dc.b	'コマンドラインは HUPAIR encoded ではないかも知れません',CR,LF,0


	.BSS

		ds.b	STACKSIZE
stack_bottom:


	.END start
