* cmdecho.s
* This contains built-in command 'echo'.
*
* Itagaki Fumihiko 19-Jul-90  Create.

.text

****************************************************************
*  Name
*       echo - echo arguments
*
*  Synopsis
*       echo [ -ne ] [ - ] [ word ... ]
****************************************************************
.xdef cmd_echo

cmd_echo:
		lea	puts(pc),a1		* A1 : print function pointer
		lea	put_newline(pc),a2	* A2 : finish function pointer
decode_opt_loop1:
		tst.w	d0
		beq	decode_opt_done

		cmpi.b	#'-',(a0)
		bne	decode_opt_done

		subq.w	#1,d0
		addq.l	#1,a0
		move.b	(a0)+,d7
		beq	decode_opt_done
decode_opt_loop2:
		cmp.b	#'n',d7
		beq	opt_n

		cmp.b	#'e',d7
		bne	bad_arg

		lea	eputs(pc),a1
		cmpa.l	#0,a2
		beq	decode_opt_nextch

		lea	eput_newline(pc),a2
		bra	decode_opt_nextch

opt_n:
		suba.l	a2,a2
decode_opt_nextch:
		move.b	(a0)+,d7
		bne	decode_opt_loop2
		bra	decode_opt_loop1

decode_opt_done:
		bsr	echo
		moveq	#0,d0
		rts

.end
