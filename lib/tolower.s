* tolower.s
* Itagaki Fumihiko 30-Sep-90  Create.

.xref isupper

.text

****************************************************************
* tolower - convert upper case alphabet character to lower case
*
* CALL
*      D0.B   character
*
* RETURN
*      none
*****************************************************************
.xdef tolower

tolower:
		jsr	isupper
		bne	done

		add.b	#$20,d0
done:
		rts

.end
