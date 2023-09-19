* printvar.s
* Itagaki Fumihiko 24-Sep-90  Create.

.xref strfor1
.xref putc
.xref cputs
.xref put_tab
.xref put_newline
.xref echo

.text

****************************************************************
* print_var - 変数の値を表示する
*
* CALL
*      A0     変数の値の先頭アドレス
*      D0.W   変数の要素数
*
* RETURN
*      無し
****************************************************************
.xdef print_var_value

print_var_value:
		movem.l	d0-d2/a1,-(a7)
		move.w	d0,d2
		cmp.w	#1,d2
		beq	print_var_value_start

		move.b	#'(',d0			* ( を
		bsr	putc			* 表示する
print_var_value_start:
		move.w	d2,d0
		lea	cputs(pc),a1
		bsr	echo

		cmp.w	#1,d2
		beq	print_var_value_done

		move.b	#')',d0			* ) を
		bsr	putc			* 表示する
print_var_value_done:
		movem.l	(a7)+,d0-d2/a1
		rts
****************************************************************
* print_var - 変数を表示する
*
* CALL
*      A0     変数領域の先頭アドレス
*
* RETURN
*      無し
****************************************************************
.xdef print_var

print_var:
		movem.l	d0/a0-a1,-(a7)
		addq.l	#8,a0
loop:
		moveq	#0,d0
		move.w	(a0),d0			* この変数が占めるバイト数
		beq	done			* 0ならおしまい

		movea.l	a0,a1			* A1に
		adda.w	d0,a1			* 次の変数のアドレスをセット　（正しい）
		addq.l	#2,a0
		move.w	(a0)+,d0		* D0.W : この変数の要素数
		bsr	cputs			* 変数名を表示する
		bsr	put_tab			* 水平タブを表示する
		bsr	strfor1
		bsr	print_var_value		* 変数の値を表示する
		bsr	put_newline		* 改行する
		movea.l	a1,a0			* 次の変数のアドレス
		bra	loop			* 繰り返す

done:
		movem.l	(a7)+,d0/a0-a1
		rts

.end
