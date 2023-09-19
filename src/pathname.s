* pathname.s
* Itagaki Fumihiko 14-Aug-90  Create.
*
* This contains pathname controll routines.

.include limits.h

.xref issjis
.xref strchr
.xref strcpy
.xref strlen
.xref for1str
.xref headtail
.xref find_shellvar
.xref word_home

.text

****************************************************************
* test_pathname - パス名を調べる
*
* CALL
*      A0     パス名の先頭アドレス
*
* RETURN
*      A1     ディレクトリ部のアドレス
*      A2     ファイル部のアドレス
*      A3     拡張子部のアドレス（. から。.が無ければ最後のNULを指す）
*      D0.L   ドライブ＋ディレクトリ部の長さ（最後の / の分を含む）
*      D1.L   ディレクトリ部の長さ（最後の / の分を含む）
*      D2.L   ファイル部（拡張子部は含まない）の長さ
*      D3.L   拡張子部の長さ（. の分を含む）
*      CCR    各部の長さが適法ならば "ls"
*****************************************************************
.xdef test_pathname

test_pathname:
	*  A2 にファイル部の先頭アドレスを
	*  D0 にドライブ＋ディレクトリ部の長さ（最後の / の分を含む）を得る

		bsr	headtail
		movea.l	a1,a2

	*  A1 にディレクトリ部の先頭アドレス
	*  D1 にディレクトリ部の長さ（最後の / の分を含む）を得る

		movea.l	a0,a1
		movem.l	d0/a0,-(a7)		*  D0 と A0 をセーブする
		move.l	d0,d1
		cmp.l	#2,d1
		blo	test_pathname_1

		cmpi.b	#':',1(a1)
		bne	test_pathname_1

		addq.l	#2,a1
		subq.l	#2,d1
test_pathname_1:

	*  A3 に拡張子部のアドレス（. から）を
	*  D3 に拡張子部の長さ（. を含む）を得る

		moveq	#'.',d0
		movea.l	a2,a0
		bsr	strchr
test_pathname_2:
		movea.l	a0,a3
		beq	test_pathname_3

		addq.l	#1,a0
		bsr	strchr
		bne	test_pathname_2
test_pathname_3:
		movea.l	a3,a0
		bsr	strlen
		move.l	d0,d3			* D3.L : 拡張子部の長さ

	*  D2 にファイル部（拡張子部は含まない）の長さを求める

		move.l	a3,d2
		sub.l	a2,d2			* D2.L : ファイル部の長さ

	*  各部分の長さをテストする

		cmp.l	#MAXDIR,d1
		bhi	test_pathname_return

		cmp.l	#MAXFILE,d2
		bhi	test_pathname_return

		cmp.l	#MAXEXT,d3
		bhi	test_pathname_return
test_pathname_return:
		movem.l	(a7)+,d0/a0		*  D0 と A0 を取り戻す
		rts
****************************************************************
* copyhead
*
* CALL
*      A0     result buffer
*      A1     points head
*      D0.W   buffer size
*
* RETURN
*      A0     next point of buffer
*      D0.L   remain buffer size
*      D1.L   1 if root directory, otherwise 0
*****************************************************************
.xdef copyhead

copyhead:
		movem.l	d2-d3/a1,-(a7)
		moveq	#0,d1
		move.w	d0,d1
		tst.b	(a1)
		beq	copyhead_start

		cmpi.b	#':',1(a1)
		bne	copyhead_start

		subq.l	#2,d1
		bcs	copyhead_done

		move.b	(a1)+,(a0)+
		move.b	(a1)+,(a0)+
		tst.b	(a1)
		bne	copyhead_start

		subq.l	#1,d1
		bcs	copyhead_done

		move.b	#'.',(a0)+
		moveq	#0,d3
		bra	copyhead_done

copyhead_start:
		moveq	#0,d2
		move.b	(a1),d0
		cmp.b	#'/',d0
		beq	copyhead_root

		cmp.b	#'\',d0
		bne	copyhead_not_root
