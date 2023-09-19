* toupper.s
* Itagaki Fumihiko 30-Sep-90  Create.

.xref islower

.text

****************************************************************
* toupper - convert lower case alphabet character to upper case
*
* CALL
*      D0.B   character
*
* RETURN
*      none
*****************************************************************
.xdef toupper

toupper:
		jsr	islower
		bne	done

		sub.b	#$20,d0
done:
		rts

.end
