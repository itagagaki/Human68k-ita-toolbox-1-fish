* passwd.s
* Itagaki Fumihiko 23-Feb-91  Create.
*
* This contains password file controll routines.

.include limits.h
.include error.h

.xref tfopen
.xref make_sys_pathname

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

pathname = -(((MAXPATH+1)+1)>>1<<1)

open_passwd:
		link	a6,#pathname
		movem.l	a0-a1,-(a7)
		lea	pathname(a6),a0
		lea	pathname_passwd,a1
		bsr	make_sys_pathname
		bmi	no_passwd

		moveq	#0,d0
		bsr	tfopen
open_passwd_return:
		movem.l	(a7)+,a0-a1
		unlk	a6
		rts

no_passwd:
		moveq	#ENOFILE,d0
		bra	open_passwd_return
*****************************************************************
.data

pathname_passwd:	dc.b	'/etc/passwd',0

.end