copyhead_root:
		subq.l	#1,d1
		bcs	copyhead_done

		move.b	(a1)+,(a0)+
		tst.b	(a1)
		bne	copyhead_not_root

		moveq	#1,d3
		bra	copyhead_done

copyhead_not_root:
		moveq	#0,d3
copyhead_loop:
		move.b	(a1),d0
		beq	copyhead_done

		tst.b	d2
		beq	copyhead_check_char

		moveq	#0,d2
		bra	copyhead_copy_one

copyhead_check_char:
		cmp.b	#'/',d0
		beq	copyhead_slash

		cmp.b	#'\',d0
		beq	copyhead_slash

		bsr	issjis
		bne	copyhead_copy_one

		moveq	#1,d2
copyhead_copy_one:
		subq.l	#1,d1
		bcs	copyhead_done

		move.b	(a1)+,(a0)+
		bra	copyhead_loop

copyhead_slash:
		tst.b	1(a1)
		bne	copyhead_copy_one
copyhead_done:
		move.l	d1,d0
		move.l	d3,d1
		movem.l	(a7)+,d2-d3/a1
		rts
****************************************************************
* cat_pathname - concatinate head and tail
*
* CALL
*      A0     result buffer (MAXPATH+1 bytes required)
*      A1     points head
*      A2     points tail
*
* RETURN
*      A1     next word
*      A3     tail pointer of result buffer
*      D0.L   positive if success.
*      CCR    TST.L D0
*****************************************************************
.xdef cat_pathname

cat_pathname:
		movem.l	d1/a0,-(a7)
		tst.b	(a1)
		bne	cat_pathname_start

		addq.l	#1,a1
		moveq	#-1,d0
		bra	cat_pathname_done

cat_pathname_start:
		move.w	#MAXPATH,d0
		bsr	copyhead
		exg	a0,a1
		bsr	for1str
		exg	a0,a1
		tst.l	d0
		bmi	cat_pathname_done

		tst.b	d1
		bne	cat_pathname_tail

		subq.l	#1,d0
		bcs	cat_pathname_done

		move.b	#'/',(a0)+
cat_pathname_tail:
		movea.l	a0,a3
		move.l	d0,d1
		exg	a0,a2
		bsr	strlen
		exg	a0,a2
		exg	d0,d1
		sub.l	d1,d0
		bcs	cat_pathname_done

		exg	d0,d1
		exg	a1,a2
		bsr	strcpy
		exg	a1,a2
		exg	d0,d1
cat_pathname_done:
		movem.l	(a7)+,d1/a0
		tst.l	d0
		rts
*****************************************************************
.xdef isabsolute

isabsolute:
		tst.b	(a0)
		beq	isabsolute_not

		cmpi.b	#':',1(a0)
		bne	return

		cmpi.b	#'/',2(a0)
		beq	return

		cmpi.b	#'\',2(a0)
return:
		rts

isabsolute_not:
		cmpi.b	#1,(a0)
		rts
*****************************************************************
.xdef includes_dos_wildcard

includes_dos_wildcard:
		movem.l	d0/a0,-(a7)
		moveq	#'*',d0
		bsr	strchr
		movem.l	(a7)+,d0/a0
		bne	includes_dos_wildcard_return

		movem.l	d0/a0,-(a7)
		moveq	#'?',d0
		bsr	strchr
		movem.l	(a7)+,d0/a0
includes_dos_wildcard_return:
		rts
****************************************************************
.xdef strcpy_export_pathname
.xdef slash_to_backslash

strcpy_export_pathname:
		bsr	strcpy
slash_to_backslash:
		movem.l	d0/a0,-(a7)
		moveq	#'/',d0
slash_to_backslash_loop:
		bsr	strchr
		beq	slash_to_backslash_done

		move.b	#'\',(a0)+
		bra	slash_to_backslash_loop

slash_to_backslash_done:
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
.xdef backslash_to_slash

backslash_to_slash:
		movem.l	d0/a0,-(a7)
		moveq	#'\',d0
backslash_to_slash_loop:
		bsr	strchr
		beq	backslash_to_slash_done

		move.b	#'/',(a0)+
		bra	backslash_to_slash_loop

backslash_to_slash_done:
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************

.end
