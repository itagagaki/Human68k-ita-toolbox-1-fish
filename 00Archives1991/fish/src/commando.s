**
**  fish - Fumihiko Itagaki SHell
**
**  for Human68k (version 2.0 or lator)
**

.include doscall.h
.include iocscall.h
.include error.h
.include limits.h
.include chrcode.h
.include ../src/fish.h
.include ../src/source.h
.include ../src/random.h

PDB_envPtr	equ	$00
PDB_argPtr	equ	$10
PDB_rootFlag	equ	$50
PDB_dataPtr	equ	$f0
PDB_stackPtr	equ	$f8

.xref isspace
.xref issjis
.xref strlen
.xref strchr
.xref strcmp
.xref memcmp
.xref strcpy
.xref stpcpy
.xref strbot
.xref stricmp
.xref strmove
.xref memmove_inc
.xref for1str
.xref fornstrs
.xref find_space
.xref malloc
.xref xfreep
.xref str_blk_copy
.xref strcpy_export_pathname
.xref DecodeFishArgs
.xref EncodeFishArgs
.xref isatty
.xref init_irandom
.xref getenv
.xref chdir
.xref eputc
.xref puts
.xref nputs
.xref eputs
.xref ecputs
.xref enputs
.xref enputs1
.xref eput_newline
.xref fopen
.xref fgetc
.xref fgets
.xref fclose
.xref fclosex
.xref fskip_space
.xref remove
.xref redirect
.xref unredirect
.xref create_normal_file
.xref tmpfile
.xref setenv
.xref set_svar
.xref getcwd
.xref reset_cwd
.xref skip_space
.xref atou
.xref make_wordlist
.xref strip_quotes_list
.xref rehash
.xref set_svar_nul
.xref pre_perror
.xref make_home_filename
.xref put_prompt_1
.xref getline
.xref getline_phigical
.xref enter_history
.xref expand_wordlist
.xref expand_wordlist_var
.xref subst_history
.xref subst_alias
.xref subst_var_wordlist
.xref subst_var
.xref subst_var_2
.xref subst_command
.xref subst_command_2
.xref unpack_word
.xref expand_tilde
.xref glob
.xref isquoted
.xref isabsolute
.xref remove_colon_word
.xref skip_paren
.xref strip_quotes
.xref itoa
.xref check_wildcard
.xref find_shellvar
.xref svartou
.xref svartol
.xref echo
.xref divul
.xref mulul
.xref printu
.xref test_drive_path
.xref includes_dos_wildcard
.xref test_pathname
.xref cat_pathname
.xref hash
.xref state_if
.xref cmd_set_expression
.xref cmd_alias
.xref cmd_cd
.xref cmd_copy
.xref cmd_ctty
.xref cmd_del
.xref cmd_dir
.xref cmd_dirs
.xref cmd_echo
.xref cmd_eval
.xref cmd_exit
.xref cmd_glob
.xref cmd_goto
.xref cmd_hashstat
.xref cmd_history
.xref cmd_md
.xref cmd_onintr
.xref cmd_popd
.xref cmd_pushd
.xref cmd_pwd
.xref cmd_rehash
.xref cmd_ren
.xref cmd_repeat
.xref cmd_rd
.xref cmd_set
.xref cmd_setenv
.xref cmd_shift
.xref cmd_source
.xref cmd_time
.xref cmd_type
.xref cmd_unalias
.xref cmd_unhash
.xref cmd_unset
.xref cmd_unsetenv
.xref cmd_which
.xref perror
.xref too_long_line
.xref no_match
.xref cannot_because_no_memory
.xref word_echo
.xref word_verbose

.text

auto_pathname	equ	(((MAXPATH+1)+1)>>1<<1)

*****************************************************************
.even

texttop:
		dc.l	datatop
		dc.l	dataend-texttop
		dc.l	dataend+STACKSIZE	* 非BIND版のプログラム・スタック・ポインターの初期値
keepdatasize:	dc.l	keepdataend-datatop

start:
		DOS	_GETPDB
		movea.l	d0,a0
	**
	**  プログラム・スタック・ポインターを設定する
	**
		movea.l	PDB_stackPtr(a0),a7
	**
	**  非BIND版ならばメモリーを切り詰める
	**
		lea	texttop-$f0,a0		* A0 : 非BIND版ならばPDBアドレスに一致する
		cmpa.l	d0,a0
		bne	binded

		lea	dataend+STACKSIZE,a1
		suba.l	a0,a1
		move.l	a1,-(a7)
		move.l	a0,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
binded:
	**
	**  データ領域を設定する
	**
		bsr	chk_proc
		bne	i_am_child_shell
		*{
		*  吾輩は親シェルである ... 共通データを初期化する
			lea	datatop,a5
			move.l	#1,pid_count
			bra	save_work_done
		*}
i_am_child_shell:
		*{
		*  吾輩は子シェルである ... 親シェルのデータをセーブする
			exg	a0,a1
			move.l	keepdatasize,d0
			bsr	memmove_inc
			lea	datatop,a5
		*}
save_work_done:
		clr.l	a5
	**
	**  子シェル毎のデータを初期化する
	**
		move.b	#1,in_commando
		move.b	#1,exit_on_interrupt
		clr.l	lineno
		clr.l	command_argument
		clr.l	tmpgetlinebufp
		clr.b	flag_ciglob
		clr.b	flag_cifilec
		clr.b	flag_echo
		clr.b	flag_filec
		clr.b	flag_ignoreeof
		clr.b	flag_nobeep
		clr.b	flag_noclobber
		clr.b	flag_noglob
		clr.b	flag_nonomatch
		clr.b	flag_stdgets
		clr.b	flag_verbose
		clr.b	last_congetbuf
		clr.b	last_congetbuf+1
		clr.b	exit_on_error		* -e
		clr.b	not_execute		* -n
		clr.b	flag_t			* -t
		clr.b	flag_e			* -E
		clr.b	flag_e_size
		clr.b	flag_h_size

		*  標準入力はキャラクタ・デバイスか

		moveq	#0,d0
		bsr	isatty
		move.b	d0,input_is_tty
		move.b	d0,interactive_mode

		*  このシェルはログイン・シェルか

		DOS	_GETPDB
		movea.l	d0,a0
		move.l	PDB_rootFlag(a0),d0
		beq	login_shell_flag_ok

		moveq	#1,d0
login_shell_flag_ok:
		move.b	d0,i_am_login_shell

		*  乱数を初期化する

		bsr	getitimer
		bclr	#15,d0
		bsr	init_irandom
	**
	**  サブ・シェル毎のデータを初期化する
	**
		move.l	pid_count,pid
		add.l	#1,pid_count
		clr.l	rootdata
		clr.l	hash_hits
		clr.l	hash_misses
		clr.b	hash_flag
		bsr	init_bss
	**
	**  シグナル処理ルーチンを設定する
	**
		pea	manage_interrupt_signal(pc)
		move.w	#_CTRLVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7

		pea	manage_abort_signal(pc)
		move.w	#_ERRJVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7
	**
	**  環境を確保して親から継承する
	**
		DOS	_GETPDB
		movea.l	d0,a1			* A1 : 親の環境のアドレス
		movea.l	PDB_envPtr(a1),a1
		moveq	#0,d1
		cmpa.l	#-1,a1
		beq	make_current_env_1

		move.l	(a1),d1			* D1.L : 親の環境のサイズ
make_current_env_1:
		move.l	#512,d0			* D0.L : 確保すべき環境の大きさ デフォルト=512
		tst.b	flag_e			* ［まだ決まっていない！］
		beq	make_current_env_2

		*  -e フラグで指定された大きさとする
		move.b	flag_e_size,d0		* ［まだ決まっていない！］
		addq.l	#2,d0
		lsl.l	#8,d0
make_current_env_2:
		*  D1.L = max(D0.L, D1.L) を環境のサイズとする
		cmp.l	d1,d0
		bhs	make_current_env_3

		move.l	d1,d0
make_current_env_3:
		*  領域を確保して親の環境を継承する
		lea	envwork,a2
		bsr	malloc_block
		clr.b	(a0)
		cmpa.l	#-1,a1
		beq	make_current_env_4

		addq.l	#4,a1
		bsr	str_blk_copy
make_current_env_4:
		bsr	reset_envptr
	**
	**  履歴領域を確保する
	**
		moveq	#0,d0
		move.b	flag_h_size,d0		* ［まだ決まっていない！］

		addq.l	#8,d0			* ［8でほぼ100行分くらいだ］
		lsl.l	#8,d0
		lea	hiswork,a2
		bsr	malloc_block
		clr.w	(a0)
		move.l	#4,his_end
		move.l	#4,his_old
		move.l	#1,his_toplineno
		move.l	#100,his_nlines_max
		clr.l	his_nlines_now
	**
	**  ディレクトリ・スタック領域を確保する
	**
		move.l	#DSTACKSIZE,d0
		lea	dstack,a2
		bsr	malloc_block
		move.l	#10,(a0)+		* +4 (4) : 使用量
		clr.w	(a0)			* +8 (2) : 要素数
	**
	**  シェル変数領域を確保する
	**
		move.l	#SHELLVARSIZE,d0
		lea	shellvar,a2
		bsr	malloc_var
	**
	**  別名領域を確保する
	**
		move.l	#ALIASSIZE,d0
		lea	alias,a2
		bsr	malloc_var
	**
	**  作業領域を確保する
	**
		bsr	alloc_work
	**
	**  ログインシェルならば $HOME に chdir する
	**  ［login プログラムができるまでの暫定処置］
	**
		tst.b	i_am_login_shell
		beq	chdir_home_done

		lea	word_upper_home,a1
		movea.l	envwork,a0
		bsr	getenv
		beq	no_home

		movea.l	d0,a0
		tst.b	(a0)
		beq	no_home

		bsr	chdir
		bpl	chdir_home_done

		bsr	perror
		bra	set_default_home

no_home:
		lea	msg_no_home,a0
		bsr	enputs
set_default_home:
		lea	pathname_buf,a0
		bsr	getcwd
		movea.l	a0,a1
		bsr	ecputs
		lea	msg_set_default_home,a0
		bsr	enputs
		movea.l	a1,a0
		bsr	strcpy_export_pathname
		lea	word_upper_home,a0
		bsr	setenv
chdir_home_done:
	**
	**  環境変数 path をシェル変数 path にインポートする
	**
		movea.l	envwork,a0
		lea	word_path,a1
		bsr	getenv
		beq	init_path_default

		movea.l	d0,a2
		bsr	init_path_static
inport_path_loop:
		cmpi.b	#';',(a2)+
		beq	inport_path_loop

		tst.b	-(a2)
		beq	do_inport_path

		movea.l	a2,a0
		moveq	#';',d0
		bsr	strchr
		exg	a0,a2

		move.l	a2,d1
		sub.l	a0,d1
		cmp.l	#MAXWORDLEN,d1
		bhi	inport_path_too_long

		cmp.w	#1,d1
		bne	inport_path_1

		cmpi.b	#'.',(a0)
		beq	inport_path_loop
inport_path_1:
		add.l	d1,d2
		addq.l	#1,d2
		cmp.l	#MAXWORDLISTSIZE,d2
		bhi	inport_path_too_long

		addq.l	#1,d3
		cmp.l	#MAXWORDS,d3
		bhi	inport_path_too_long

		subq.w	#1,d1
inport_path_dup:
		move.b	(a0)+,d0
		bsr	issjis
		beq	inport_path_dup_2

		cmp.b	#'\',d0
		bne	inport_path_dup_1

		moveq	#'/',d0
		bra	inport_path_dup_1

inport_path_dup_2:
		tst.w	d1
		beq	inport_path_dup_1

		move.b	d0,(a1)+
		move.b	(a0)+,d0
inport_path_dup_1:
		move.b	d0,(a1)+
		dbra	d1,inport_path_dup

		clr.b	(a1)+
		bra	inport_path_loop

init_path_static:
		movem.l	d0/a0,-(a7)
		lea	tmpargs,a0
		lea	str_builtin_dir,a1
		bsr	strmove
		lea	str_current_dir,a1
		bsr	strmove
		movea.l	a0,a1
		lea	tmpargs,a0
		move.l	a1,d2
		sub.l	a0,d2		* D2.L : 単語並びの長さカウンタ
		moveq	#2,d3		* D3.L : 単語数カウンタ
		movem.l	(a7)+,d0/a0
		rts

inport_path_too_long:
		lea	word_path,a0
		bsr	inport_too_long0
init_path_default:
		bsr	init_path_static
do_inport_path:
		lea	tmpargs,a1
		move.w	d3,d0
		lea	word_path,a0
		moveq	#0,d1
		bsr	set_svar
init_path_done:
	**
	**  環境変数 temp をシェル変数 temp にインポートする
	**
		lea	word_temp,a2
		movea.l	a2,a1
		bsr	inport
	**
	**  環境変数 USER（無ければ LOGNAME）をシェル変数 user にインポートする
	**
		lea	word_user,a2
		lea	word_upper_user,a1
		bsr	inport
		bpl	inport_user_done

		lea	word_upper_logname,a1
		bsr	inport
inport_user_done:
	**
	**  環境変数 TERM をシェル変数 term にインポートする
	**
		lea	word_term,a2
		lea	word_upper_term,a1
		bsr	inport
	**
	**  環境変数 HOME をシェル変数 home にインポートする
	**
		lea	word_home,a2
		lea	word_upper_home,a1
		bsr	inport
	**
	**  シェル変数 shell を初期設定する
	**
		lea	word_shell,a0
		lea	init_shell,a1
		moveq	#1,d0
		moveq	#0,d1
		bsr	inport
	**
	**  シェル変数 prompt を初期設定する
	**
		lea	word_prompt,a0
		lea	init_prompt,a1
		moveq	#1,d0
		moveq	#0,d1
		bsr	set_svar
	**
	**  シェル変数 prompt2 を初期設定する
	**
		lea	word_prompt2,a0
		lea	init_prompt2,a1
		moveq	#1,d0
		moveq	#0,d1
		bsr	set_svar
	**
	**  シェル変数 cwd を初期設定する
	**
		bsr	reset_cwd
	**
	**  シェル変数 status を初期設定する
	**
		bsr	set_status_0
	**
	**  引数を解釈する
	**
		moveq	#0,d7
				* D7 : 10987654321098765432109876543210
				*                              VXvxfscb

		moveq	#0,d6	* D6 : 最後の -c のコマンド
		DOS	_GETPDB
		movea.l	d0,a0
		movea.l	PDB_argPtr(a0),a0
		addq.l	#1,a0
		bsr	DecodeFishArgs
		move.w	d0,d5
parse_args_loop:
		tst.w	d5
		beq	done_flag_argument_parsing

		btst	#0,d7			* -b
		bne	done_flag_argument_parsing

		cmpi.b	#'-',(a0)
		bne	done_flag_argument_parsing

		subq.w	#1,d5
		addq.l	#1,a0
parse_one_arg_loop:
		move.b	(a0)+,d0
		beq	parse_one_arg_done

		bsr	issjis
		beq	flag_parse_sjis

		moveq	#0,d1
		cmp.b	#'b',d0			* -b : break flag argument
		beq	set_flag

		moveq	#1,d1
		cmp.b	#'c',d0			* -c : 引数のコマンドを実行して終了
		beq	set_flag

		moveq	#2,d1
		cmp.b	#'s',d0			* -s : コマンドは標準入力から読み取る
		beq	set_flag

		moveq	#3,d1
		cmp.b	#'f',d0			* -f : %fishrc を実行しない
		beq	set_flag

		moveq	#4,d1
		cmp.b	#'x',d0			* -x : echo を set する
		beq	set_flag

		moveq	#5,d1
		cmp.b	#'v',d0			* -v : verbose を set する
		beq	set_flag

		moveq	#6,d1
		cmp.b	#'X',d0			* -X : %fishrc を実行する前に echo を set する
		beq	set_flag

		moveq	#7,d1
		cmp.b	#'V',d0			* -V : %fishrc を実行する前に verbose を set する
		beq	set_flag

		cmp.b	#'e',d0			* -e : exit on error
		beq	flag_e_found

		cmp.b	#'i',d0			* -i : interactive
		beq	flag_i_found

		cmp.b	#'n',d0			* -n : not execute
		beq	flag_n_found

		cmp.b	#'t',d0			* -t : Do 1 line from stdin
		beq	flag_t_found

		cmp.b	#'E',d0			* -E : 環境の大きさ
		beq	flag_xe_found

		cmp.b	#'H',d0			* -H : 履歴の大きさ
		beq	flag_xh_found

		bra	parse_one_arg_loop

