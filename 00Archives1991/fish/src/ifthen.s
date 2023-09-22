* ifthen.s
* This contains if/else if/else/endif directive.
*
* Itagaki Fumihiko 13-Aug-90  Create.

.xref strcmp
.xref enputs
.xref expression2
.xref do_line
.xref set_status_1

.text

****************************************************************
*   1.  if expression command
*
*   2.  if expression then
*           command(s)
*       endif
*
*   3.  if expression then
*           command(s)
*       else
*           command(s)
*       endif
*
*   4.  if expression then
*           command(s)
*       [ else if expression then
*           command(s) ]
*       . . . . .
*       [ else
*           command(s) ]
*       endif
****************************************************************
.xdef state_if

state_if:
		move.w	d0,d7
		bsr	expression2
		bne	set_status_1	* rts

		tst.w	d7
		beq	if_synerr

		lea	token_then,a1
		bsr	strcmp
		beq	if_then
****************
		tst.l	d1
		beq	if_false

		move.w	d7,d0
		bra	do_line
****************
if_false:
		rts
****************
if_then:
		rts
****************
if_synerr:
		lea	msg_synerror(pc),a0
		bsr	enputs
		bra	set_status_1	* rts
****************************************************************
.data

token_then:		dc.b	'then',0
msg_synerror:		dc.b	'•¶–@‚ªˆá‚¢‚Ü‚·',0

.end
