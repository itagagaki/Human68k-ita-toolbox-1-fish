* flagvar.s
* Itagaki Fumihiko 28-Feb-91  Create.

.xref strcmp

.xref flag_addsuffix
.xref flag_autolist
.xref flag_cdsysroot
.xref flag_ciglob
.xref flag_cifilec
.xref flag_echo
.xref flag_forceio
.xref flag_ignoreeof
.xref flag_listexec
.xref flag_listlinks
.xref flag_matchbeep
.xref flag_noalias
.xref flag_nobeep
.xref flag_noclobber
.xref flag_noglob
.xref flag_nonomatch
.xref flag_nonullcommandc
.xref flag_printexitvalue
.xref flag_pushdsilent
.xref flag_recexact
.xref flag_reconlyexec
.xref flag_savedirs
.xref flag_showdots
.xref flag_symlinks
.xref flag_usegets
.xref flag_verbose

.text

****************************************************************
* set_flagvar  フラグ変数名かどうかを調べ，もしそうならば
*              フラグ・データに値をセットする．
*
* CALL
*      D0.B   0:unset, 非0:set
*      A0     変数名
*      A1     set のとき、値のアドレス
*      D1.W   set のとき、値の要素数
*
* RETURN
*      D0.L   非0 なら set/unset した．
*      CCR    TST.L D0
****************************************************************
.xdef set_flagvar

set_flagvar:
		movem.l	d2-d3/a0-a4,-(a7)
		move.b	d0,d2				*  D2.B : set(非0) or unset(0)
		movea.l	a1,a2				*  A2 : 値のアドレス
		lea	flagvar_table,a3
		movea.l	a3,a4
find_flagvar:
		move.w	(a3)+,d0
		beq	flagvar_not_found

		move.w	(a3)+,d3
		lea	(a4,d0.w),a1
		bsr	strcmp
		beq	flagvar_found
		blo	flagvar_not_found

		btst	#15,d3
		beq	find_flagvar

		addq.l	#2,a3
		bra	find_flagvar

flagvar_found:
		movea.l	a2,a0				*  A0 : 値のアドレス
		move.w	d3,d0
		bclr	#15,d0
		lea	(a5,d0.w),a2			*  A2 : フラグアドレス
		tst.b	d2
		beq	set_flagvar_set			*  unset ... 0

		moveq	#-1,d2
		tst.w	d1
		beq	set_flagvar_set			*  set noword ... $ff

		moveq	#1,d2
		btst	#15,d3
		beq	set_flagvar_set			*  set word to boolean ... 1

		move.w	(a3),d0
		lea	(a4,d0.w),a3
		moveq	#0,d2
compare_value:
		addq.b	#1,d2
		move.w	(a3)+,d0
		beq	set_flagvar_set

		lea	(a4,d0.w),a1
		bsr	strcmp
		bne	compare_value
set_flagvar_set:
		move.b	d2,(a2)
		moveq	#1,d0
		bra	set_flagvar_return

flagvar_not_found:
		moveq	#0,d0
set_flagvar_return:
		movem.l	(a7)+,d2-d3/a0-a4
		rts
****************************************************************
* clear_flagvars  フラグ変数で制御されるフラグをすべてクリアする
*
* CALL
*      none
*
* RETURN
*      none
****************************************************************
.xdef clear_flagvars

clear_flagvars:
		move.l	a0,-(a7)
		lea	flagvar_table,a0
clear_flagvars_loop:
		tst.w	(a0)+
		beq	clear_flagvars_done

		move.w	(a0)+,d0
		bpl	clear_flagvar_1

		addq.l	#2,a0
		bclr	#15,d0
clear_flagvar_1:
		clr.b	(a5,d0.w)
		bra	clear_flagvars_loop

clear_flagvars_done:
		movea.l	(a7)+,a0
		rts
****************************************************************
.data

.xdef word_glob
.xdef word_echo
.xdef word_fignore
.xdef word_verbose

.even