set_flag:
		bset	d1,d7
		bra	parse_one_arg_loop

flag_parse_sjis:
		tst.b	(a0)+
		bne	parse_one_arg_loop
parse_one_arg_done:
		btst	#1,d7			* -c
		beq	parse_args_loop

		bclr	#1,d7			* -c
		moveq	#-1,d6
		tst.w	d5
		beq	parse_args_loop

		move.l	a0,d6
		bsr	for1str
		subq.w	#1,d5
		bra	parse_args_loop

flag_xe_found:
		bsr	atou
		move.l	d1,d2
		move.l	d0,d1
		move.b	(a0),d0
		bsr	for1str
		tst.b	d0
		bne	parse_args_loop

		tst.l	d1
		bne	parse_args_loop

		cmp.l	#$ff,d2
		bhi	parse_args_loop

		move.b	#1,flag_e
		move.b	d2,flag_e_size
		bra	parse_args_loop

flag_xh_found:
		bsr	atou
		move.l	d1,d2
		move.l	d0,d1
		move.b	(a0),d0
		bsr	for1str
		tst.b	d0
		bne	parse_args_loop

		tst.l	d1
		bne	parse_args_loop

		cmp.l	#$ff,d2
		bhi	parse_args_loop

		move.b	d2,flag_h_size
		bra	parse_args_loop

flag_i_found:
		move.b	#1,interactive_mode
		bset	#2,d7				* -s
		bra	parse_one_arg_loop

flag_n_found:
		move.b	#1,not_execute
flag_e_found:
		move.b	#1,exit_on_error
		bra	parse_one_arg_loop

flag_t_found:
		move.b	#1,flag_t
		bra	parse_one_arg_loop

done_flag_argument_parsing:
		tst.b	i_am_login_shell
		beq	flags_ok

		moveq	#0,d6				* -c のコマンド
		clr.b	exit_on_error			* -e
		moveq	#0,d5
flags_ok:
	**
	**  $0 と $argv を初期設定する
	**
		clr.l	argv0p
		move.w	d5,d0
		beq	set_argv

		tst.l	d6				* -c
		bne	set_argv

		tst.b	flag_t				* -t
		bne	set_argv

		btst	#2,d7				* -s
		bne	set_argv
set_argv0:
		move.l	a0,argv0p
		bsr	for1str
		subq.w	#1,d5
set_argv:
		move.w	d5,d0
		movea.l	a0,a1
		lea	word_argv,a0
		moveq	#0,d1
		bsr	set_svar
		bne	exit_shell_1
	**
	**  -V と -X を処理する
	**
		btst	#7,d7				* -V
		beq	preset_verbose_done

		bsr	set_verbose
preset_verbose_done:
		btst	#6,d7				* -X
		beq	preset_echo_done

		bsr	set_echo
preset_echo_done:
	**
	**  %fishrcを source する
	**
		movem.l	d6-d7,-(a7)
		btst	#3,d7				* -f
		bne	fishrc_done

		lea	dot_fishrc,a1
		bsr	run_home_source_if_any
fishrc_done:
	**
	**  ログイン・シェルならば %login を source する
	**
		tst.b	i_am_login_shell
		beq	login_done

		lea	dot_login,a1
		bsr	run_home_source_if_any
login_done:
		movem.l	(a7)+,d6-d7
	**
	**  -v と -x を処理する
	**
		btst	#5,d7				* -v
		beq	set_verbose_done

		bsr	set_verbose
set_verbose_done:
		btst	#4,d7				* -x
		beq	set_echo_done

		bsr	set_echo
set_echo_done:
		tst.l	d6				* -c
		bne	do_argument

		tst.b	flag_t				* -t
		bne	do_tty_line

		bsr	rehash

		tst.l	argv0p
		bne	do_file

		lea	main(pc),a0
		move.l	a0,mainjmp
		clr.b	exit_on_interrupt
main:
		bsr	run_source
		tst.b	exitflag
		bne	exit_shell

		tst.b	input_is_tty
		beq	exit_shell

		tst.b	flag_ignoreeof
		beq	exit_shell

		lea	msg_use_exit_to_leave_fish,a0
		bsr	enputs
		bra	main
*****************************************************************
do_tty_line:
		lea	ttymain(pc),a0
		move.l	a0,mainjmp
		clr.b	exit_on_interrupt
ttymain:
		bsr	do_line_getline
		bra	exit_shell
*****************************************************************
do_argument:
		tst.l	d6
		bmi	exit_shell_0

		movea.l	d6,a0
		bsr	strlen
		cmp.l	#MAXLINELEN,d0
		bhi	do_argment_too_long

		movea.l	a0,a1
		lea	line,a0
		bsr	strcpy
		bsr	do_line_substhist
		bra	exit_shell

do_argment_too_long:
		bsr	too_long_line
		bra	exit_shell_1
*****************************************************************
do_file:
		movea.l	argv0p,a0
		bsr	OpenLoadRun_source
		bra	exit_shell
*****************************************************************
*  ルート・シェルやサブ・シェル毎のデータを初期化する
*****************************************************************
init_bss:
		bsr	getitimer
		move.l	d1,shell_timer_high
		move.l	d0,shell_timer_low
		move.l	d1,last_yow_high
		move.l	d0,last_yow_low
		clr.l	current_source
		clr.l	onintr_pointer
		clr.l	command_name
		move.w	#-1,save_stdin
		move.w	#-1,save_stdout
		move.w	#-1,save_stderr
		move.w	#-1,undup_input
		move.w	#-1,undup_output
		clr.b	file1_del_flag
		clr.b	file2_del_flag
		clr.b	redirect_in1_out2
		clr.b	argment_pathname
		clr.b	prev_search
		clr.b	prev_lhs
		clr.b	prev_rhs
		rts
*****************************************************************
set_verbose:
		lea	word_verbose,a0
		bra	set_svar_nul
*****************************************************************
set_echo:
		lea	word_echo,a0
		bra	set_svar_nul
****************************************************************
* inport - 環境変数をシェル変数にインポートする
*
* CALL
*      A1     環境変数名
*      A2     シェル変数名
*
* RETURN
*      D1/A0-A1  破壊
*      D0.L   -1:環境変数は定義されていない  0:インポートした  1:エラー
*      CCR    TST.L D0
****************************************************************
inport:
		movea.l	envwork,a0
		bsr	getenv
		beq	not_inport

		movea.l	d0,a0
		bsr	strlen
		cmp.l	#MAXWORDLEN,d0
		bhi	inport_too_long

		lea	tmpword01,a1
back_slash_to_slash:
		move.b	(a0)+,d0
		bsr	issjis
		beq	back_slash_to_slash_dup_2

		cmp.b	#'\',d0
		bne	back_slash_to_slash_dup_1

		moveq	#'/',d0
		bra	back_slash_to_slash_dup_1

back_slash_to_slash_dup_2:
		move.b	d0,(a1)+
		move.b	(a0)+,d0
back_slash_to_slash_dup_1:
		move.b	d0,(a1)+
		bne	back_slash_to_slash

		movea.l	a2,a0
		lea	tmpword01,a1
		moveq	#1,d0
		moveq	#0,d1
		bra	set_svar

inport_too_long:
		movea.l	a1,a0
inport_too_long0:
		bsr	pre_perror
		lea	msg_inport_too_long,a0
		bra	enputs

not_inport:
		moveq	#-1,d0
		rts
*****************************************************************
malloc_var:
		bsr	malloc_block
		move.l	#8,(a0)+
		clr.w	(a0)
		rts
*****************************************************************
malloc_block:
		move.l	d0,d1
		bsr	malloc_or_abort
		movea.l	d0,a0
		move.l	a0,(a2)
		move.l	d1,(a0)+
		rts
*****************************************************************
.xdef malloc_or_abort

malloc_or_abort:
		bsr	malloc
		beq	exr_memerr

		rts
****************************************************************
reset_envptr:
		movem.l	d0/a0,-(a7)
		DOS	_GETPDB
		movea.l	d0,a0
		move.l	envwork,PDB_envPtr(a0)
		movem.l	(a7)+,d0/a0
		rts
****************************************************************
* chk_proc - 現プロセスのデータ領域アドレスと実際にアクセスされるデータアドレスを得る
*
* CALL
*      none
*
* RETURN
*      A0     実際にアクセスされるデータ領域のアドレス
*      A1     現プロセスのデータ領域アドレス
*      CCR    CMPA.L A0,A1
*****************************************************************
chk_proc:
		DOS	_GETPDB
		movea.l	d0,a0
		movea.l	PDB_dataPtr(a0),a1
		lea	datatop,a0
		cmpa.l	a0,a1
		rts
*****************************************************************
*								*
*	reallocate work memory (memory free and allocate)	*
*								*
*****************************************************************
re_alloc_work:
		bsr	free_work
*****************************************************************
*								*
*	allocate work memory					*
*								*
*****************************************************************
alloc_work:
		move.l	d0,-(a7)

		move.l	#DIRWORK,d0
		bsr	malloc_or_abort
		move.l	d0,work_area

		move.l	(a7)+,d0
		rts
*****************************************************************
*								*
*	free work memory					*
*								*
*****************************************************************
free_work:
		movem.l	d0/a0,-(a7)
		lea	work_area,a0
		bsr	xfreep
		movem.l	(a7)+,d0/a0
FreeSource_done:
		rts
*****************************************************************
*								*
*	reallocate batch work memory (default size)		*
*								*
*****************************************************************
.xdef FreeCurrentSource

FreeCurrentSource:
		tst.l	current_source
		beq	FreeSource_done

		bsr	free_work
		movem.l	d0/a0,-(a7)
		movea.l	current_source,a0
		move.l	SOURCE_PARENT(a0),current_source
		move.l	a0,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
		movem.l	(a7)+,d0/a0
		bra	alloc_work
*****************************************************************
reset_shell:
		move.l	(a7)+,a6
		DOS	_GETPDB
		movea.l	d0,a0
		movea.l	PDB_stackPtr(a0),a7
reset_shell_loop:
		bsr	FreeAllSources
		bsr	reset_io_del
		tst.l	rootdata
		beq	done_reset_shell

		move.l	alias,-(a7)
		DOS	_MFREE
		move.l	shellvar,(a7)
		DOS	_MFREE
		move.l	dstack,(a7)
		DOS	_MFREE
		move.l	hiswork,(a7)
		DOS	_MFREE
		move.l	envwork,(a7)
		DOS	_MFREE
		move.l	a1,-(a7)
		movea.l	rootdata,a1
		move.l	a1,-(a7)
		lea	datatop,a0
		move.l	#subdataend-datatop,d0
		bsr	memmove_inc
		DOS	_MFREE
		addq.l	#4,a7
		move.l	(a7)+,a1
		bra	reset_shell_loop

done_reset_shell:
		bsr	reset_envptr
		jmp	(a6)
*****************************************************************
manage_abort_signal:
		move.w	#$03fc,d0		* D0.W = 03FC
		cmp.w	#$100,d1
		bcs	manage_signals

		addq.w	#1,d0			* D0.W = 03FD
		cmp.w	#$200,d1
		bcs	manage_signals

		addq.w	#2,d0			* D0.W = 03FF
		cmp.w	#$ff00,d1
		bcc	manage_signals

		cmp.w	#$f000,d1
		bcc	manage_signals

		move.b	d1,d0
		bra	manage_signals
****************
manage_interrupt_signal:
		move.w	#$0200,d0
****************
manage_signals:
		tst.b	in_commando
		beq	exit_user_command
****************
action_after_signals:
		move.w	d0,-(a7)
		lea	tmpgetlinebufp,a0
		bsr	xfreep
		move.w	(a7)+,d0
		lsr.w	#8,d0
		cmp.b	#2,d0
		bne	terminate_running
****************
action_after_interrupt:
		move.l	current_source,d1
		beq	terminate_running

		move.l	onintr_pointer,d0
		beq	terminate_running

		cmp.l	#-1,d0
		beq	stop_run_longjump

		movea.l	d1,a0
		move.l	d0,SOURCE_POINTER(a0)
stop_run_longjump:
		movea.l	run_source_stackp,a7
		bra	run_source_loop
****************
terminate_running:
		tst.b	exit_on_interrupt
		bne	exit_shell_1

		tst.b	exit_on_error
		bne	exit_shell_1

		bsr	reset_shell
		bsr	re_alloc_work
		clr.l	command_name
.if 0
		DOS	_FFLUSH				* initialize disk
.endif
		movea.l	mainjmp,a0
		jmp	(a0)

exr_memerr:
		lea	msg_insufficient_memory,a0
		bsr	enputs
emergency:
		lea	msg_abort,a0
		bsr	enputs
exit_shell_1:
		moveq	#1,d0
		bra	exit_shell_d0

exit_shell_0:
		moveq	#0,d0
		bra	exit_shell_d0

exit_shell:
		bsr	get_status
exit_shell_d0:
		move.l	d0,d1
		bsr	reset_shell
		bsr	chk_proc
		beq	do_exit_shell

		move.l	keepdatasize,d0
		bsr	memmove_inc
do_exit_shell:
		move.l	d1,d0
exit_user_command:
		move.w	d0,user_command_signal
		move.w	d0,-(a7)
		DOS	_EXIT2
exit_shell_for:
		bra	exit_shell_for
*****************************************************************
FreeAllSources:
		tst.l	current_source
		beq	FreeSource_done

		bsr	FreeCurrentSource
		bra	FreeAllSources
*****************************************************************
**
**  () "" '' `` の対をチェックする
**
test_line:
		movem.l	d0-d3/a0,-(a7)
		move.w	d0,d1
		moveq	#0,d2		* D2 : () レベル
		bra	check_parens_and_quotes_continue

check_parens_and_quotes_loop:
		cmpi.b	#'(',(a0)
		bne	not_open_paren

		tst.b	1(a0)
		bne	not_open_paren
		*{
			addq.w	#1,d2
			bra	check_parens_and_quotes_next
		*}
not_open_paren:
		cmpi.b	#')',(a0)
		bne	not_close_paren

		tst.b	1(a0)
		bne	not_close_paren
		*{
			subq.w	#1,d2
			bcs	unmatched_paren
check_parens_and_quotes_next:
			bsr	for1str
			bra	check_parens_and_quotes_continue
		*}
not_close_paren:
		moveq	#0,d3				* D3 : ' " `
check_quotes:
		move.b	(a0)+,d0
		beq	check_quotes_break

		bsr	issjis
		beq	check_quotes_skip_1

		tst.b	d3
		beq	check_quotes_test_quote

		cmp.b	d3,d0
		bne	check_quotes
check_quotes_quotes:
		eor.b	d0,d3
		bra	check_quotes

check_quotes_test_quote:
		cmp.b	#'\',d0
		beq	check_quotes_escape

		cmp.b	#'"',d0
		beq	check_quotes_quotes

		cmp.b	#"'",d0
		beq	check_quotes_quotes

		cmp.b	#'`',d0
		beq	check_quotes_quotes

		bra	check_quotes

check_quotes_escape:
		move.b	(a0)+,d0
		beq	check_quotes_break

		bsr	issjis
		bne	check_quotes
