* fgetpwnam.s
* Itagaki Fumihiko 17-Aug-91  Create.

.include limits.h
.include pwd.h

.xref strcmp
.xref fgetpwent

.text

*****************************************************************
* fgetpwnam - パスワード・ファイルからユーザ名でエントリを検索する
*
* CALL
*      D0.W   パスワード・ファイルのファイル・ハンドル（行の先頭を指していること）
*      A0     pwd構造体の先頭アドレス
*      A1     行読み込みバッファの先頭アドレス
*      D1.L   行読み込みバッファの容量
*      A2     検索する名前の先頭アドレス(NUL終端は不要)
*
* RETURN
*      D0.L   見つかったならば 0
*      CCR    TST.L D0
*****************************************************************
.xdef fgetpwnam

fgetpwnam:
		movem.l	d2/a0/a3,-(a7)
		move.w	d0,d2				*  D2.W : ファイル・ハンドル
		movea.l	a0,a3				*  A3 : pwd構造体
fgetpwnam_loop:
		move.w	d2,d0
		movea.l	a3,a0
		jsr	fgetpwent
		bne	fgetpwnam_done

		movea.l	PW_NAME(a3),a0
		exg	a1,a2
		jsr	strcmp
		exg	a1,a2
		bne	fgetpwnam_loop
fgetpwnam_done:
		movem.l	(a7)+,d2/a0/a3
		rts

.end
