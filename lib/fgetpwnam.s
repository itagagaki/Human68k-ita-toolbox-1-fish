* fgetpwnam.s
* Itagaki Fumihiko 17-Aug-91  Create.

.include limits.h
.include pwd.h

.xref memcmp
.xref fgetpwent

.text

*****************************************************************
* fgetpwnam - パスワード・ファイルからユーザ名でエントリを検索する
*
* CALL
*      D0.W   パスワード・ファイルのファイル・ハンドル
*             （行の先頭を指していること）
*
*      A0     格納バッファ（PW_SIZEバイト）の先頭アドレス
*
*      A1     検索する名前の先頭アドレス
*
*      D1.L   検索する名前の長さ
*
* RETURN
*      D0.L   見つかったならば 0
*      CCR    TST.L D0
*****************************************************************
.xdef fgetpwnam

fgetpwnam:
		movem.l	d2/a0-a2,-(a7)
		move.w	d0,d2				*  D2.W : ファイル・ハンドル
		moveq	#-1,d0
		cmp.l	#PW_NAME_SIZE,d1
		bhi	fgetpwnam_done

		movea.l	a0,a2				*  A2 : 格納構造体
fgetpwnam_loop:
		move.w	d2,d0
		movea.l	a2,a0
		jsr	fgetpwent
		bne	fgetpwnam_done

		lea	PW_NAME(a2),a0
		tst.b	(a0,d1.l)
		bne	fgetpwnam_loop

		move.l	d1,d0
		jsr	memcmp
		bne	fgetpwnam_loop
fgetpwnam_done:
		movem.l	(a7)+,d2/a0-a2
		rts

.end