check_quotes_skip_1:
		move.b	(a0)+,d0
		bne	check_quotes
check_quotes_break:
		move.b	d3,d0
		bne	unmatched
check_parens_and_quotes_continue:
		dbra	d1,check_parens_and_quotes_loop

		tst.w	d2
		bne	unmatched_paren
test_line_return:
		movem.l	(a7)+,d0-d3/a0
		rts

unmatched_paren:
		lea	msg_unmatched_parens,a0
		bra	unmatched_1

unmatched_accent:
		moveq	#'`',d0
unmatched:
		bsr	eputc
		bsr	eputc
		lea	msg_unmatched,a0
unmatched_1:
		bsr	enputs1
		bra	test_line_return
*****************************************************************
mdup:
		movea.l	(a2),a1
		move.l	(a1)+,d1
		move.l	d1,-(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	mdup_return

		movea.l	d0,a0
		move.l	a0,(a2)
		move.l	d1,(a0)+
		move.l	d1,d0
		subq.l	#4,d0
		bsr	memmove_inc
		moveq	#0,d0
mdup_return:
		rts
*****************************************************************
* fork
*
* CALL
*      A0     単語並び または 文字列
*      D0.W   A0が単語並びならば単語数．A0が文字列ならば文字列の長さ
*      D1.B   A0が単語並びならば0以外
*
* RETURN
*      D0.L   ステータス（ここではセットはしない）
*      CCR    TST.L D0
*****************************************************************
.xdef fork

fork:
		movem.l	d1-d7/a0-a6,-(a7)
		*
		*  プログラム・スタックとデータ領域を確保する
		*
		movea.l	a0,a3
		move.l	d0,d3
		move.b	d1,d4
		moveq	#1,d5				* status = 1
		moveq	#1,d6				* error = 1

		move.l	#subdataend-datatop+STACKSIZE,d0
		bsr	malloc
		beq	fork_fail1
		*
		*  現在のデータを待避する
		*
		move.l	a7,fork_stackp
		movea.l	d0,a0
		lea	datatop,a1
		move.l	#subdataend-datatop,d0
		move.l	a0,-(a7)
		bsr	memmove_inc
		movea.l	(a7)+,a0
		move.l	a0,rootdata
		adda.l	#subdataend-datatop+STACKSIZE,a0
		movea.l	a0,a7
		*
		*  ＢＳＳ初期化
		*
		bsr	init_bss
		*
		*  環境，履歴，ディレクトリ・スタック，シェル変数，別名を複製する
		*
		lea	envwork,a2
		bsr	mdup
		bmi	fork_fail2

		lea	hiswork,a2
		bsr	mdup
		bmi	fork_fail3

		lea	dstack,a2
		bsr	mdup
		bmi	fork_fail4

		lea	shellvar,a2
		bsr	mdup
		bmi	fork_fail5

		lea	alias,a2
		bsr	mdup
		bmi	fork_fail6
		*
		*  サブ・シェルを実行する
		*
		bsr	reset_envptr
		movea.l	a3,a0
		move.w	d3,d0
		tst.b	d4
		bne	fork_run

		movea.l	a0,a1
		lea	line,a0
		bsr	memmove_inc
		clr.b	(a0)
		lea	line,a0
		lea	args,a1
		move.l	a1,argsptr
		bsr	make_wordlist
		bmi	fork_ran

		movea.l	a1,a0
fork_run:
		bsr	do_line
		bsr	get_status
		move.l	d0,d5				* status = $status[1]
fork_ran:
		moveq	#0,d6				* error = 0
		*
		*  環境，履歴，ディレクトリ・スタック，シェル変数，別名を解放する
		*
		move.l	alias,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
fork_fail6:
		move.l	shellvar,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
fork_fail5:
		move.l	dstack,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
fork_fail4:
		move.l	hiswork,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
fork_fail3:
		move.l	envwork,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
fork_fail2:
		*
		*  プログラム・スタック・ポインタとデータを元に戻す
		*
		movea.l	rootdata,a1
		lea	datatop,a0
		move.l	#subdataend-datatop,d0
		move.l	a1,-(a7)
		bsr	memmove_inc
		movea.l	(a7)+,a1
		movea.l	fork_stackp,a7
		move.l	a1,-(a7)
		DOS	_MFREE
		addq.l	#4,a7
		bsr	reset_envptr
fork_fail1:
		lea	msg_fork_failure,a0
		tst.l	d6
		bne	cannot_because_no_memory

		move.l	d5,d0
		movem.l	(a7)+,d1-d7/a0-a6
		rts
*****************************************************************
bgfork:
		lea	msg_start,a0
		bsr	enputs
		link	a6,#-116
		pea	-116(a6)
		move.w	#-2,-(a7)
		DOS	_GET_PR
		addq.l	#6,a7
		move.l	-24(a6),a0
		unlk	a6
		move.l	4(a0),a1
		move.l	(a1)+,a0
		move.w	(a1)+,d0
		moveq	#1,d1
		bsr	fork
		lea	msg_done,a0
		bsr	enputs
		DOS	_KILL_PR
bgfork_for:
		bra	bgfork_for
*****************************************************************
load_source:
		move.w	d0,d2
		move.w	#2,-(a7)
		clr.l	-(a7)
		move.w	d2,-(a7)
		DOS	_SEEK
		addq.l	#8,a7
		tst.l	d0
		bmi	load_source_perror

		bsr	free_work
		add.l	#SOURCE_HEADER_SIZE+1,d0
		move.l	d0,d1
		bsr	malloc
		beq	batch_alloc_2

		movea.l	d0,a0
		move.l	d1,SOURCE_SIZE(a0)
		move.l	current_source,SOURCE_PARENT(a0)
		move.l	a0,current_source
batch_alloc_2:
		bsr	alloc_work
		tst.l	d0
		beq	load_source_error_2		* insufficient memory

		clr.w	-(a7)
		clr.l	-(a7)
		move.w	d2,-(a7)
		DOS	_SEEK
		addq.l	#8,a7

		movea.l	current_source,a1
		move.l	SOURCE_SIZE(a1),d1
		sub.l	#SOURCE_HEADER_SIZE,d1
		lea	SOURCE_HEADER_SIZE(a1),a0
		move.l	a0,SOURCE_POINTER(a1)
		move.l	d1,-(a7)	*read length (long)
		move.l	a0,-(a7)	*read buffer
		move.w	d2,-(a7)	*file handler
		DOS	_READ		*os read function
		lea	10(a7),a7
		tst.l	d0
		bmi	load_source_error_3		* read error

		adda.l	d0,a0
		move.b	#EOT,(a0)
		bsr	CloseSourceFile
		moveq	#0,d0
		rts

load_source_error_3:
		bsr	FreeCurrentSource
		bsr	CloseSourceFile
		lea	msg_read_err,a0
		bra	load_source_errorp

load_source_error_2:
		bsr	CloseSourceFile
		lea	msg_no_memory_for_source,a0
load_source_errorp:
		bsr	enputs
		bra	load_source_error_return

load_source_perror:
		bsr	perror
load_source_error_return:
		moveq	#1,d0
		rts

CloseSourceFile:
		move.w	d2,d0
		bra	fclose
*****************************************************************
* run_source - run source until EOF/EOT
*
* CALL
*      none
*
* RETURN
*      全て   破壊
*****************************************************************
.xdef OpenLoadRun_source

run_home_source_if_any:
		lea	pathname_buf,a0
		bsr	make_home_filename
		moveq	#0,d0
		bsr	fopen
		bmi	run_source_return

		bsr	LoadRun_source
		lea	word_exit,a0
		moveq	#1,d0
		bra	verbose

OpenLoadRun_source:
		moveq	#0,d0
		bsr	fopen
		bpl	LoadRun_source

		bsr	perror
		bra	set_status_1	* rts

LoadRun_source:
		bsr	load_source
		bne	set_status_1	* rts
run_source:
		move.l	run_source_stackp,-(a7)
		move.l	a6,-(a7)
		move.l	a7,run_source_stackp
		clr.b	exitflag
run_source_loop:
		bsr	do_line_getline
		tst.b	exitflag		* exit?
		bne	run_source_done

		tst.l	d0			* EOF?
		bpl	run_source_loop
run_source_done:
		bsr	FreeCurrentSource
		movea.l	(a7)+,a6
		move.l	(a7)+,run_source_stackp
run_source_return:
		rts
*****************************************************************
.xdef do_line

do_line_getline:
		**
		**  行を入力する
		**
		moveq	#1,d2			*  D2.B = 1 : コメントを削除する
		suba.l	a1,a1			*  A1 = NULL : プロンプトは無し

		tst.l	current_source
		bne	do_line_getline_2

		tst.b	input_is_tty
		beq	do_line_getline_1

		tst.b	flag_t
		bne	do_line_getline_1

		lea	put_prompt_1(pc),a1	* A1 : プロンプト出力ルーチン
do_line_getline_1:
		tst.b	interactive_mode
		beq	do_line_getline_2

		moveq	#0,d2			* D2.B = 0 : コメントは削除しない
do_line_getline_2:
		lea	line,a0
		move.w	#MAXLINELEN,d1
		lea	getline_phigical(pc),a2
		bsr	getline
		bne	do_line_return
****************
do_line_substhist:
		**
		**  履歴の置換を行う
		**
		lea	tmpline,a1
		move.w	#MAXLINELEN,d1
		clr.l	a2
		bsr	subst_history
		btst	#2,d0
		bne	set_status_1	* rts

		move.b	d0,d2
		lea	tmpline,a1
		lea	line,a0
		bsr	strcpy
		**
		**  単語を探す
		**
		lea	args,a1
		tst.l	current_source
		beq	find_words_1

		movea.l	current_source,a1
		lea	SOURCE_WORDLIST(a1),a1
find_words_1:
		bsr	make_wordlist
		bmi	set_status_1	* rts

		movea.l	a1,a0
		**
		**  verbose 表示をする
		**
		bsr	verbose_0
		**
		**  履歴に登録する
		**
		tst.l	current_source
		bne	skip_enter_history

		tst.b	interactive_mode
		beq	skip_enter_history

		bsr	enter_history
skip_enter_history:
		**
		**  行を解釈・実行する
		**
		btst	#0,d2			*  !:p
		bne	do_line_return

		move.l	a0,argsptr
		move.w	d0,argc
*****************************************************************
* do_line - １行を実行する
*
* CALL
*      A0      単語並び（破壊される。MAXWORDLISTSIZEバイト必要）
*      D0.W    単語数
*
* RETURN
*      全て    破壊
*      (tmpline)  破壊
*****************************************************************
do_line:
		bsr	test_line
		bne	set_status_1	* rts

		tst.b	not_execute
		bne	do_line_skip_subst_alias

		lea	tmpline,a1
		move.w	#MAXLINELEN,d1
		move.w	d0,d3
		bsr	subst_alias
		bne	set_status_1	* rts

		tst.b	d2
		beq	no_alias_substed

		moveq	#MAXALIASLOOP,d4		* D4 : 別名置換ループ・カウンタ
recurse_subst_alias:
		exg	a0,a1
		bsr	make_wordlist
		exg	a0,a1
		bmi	set_status_1	* rts

		btst	#1,d2
		beq	no_more_alias

		subq.w	#1,d4
		bcs	alias_loop_over

		move.w	#MAXLINELEN,d1
		move.w	d0,d3
		bsr	subst_alias
		bne	set_status_1	* rts

		tst.b	d2
		bne	recurse_subst_alias
no_alias_substed:
		move.w	d3,d0
no_more_alias:
		bsr	remove_colon_word
do_line_skip_subst_alias:
		tst.w	d0
		beq	do_line_return

		bsr	test_line
		bne	set_status_1	* rts

		movea.l	a0,a1
		bsr	strbot
		exg	a0,a1
		cmpa.l	a0,a1
		beq	not_label

		cmpi.b	#':',-1(a1)
		bne	not_label

		subq.w	#1,d0
		beq	set_status_0	* rts

		bsr	for1str
not_label:
		lea	statement_table,a1
		bsr	search_builtin
		beq	DoCommandList

		movea.l	a1,a2
		bsr	for1str
		subq.w	#1,d0
		movea.l	a0,a1
		lea	tmpargs,a0
		bsr	expand_wordlist_var
		bmi	set_status_1	* rts

		tst.b	not_execute
		bne	do_line_return

		move.l	10(a2),a2
		jmp	(a2)			* 文の処理

alias_loop_over:
		lea	msg_alias_loop,a0
		bsr	enputs
		bra	set_status_1	* rts
*****************************************************************
.xdef verbose

verbose_0:
		btst	#1,d2
		bne	verbose

		btst	#3,d2
		bne	do_print_verbose
verbose:
		tst.b	flag_verbose
		beq	print_verbose_done
do_print_verbose:
		bsr	echo_args
print_verbose_done:
do_line_return:
		rts
*****************************************************************
skip_redirect_token:
		tst.b	1(a0)
		beq	skip_redirect_token_1

		cmp.b	1(a0),d0
		bne	skip_redirect_token_9

		tst.b	2(a0)
		bne	skip_redirect_token_9
skip_redirect_token_1:
		addq.w	#1,d1
		bsr	for1str
		subq.w	#1,d7
		beq	skip_redirect_token_done

		cmpi.b	#'&',(a0)
		bne	skip_redirect_token_2

		tst.b	1(a0)
		bne	skip_redirect_token_2

		addq.w	#1,d1
		bsr	for1str
		subq.w	#1,d7
skip_redirect_token_2:
		tst.w	d7
		beq	skip_redirect_token_done

		cmpi.b	#'!',(a0)
		bne	skip_redirect_token_done

		tst.b	1(a0)
		bne	skip_redirect_token_done
skip_redirect_token_9:
		addq.w	#1,d1
		bsr	for1str
		subq.w	#1,d7
skip_redirect_token_done:
		rts
*****************************************************************
* DoCommandList - do command list
*
* CALL
*      A0      word list
*      D0.W    number of words
*
* RETURN
*      全て    破壊
*****************************************************************
TPIPE = 1
TLST  = 2
TOR   = 3
TAND  = 4

* A6
nextptr            = -4
nwords_next        = nextptr-2
connect_type       = nwords_next-1
pad1               = connect_type-1			* 偶数に合わせる

* A4
input_pathname     = -auto_pathname
output_pathname    = input_pathname-auto_pathname
tempptr            = output_pathname-4
last_connect_type  = tempptr-1
line_condition     = last_connect_type-1
here_document      = line_condition-1
output_cat         = here_document-1
output_both        = output_cat-1
output_nonoclobber = output_both-1
pad2               = output_nonoclobber-0		* 偶数に合わせる

DoCommandList:
		link	a6,#pad1
		link	a4,#pad2
		move.l	a0,nextptr(a6)
		move.w	d0,nwords_next(a6)
do_next_command_0:
		clr.b	last_connect_type(a4)
do_next_command:
		move.b	#1,line_condition(a4)
start_DoCommandList:
		move.w	nwords_next(a6),d0
		movea.l	nextptr(a6),a0
		not.b	redirect_in1_out2
		**
		**  & を探す
		**  （もしあれば、& までのリストはサブシェルで実行する）
		**
		movea.l	a0,a1			* A0 を待避
		move.w	d0,d7			* D7.W : 語数カウンタ
		moveq	#0,d1			* D1.W : このコマンド・リストの語数カウンタ
extract_simple_list:
		tst.w	d7
		beq	no_ampersand

		cmpi.b	#'(',(a0)
		bne	extract_simple_list_1

		tst.b	1(a0)
		bne	extract_simple_list_continue

		move.w	d7,d0
		bsr	skip_paren
		exg	d0,d7			* D7.W : ) 以降の単語数
		sub.w	d7,d0			* D0.W : ( から ) の直前までの単語数
		add.w	d0,d1
		bra	extract_simple_list_continue

