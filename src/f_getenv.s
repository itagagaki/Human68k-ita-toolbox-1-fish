* f_getenv.s
* Itagaki Fumihiko 18-Aug-91  Create.

.include ../src/var.h

.xref strcmp
.xref strfor1

.xref env_top

.text

****************************************************************
* fish_getenv - FISH の環境変数リストから名前で変数を探す
*
* CALL
*      A0     検索する変数名の先頭アドレス
*
* RETURN
*      A0     変数名よりも辞書的に前方に位置する最後の変数のアドレス
*             あるいは 0
*
*      D0.L   見つかった変数のアドレス．
*             見つからなければ 0．
*
*      CCR    TST.L D0
*****************************************************************
.xdef fish_getenv

fish_getenv:
		movem.l	a1-a3,-(a7)
		movea.l	env_top(a5),a2
		suba.l	a3,a3
loop:
		cmpa.l	#0,a2
		beq	done

		lea	var_body(a2),a1
		bsr	strcmp
		beq	done

		movea.l	a2,a3
		movea.l	var_next(a3),a2
		bra	loop

done:
		movea.l	a3,a0
		move.l	a2,d0
		movem.l	(a7)+,a1-a3
		rts

.end
