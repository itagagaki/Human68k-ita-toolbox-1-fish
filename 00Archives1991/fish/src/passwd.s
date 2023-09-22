* passwd.s
* Itagaki Fumihiko 23-Feb-91  Create.
*
* This contains password file controll routines.

.xref fopen
.xref fgetc
.xref fseek_nextline
.xref fmemcmp

.text

*****************************************************************
* open_passwd - パスワード・ファイルをオープンする
*
* CALL
*      none
*
* RETURN
*      D0.L   負ならば失敗で、ＤＯＳのエラー・コード
*             さもなくば下位ワードがオープンしたパスワード・ファイルのファイル・ハンドル
*****************************************************************
.xdef open_passwd

open_passwd:
		move.l	a0,-(a7)
		lea	pathname_passwd,a0
		moveq	#0,d0
		bsr	fopen
		movea.l	(a7)+,a0
		rts
*****************************************************************
* findpwent - パスワード・ファイルからユーザーのエントリを探す
*
* CALL
*      D0.W   パスワード・ファイルのファイル・ハンドル
*      A0     検索ユーザー名
*      D1.L   A0 の長さ（バイト数）
*
* RETURN
*      D0.L   負：エラー・コード，零：見つかった
*      CCR    TST.L D0
*****************************************************************
.xdef findpwent

findpwent:
		move.w	d2,-(a7)
		move.w	d0,d2
findpwent_loop:
		move.w	d2,d0
		bsr	fmemcmp
		bne	findpwent_next

		move.w	d2,d0
		bsr	fgetc
		bmi	findpwent_return

		cmp.b	#';',d0
		beq	findpwent_found
findpwent_next:
		move.w	d2,d0
		bsr	fseek_nextline
		bpl	findpwent_loop
findpwent_return:
		move.w	(a7)+,d2
		tst.l	d0
		rts

findpwent_found:
		moveq	#0,d0
		bra	findpwent_return
*****************************************************************
.data

pathname_passwd:	dc.b	'A:/etc/passwd',0

.end