extract_simple_list_1:
		move.b	(a0),d0
		cmp.b	#'&',d0
		beq	ampersand_found

		cmp.b	#'|',d0
		beq	extract_simple_list_vline

		cmp.b	#'>',d0
		beq	extract_simple_list_redirect
extract_simple_list_continue:
		bsr	for1str
		subq.w	#1,d7
		addq.w	#1,d1
		bra	extract_simple_list
****************
extract_simple_list_redirect:
		bsr	skip_redirect_token
		bra	extract_simple_list
****************
extract_simple_list_vline:
		tst.b	1(a0)
		bne	extract_simple_list_continue

		addq.w	#1,d1
		bsr	for1str
		subq.w	#1,d7
		beq	extract_simple_list

		cmpi.b	#'&',(a0)
		bne	extract_simple_list

		tst.b	1(a0)
		bne	extract_simple_list
		bra	extract_simple_list_continue
****************
ampersand_found:
		tst.b	1(a0)
		bne	extract_simple_list_continue

		bsr	for1str
		subq.w	#1,d7
		move.l	a0,nextptr(a6)
		move.w	d7,nwords_next(a6)
		tst.b	not_execute
		bne	do_next_command_0
.if 1
		*  バックグラウンド・プロセスのためのシステム・スタックを用意する

		move.l	#6*1024,d0
		bsr	malloc
		beq	bg_error

		add.l	#6*1024,d0
		movea.l	d0,a2				* A2 : bgプロセスの usp/ssp

		*  タスク間通信バッファを用意する

		move.l	#12+6,d0
		bsr	malloc
		beq	bg_error

		movea.l	d0,a3				* A3 : タスク間通信バッファ構造体
		move.l	#6,(a3)
		add.l	#12,d0
		move.l	d0,4(a3)
		move.w	#-1,10(a3)

		*  バックグラウンド・プロセスのためのメモリを用意する

		move.l	#128*1024,-(a7)
		move.w	#2,-(a7)
		DOS	_S_MALLOC
		addq.l	#6,a7
		tst.l	d0
		bmi	bg_error

		move.l	d0,d2				* D2 : bg プロセスに与えるメモリ

		*  スレッドをオープンする

		clr.l	-(a7)			* sleep
		move.l	a3,-(a7)		* buffer
		pea	bgfork(pc)		* initial PC
		move.w	sr,-(a7)		* initial SR
		pea	-256(a2)		* initial SSP
		pea	(a2)			* initial USP
		move.w	#10,-(a7)		* nice value
		pea	tmp_thred_name		* thred name
		DOS	_OPEN_PR
		lea	28(a7),a7
		move.l	d0,d3				* D3 : thred ID
		bmi	bg_error

		*  スレッドに MALLOC 可能なメモリを与える

		move.l	#16,-(a7)
		move.l	#128*1024,-(a7)
		move.l	d2,-(a7)
		move.w	d3,-(a7)
		DOS	_S_PROCESS
		lea	14(a7),a7
		tst.l	d0
		bmi	bg_error

		*  スレッドを起動する

		link	a6,#-6
		move.l	a1,-6(a6)
		move.w	d1,-2(a6)
		move.l	#6,-(a7)
		pea	-6(a6)
		clr.w	-(a7)
		move.w	d3,-(a7)
		clr.w	-(a7)
		DOS	_SEND_PR
		lea	14(a7),a7
		unlk	a6
		bra	do_next_command_0

bg_error:
		lea	msg_cannot_bg,a0
		bsr	enputs
		bra	do_next_command_0

.else

		movea.l	a1,a0
		move.w	d1,d0
		moveq	#1,d1
		unlk	a4
		bsr	fork
		link	a4,#pad2
		bra	do_next_command_0

.endif

********************************
no_ampersand:
		**
		**  単一のコマンドの終わりを見つける
		**
		movea.l	a1,a0
		move.w	d1,d7			* D7.W : 語数カウンタ
		moveq	#0,d1			* D1.W : この単一コマンドの語数カウンタ
		clr.b	connect_type(a6)	* 次のコマンドとの接続形式
find_command_separation:
		tst.w	d7
		beq	separation_done

		cmpi.b	#'(',(a0)
		bne	find_command_separation_1

		tst.b	1(a0)
		bne	find_command_separation_continue

		move.w	d7,d0
		bsr	skip_paren
		exg	d0,d7			* D7.W : ) 以降の単語数
		sub.w	d7,d0			* D0.W : ( から ) の直前までの単語数
		add.w	d0,d1
		bra	find_command_separation_continue

find_command_separation_1:
		move.b	(a0),d0
		cmp.b	#';',d0
		beq	semicolon_found

		cmp.b	#'|',d0
		beq	vertical_line_found

		cmp.b	#'&',d0
		beq	find_command_ampersand

		cmp.b	#'>',d0
		beq	find_command_redirect
find_command_separation_continue:
		bsr	for1str
		subq.w	#1,d7
		addq.w	#1,d1
		bra	find_command_separation
****************
find_command_redirect:
		bsr	skip_redirect_token
		bra	find_command_separation
****************
vertical_line_found:
		moveq	#TOR,d2
		tst.b	1(a0)
		bne	test_separator_2

		moveq	#TPIPE,d2
		bsr	for1str
		subq.w	#1,d7
		bsr	check_out_both
		bra	separator_found
****************
find_command_ampersand:
		moveq	#TAND,d2
test_separator_2:
		cmp.b	1(a0),d0
		bne	find_command_separation_continue

		tst.b	2(a0)
		bne	find_command_separation_continue

		bra	list_found_1
****************
semicolon_found:
		moveq	#TLST,d2
		tst.b	1(a0)
		bne	find_command_separation_continue
list_found_1:
		bsr	for1str
		subq.w	#1,d7
separator_found:
		move.b	d2,connect_type(a6)
		move.l	a0,nextptr(a6)
		move.w	d7,nwords_next(a6)
separation_done:
********************************
		**
		**  入出力切り換えを認識する
		**
		movea.l	a1,a0
		move.w	d1,d7			* D7.W : 語数カウンタ

		lea	simple_args,a1
		move.l	a1,argsptr
		clr.w	argc

		moveq	#0,d5			* D5.L : 入力ファイル名ポインタ
		moveq	#0,d6			* D6.L : 出力ファイル名ポインタ
find_redirection:
		tst.w	d7
		beq	find_redirection_done

		cmpi.b	#'(',(a0)
		bne	find_redirection_not_paren

		tst.b	1(a0)
		bne	find_redirection_not_paren

		movea.l	a0,a2
		move.w	d7,d0
		bsr	skip_paren
		exg	d0,d7
		sub.w	d7,d0
		add.w	d0,argc
		exg	a0,a2
		exg	a0,a1
		move.l	a2,d0
		sub.l	a1,d0
		bsr	memmove_inc
		exg	a0,a1
		exg	a0,a2
		bra	find_redirection_continue

find_redirection_not_paren:
		move.b	(a0),d0
		moveq	#0,d2
		cmp.b	#'<',d0
		beq	find_redirection_1

		moveq	#1,d2
		cmp.b	#'>',d0
		bne	find_redirection_continue
find_redirection_1:
		moveq	#0,d3
		tst.b	1(a0)
		beq	redirection_found

		cmp.b	1(a0),d0
		bne	find_redirection_continue

		moveq	#1,d3
		tst.b	2(a0)
		beq	redirection_found
find_redirection_continue:
		subq.w	#1,d7
		addi.w	#1,argc
		exg	a0,a1
		bsr	strmove
		exg	a0,a1
		bra	find_redirection
****************
redirection_found:
		tst.b	d2
		bne	redirect_out_found

		cmpi.b	#TPIPE,last_connect_type(a4)
		beq	input_ambiguous

		tst.l	d5
		bne	input_ambiguous

		bsr	for1str
		subq.w	#1,d7
		move.b	d3,here_document(a4)		* << フラグ
		bne	heredoc_found

		lea	input_pathname(a4),a2		* A2 : 入力先のファイル名格納処
		move.l	a2,d5				* D5 : 入力先ファイル名を示す
		bra	get_redirect_filename
****************
redirect_out_found:
		cmpi.b	#TPIPE,connect_type(a6)
		beq	output_ambiguous

		tst.l	d6
		bne	output_ambiguous

		move.b	d3,output_cat(a4)		* >> フラグ
		bsr	for1str
		subq.w	#1,d7
		bsr	check_out_both
		clr.b	output_nonoclobber(a4)
		tst.w	d7
		beq	rd_out_get_filename

		cmpi.b	#'!',(a0)
		bne	rd_out_get_filename

		tst.b	1(a0)
		bne	rd_out_get_filename

		move.b	#1,output_nonoclobber(a4)
		bsr	for1str
		subq.w	#1,d7
rd_out_get_filename:
		lea	output_pathname(a4),a2		* A2 : 出力先ファイル名格納処
		move.l	a2,d6				* D6 : 出力先ファイル名を示す
get_redirect_filename:
		tst.w	d7
		beq	missing_redirect_filename

		movea.l	a0,a3				* A3:ファイル名
		bsr	for1str				* A0:次の単語
		subq.w	#1,d7
		exg	a0,a3				* A0:ファイル名  A3:次の単語
		movem.l	a0-a1,-(a7)
		lea	tmpword01,a1
		moveq	#1,d0
		move.w	#MAXWORDLEN+1,d1
		bsr	subst_var
		movem.l	(a7)+,a0-a1
		beq	redirect_name_error
		bmi	redirect_name_error

		exg	a0,a3				* A0:次の単語  A3:ファイル名
		move.l	a0,-(a7)
		lea	tmpword01,a0
		exg	a1,a2
		move.l	#MAXPATH,d1
		bsr	expand_a_word
		exg	a1,a2
		movea.l	(a7)+,a0
		bpl	find_redirection

		movea.l	a3,a0				* A0:ファイル名
		cmp.l	#-5,d0
		bne	redirect_name_error

		moveq	#0,d0
redirect_name_error:
		cmp.l	#-4,d0
		beq	rd_error0

		bsr	strip_quotes
		bsr	pre_perror

		tst.l	d0
		beq	missing_redirect_filename

		addq.l	#1,d0
		beq	redirect_name_ambiguous

		lea	msg_too_long_pathname,a0
		bra	rd_error

redirect_name_ambiguous:
		tst.b	d2
		beq	input_ambiguous
		bra	output_ambiguous

missing_redirect_filename:
		lea	msg_missing_input,a0
		tst.b	d2
		beq	rd_error

		lea	msg_missing_output,a0
		bra	rd_error
****************
heredoc_found:
		tst.w	d7
		beq	missing_heredoc_word

		move.l	a0,d5
		bsr	for1str
		subq.w	#1,d7
		bra	find_redirection

missing_heredoc_word:
		lea	msg_missing_heredoc_word,a0
		bra	rd_error
********************************
find_redirection_done:
		**
		**  無効な空コマンドを検出する
		**
		tst.w	argc
		bne	not_null_command

		lea	msg_invalid_null_command,a0
		move.b	last_connect_type(a4),d0
		cmp.b	#TPIPE,d0
		beq	rd_error

		cmp.b	#TOR,d0
		beq	rd_error

		cmp.b	#TAND,d0
		beq	rd_error

		move.b	connect_type(a6),d0
		cmp.b	#TPIPE,d0
		beq	rd_error

		cmp.b	#TOR,d0
		beq	rd_error

		cmp.b	#TAND,d0
		beq	rd_error

		tst.l	d5
		bne	rd_error

		tst.l	d6
		bne	rd_error
not_null_command:
********************************
		**
		**  入力を切り換える
		**
		lea	pipe_file_1,a0
		lea	file1_del_flag,a3
		tst.b	redirect_in1_out2
		bne	redirect_in_1

		lea	pipe_file_2,a0
		lea	file2_del_flag,a3
redirect_in_1:
		cmpi.b	#TPIPE,last_connect_type(a4)
		beq	redirect_in_pipe

		clr.b	(a3)

		tst.l	d5
		beq	redirect_in_done

		tst.b	here_document(a4)
		bne	redirect_in_here_document

		movea.l	d5,a0
		bra	redirect_in_open
****************
redirect_in_pipe:
		move.b	#2,(a3)
****************
redirect_in_open:
		tst.b	not_execute
		bne	redirect_in_done

		moveq	#0,d0				* 読み込みモードで
		bsr	fopen				* 入力先ファイルをオープンする
		move.l	d0,d1				* デスクリプタを D1 にセット
		bmi	rd_perror

		move.w	d1,undup_input			* デスクリプタを undup_input に覚えておく

		bsr	isatty				* そいつがキャラクタデバイスで
		beq	redirect_in_ok			*   ないならばＯＫ

		move.w	d1,-(a7)			* そいつが
		move.w	#6,-(a7)			* ファイルハンドルを介して入力可能か
		DOS	_IOCTRL				* 調べる
		addq.l	#4,a7
		tst.l	d0				* 入力可能ならば
		bne	redirect_in_ok			*   ＯＫ

		lea	msg_not_inputable_device,a1
		bra	rd_errorp
****************
redirect_in_here_document:
		tst.b	not_execute
		bne	heredoc_open_ok

		movea.l	a0,a2
		bsr	tmpfile
		bmi	rd_error0

		move.w	d0,undup_input
		move.w	d0,d1				* D1.W : 埋め込み文書用一時ファイルのファイル・ハンドル
		move.b	#2,(a3)				* コマンド終了後即消去する
heredoc_open_ok:
		movea.l	d5,a0
		bsr	isquoted
		move.b	d0,d3				* D3 : 「クオートされている」フラグ
heredoc_loop:
		lea	line,a0
		suba.l	a1,a1
		move.w	d1,-(a7)
		move.w	#MAXLINELEN,d1
		bsr	getline_phigical
		move.w	(a7)+,d1
		tst.l	d0
		bmi	heredoc_eof
		bne	rd_error0

		lea	line,a0
		movea.l	d5,a1
		bsr	strcmp
		beq	heredoc_end

		tst.b	d3
		bne	heredoc_subst_ok

		move.l	d1,-(a7)
		lea	tmpline,a1
		move.w	#MAXLINELEN,d1
		moveq	#0,d0
		bsr	subst_var_2
		move.l	(a7)+,d1
		tst.l	d0
		bpl	heredoc_subst_var_ok
heredoc_subst_error:
		cmp.l	#-4,d0
		beq	rd_error0

		bsr	too_long_line
		bra	rd_error0

heredoc_subst_var_ok:
		lea	tmpline,a0
		lea	line,a1
		move.l	d1,-(a7)
		move.w	#MAXLINELEN,d1
		bsr	subst_command_2
		move.l	(a7)+,d1
		tst.l	d0
		bmi	heredoc_subst_error
heredoc_subst_ok:
		tst.b	not_execute
		bne	heredoc_loop

		lea	line,a0
		bsr	strlen
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		move.w	d1,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		tst.l	d0
		bmi	heredoc_write_error

		move.l	#2,-(a7)
		pea	str_newline
		move.w	d1,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		tst.l	d0
		bmi	heredoc_write_error

		bra	heredoc_loop

heredoc_write_error:
		movea.l	a2,a0
		bra	rd_perror

heredoc_eof:
		movea.l	d5,a0
		lea	msg_no_heredoc_terminator,a1
		bra	rd_errorp

heredoc_end:
		tst.b	not_execute
		bne	redirect_in_done

		clr.w	-(a7)				* 先頭
		clr.l	-(a7)				* 　まで
		move.w	d1,-(a7)			*
		DOS	_SEEK				* 　シークする
		addq.l	#8,a7
****************
redirect_in_ok:
		moveq	#0,d0				* 標準入力を
		bsr	redirect			*   リダイレクト
		bmi	rd_perror

		move.w	d0,save_stdin			* 旧デスクリプタのコピーをセーブ
