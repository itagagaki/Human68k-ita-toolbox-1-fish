* getcwd.s
* Itagaki Fumihiko 14-Jul-90  Create.

.include doscall.h

.text

****************************************************************
* getcwd - get current working directory name
*
* CALL
*      A0     buffer point
*
* RETURN
*      None.
*****************************************************************
.xdef getcwd

getcwd:
		movem.l	d0/a0,-(a7)
		DOS	_CURDRV
		add.b	#'A',d0
		move.b	d0,(a0)+
		move.b	#':',(a0)+
		move.b	#'/',(a0)+
		move.l	a0,-(a7)
		move.l	a0,-(a7)
		clr.w	-(a7)
		DOS	_CURDIR
		addq.l	#6,a7
		move.l	(a7)+,a0
replace_loop:
		tst.b	(a0)
		beq	done

		cmpi.b	#'\',(a0)
		bne	replace_next

		move.b	#'/',(a0)
replace_next:
		addq.l	#1,a0
		bra	replace_loop
done:
		movem.l	(a7)+,d0/a0
		rts

.end
