* expwords.s
* Itagaki Fumihiko 30-Sep-90  Create.

.xref subst_var_wordlist
.xref subst_command_wordlist
.xref unpack_wordlist
.xref glob_wordlist
.xref strip_quotes_list

.xref flag_noglob
.xref not_execute

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

		tst.b	flag_noglob(a5)
		bne	strip

		movea.l	a0,a1
		bsr	unpack_wordlist
		bmi	return

		tst.b	not_execute(a5)
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