redirect_in_done:
********************************
		**
		**  出力を切り換える
		**
		lea	pipe_file_2,a0
		lea	file2_del_flag,a3
		tst.b	redirect_in1_out2
		bne	rd_pipe_1

		lea	pipe_file_1,a0
		lea	file1_del_flag,a3
rd_pipe_1:
		clr.b	(a3)

		tst.b	not_execute
		bne	redirect_out_done

		cmpi.b	#TPIPE,connect_type(a6)
		beq	redirect_out_pipe

		tst.l	d6
		beq	redirect_out_done

		movea.l	d6,a0

		moveq	#0,d0				* まず読み込みモードで
		bsr	fopen				* 出力先ファイルをオープンしてみる
		move.l	d0,d2				* デスクリプタをD2にセット
		bpl	redirect_out_device_check	* オープンできたならデバイスチェック

		cmp.l	#-2,d0				* エントリがなければ
		beq	redirect_out_exist_check_done	*   チェック終わり

		bra	rd_perror
			* あとで本当にOPENしたときにもチェックするので不要と思うかも知れな
			* いが、CREATEではディレクトリへのアクセスが「このファイルは書き込
			* みできない」となってしまうので、ここで予めチェックしておく

redirect_out_device_check:
		bsr	isatty				* そいつがキャラクタデバイスかどうかを
		move.b	d0,d1				*   D1にセット
		moveq	#1,d0
		btst	#7,d1				* キャラクタ・デバイスで
		beq	redirect_out_device_check_done	*   なければチェック終わり

		move.w	d2,-(a7)			* そいつが
		move.w	#7,-(a7)			*   出力可能デバイスかどうか
		DOS	_IOCTRL				*   調べる
		addq.l	#4,a7
redirect_out_device_check_done:
		move.l	d0,-(a7)
		move.w	d2,d0
		bsr	fclose
		move.l	(a7)+,d0			* 出力可能
		bne	redirect_out_exist_check_done	* 　ならばＯＫ

		lea	msg_not_outputable_device,a1
		bra	rd_errorp

redirect_out_exist_check_done:
		tst.b	output_cat(a4)
		beq	redirect_out_not_cat
****************
		tst.l	d2				* 出力先ファイルが存在して
		bpl	redirect_out_open		*   いるならばＯＫ。オープンする

		tst.b	output_nonoclobber(a4)
		bne	redirect_out_create

		tst.b	flag_noclobber
		beq	redirect_out_create

		lea	msg_nofile,a1
		bra	rd_errorp

****************
redirect_out_not_cat:
		tst.l	d2				* 出力先ファイルが存在して
		bmi	redirect_out_create		* 　いないならばＯＫ。作成する

		btst	#7,d1				* キャラクタ・デバイス
		bne	redirect_out_open		* 　ならばＯＫ。オープンする

		tst.b	output_nonoclobber(a4)
		bne	redirect_out_create

		tst.b	flag_noclobber
		beq	redirect_out_create

		lea	msg_file_exists,a1
		bra	rd_errorp
****************
redirect_out_pipe:
		clr.b	output_cat(a4)
		bsr	tmpfile
		bmi	rd_error0

		move.b	#1,(a3)				* 次のコマンドの終了後には消去する
		bra	redirect_out_ready
****************
redirect_out_create:
		clr.b	output_cat(a4)
		bsr	create_normal_file
		bra	redirect_out_opened

redirect_out_open:
		moveq	#1,d0				* 書き込みモードで
		bsr	fopen				* 出力先ファイルをオープンする
redirect_out_opened:
		bmi	rd_perror
redirect_out_ready:
		move.w	d0,d1				* リダイレクト先を D1 にセットして
		move.w	d1,undup_output			*   undup_output に覚えておく

		tst.b	output_cat(a4)			* >> で
		beq	do_redirect_out			*   なければシークしない

		bsr	isatty				* リダイレクト先がキャラクタ・デバイス
		bne	do_redirect_out			*   ならばシークしない

		move.w	#2,-(a7)			* EOF
		clr.l	-(a7)				* 　まで
		move.w	d1,-(a7)			* 　出力を
		DOS	_SEEK				* 　シークする
		addq.l	#8,a7
do_redirect_out:
		moveq	#1,d0				* 標準出力を
		bsr	redirect			* リダイレクト
		bmi	rd_perror

		move.w	d0,save_stdout			* 旧デスクリプタのコピーをセーブ

		tst.b	output_both(a4)
		beq	redirect_out_done

		moveq	#2,d0				* 警告出力を
		bsr	redirect			* リダイレクト
		bmi	rd_perror

		move.w	d0,save_stderr			* 旧デスクリプタのコピーをセーブ
redirect_out_done:
********************************
		**
		**  単一のコマンドを実行する
		**
		moveq	#0,d0
		tst.b	line_condition(a4)
		beq	skip_simple_command

		unlk	a4
		bsr	DoSimpleCommand0
		link	a4,#pad2
skip_simple_command:
		move.b	connect_type(a6),d1
		move.b	d1,last_connect_type(a4)
		beq	command_done

		tst.b	not_execute
		bne	do_next_command

		cmp.b	#TOR,d1
		beq	do_next_or

		cmp.b	#TAND,d1
		bne	do_next_command
do_next_and:
		bsr	get_status
		tst.l	d0
		bne	command_done

		tst.l	d0
		beq	do_next_command

		bra	skip_next_command

do_next_or:
		bsr	get_status
		tst.l	d0
		bne	command_done

		tst.l	d0
		bne	do_next_command
skip_next_command:
		clr.b	line_condition(a4)
		bra	start_DoCommandList


input_ambiguous:
		lea	msg_input_ambiguous,a0
		bra	rd_error

output_ambiguous:
		lea	msg_output_ambiguous,a0
		bra	rd_error

rd_errorp:
		bsr	pre_perror
		movea.l	a1,a0
rd_error:
		bsr	enputs
		bra	rd_error0

rd_perror:
		bsr	perror
rd_error0:
		tst.b	file1_del_flag
		beq	rd_error1

		move.b	#2,file1_del_flag
rd_error1:
		tst.b	file2_del_flag
		beq	rd_error2

		move.b	#2,file2_del_flag
rd_error2:
		bsr	set_status_1
command_done:
		unlk	a4
		unlk	a6
		bra	reset_io
*****************************************************************
check_out_both:
		clr.b	output_both(a4)
		tst.w	d7
		beq	out_not_both

		cmpi.b	#'&',(a0)
		bne	out_not_both

		tst.b	1(a0)
		bne	out_not_both

		move.b	#1,output_both(a4)
		bsr	for1str
		subq.w	#1,d7
out_not_both:
		rts
*****************************************************************
* DoSimpleCommand - run a simple command
*
* CALL
*      D1.W   0以外ならば、消費時間を必ず報告する
*      simple_args
*      argc
*
* RETURN
*      全て   破壊
*****************************************************************
.xdef DoSimpleCommand0
.xdef DoSimpleCommand

timer_ok = -2
time_always = timer_ok-2
timer_start_low = time_always-4
timer_start_high = timer_start_low-4
timer_search_low = timer_start_high-4
timer_search_high = timer_search_low-4
timer_load_low = timer_search_high-4
timer_load_high = timer_load_low-4
timer_exec_low = timer_load_high-4
timer_exec_high = timer_exec_low-4

DoSimpleCommand0:
		moveq	#0,d1
DoSimpleCommand:
		link	a6,#timer_exec_high
		clr.w	user_command_signal
		clr.b	timer_ok(a6)
		move.w	d1,time_always(a6)
		move.w	argc,d0
		beq	simple_command_not_perform
	*
	*  コマンド・グループであるかどうかを調べる
	*
		lea	simple_args,a0
		cmpi.b	#'(',(a0)
		bne	is_not_command_group

		tst.b	1(a0)
		bne	is_not_command_group
	*
	*  コマンドはコマンド・グループである
	*
		movea.l	a0,a1
		subq.w	#1,d0
		bcs	badly_placed_paren

		bsr	fornstrs
		cmpi.b	#')',(a0)
		bne	badly_placed_paren

		tst.b	1(a0)
		bne	badly_placed_paren

		subq.w	#1,d0
		bcs	simple_command_not_perform

		movea.l	a1,a0
		bsr	for1str
		moveq	#1,d1
		bsr	fork
		bra	simple_command_done

is_not_command_group:
	*
	*  コマンドはコマンド・グループではない
	*
		move.w	argc,d0
		movea.l	a0,a1
		bsr	subst_var_wordlist
		bmi	simple_command_error0

		move.w	d0,argc
		beq	simple_command_not_perform

		tst.b	not_execute
		beq	start_do_simple_command

		movea.l	a0,a1
		bsr	expand_wordlist				* ただチェックのため
		bra	simple_command_not_perform

start_do_simple_command:
	*
	*  コマンド名を展開する
	*
		lea	simple_args,a0
		lea	command_pathname,a1
		move.l	#MAXPATH,d1
		bsr	expand_a_word
		bpl	command_name_ok

		cmp.l	#-4,d0
		beq	simple_command_error0

		lea	simple_args,a0
		bsr	strip_quotes
		bsr	pre_perror
		lea	msg_command_ambiguous,a0
		cmp.l	#-1,d0
		beq	simple_command_error

		lea	msg_missing_command_name,a0
		cmp.l	#-5,d0
		beq	simple_command_error

		lea	msg_too_long_command_name,a0
		bra	simple_command_error

command_name_ok:
	*
	*  コマンド・プログラムを検索する
	*
		bsr	getitimer			* 検索を開始した時刻を記憶する
		move.l	d0,timer_start_low(a6)
		move.l	d1,timer_start_high(a6)
		lea	command_pathname,a0
		moveq	#0,d0
		bsr	search_command			* 検索する
		move.l	d0,-(a7)
		bsr	getitimer			* 検索を終了した時刻を記憶する
		move.l	d0,timer_search_low(a6)
		move.l	d1,timer_search_high(a6)
		move.l	(a7)+,d0
		bmi	command_not_found

		add.l	#1,hash_hits
		cmp.l	#6,d0
		bls	simple_command_user_program
	*
	*  組み込みコマンド
	*
		move.l	d0,a1
		move.l	a1,command_name
		move.l	timer_search_low(a6),timer_load_low(a6)
		move.l	timer_search_high(a6),timer_load_high(a6)

		lea	simple_args,a0
		bsr	for1str
		move.w	argc,d0
		subq.w	#1,d0

		btst.b	#2,9(a1)
		bne	builtin_paren_ok

		bsr	check_paren
		bne	badly_placed_paren
builtin_paren_ok:
		*
		*  コマンドをエコーする
		*
		bsr	echo_command
		*
		*  引数並びを展開する
		*  （コマンドによっては、ここではまだ展開しない）
		*
		btst.b	#0,9(a1)
		bne	run_builtin

		exg	a1,a2
		movea.l	a0,a1
		lea	simple_args,a0
		bsr	expand_wordlist
		exg	a1,a2
		bmi	simple_command_error0
run_builtin:
		*
		* 組み込みコマンドを実行する
		*
		btst.b	#1,9(a1)
		beq	run_builtin_1

		move.w	d0,-(a7)
		bsr	set_status_0
		move.w	(a7)+,d0
run_builtin_1:
		move.l	a1,-(a7)
		movea.l	10(a1),a1
		jsr	(a1)
		movea.l	(a7)+,a1
		move.b	#1,timer_ok(a6)
		btst.b	#1,9(a1)
		beq	simple_command_done

		tst.l	d0
		bne	simple_command_done
		bra	simple_command_done_1

simple_command_user_program:
	*
	*  プログラム・ファイル
	*
		move.l	d0,d2				* D2.L : 拡張子コード

		lea	simple_args,a0
		movea.l	a0,a1
		bsr	for1str
		move.w	argc,d0
		subq.w	#1,d0
		bsr	check_paren
		bne	badly_placed_paren
		*
		*  引数並びを展開する
		*
		exg	a0,a1
		bsr	expand_wordlist
		bmi	simple_command_error0

		move.w	d0,argc
		*
		*  コマンドをエコーする
		*
		bsr	echo_command
		*
		*  実行可能か？
		*
		tst.l	d2
		beq	cannot_exec
		*
		*  実際に起動するバイナリ・コマンド・ファイルのパス名と
		*  パラメータ行を決定する
		*
		lea	user_program_parameter,a3	*  A3 : パラメータ行の先頭
		move.w	#MAXLINELEN,d3			*  D3.W : パラメータ行の最大文字数

		cmp.l	#3,d2
		bhi	do_binary_command
		beq	do_BAT_command

		lea	command_pathname,a0		* コマンド・ファイルを
		moveq	#0,d0				* 読み込みモードで
		bsr	fopen				* オープンする
		move.l	d0,d1
		bmi	cannot_exec			* オープンできない .. 実行不可

		move.w	d1,d0
		bsr	fgetc
		cmp.b	#'#',d0				* 先頭が # でなければ
		bne	cannot_exec_script		* 実行不可

		move.w	d1,d0
		bsr	fgetc
		cmp.b	#'!',d0				* # の次の文字が ! でなければ
		bne	cannot_exec_script		* 実行不可

		lea	command_pathname,a1		* コマンドのパス名を
		lea	pathname_buf,a0			* 一時領域に
		bsr	strcpy				* コピーしておく

		*  起動すべきシェルのパス名を読み取る
		move.w	d1,d0
		bsr	fskip_space
		bmi	by_default_shell
		beq	by_default_shell

		lea	command_pathname,a0
		move.w	#MAXPATH,d2
get_shell_loop:
		subq.w	#1,d2
		bcs	too_long_shellname

		move.b	d0,(a0)+
		move.w	d1,d0
		bsr	fgetc
		bmi	get_shell_done

		bsr	isspace
		bne	get_shell_loop
get_shell_done:
		clr.b	(a0)

		*  シェルに渡す引数を読み取る
		lea	congetbuf+2,a0			* ［暫定］
		clr.b	(a0)
		tst.l	d0
		bmi	get_shellarg_done

		cmp.b	#CR,d0
		beq	get_shellarg_done

		move.w	d1,d0
		bsr	fskip_space
		bmi	get_shellarg_done
		beq	get_shellarg_done

		move.b	d0,(a0)+
		move.w	d1,d0
		move.w	d1,-(a7)
		move.w	#254,d1
		bsr	fgets
		move.w	(a7)+,d1
		exg	d0,d1
		bsr	fclose
		cmp.l	#1,d1
		beq	hugearg_error
get_shellarg_done:
		lea	congetbuf+2,a1			* ［暫定］
		tst.b	(a1)
		beq	do_script_2

		moveq	#1,d1
		movea.l	a3,a0
		move.w	d3,d0
		bsr	EncodeFishArgs
		bmi	simple_command_too_long_line

		movea.l	a0,a3
		move.w	d0,d3
		bra	do_script_2
****************
by_default_shell:
		move.w	d1,d0
		bsr	fclose

		lea	default_shell_pathname,a1
		lea	word_shell,a0
		bsr	find_shellvar
		beq	do_script_1

		addq.l	#2,a0
		tst.w	(a0)+
		beq	do_script_1

		bsr	for1str
		bsr	strlen
		tst.l	d0
		beq	do_script_1

		cmp.l	#MAXPATH,d0
		bhi	too_long_default_shell_pathname

		movea.l	a0,a1
		bra	do_script_1
****************
do_BAT_command:
		lea	command_pathname,a1
		lea	pathname_buf,a0		* pathname_buf に
		bsr	strcpy_export_pathname	* \ を / に替えたコマンドのパス名をセット
		lea	command_x_pathname,a1	* A1 : 起動するバイナリ : A:/COMMAND.X
****************
do_script_1:
		lea	command_pathname,a0
		bsr	strcpy
