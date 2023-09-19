* rmtslash.s
* Itagaki Fumihiko 22-Aug-92  Create.

.xref issjis
.xref strmove

.text

****************************************************************
* strip_excessive_slashes - strip excessive slashes of pathname
*
* CALL
*      A0     pathname
*
* RETURN
*      none
*
* DESCRIPTION
*      // は / に置き換えられる
*      //foo//bar// は /foo/bar に置き換えられる
*      \ も / と同等に処理される
*      先頭のドライブ名 (?:) は無視される
*****************************************************************
.xdef strip_excessive_slashes

strip_excessive_slashes:
		movem.l	d0-d1/a0-a2,-(a7)
		tst.b	(a0)
		beq	return

		cmpi.b	#':',1(a0)
		bne	drive_skipped

		addq.l	#2,a0
drive_skipped:
		movea.l	a0,a2
		move.b	(a2),d0
		cmp.b	#'/',d0
		beq	skip_root

		cmp.b	#'\',d0
		bne	root_skipped
skip_root:
		addq.l	#1,a2
root_skipped:
		sf	d1
		movea.l	a0,a1
loop:
		move.b	(a1),d0
		beq	done

		cmp.b	#'/',d0
		beq	check_slash

		cmp.b	#'\',d0
		bne	not_slash
check_slash:
		tst.b	d1
		bne	continue

		lea	1(a1),a0
		st	d1
		bra	continue

not_slash:
		tst.b	d1
		beq	not_move

		sf	d1
		cmpa.l	a0,a1
		beq	not_move

		move.l	a0,-(a7)
		jsr	strmove
		movea.l	(a7)+,a1
not_move:
		move.b	(a1)+,d0
		jsr	issjis
		bne	loop

		tst.b	(a1)
		beq	done
continue:
		addq.l	#1,a1
		bra	loop

done:
		tst.b	d1
		beq	return

		cmpa.l	a2,a0
		beq	strip_trailing_slash

		subq.l	#1,a0
strip_trailing_slash:
		clr.b	(a0)
return:
		movem.l	(a7)+,d0-d1/a0-a2
		rts

.end
