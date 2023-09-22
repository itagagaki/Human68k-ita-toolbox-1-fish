* expwords.s
* Itagaki Fumihiko 30-Sep-90  Create.

.text

.xdef expand_wordlist_var
.xdef expand_wordlist

expand_wordlist_var:
		bsr	subst_var_wordlist
		bmi	return

		movea.l	a0,a1
expand_wordlist:
		bsr	subst_command_wordlist
		bmi	return

		tst.b	flag_noglob
		bne	strip

		movea.l	a0,a1
		bsr	unpack_wordlist
		bmi	return

		tst.b	not_execute
		bne	return

		movea.l	a0,a1
		bsr	glob_wordlist
		bra	return

strip:
		bsr	strip_quotes_list
return:
		tst.l	d0
		rts

.end
