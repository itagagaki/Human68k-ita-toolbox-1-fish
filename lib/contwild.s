* contwild.s
* Itagaki Fumihiko 26-Aug-91  Create.

.text

*****************************************************************
* contain_dos_wildcard - •¶š—ñ–¼‚Ée*f‚à‚µ‚­‚Íe?f‚ªŠÜ‚Ü‚ê‚Ä
*                        ‚¢‚é‚©‚Ç‚¤‚©‚ğŒŸ¸‚·‚é
*
* CALL
*      A0     •¶š—ñ‚Ìæ“ªƒAƒhƒŒƒX
*
* RETURN
*      CCR    e*f‚à‚µ‚­‚Íe?f‚ªŠÜ‚Ü‚ê‚Ä‚¢‚é‚È‚ç‚Î NE
*****************************************************************
.xdef contains_dos_wildcard

contains_dos_wildcard:
		movem.l	d0/a0,-(a7)
contains_dos_wildcard_loop:
		move.b	(a0)+,d0
		beq	contains_dos_wildcard_done

		cmp.b	#'*',d0
		beq	contains_dos_wildcard_done

		cmp.b	#'?',d0
		bne	contains_dos_wildcard_loop
contains_dos_wildcard_done:
		tst.b	-(a0)
		movem.l	(a7)+,d0/a0
		rts

.end