do_script_2:
		lea	command_pathname,a0
		moveq	#1,d0
		bsr	search_command
		bmi	shell_not_found

		cmp.l	#3,d0
		bls	cannot_exec

		lea	pathname_buf,a1
		moveq	#1,d1
		movea.l	a3,a0
		move.w	d3,d0
		bsr	EncodeFishArgs
		bmi	simple_command_too_long_line

		movea.l	a0,a3
		move.w	d0,d3
****************
do_binary_command:
		bsr	getitimer
		move.l	d0,timer_search_low(a6)
		move.l	d1,timer_search_high(a6)

		lea	simple_args,a1
		move.w	argc,d1
		movea.l	a3,a0
		move.w	d3,d0
		bsr	EncodeFishArgs
		bmi	simple_command_too_long_line

		tst.w	d0
		beq	simple_command_too_long_line

		sub.w	#MAXLINELEN,d0
		neg.w	d0
		beq	do_binary_command_noarg

		clr.b	(a0)
		subq.w	#1,d0
		cmp.w	#255,d0
		bls	do_binary_command_arg_length_ok

		*  ユーザー・プログラムへの引数が255バイトを超えている
		*  シェル変数 hugearg[1] の値が
		*  indirect ならば
		*       引数を一時ファイルに書き込んで -+-+-filename を渡す
		*  force ならば
		*       長さフィールドは255としておいて、実は引数をそのまま置く
		*  さもなくば
		*       エラーとする
		*
		move.l	d0,d1
		lea	word_hugearg,a0
		bsr	find_shellvar
		beq	hugearg_error

		addq.l	#2,a0
		move.w	(a0)+,d2
		beq	hugearg_error

		bsr	for1str
		lea	word_indirect,a1
		bsr	strcmp
		beq	hugearg_indirect

		lea	word_force,a1
		bsr	strcmp
		beq	hugearg_force
hugearg_error:
		lea	msg_too_long_arg_for_program,a0
		bra	simple_command_error

hugearg_indirect:
		lea	str_indirect_flag,a1
		cmp.w	#2,d2
		blo	hugearg_indirect_flag_ok

		bsr	for1str
		tst.b	(a0)
		beq	hugearg_indirect_flag_ok

		movea.l	a0,a1
hugearg_indirect_flag_ok:
		lea	argment_pathname,a0
		bsr	tmpfile
		bmi	simple_command_error0

		move.w	d0,d2
		move.l	d1,-(a7)
		pea	user_program_parameter+1
		move.w	d2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		move.l	d0,d1
		move.w	d2,d0
		bsr	fclose
		exg	d0,d1
		tst.l	d0
		bmi	simple_command_perror

		exg	d0,d1
		tst.l	d0
		bmi	simple_command_perror

		movea.l	a0,a2
		lea	user_program_parameter+1,a0
		bsr	stpcpy
		move.l	d0,d1
		movea.l	a2,a1
		bsr	strcpy
		add.l	d1,d0
		cmp.l	#255,d0
		blo	do_binary_command_arg_length_ok

		lea	msg_too_long_indirect_flag,a0
		bra	simple_command_error

hugearg_force:
		moveq	#-1,d0	* D0.B := 255
		bra	do_binary_command_arg_length_ok

do_binary_command_noarg:
		clr.b	1(a0)
do_binary_command_arg_length_ok:
		move.b	d0,user_program_parameter

		bsr	free_work
		move.l	a6,-(a7)
		move.l	envwork,-(a7)		*  環境のアドレス
		pea	user_program_parameter	*  パラメータのアドレス
		pea	command_pathname	*  起動するコマンドのパス名のアドレス
		move.w	#1,-(a7)		*  ファンクション：LOAD
		clr.b	in_commando
		DOS	_EXEC
		lea	14(a7),a7
		tst.l	d0
		bmi	loadprg_stop

		tst.w	user_command_signal
		bne	loadprg_stop		*  既に EXIT された

		movem.l	d0-d1,-(a7)
		bsr	getitimer
		move.l	d0,timer_load_low(a6)
		move.l	d1,timer_load_high(a6)
		movem.l	(a7)+,d0-d1

		move.l	d0,-(a7)		*  エントリ・アドレス
		move.w	#4,-(a7)		*  ファンクション：EXEC
		DOS	_EXEC
		addq.l	#6,a7
loadprg_stop:
		move.b	#1,in_commando
		movea.l	(a7)+,a6
		move.l	d0,-(a7)
		DOS	_CHANGE_PR
		bsr	alloc_work
		move.l	(a7)+,d0
		tst.l	d0
		bmi	loadexec_error

		cmp.l	#$10000,d0
		bcs	binary_command_done

		and.l	#$ff,d0
		or.l	#$100,d0
binary_command_done:
		move.b	#2,timer_ok(a6)
simple_command_done:
		bsr	set_status
simple_command_done_1:
		move.l	d0,d7
		tst.b	timer_ok(a6)
		beq	count_command_time_ok

		bsr	getitimer
		move.l	d0,timer_exec_low(a6)
		move.l	d1,timer_exec_high(a6)
count_command_time_ok:
		clr.l	command_name
		bsr	reset_io
		move.w	user_command_signal,d0
		bne	action_after_signals

		move.l	d7,d0
		lsr.w	#8,d0
		cmp.b	#2,d0
		beq	action_after_interrupt

		cmp.b	#3,d0
		beq	terminate_running

		tst.b	timer_ok(a6)
		beq	simple_command_return

		lea	puts(pc),a1
		tst.w	time_always(a6)
		bne	report_command_time

		cmp.b	#2,timer_ok(a6)
		blo	simple_command_return

		lea	word_time,a0
		bsr	svartou
		beq	simple_command_return		* time は定義されていない
		bmi	simple_command_return		* $time[1] はオーバーフロー

		move.l	d1,d4				* D4 : $time[1]の値
		move.l	timer_exec_low(a6),d0
		move.l	timer_exec_high(a6),d1
		move.l	timer_load_low(a6),d2
		move.l	timer_load_high(a6),d3
		bsr	count_time_sec
		cmp.l	d4,d0
		blo	simple_command_return

		lea	eputs(pc),a1
report_command_time:
		lea	msg_total_time,a0
		move.l	timer_exec_low(a6),d0
		move.l	timer_exec_high(a6),d1
		move.l	timer_start_low(a6),d2
		move.l	timer_start_high(a6),d3
		bsr	count_time
		bsr	report_time

		lea	msg_exec_time,a0
		move.l	timer_exec_low(a6),d0
		move.l	timer_exec_high(a6),d1
		move.l	timer_load_low(a6),d2
		move.l	timer_load_high(a6),d3
		bsr	count_time
		bsr	report_time

		lea	msg_load_time,a0
		move.l	timer_load_low(a6),d0
		move.l	timer_load_high(a6),d1
		move.l	timer_search_low(a6),d2
		move.l	timer_search_high(a6),d3
		bsr	count_time
		bsr	report_time

		lea	msg_search_time,a0
		move.l	timer_search_low(a6),d0
		move.l	timer_search_high(a6),d1
		move.l	timer_start_low(a6),d2
		move.l	timer_start_high(a6),d3
		bsr	count_time
		bsr	report_time
simple_command_return:
		move.l	d7,d0
		unlk	a6
		rts


simple_command_not_perform:
		moveq	#0,d0
		bra	simple_command_done_1


badly_placed_paren:
		lea	msg_badly_placed_paren,a0
		bra	simple_command_error

shell_not_found:
		moveq	#ENOFILE,d0
		lea	command_pathname,a0
simple_command_perror:
		bsr	perror
simple_command_error0:
		moveq	#1,d0
		bra	simple_command_done

simple_command_too_long_line:
		bsr	too_long_line
		bra	simple_command_done

too_long_default_shell_pathname:
		lea	msg_too_long_default_shell,a0
		bra	simple_command_error

too_long_shellname:
		move.w	d1,d0
		bsr	fclose
		lea	msg_too_long_shellname,a1
		bra	simple_command_errorp

loadexec_error:
		lea	msg_loadexec_error,a1
		bra	simple_command_errorp

cannot_exec_script:
		move.w	d1,d0
		bsr	fclose
cannot_exec:
		lea	msg_cannot_exec,a1
		bra	simple_command_errorp

command_not_found:
		lea	msg_no_command,a1
simple_command_errorp:
		lea	command_pathname,a0
		bsr	pre_perror
		movea.l	a1,a0
simple_command_error:
		bsr	enputs1
		bra	simple_command_done
****************************************************************
check_paren:
		movem.l	d0/a0,-(a7)
		bra	check_paren_continue

check_paren_loop:
		cmpi.b	#'(',(a0)
		beq	check_paren_1

		cmpi.b	#')',(a0)
		bne	check_paren_next
check_paren_1:
		tst.b	1(a0)
		beq	check_paren_break
check_paren_next:
		bsr	for1str
check_paren_continue:
		dbra	d0,check_paren_loop
check_paren_break:
		addq.w	#1,d0
		movem.l	(a7)+,d0/a0
not_echo_command:
		rts
****************************************************************
echo_command:
		tst.b	flag_echo
		beq	not_echo_command

		movem.l	d0/a0,-(a7)
		lea	command_pathname,a0
		bsr	ecputs
		moveq	#' ',d0
		bsr	eputc
		movem.l	(a7)+,d0/a0
		bra	echo_args
****************************************************************
.xdef set_status_1

set_status_1:
		moveq	#1,d0
		bra	set_status

set_status_0:
		moveq	#0,d0
set_status:
		link	a6,#-12
		movem.l	d0-d1/a0-a1,-(a7)
		lea	-12(a6),a0
		bsr	itoa
		bsr	skip_space
		movea.l	a0,a1
		lea	word_status,a0
		moveq	#1,d0
		moveq	#0,d1
		bsr	set_svar
		movem.l	(a7)+,d0-d1/a0-a1
		unlk	a6
		tst.b	exit_on_error
		beq	set_status_return

		tst.l	d0
		bne	exit_shell
set_status_return:
		rts
*****************************************************************
* get_status - シェル変数 status の値を数値に変換する
*
* CALL
*      none
*
* RETURN
*      D0.L   $status[1]の値．ただし $status[1]がエラーならば 1
*      CCR    $status[1]がエラーならば NZ
*
* NOTE
*      $status[1]がエラーならばエラー・メッセージを表示する
*****************************************************************
get_status:
		movem.l	d1/a0,-(a7)
		lea	word_status,a0
		bsr	svartol
		cmp.l	#4,d0
		beq	get_status_ok

		lea	msg_bad_status,a0
		bsr	enputs
		moveq	#0,d1
		moveq	#0,d0
get_status_ok:
		exg	d0,d1
		cmp.l	#4,d0
		movem.l	(a7)+,d1/a0
		rts
*****************************************************************
echo_args:
		movem.l	a0-a2,-(a7)
		lea	ecputs(pc),a1
		clr.l	a2
		bsr	echo
		bsr	eput_newline
		movem.l	(a7)+,a0-a2
		rts
*****************************************************************
.xdef getitimer

getitimer:
		IOCS	_ONTIME
		rts
*****************************************************************
.xdef count_time

count_time:
		sub.l	d3,d1		* D1 : 24時間以上部分の日数
		sub.l	d2,d0		* D0 : 24時間未満部分の1/100秒数
		bcc	count_time_1

		add.l	#24*60*60*100,d0
		subq.l	#1,d1
count_time_1:
		move.l	d1,-(a7)
		move.l	#60*60*100,d1
		bsr	divul
		move.l	d0,d3		* D3 : 1時間以上24時間未満部分の時間数
		move.l	d1,d2		* D2 : 1時間未満部分の1/100秒数
		move.l	(a7)+,d1
		move.l	#24,d0
		bsr	mulul		* D1:D0 : 24時間以上部分の日数を時間数に換算した値
		tst.l	d1
		bne	count_time_hour_overflow

		add.l	d3,d0
		bcs	count_time_hour_overflow

		cmp.l	#99,d0
		bls	count_time_hour_ok
count_time_hour_overflow:
		moveq	#99,d0
count_time_hour_ok:
		move.l	#60*60*100,d1
		bsr	mulul
		add.l	d2,d0
		rts
*****************************************************************
.xdef count_time_sec

count_time_sec:
		bsr	count_time
		move.l	#100,d1
		bra	divul
*****************************************************************
.xdef report_time

report_time:
		movem.l	d0-d3/a0,-(a7)
		jsr	(a1)
		moveq	#2,d2
		moveq	#0,d3
		cmp.l	#60*60*100,d0
		bhs	report_time_hour

		lea	space3,a0
		jsr	(a1)
		cmp.l	#60*100,d0
		bhs	report_time_minute

		jsr	(a1)
		bra	report_time_second

report_time_hour:
		move.l	#60*60*100,d1
		bsr	divul
		bsr	printu
		lea	str_colon,a0
		jsr	(a1)
		move.l	d1,d0
		moveq	#2,d2
		moveq	#1,d3
report_time_minute:
		move.l	#60*100,d1
		bsr	divul
		bsr	printu
		lea	str_colon,a0
		jsr	(a1)
		move.l	d1,d0
		moveq	#1,d3
report_time_second:
		move.l	#100,d1
		bsr	divul
		bsr	printu
		lea	str_dot,a0
		jsr	(a1)
		move.l	d1,d0
		moveq	#1,d3
		bsr	printu
		lea	str_newline,a0
		jsr	(a1)
		movem.l	(a7)+,d0-d3/a0
		rts
****************************************************************
.xdef is_builtin_dir

is_builtin_dir:
		movem.l	d0/a1,-(a7)
		lea	str_builtin_dir,a1
		bsr	strcmp
		movem.l	(a7)+,d0/a1
		rts
****************************************************************
.xdef builtin_dir_match

builtin_dir_match:
		movem.l	d1/a1,-(a7)
		lea	str_builtin_dir,a1
		exg	a0,a1
		bsr	strlen
		move.l	d0,d1
		bsr	memcmp
		exg	a0,a1
		beq	builtin_dir_match_ok

		moveq	#0,d1
builtin_dir_match_ok:
		move.l	d1,d0
		movem.l	(a7)+,d1/a1
		rts
*****************************************************************
search_builtin:
		move.l	d0,-(a7)
search_builtin_loop:
		tst.b	(a1)
		beq	search_builtin_done

		bsr	strcmp
		beq	search_builtin_done

		lea	14(a1),a1
		bra	search_builtin_loop

search_builtin_done:
		move.l	(a7)+,d0
		tst.b	(a1)
		rts
****************************************************************
* implicit_executable - 暗黙の実行可能拡張子かどうかを調べる
*
* CALL
*      A0     パス名
*
* RETURN
*      D0.L   5: .R
*             4: .Z
*             3: .X
*             2: .BAT
*             1: 拡張子無し
*             0: 上記以外の拡張子
*
*      A0     拡張子部をさす
*
*      CCR    TST.L D0
****************************************************************
implicit_executable:
		movem.l	d1/a1,-(a7)
		moveq	#1,d1
		move.b	#'.',d0
		bsr	strchr			* '.'は、もしあっても1つだけ
		beq	implicit_executable_return

		movea.l	a0,a1
		lea	ext_table,a0
implicit_executable_compare:
		tst.b	(a0)
		beq	not_implicit_executable

		addq.l	#1,d1
		bsr	stricmp
		beq	implicit_executable_matched

		bsr	for1str
		bra	implicit_executable_compare

not_implicit_executable:
		moveq	#0,d1
implicit_executable_matched:
		movea.l	a1,a0
implicit_executable_return:
		move.l	d1,d0
		movem.l	(a7)+,d1/a1
		rts
