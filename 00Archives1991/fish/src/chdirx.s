* chdirx.s
* Itagaki Fumihiko 14-Jul-90  Create.

.include error.h

.xref chdir

.xref for1str
.xref isabsolute
.xref cat_pathname
.xref find_var
.xref word_cdpath
.xref shellvar
.xref pathname_buf

.text

****************************************************************
* chdirx - change current working directory and/or drive.
*
*      This function looks shell variable "home", "cdpath"
*      and specified name.
*
* CALL
*      A0     dirname
*
* RETURN
*      D0.L   エラーならば負数（ＯＳのエラーコード）
*             指定のディレクトリに移動したならば、0
*             シェル変数で補われたならば、1
*      CCR    TST.L D0
*****************************************************************
.xdef chdirx

chdirx:
		movem.l	d1-d3/a0-a3,-(a7)
		bsr	chdir			* カレント・ディレクトリを変更する
		bpl	done0

		cmpi.b	#':',1(a0)		* ドライブ指定がある場合は
		beq	done			* cdpathを検索しない

		movea.l	a0,a1
		cmpi.b	#'.',(a1)
		bne	chdirx_1

		addq.l	#1,a1
		cmpi.b	#'.',(a1)
		bne	chdirx_1

		addq.l	#1,a1
chdirx_1:
		cmpi.b	#'/',(a1)
		beq	done

		cmpi.b	#'\',(a1)
		beq	done
****************
		movea.l	a0,a2				* A2 : dirname
		movea.l	shellvar,a0
		lea	word_cdpath,a1
		bsr	find_var
		beq	try_varname

		addq.l	#2,a0
		move.w	(a0)+,d1			* D1.W : cdpath の単語数
		bsr	for1str
		movea.l	a0,a1				* A1 : cdpath の単語並び
		lea	pathname_buf,a0
		bra	try_cdpath_continue

try_cdpath_loop:
		bsr	cat_pathname
		bmi	try_cdpath_continue

		bsr	chdir
		bpl	done1
try_cdpath_continue:
		dbra	d1,try_cdpath_loop
****************
try_varname:
		movea.l	shellvar,a0
		movea.l	a2,a1
		bsr	find_var
		beq	varname_fail

		lea	2(a0),a0
		move.w	(a0)+,d1		* D1.W : 単語数  A0 : 値
		beq	varname_fail

		bsr	for1str
		bsr	isabsolute
		bne	varname_fail

		bsr	chdir
		bpl	done1
done:
		movem.l	(a7)+,d1-d3/a0-a3
		tst.l	d0
		rts

done0:
		moveq	#0,d0
		bra	done

done1:
		moveq	#1,d0
		bra	done

varname_fail:
		moveq	#ENODIR,d0
		bra	done

.end
