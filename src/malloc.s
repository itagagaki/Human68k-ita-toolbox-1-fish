.include ../src/fish.h


.if EXTMALLOC
	.xref MALLOC
	.xref MFREE
	.xref MFREEALL

	.xref lake_top
	.xref tmplake_top
.else
	.include doscall.h
.endif


.text

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
	.if EXTMALLOC
		bsr	MFREE
	.else
		DOS	_MFREE
	.endif
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
* xmalloc - メモリを確保する
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
.xdef xmalloc

xmalloc:
		move.l	d0,-(a7)			*  要求量
		move.w	#1,-(a7)			*  必要最小ブロックから
	.if EXTMALLOC
		bsr	MALLOC
	.else
		DOS	_MALLOC
	.endif
		addq.l	#6,a7
		tst.l	d0
		bpl	xmalloc_return

		moveq	#0,d0
xmalloc_return:
		rts
*****************************************************************
* xmalloct - 一時的メモリを確保する
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
.xdef xmalloct

xmalloct:
		bsr	swap_lake
		bsr	xmalloc
swap_lake:
		move.l	tmplake_top(a5),-(a7)
		move.l	lake_top(a5),tmplake_top(a5)
		move.l	(a7)+,lake_top(a5)
		tst.l	d0
		rts
*****************************************************************
* freet - 確保した一時的メモリを解放する
*
* CALL
*      D0.L   メモリ・ブロックの先頭アドレス
*
* RETURN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*****************************************************************
.xdef freet

freet:
		bsr	swap_lake
		bsr	free
		bra	swap_lake
*****************************************************************
* free_all_tmp - 確保した一時的メモリをすべて解放する
*
* CALL
*      none
*
* RETURN
*      D0.L   エラー・コード
*      CCR    TST.L D0
*****************************************************************
.xdef free_all_tmp

free_all_tmp:
	.if EXTMALLOC
		bsr	swap_lake
		bsr	MFREEALL
		bra	swap_lake
	.else
		*  代用品は無い (^^;
		rts
	.endif
*****************************************************************
* xmallocp - メモリを確保する
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
*      (A0) != 0 ならば xmalloc せず、(A0) を持って帰る
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

.end
