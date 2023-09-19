* getenv.s
* Itagaki Fumihiko 15-Jul-90  Create.

****************************************************************
* getenv - get environment variable address
*
* CALL
*      A0     検索する変数名の先頭アドレス
*      A3     環境変数ブロックの先頭アドレス
*
* RETURN
*      A0     見つかったならば環境ブロックの変数名の先頭を指す
*      D0.L   見つかったならば値の文字列の先頭アドレスを指す
*             見つからなければ 0
*      CCR    TST.L D0
*****************************************************************
.xdef getenv

getenv:
		movem.l	d1/a1-a3,-(a7)
		cmpa.l	#-1,a3
		beq	getenv_fail

		addq.l	#4,a3
getenv_loop1:
		tst.b	(a3)
		beq	getenv_fail

		movea.l	a3,a2
		movea.l	a0,a1
getenv_loop2:
		move.b	(a3)+,d1
		move.b	(a1)+,d0
		beq	getenv_term

		cmp.b	d0,d1
		beq	getenv_loop2

		bra	getenv_next
getenv_term:
		cmp.b	#'=',d1
		beq	env_found
getenv_next:
		subq.l	#1,a3
getenv_next_loop:
		tst.b	(a3)+
		bne	getenv_next_loop
		bra	getenv_loop1

getenv_fail:
		suba.l	a3,a3
env_found:
		move.l	a3,d0
		movea.l	a2,a0
		movem.l	(a7)+,d1/a1-a3
		rts

.end