*****************************************************************
* find_command - コマンドを検索する
*
* CALL
*      A0     検索するコマンドのパス名
*             拡張子は省略可能だが、その場合、最大４文字が(A0)の
*             末尾に付加されるので、その分の余裕があること。
*
*      D0.B   検索するパス名に拡張子が無いならば 0
*             （その場合、（メタ・ディレクトリでなければ）拡張子を補って検索する）
*
* RETURN
*      D0.L    6: 見つかった .R
*              5:            .Z
*              4:            .X
*              3:            .BAT
*              2:            拡張子無し
*              1:            上記以外の拡張子
*              0: 見つかったが、実行不可能であることが明らかである
*             -1: 見当たらない
*             上記以外 : 組み込みコマンド表のアドレス
*
*      CCR    TST.L D0
*****************************************************************
filebuf = -(((54)+1)>>1<<1)

find_command:
		link	a6,#filebuf
		movem.l	d1-d4/a0-a2,-(a7)
		move.b	d0,d3
		bsr	builtin_dir_match
		beq	find_real_command_file

		move.b	(a0,d0.l),d1
		cmp.b	#'/',d1
		beq	find_bultin_command

		cmp.b	#'\',d1
		bne	find_real_command_file
****************
find_bultin_command:
		lea	1(a0,d0.l),a0
		lea	command_table,a1
		bsr	search_builtin
		beq	command_file_not_found

		move.l	a1,d0
		bra	find_command_done
****************
find_real_command_file:
		bsr	test_drive_path
		bne	command_file_not_found

		tst.b	d3
		bne	find_command_static_ext

		movea.l	a0,a2
		bsr	strbot
		lea	ext_asta,a1
		bsr	strcpy
		exg	a0,a2
find_command_static_ext:
		move.w	#$37,-(a7)		* ボリューム・ラベル以外
		move.l	a0,-(a7)
		pea	filebuf(a6)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
		bmi	command_file_not_found

		lea	filebuf+30(a6),a0
		bsr	implicit_executable		* D0.L : 拡張子コード
		move.b	filebuf+21(a6),d4		* D4.B : ファイル・モード
		tst.b	d3
		bne	command_file_found

		* 拡張子は指定されていない
		* .R, .Z, .X, .BAT, 拡張子無しの順位で最も優先順位の高いものを選ぶ

		moveq	#0,d1
find_more_loop:
		cmp.l	d1,d0
		bls	find_more

		move.l	d0,d1
		move.b	filebuf+21(a6),d4
		movea.l	a0,a1
		movea.l	a2,a0
		bsr	strcpy
find_more:
		pea	filebuf(a6)
		DOS	_NFILES
		addq.l	#4,a7
		tst.l	d0
		bmi	find_more_done

		lea	filebuf+30(a6),a0
		bsr	implicit_executable
		bra	find_more_loop

find_more_done:
		move.l	d1,d0
		beq	command_file_not_found
command_file_found:
		*  D0.L : 拡張子コード
		*  D4.B : ファイル・モード
		addq.l	#1,d0			* 下駄
		and.b	#$18,d4
		beq	find_command_done

		moveq	#0,d0
find_command_done:
		movem.l	(a7)+,d1-d4/a0-a2
		unlk	a6
		tst.l	d0
		rts

command_file_not_found:
		add.l	#1,hash_misses
		moveq	#-1,d0
		bra	find_command_done
*****************************************************************
* search_command - コマンドを検索する
*
* CALL
*      A0     検索するコマンド名
*             長さは MAXPATH 以下であること
*
*             検索されたコマンド・パス名は同じアドレスに格納される
*             MAXPATH+1 必要
*
*      D0.B   0 以外だと、$path 中のメタ・ディレクトリを無視する
*
* RETURN
*      D0.L    6: 見つかった .R
*              5:            .Z
*              4:            .X
*              3:            .BAT
*              2:            拡張子無し
*              1:            上記以外の拡張子
*              0: 見つかったが、実行不可能であることが明らかである
*             -1: 見当たらない
*             上記以外 : 組み込みコマンド表のアドレス
*
*      CCR    TST.L D0
*****************************************************************
.xdef search_command

exp_command_name = -auto_pathname

search_command:
		link	a6,#exp_command_name
		movem.l	d1-d4/a0-a3,-(a7)
		move.b	d0,d4				* D4 : 「メタ・ディレクトリ無視」フラグ

		bsr	includes_dos_wildcard		* Human のワイルドカードを含んで
		bne	search_command_not_found	* いるならば無効

		bsr	test_pathname
		bhi	search_command_not_found

		move.b	(a3),d3				* D3.B : 拡張子フラグ
		cmpa.l	a0,a2				* A2 == A0 (arg)
		beq	search_command_with_path
	*
	*  ドライブ＋ディレクトリ部がある .. このまま検索する
	*
		movea.l	a0,a2				* A2 : arg
		movea.l	a2,a1
		lea	exp_command_name(a6),a0		* A0 : buffer
		bsr	strcpy
		move.b	d3,d0
		bsr	find_command
		bmi	search_command_return
		bra	search_command_found

search_command_with_path:
	*
	*  ディレクトリ部がない .. $path に従って検索する
	*
		lea	word_path,a0
		bsr	find_shellvar
		beq	search_command_not_found

		addq.l	#2,a0
		move.w	(a0)+,d1			* D1.W : $path の要素数
		beq	search_command_not_found

		subq.w	#1,d1
		bsr	for1str
		move.l	a0,-(a7)			* pathlist のアドレスを退避

		moveq	#-1,d2
		tst.b	hash_flag
		beq	hash_ok

		movea.l	a2,a0
		bsr	hash
		lea	hash_table,a0
		move.b	(a0,d0.l),d2
hash_ok:
		movea.l	(a7)+,a0			* A0 : pathlist
		lea	exp_command_name(a6),a1		* A1 : buffer
search_command_with_path_loop:
		ror.b	#1,d2
		bcs	search_command_with_path_try	* ハッシュがヒットしたならばトライする

		bsr	is_builtin_dir
		beq	search_command_with_path_not_try

		bsr	isabsolute
		beq	search_command_with_path_not_try
search_command_with_path_try:
		bsr	is_builtin_dir
		bne	search_command_with_path_try_ok

		tst.b	d4
		beq	search_command_with_path_try_ok
search_command_with_path_not_try:
		bsr	for1str
		bra	search_command_with_path_continue

search_command_with_path_try_ok:
		cmpi.b	#'.',(a0)
		bne	search_command_with_path_cat

		tst.b	1(a0)
		bne	search_command_with_path_cat

		* カレントディレクトリ
		bsr	for1str				* A0:nextpath A1:buffer    A2:arg
		exg	a0,a1				* A0:buffer   A1:nextpath  A2:arg
		exg	a1,a2				*             A1:arg       A2:nextpath
		bsr	strcpy
		exg	a1,a2				*             A1:nextpath  A2:arg
		bra	search_command_with_path_find

search_command_with_path_cat:
		exg	a0,a1				* A0:buffer   A1:currpath  A2:arg
		bsr	cat_pathname			*             A1:nextpath
		exg	a0,a1				* A0:nextpath A1:buffer
		bmi	search_command_with_path_continue

		exg	a0,a1				* A0:buffer   A1:nextpath
search_command_with_path_find:
		move.b	d3,d0
		bsr	find_command
		bpl	search_command_found

		exg	a0,a1				* A0:nextpath A1:buffer
search_command_with_path_continue:
		dbra	d1,search_command_with_path_loop
search_command_not_found:
		moveq	#-1,d0
search_command_return:
		movem.l	(a7)+,d1-d4/a0-a3
		unlk	a6
		rts

search_command_found:
		move.l	d0,-(a7)
		movea.l	a0,a1
		movea.l	a2,a0
		bsr	strcpy
		move.l	(a7)+,d0
		bra	search_command_return
*****************************************************************
* expand_a_word - 1つの単語をコマンド置換、ファイル名展開して
*                 1つの単語を得る
*
* CALL
*      A0     ソース単語（長さは MAXWORDLEN 以内であること）
*      A1     展開単語領域
*      D1.L   展開単語領域の大きさ（最後の NUL の分は含まない）
*
* RETURN
*      D0.W    0 : 成功．ファイル名展開は無かった
*              1 : 成功．ファイル名が 1つ以上展開された
*             -1 : 単語数が 2語以上になった
*             -2 : 単語の長さが長過ぎる
*             -4 : 他のさまざまなエラー（メッセージが表示される）
*             -5 : ファイル名展開以前に単語が無くなった
*****************************************************************
.xdef expand_a_word

tmpwordbuf1 = -(((MAXWORDLEN+1)+1)>>1<<1)
tmpwordbuf2 = tmpwordbuf1-(((MAXWORDLEN+1)+1)>>1<<1)

