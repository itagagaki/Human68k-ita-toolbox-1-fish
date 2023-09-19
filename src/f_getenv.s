* f_getenv.s
* Itagaki Fumihiko 18-Aug-91  Create.

.include ../src/var.h

.xref strcmp
.xref strfor1

.xref envtop

.text

****************************************************************
* fish_getenv - FISH の環境変数リストから名前で変数を探す
*
* CALL
*      A0     検索する変数名の先頭アドレス
*
* RETURN
*      D0.L   見つかった変数のヘッダの先頭アドレス．
*             見つからなければ 0．
*      CCR    TST.L D0
*****************************************************************
.xdef fish_getenv

fish_getenv:
		movem.l	a1-a2,-(a7)
		movea.l	envtop(a5),a2
loop:
		cmpa.l	#0,a2
		beq	done

		lea	var_body(a2),a1
		bsr	strcmp
		beq	done

		movea.l	var_next(a2),a2
		bra	loop

done:
		move.l	a2,d0
		movem.l	(a7)+,a1-a2
		rts

.end
