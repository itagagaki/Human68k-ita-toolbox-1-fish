* nextword.s
* Itagaki Fumihiko 11-Jul-90  Create.

.text

.xdef nextword

nextword:
		bsr	find_space
		bra	skip_space
.end