flagvar_table:
		dc.w	word_addsuffix-flagvar_table
		dc.w	flag_addsuffix+$8000
		dc.w	addsuffix_values-flagvar_table

		dc.w	word_autolist-flagvar_table
		dc.w	flag_autolist

		dc.w	word_cdsysroot-flagvar_table
		dc.w	flag_cdsysroot

		dc.w	word_cifilec-flagvar_table
		dc.w	flag_cifilec

		dc.w	word_ciglob-flagvar_table
		dc.w	flag_ciglob

		dc.w	word_echo-flagvar_table
		dc.w	flag_echo

		dc.w	word_forceio-flagvar_table
		dc.w	flag_forceio

		dc.w	word_ignoreeof-flagvar_table
		dc.w	flag_ignoreeof

		dc.w	word_listexec-flagvar_table
		dc.w	flag_listexec

		dc.w	word_listlinks-flagvar_table
		dc.w	flag_listlinks

		dc.w	word_matchbeep-flagvar_table
		dc.w	flag_matchbeep+$8000
		dc.w	matchbeep_values-flagvar_table

		dc.w	word_noalias-flagvar_table
		dc.w	flag_noalias

		dc.w	word_nobeep-flagvar_table
		dc.w	flag_nobeep

		dc.w	word_noclobber-flagvar_table
		dc.w	flag_noclobber

		dc.w	word_noglob-flagvar_table
		dc.w	flag_noglob

		dc.w	word_nonomatch-flagvar_table
		dc.w	flag_nonomatch+$8000
		dc.w	nonomatch_values-flagvar_table

		dc.w	word_nonullcommandc-flagvar_table
		dc.w	flag_nonullcommandc

		dc.w	word_printexitvalue-flagvar_table
		dc.w	flag_printexitvalue

		dc.w	word_pushdsilent-flagvar_table
		dc.w	flag_pushdsilent

		dc.w	word_recexact-flagvar_table
		dc.w	flag_recexact

		dc.w	word_reconlyexec-flagvar_table
		dc.w	flag_reconlyexec

		dc.w	word_savedirs-flagvar_table
		dc.w	flag_savedirs

		dc.w	word_showdots-flagvar_table
		dc.w	flag_showdots+$8000
		dc.w	showdots_values-flagvar_table

		dc.w	word_symlinks-flagvar_table
		dc.w	flag_symlinks+$8000
		dc.w	symlinks_values-flagvar_table

		dc.w	word_usegets-flagvar_table
		dc.w	flag_usegets

		dc.w	word_verbose-flagvar_table
		dc.w	flag_verbose

		dc.w	0


addsuffix_values:
		dc.w	word_exact-flagvar_table
		dc.w	0

matchbeep_values:
		dc.w	word_nomatch-flagvar_table
		dc.w	word_ambiguous-flagvar_table
		dc.w	word_notunique-flagvar_table
		dc.w	0

nonomatch_values:
		dc.w	word_drop-flagvar_table
		dc.w	0

showdots_values:
		dc.w	word_MINUS_A-flagvar_table
		dc.w	0

symlinks_values:
		dc.w	word_chase-flagvar_table
		dc.w	word_ignore-flagvar_table
		dc.w	word_expand-flagvar_table
		dc.w	0


word_addsuffix:		dc.b	'addsuffix',0
word_autolist:		dc.b	'autolist',0
word_cdsysroot:		dc.b	'cdsysroot',0
word_cifilec:		dc.b	'cifilec',0
word_ciglob:		dc.b	'ciglob',0
word_echo:		dc.b	'echo',0
word_fignore:		dc.b	'f'
word_ignore:		dc.b	'ignore',0
word_forceio:		dc.b	'forceio',0
word_ignoreeof:		dc.b	'ignoreeof',0
word_noalias:		dc.b	'noalias',0
word_nobeep:		dc.b	'nobeep',0
word_noclobber:		dc.b	'noclobber',0
word_noglob:		dc.b	'no'
word_glob:		dc.b	'glob',0
word_listexec:		dc.b	'listexec',0
word_listlinks:		dc.b	'listlinks',0
word_matchbeep:		dc.b	'matchbeep',0
word_nonomatch:		dc.b	'no'
word_nomatch:		dc.b	'nomatch',0
word_nonullcommandc:	dc.b	'nonullcommandc',0
word_printexitvalue:	dc.b	'printexitvalue',0
word_pushdsilent:	dc.b	'pushdsilent',0
word_recexact:		dc.b	'rec'
word_exact:		dc.b	'exact',0
word_reconlyexec:	dc.b	'reconlyexec',0
word_savedirs:		dc.b	'savedirs',0
word_showdots:		dc.b	'showdots',0
word_symlinks:		dc.b	'symlinks',0
word_usegets:		dc.b	'usegets',0
word_verbose:		dc.b	'verbose',0

word_quick:		dc.b	'quick',0

word_ambiguous:		dc.b	'ambiguous',0
word_notunique:		dc.b	'notunique',0

word_drop:		dc.b	'drop',0

word_MINUS_A:		dc.b	'-A',0

word_chase:		dc.b	'chase',0
word_expand:		dc.b	'expand',0
****************************************************************

.end