expand_a_word:
		link	a6,#tmpwordbuf2
		movem.l	a0-a2/d1-d3,-(a7)
		movea.l	a1,a2			*  A2 : destination
		move.l	d1,d3
	*
	*  コマンド置換
	*
	*  source -> tmp1
	*
		lea	tmpwordbuf1(a6),a1
		moveq	#1,d0
		move.w	#MAXWORDLEN+1,d1
		bsr	subst_command
		bmi	expand_a_word_fail
		beq	expand_a_word_miss

		lea	tmpwordbuf1(a6),a0	*  ここまでの結果は tmp1 にある
		tst.b	flag_noglob		*  noglob が set されて
		bne	expand_a_word_stop	*  いるならば、これでおしまい
	*
	*  {} を展開する
	*
	*  tmp1 -> tmp2
	*
		lea	tmpwordbuf2(a6),a1
		move.w	#MAXWORDLEN+1,d1
		bsr	unpack_word
		bmi	expand_a_word_fail
		beq	expand_a_word_miss

		lea	tmpwordbuf2(a6),a0	*  ここまでの結果は tmp2 にある
		tst.b	not_execute		*  あとの展開は実行時の状況次第で
		bne	expand_a_word_stop	*  あるから、-n ではここまでとする
	*
	*  ~ を展開する
	*
	*  tmp2 -> tmp1
	*
		lea	tmpwordbuf1(a6),a1
		move.w	#MAXWORDLEN+1,d1
		moveq	#1,d2
		bsr	expand_tilde
		bmi	expand_a_word_fail

		lea	tmpwordbuf1(a6),a0	*  ここまでの結果は tmp1 にある
		bsr	check_wildcard		*  単語が * ? [ を含んで
		beq	expand_a_word_stop	*  いないならばおしまい
	*
	*  * ? [] を展開する
	*
	*  tmp1 -> tmp2
	*
		lea	tmpwordbuf2(a6),a1
		moveq	#1,d0
		move.w	#MAXPATH+1,d1
		bsr	glob
		bmi	expand_a_word_fail
		beq	expand_a_word_nomatch

		lea	tmpwordbuf2(a6),a0
		moveq	#1,d0
		bra	expand_a_word_store

		*  nomatch は無視して、展開しない単語を返す
expand_a_word_stop:
		bsr	strip_quotes
		moveq	#0,d1
expand_a_word_store:
		bsr	strlen
		cmp.l	d3,d0
		bhi	expand_a_word_too_long

		movea.l	a0,a1
		movea.l	a2,a0
		bsr	strcpy
		move.l	d1,d0
expand_a_word_return:
		movem.l	(a7)+,a0-a2/d1-d3
		unlk	a6
		tst.l	d0
		rts


expand_a_word_miss:
		moveq	#-5,d0
		bra	expand_a_word_return

expand_a_word_nomatch:
		tst.b	flag_nonomatch		*  nonomatch が set されて
		bne	expand_a_word_stop	*  いるならば無視する

		bsr	strip_quotes
		bsr	pre_perror
		bsr	no_match
		moveq	#-4,d0
		bra	expand_a_word_return

expand_a_word_fail:
		cmp.l	#-3,d0
		bne	expand_a_word_return
expand_a_word_too_long:
		moveq	#-2,d0
		bra	expand_a_word_return
*****************************************************************
*								*
*	reset input/output redirection file			*
*								*
*****************************************************************
reset_io_del:
		tst.b	file1_del_flag
		beq	reset_io_del_1

		move.b	#2,file1_del_flag
reset_io_del_1:
		tst.b	file2_del_flag
		beq	reset_io

		move.b	#2,file2_del_flag
reset_io:
		tst.b	not_execute
		bne	reset_io_done

		movem.l	d0-d1/a0,-(a7)

		moveq	#0,d0
		move.w	save_stdin,d1
		bsr	unredirect
		move.w	d0,save_stdin
*
		moveq	#1,d0
		move.w	save_stdout,d1
		bsr	unredirect
		move.w	d0,save_stdout
*
		moveq	#2,d0
		move.w	save_stderr,d1
		bsr	unredirect
		move.w	d0,save_stderr
*
		move.w	undup_input,d0
		bsr	fclosex
		move.w	#-1,undup_input
*
		move.w	undup_output,d0
		bsr	fclosex
		move.w	#-1,undup_output
*
		cmp.b	#2,file1_del_flag
		bne	reset_io_5

		lea	pipe_file_1,a0
		bsr	remove
		clr.b	file1_del_flag
reset_io_5:
		cmp.b	#2,file2_del_flag
		bne	reset_io_6

		lea	pipe_file_2,a0
		bsr	remove
		clr.b	file2_del_flag
reset_io_6:
		lea	argment_pathname,a0
		tst.b	(a0)
		beq	reset_io_7

		bsr	remove
		clr.b	(a0)
reset_io_7:
		movem.l	(a7)+,d0-d1/a0
reset_io_done:
		rts
*****************************************************************
.xdef errs_print

errs_print:
		move.l	d0,-(a7)
		and.l	#$ff,d0
		lea	msg_normal_err,a0
		cmp.b	#$11,d0
		bhi	errs_print_1

		lsl.l	#2,d0
		lea	errmsgtable,a0
		move.l	(a0,d0.l),a0
errs_print_1:
		bsr	enputs
		move.l	(a7)+,d0
		rts
*****************************************************************
*****************************************************************
*****************************************************************
.data

.xdef err_table
.xdef command_table

.xdef str_nul
.xdef str_newline
.xdef str_space
.xdef str_current_dir
.xdef dos_allfile
.xdef word_upper_home
.xdef word_upper_term
.xdef word_upper_user
.xdef word_alias
.xdef word_argv
.xdef word_cdpath
.xdef word_history
.xdef word_home
.xdef word_path
.xdef word_prompt
.xdef word_shell
.xdef word_status
.xdef word_temp
.xdef word_term
.xdef word_unalias
.xdef word_user
.xdef msg_ambiguous
.xdef msg_dirnofile
.xdef msg_disk_full
.xdef msg_maxfiles
.xdef msg_nodir
.xdef msg_nofile
.xdef msg_no_home
.xdef msg_too_long_pathname
.xdef msg_total_time
.xdef msg_unmatched
.xdef msg_no_memory_for

.even
statement_table:
		dc.b	'if',0,0,0,0,0,0,0,0		* 10bytes
		dc.l	state_if
		dc.b	0

.even
command_table:
		dc.b	'@',0,0,0,0,0,0,0,0,1+2+4
		dc.l	cmd_set_expression

word_alias:	dc.b	'alias',0,0,0,0,1
		dc.l	cmd_alias

		dc.b	'cd',0,0,0,0,0,0,0,0
		dc.l	cmd_cd

		dc.b	'chdir',0,0,0,0,0
		dc.l	cmd_cd

		dc.b	'copy',0,0,0,0,0,0		* 据置
		dc.l	cmd_copy

		dc.b	'ctty',0,0,0,0,0,0
		dc.l	cmd_ctty

		dc.b	'del',0,0,0,0,0,0,0		* 据置
		dc.l	cmd_del

		dc.b	'dir',0,0,0,0,0,0,0		* 据置
		dc.l	cmd_dir

		dc.b	'dirs',0,0,0,0,0,0
		dc.l	cmd_dirs

		dc.b	'echo',0,0,0,0,0,0
		dc.l	cmd_echo

		dc.b	'eval',0,0,0,0,0,2
		dc.l	cmd_eval

word_exit:	dc.b	'exit',0,0,0,0,0,4
		dc.l	cmd_exit

		dc.b	'glob',0,0,0,0,0,0
		dc.l	cmd_glob

		dc.b	'goto',0,0,0,0,0,0
		dc.l	cmd_goto

		dc.b	'hashstat',0,0
		dc.l	cmd_hashstat

		dc.b	'history',0,0,0
		dc.l	cmd_history

		dc.b	'mkdir',0,0,0,0,0		* 据置
		dc.l	cmd_md

		dc.b	'onintr',0,0,0,0
		dc.l	cmd_onintr

		dc.b	'popd',0,0,0,0,0,0
		dc.l	cmd_popd

		dc.b	'pushd',0,0,0,0,0
		dc.l	cmd_pushd

		dc.b	'pwd',0,0,0,0,0,0,0
		dc.l	cmd_pwd

		dc.b	'rehash',0,0,0,0
		dc.l	cmd_rehash

		dc.b	'ren',0,0,0,0,0,0,0		* 据置
		dc.l	cmd_ren

		dc.b	'repeat',0,0,0,2
		dc.l	cmd_repeat

		dc.b	'rmdir',0,0,0,0,0		* 据置
		dc.l	cmd_rd

		dc.b	'set',0,0,0,0,0,0,1+2+4
		dc.l	cmd_set

		dc.b	'setenv',0,0,0,1
		dc.l	cmd_setenv

		dc.b	'shift',0,0,0,0,0
		dc.l	cmd_shift

		dc.b	'source',0,0,0,2
		dc.l	cmd_source

word_time:	dc.b	'time',0,0,0,0,0,2
		dc.l	cmd_time

		dc.b	'type',0,0,0,0,0,0		* 据置
		dc.l	cmd_type

word_unalias:	dc.b	'unalias',0,0,1
		dc.l	cmd_unalias

		dc.b	'unhash',0,0,0,0
		dc.l	cmd_unhash

		dc.b	'unset',0,0,0,0,1+2
		dc.l	cmd_unset

		dc.b	'unsetenv',0,1
		dc.l	cmd_unsetenv

		dc.b	'which',0,0,0,0,0
		dc.l	cmd_which

		dc.b	0

.even
errmsgtable:
		dc.l	msg_bad_arg
		dc.l	msg_read_err
		dc.l	msg_write_err
		dc.l	msg_nofile
		dc.l	msg_dirfull
		dc.l	msg_disk_full
		dc.l	msg_device_err
		dc.l	msg_memalloc
		dc.l	msg_nopath
		dc.l	msg_open_error
		dc.l	msg_acs_error
		dc.l	msg_memory
		dc.l	msg_protect
		dc.l	msg_not_ready
		dc.l	msg_sct_err
		dc.l	msg_normal_err
		dc.l	msg_file_exists
		dc.l	msg_sys_error

err_table:
		dc.b	$11,$11,$03,$08,$09,$0a,$0a,$07
		dc.b	$0b,$07,$11,$11,$0a,$00,$11,$00
		dc.b	$08,$06,$03,$0c,$10,$10,$10,$05
		dc.b	$04,$0a,$11,$11,$11,$11,$11,$11

ext_table:
		dc.b	'.BAT',0
		dc.b	'.X',0
		dc.b	'.Z',0
		dc.b	'.R',0
		dc.b	0

command_x_pathname:	dc.b	'COMMAND.X',0
init_shell:
default_shell_pathname:	dc.b	'itash.x',0
dot_fishrc:		dc.b	'%fishrc',0
dot_login:		dc.b	'%login',0
dot_logout:		dc.b	'%logout',0
word_upper_home:	dc.b	'HOME',0
word_upper_logname:	dc.b	'LOGNAME',0
word_upper_term:	dc.b	'TERM',0
word_upper_user:	dc.b	'USER',0
word_argv:		dc.b	'argv',0
word_cdpath:		dc.b	'cd'	* "cdpath"
word_path:		dc.b	'path',0
word_force:		dc.b	'force',0
dot_history:		dc.b	'%'	* "%history"
word_history:		dc.b	'history',0
word_home:		dc.b	'home',0
word_hugearg:		dc.b	'hugearg',0
word_indirect:		dc.b	'indirect',0
word_prompt:		dc.b	'prompt',0
word_prompt2:		dc.b	'prompt2',0
word_shell:		dc.b	'shell',0
word_status:		dc.b	'status',0
word_temp:		dc.b	'temp',0
word_term:		dc.b	'term',0
word_user:		dc.b	'user',0
dos_allfile:		dc.b	'*'	* "*.*"
ext_asta:		dc.b	'.*',0
str_dot:
str_current_dir:	dc.b	'.',0
str_builtin_dir:	dc.b	'~~',0
init_prompt:		dc.b	'%'	* "% "
str_space:		dc.b	' ',0
init_prompt2:		dc.b	'? '
init_env:
str_nul:		dc.b	0
str_colon:		dc.b	':',0
str_indirect_flag:	dc.b	'-+-+-',0

str_newline:			dc.b	CR,LF,0
msg_no_home:			dc.b	'ホーム・ディレクトリーが定義されていません',0
msg_set_default_home:		dc.b	'をホーム・ディレクトリーとします',0
msg_memalloc:			dc.b	'メモリー・アロケ－ションが異常です',0
msg_insufficient_memory:	dc.b	'メモリーが不足です',0
msg_no_memory_for_source:	dc.b	'バッチの'
msg_no_memory_for:		dc.b	'ための'
msg_memory:			dc.b	'メモリーが足りません',0
msg_bad_arg:			dc.b	'パラメ－ターが無効です',0
msg_disk_full:			dc.b	'ディスクがいっぱいです',0
msg_read_err:			dc.b	'ディスクから読み込めません',0
msg_protect:			dc.b	'書き込み禁止です',0
msg_write_err:			dc.b	'ディスクに書き込めません',0
msg_not_ready:			dc.b	'ディスクの準備が出来ていません',0
msg_open_error:			dc.b	'ファイルがオ－プンできません',0
msg_dirfull:			dc.b	'ディレクトリーがいっぱいです',0
msg_dirnofile:			dc.b	' '
msg_nofile:			dc.b	'ファイルがありません',0
msg_sct_err:			dc.b	'セクターが見つかりません',0
msg_nopath:			dc.b	'パスが見つかりません',0
msg_nodir:			dc.b	'ディレクトリーが見つかりません',0
msg_device_err:			dc.b	'デバイスが'
msg_acs_error:			dc.b	'アクセスできません',0
msg_sys_error:			dc.b	'システム内部で'
msg_normal_err:			dc.b	'エラ－が発生しました',0
msg_maxfiles:			dc.b	'ファイル数がシェルの処理能力を超えているので、'
				dc.b	'超えた分を無視します',0
msg_abort:			dc.b	'異常終了します',0
msg_use_exit_to_leave_fish:	dc.b	CR,LF,'fishから抜けるには"exit"を使って下さい',0
msg_unmatched_parens:		dc.b	'()'
msg_unmatched:			dc.b	'の対が合っていません',0
msg_alias_loop:			dc.b	'別名置換が深過ぎます',0
msg_inport_too_long:		dc.b	'環境変数の値が長過ぎます',0
msg_badly_placed_paren:		dc.b	'おかしな()があります',0
msg_missing_heredoc_word:	dc.b	'<<の印の単語がありません',0
msg_missing_input:		dc.b	'入力ファイル名がありません',0
msg_missing_output:		dc.b	'出力ファイル名がありません',0
msg_input_ambiguous:		dc.b	'入力ファイル名が曖昧です',0
msg_output_ambiguous:		dc.b	'出力ファイル名が曖昧です',0
msg_not_inputable_device:	dc.b	'デバイスが入力可能状態にありません',0
msg_not_outputable_device:	dc.b	'デバイスが出力可能状態にありません',0
msg_invalid_null_command:	dc.b	'無効な空コマンドです',0
msg_no_command:			dc.b	'コマンドが見当たりません',0
msg_command_ambiguous:		dc.b	'コマンド名が'
msg_ambiguous:			dc.b	'曖昧です',0
msg_too_long_pathname:		dc.b	'パス名が長過ぎます',0
msg_no_heredoc_terminator:	dc.b	'<<の終わりの印が見つかりませんでした',0
msg_file_exists:		dc.b	'ファイルがすでに存在しています',0
msg_bad_status:			dc.b	'シェル変数 status が不正です',0
msg_cannot_exec:		dc.b	'実行できません',0
msg_fork_failure:		dc.b	'サブ・シェルをforkできません',0
msg_loadexec_error:		dc.b	'コマンドを起動することができませんでした',0
msg_too_long_shellname:		dc.b	'シェルのパス名が長過ぎます',0
msg_too_long_command_name:	dc.b	'コマンド名が長過ぎます',0
msg_missing_command_name:	dc.b	'コマンド名がありません',0
msg_too_long_default_shell:	dc.b	'$shellの値が長過ぎます',0
msg_too_long_arg_for_program:	dc.b	'ユーザー・プログラムへの引数が255バイトを超えています',0
msg_too_long_indirect_flag:	dc.b	'インダイレクト・フラグが長過ぎます',0
msg_total_time:			dc.b	'トータル ',0
msg_exec_time:			dc.b	'実行     ',0
msg_load_time:			dc.b	'ロード   ',0
msg_search_time:		dc.b	'検索  '
space3:				dc.b	'   ',0
tmp_thred_name:			dc.b	'thred0000000000',0
msg_start:			dc.b	'Start',0
msg_done:			dc.b	'Done',0
msg_cannot_bg:			dc.b	'バックグラウンド・ジョブを実行できませんでした',0
*****************************************************************
*****************************************************************
*****************************************************************
.bss
.even
datatop:

.if 0
	.offset datatop
.endif

.xdef pid
.xdef i_am_login_shell
.xdef not_execute
.xdef input_is_tty
.xdef rootdata
.xdef dstack
.xdef shellvar
.xdef alias
.xdef pathname_buf
.xdef command_name
.xdef hash_flag
.xdef hash_table
.xdef hash_hits
.xdef hash_misses
.xdef onintr_pointer
.xdef shell_timer_high
.xdef shell_timer_low
.xdef random_table
.xdef random_pool
.xdef random_index
.xdef random_position
.xdef prev_search
.xdef prev_lhs
.xdef prev_rhs
.xdef current_source
.xdef emergency
.xdef envwork
.xdef line
.xdef tmpline
.xdef datatop
.xdef work_area
.xdef his_toplineno
.xdef his_nlines_max
.xdef his_nlines_now
.xdef hiswork
.xdef his_end
.xdef his_old
.xdef argsptr
.xdef argc
.xdef tmpgetlinebufp
.xdef tmpword01
.xdef tmpword1
.xdef tmpword2
.xdef tmpargs
.xdef simple_args
.xdef argv0p
.xdef congetbuf
.xdef last_congetbuf
.xdef exitflag
.xdef dummy
.xdef last_yow_high
.xdef last_yow_low
.xdef flag_ciglob
.xdef flag_cifilec
.xdef flag_echo
.xdef flag_filec
.xdef flag_ignoreeof
.xdef flag_nobeep
.xdef flag_noclobber
.xdef flag_noglob
.xdef flag_nonomatch
.xdef flag_stdgets
.xdef flag_verbose

**  子シェル、サブ・シェル毎のデータ

rootdata:		dc.l	1			* 親シェルのデータを格納した領域
fork_stackp:		ds.l	1			* プログラム・スタック・ポインタ
run_source_stackp:	ds.l	1
envwork:		ds.l	1			* 環境
shellvar:		ds.l	1			* シェル変数
alias:			ds.l	1			* 別名
dstack:			ds.l	1			* ディレクトリ・スタック
hiswork:		ds.l	1			* 履歴
his_toplineno:		ds.l	1			* 履歴の現在の先頭の番号
his_nlines_now:		ds.l	1			* 履歴の現在のイベント数
his_nlines_max:		ds.l	1			* 履歴の最大イベント数
his_end:		ds.l	1			* 履歴の末尾のオフセット
his_old:		ds.l	1			* 履歴の最新イベントのオフセット
current_source:		ds.l	1			* source ワーク・バッファのチェイン
onintr_pointer:		ds.l	1
hash_hits:		ds.l	1
hash_misses:		ds.l	1
shell_timer_high:	ds.l	1
shell_timer_low:	ds.l	1
last_yow_high:		ds.l	1
last_yow_low:		ds.l	1
command_name:		ds.l	1
argsptr:		ds.l	1
argc:			ds.w	1
save_stdin:		ds.w	1
save_stdout:		ds.w	1
save_stderr:		ds.w	1
undup_input:		ds.w	1
undup_output:		ds.w	1
file1_del_flag:		ds.b	1
file2_del_flag:		ds.b	1
redirect_in1_out2:	ds.b	1
hash_flag:		ds.b	1
hash_table:		ds.b	1024
args:			ds.b	MAXWORDLISTSIZE+1	*［+1は要らなくする］
simple_args:		ds.b	MAXWORDLISTSIZE
pipe_file_1:		ds.b	MAXPATH+1
pipe_file_2:		ds.b	MAXPATH+1
command_pathname:	ds.b	MAXPATH+1
line:			ds.b	MAXLINELEN+1		* ［shucks! eval で使ってる］
tmpline:		ds.b	MAXLINELEN+1		* ［shucks! subst_command で使ってる］
prev_search:		ds.b	MAXSEARCHLEN+1
prev_lhs:		ds.b	MAXSEARCHLEN+1
prev_rhs:		ds.b	MAXSUBSTLEN+1
flag_ciglob:		ds.b	1
flag_cifilec:		ds.b	1
flag_echo:		ds.b	1
flag_filec:		ds.b	1
flag_ignoreeof:		ds.b	1
flag_nobeep:		ds.b	1
flag_noclobber:		ds.b	1
flag_noglob:		ds.b	1
flag_nonomatch:		ds.b	1
flag_stdgets:		ds.b	1
flag_verbose:		ds.b	1
exitflag:		ds.b	1

.even
subdataend:

**  子シェル毎のデータ．サブ・シェルは変更してはならない

pid:			ds.l	1
mainjmp:		ds.l	1
argv0p:			ds.l	1
lineno:			ds.l	1
tmpgetlinebufp:		ds.l	1
user_command_signal:	ds.w	1
in_commando:		ds.b	1
i_am_login_shell:	ds.b	1
input_is_tty:		ds.b	1
exit_on_interrupt:	ds.b	1
exit_on_error:		ds.b	1
not_execute:		ds.b	1
interactive_mode:	ds.b	1
flag_t:			ds.b	1
flag_e:			ds.b	1
flag_e_size:		ds.b	1
flag_h_size:		ds.b	1
last_congetbuf:		ds.b	1+256

.even
keepdataend:

**  各シェル共通のデータ．ルート・シェルのみが初期化する．
**  子シェル、サブ・シェルが変更しても構わない．

.even
pid_count:		ds.l	1
command_argument:	ds.l	1
work_area:		ds.l	1
random_table:		ds.w	55
random_pool:		ds.w	POOLSIZE
random_index:		ds.b	1
random_position:	ds.b	1

**  一時バッファ

.even
congetbuf:		ds.b	2+256
user_program_parameter:	ds.b	1+MAXLINELEN+1	** ユーザー・プログラムへの引数
argment_pathname:	ds.b	MAXPATH+1	** ユーザー・プログラムへの引数を書き込んだファイル名

tmpargs:		ds.b	MAXWORDLISTSIZE
tmpword01:		ds.b	MAXWORDLEN+1	** inport,get_redirect_filename,set_expression
tmpword1:		ds.b	MAXWORDLEN*2+1	** glob
tmpword2:		ds.b	MAXWORDLEN*2+1	** globsub
pathname_buf:		ds.b	MAXPATH+1	* $home初期化，~/..オープン，filec, ファイル名展開，cdpath検索, コマンド起動
dummy:			ds.b	1

.even
dataend:

.end start
