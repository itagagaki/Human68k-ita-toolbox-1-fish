* fairpath.s
* Itagaki Fumihiko 20-Mar-93  Create.

.xref skip_root
.xref skip_slashes
.xref find_slashes
.xref memmovi

.text

****************************************************************
* fair_pathname - strip excessive slashes of pathname
*
* CALL
*      D0.L   size of result buffer
*      A0     result buffer
*      A1     pathname
*
* RETURN
*      CCR    CS:buffer full
*
* DESCRIPTION
*      // は / に置き換えられる
*      //foo//bar// は /foo/bar に置き換えられる
*      \ も / と同等に処理される
*      先頭のドライブ名 (?:) は無視される
*****************************************************************
.xdef fair_pathname

fair_pathname:
		movem.l	d0-d1/a0-a3,-(a7)
		move.l	d0,d1
		movea.l	a1,a2
		exg	a0,a2
		jsr	skip_root
		exg	a0,a2
		bsr	flush
		bcs	return

		exg	a0,a2
		jsr	skip_slashes
		exg	a0,a2
		beq	done
loop:
		movea.l	a2,a1
find_slash:
		exg	a0,a2
		jsr	find_slashes
		exg	a0,a2
		movea.l	a2,a3
		exg	a0,a3
		jsr	skip_slashes
		exg	a0,a3
		beq	finish

		addq.l	#1,a2
		bsr	flush
		bcs	return

		movea.l	a3,a2
		bra	loop

finish:
		bsr	flush
		bcs	return
done:
		clr.b	(a0)
return:
		movem.l	(a7)+,d0-d1/a0-a3
		rts

flush:
		move.l	a2,d0
		sub.l	a1,d0
		beq	flush_return

		sub.l	d0,d1
		bcs	flush_return

		jsr	memmovi
		cmp.w	d0,d0
flush_return:
		rts

.end
