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
.include ../src/history.h
.include ../src/loop.h

PDB_envPtr	equ	$00
PDB_argPtr	equ	$10
PDB_ProcessFlag	equ	$50

PDB_dataPtr	equ	$f0
PDB_stackPtr	equ	$f8

.xref isspace
.xref issjis
.xref atou
.xref itoa
.xref utoa
.xref strlen
.xref jstrchr
.xref strcmp
.xref memcmp
.xref strcpy
.xref stpcpy
.xref strbot
.xref strfor1
.xref strforn
.xref stricmp
.xref strmove
.xref strazcpy
.xref memmovi
.xref skip_space
.xref wordlistlen
.xref make_wordlist
.xref copy_wordlist
.xref words_to_line
.xref strip_quotes
.xref strip_quotes_list
.xref bsltosl
.xref sltobsl
.xref malloc
.xref xmalloc
.xref JustFitMalloc
.xref free
.xref xfree
.xref xfreep
.xref putc
.xref eputc
.xref puts
.xref nputs
.xref eputs
.xref ecputs
.xref enputs
.xref enputs1
.xref eput_newline
.xref printfi
.xref echo
.xref isblkdev
.xref isttyin
.xref tfopen
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
.xref stat
.xref getcwd
.xref chdir
.xref drvchkp
.xref contains_dos_wildcard
.xref split_pathname
.xref cat_pathname
.xref suffix
.xref make_sys_pathname
.xref DecodeHUPAIR
.xref EncodeHUPAIR
.xref SetHUPAIR
.xref fish_getenv
.xref dupenv
.xref rehash
.xref set_svar
.xref set_svar_nul
.xref reset_cwd
.xref clear_flagvars
.xref init_key_bind
.xref put_prompt_1
.xref getline
.xref getline_phigical
.xref enter_history
.xref expand_wordlist_var
.xref expand_wordlist
.xref subst_history
.xref subst_alias
.xref subst_var
.xref subst_var_2
.xref subst_var_wordlist
.xref subst_command
.xref subst_command_2
.xref unpack_word
.xref expand_tilde
.xref glob
.xref isquoted
.xref isfullpath
.xref remove_dot_word
.xref skip_paren
.xref check_wildcard
.xref find_shellvar
.xref svartou
.xref svartol
.xref divul
.xref mulul
.xref minmaxul
.xref hash
.xref do_print_history
.xref read_source
.xref source_goto_onintr
.xref abort_loops
.xref state_if
.xref state_else
.xref state_endif
.xref state_switch
.xref state_case
.xref state_default
.xref state_endsw
.xref state_foreach
.xref state_while
.xref state_end
.xref cmd_set_expression
.xref cmd_alias
.xref cmd_alloc
.xref cmd_bind
.xref cmd_break
.xref cmd_breaksw
.xref cmd_cd
.xref cmd_continue
.xref cmd_dirs
.xref cmd_echo
.xref cmd_eval
.xref cmd_exit
.xref cmd_glob
.xref cmd_goto
.xref cmd_hashstat
.xref cmd_history
.xref cmd_logout
.xref cmd_onintr
.xref cmd_popd
.xref cmd_printf
.xref cmd_pushd
.xref cmd_pwd
.xref cmd_rehash
.xref cmd_repeat
.xref cmd_set
.xref cmd_setenv
.xref cmd_shift
.xref cmd_source
.xref cmd_time
.xref cmd_unalias
.xref cmd_unhash
.xref cmd_unset
.xref cmd_unsetenv
.xref cmd_which
.xref pre_perror
.xref perror
.xref perror1
.xref syntax_error
.xref too_long_line
.xref no_match
.xref cannot_because_no_memory
.xref word_cwd
.xref word_echo
.xref word_verbose

auto_pathname	equ	(((MAXPATH+1)+1)>>1<<1)
auto_word	equ	(((MAXWORDLEN+1)+1)>>1<<1)

.text
*****************************************************************
texttop:					*   BIND版  :非BIND版
	dc.l	bsstop				* 0(texttop):$f0(PDB): 子シェル毎のデータのアドレス
	dc.l	bsstop+bsssize-texttop		* 4(texttop):$f4(PDB): BIND版の、切り詰める大きさ
	dc.l	bsstop+bsssize+STACKSIZE	* 8(texttop):$f8(PDB): スタック・ポインタの初期値
	dc.l	bsssize				*12(texttop):$fc(PDB): 子シェル毎のデータの大きさ
*****************************************************************
.even
start:
		bra.s	start1
str_hupair:	dc.b	'#HUPAIR',0
start1:
	**
	**  プログラム・スタック・ポインタを設定する
	**  非BIND版ならばメモリを切り詰める
	**
		DOS	_GETPDB
		movea.l	d0,a4				*  A4 : PDBアドレス
		movea.l	PDB_stackPtr(a4),a7
		lea	texttop-$f0,a0		*  A0 : 非BIND版ならば、texttop == PDB + $f0
		cmpa.l	d0,a0
		bne	binded

		move.l	a7,d0
		sub.l	a0,d0
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
binded:
	**
	**  （ルート・シェルならば）初期設定する
	**
		movea.l	PDB_dataPtr(a4),a5		*  A5 : 自分のデータのアドレス
		cmpa.l	#bsstop,a5
		bne	i_am_not_root_shell

		move.l	#1,pid_count
		clr.l	tmpgetlinebufp
		clr.l	user_command_env(a5)
i_am_not_root_shell:
		move.l	a7,stackp(a5)
	**
	**  シェル毎のデータを設定する
	**
		bsr	init_bss

		st	in_fish
		clr.b	argment_pathname
		clr.b	linecutbuf(a5)

		move.l	pid_count,pid(a5)
		add.l	#1,pid_count

		*  標準入力は端末か

		moveq	#0,d0
		bsr	isttyin
		move.b	d0,input_is_tty(a5)		*  端末なら非0
		move.b	d0,interactive_mode(a5)		*  端末なら非0にしておく

		*  このシェルはログイン・シェルか
		st	i_am_login_shell(a5)
		tst.l	PDB_ProcessFlag(a4)		*  0:親有り  -1:OSから起動
		bne	check_login_ok

		movea.l	-12(a4),a0			*  親プロセスのメモリ管理ポインタ
		lea	$100+10(a0),a0
		lea	str_login,a1
		bsr	strcmp
		beq	check_login_ok

		sf	i_am_login_shell(a5)
check_login_ok:
		clr.l	fork_stackp(a5)
		move.w	#'!',histchar1(a5)
		move.w	#'^',histchar2(a5)
		bsr	clear_flagvars
		clr.b	last_congetbuf(a5)
		clr.b	last_congetbuf+1(a5)
		sf	not_execute(a5)		* -n
		sf	exit_on_error(a5)	* -e
		sf	flag_t(a5)		* -t
		clr.l	flag_e_size(a5)

		bsr	init_key_bind
	**
	**  引数を解釈する
	**
		clr.b	flags(a5)			*  VXvxfscb
		clr.l	arg_command(a5)			*  最後の -c のコマンド
		movea.l	PDB_argPtr(a4),a0
		addq.l	#1,a0
		bsr	DecodeHUPAIR
		move.w	d0,d5				*  D5.W : 引数カウンタ
parse_args_loop:
		tst.w	d5
		beq	done_flag_argument_parsing

		btst.b	#0,flags(a5)			* -b
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
		cmp.b	#'b',d0		*  -b : フラグ引数の解釈をブレークする
		beq	set_flag

		moveq	#1,d1
		cmp.b	#'c',d0		*  -c : 引数のコマンドを実行して終了する
		beq	set_flag

		moveq	#2,d1
		cmp.b	#'s',d0		*  -s : コマンドは標準入力から読み取る
		beq	set_flag

		moveq	#3,d1
		cmp.b	#'f',d0		*  -f : 高速な起動 .. 環境ファイルを実行しない
		beq	set_flag

		moveq	#4,d1
		cmp.b	#'x',d0		*  -x : echoをsetする
		beq	set_flag

		moveq	#5,d1
		cmp.b	#'v',d0		*  -v : verboseをsetする
		beq	set_flag

		moveq	#6,d1
		cmp.b	#'X',d0		*  -X : ~/%fishrc を実行する前に echo を set する
		beq	set_flag

		moveq	#7,d1
		cmp.b	#'V',d0		*  -V : ~/%fishrc を実行する前に verbose を set する
		beq	set_flag

		cmp.b	#'e',d0		*  -e : エラーで終了する
		beq	flag_e_found

		cmp.b	#'i',d0		*  -i : 対話モード
		beq	flag_i_found

		cmp.b	#'n',d0		*  -n : コマンドを実行しない
		beq	flag_n_found

		cmp.b	#'t',d0		*  -t : 標準入力からのコマンドを1行実行して終了する
		beq	flag_t_found

		cmp.b	#'l',d0		*  -l : login shell として働く
		beq	flag_l_found

		cmp.b	#'E',d0		*  -Eddd : 環境の余裕の大きさ
		beq	flag_xe_found

		bra	parse_one_arg_loop

set_flag:
		bset	d1,flags(a5)
		bra	parse_one_arg_loop

flag_parse_sjis:
		tst.b	(a0)+
		bne	parse_one_arg_loop
parse_one_arg_done:
		btst	#1,flags(a5)				*  -c
		beq	parse_args_loop

		bclr	#1,flags(a5)				*  -c
		move.l	#-1,arg_command(a5)
		tst.w	d5
		beq	parse_args_loop

		move.l	a0,arg_command(a5)
		bsr	strfor1
		subq.w	#1,d5
		bra	parse_args_loop

flag_i_found:
		st	interactive_mode(a5)
		bset	#2,flags(a5)				*  -s
		bra	parse_one_arg_loop

flag_n_found:
		st	not_execute(a5)
flag_e_found:
		st	exit_on_error(a5)
		bra	parse_one_arg_loop

flag_t_found:
		st	flag_t(a5)
		bra	parse_one_arg_loop

flag_l_found:
		st	i_am_login_shell(a5)
		bra	parse_one_arg_loop

flag_xe_found:
		clr.l	flag_e_size(a5)
		bsr	atou
		move.l	d1,d2
		move.b	(a0),d1
		bsr	strfor1
		tst.l	d0
		bne	parse_args_loop

		tst.b	d1
		bne	parse_args_loop

		move.l	d2,flag_e_size(a5)
		bra	parse_args_loop

done_flag_argument_parsing:
		move.l	a0,argv0p(a5)

		*  ログイン・シェルならば -c, -t, -n, -e, -f,
		*  およびスクリプト・ファイル引数は無視する

		tst.b	i_am_login_shell(a5)
		beq	flags_ok

		clr.l	arg_command(a5)			*  -c をクリアする
		sf	flag_t(a5)			*  -t をクリアする
		sf	not_execute(a5)			*  -n をクリアする
		sf	exit_on_error(a5)		*  -e をクリアする
		bclr.b	#3,flags(a5)			*  -f をクリアする
		moveq	#0,d5				*  残りの引数をクリアする
flags_ok:
	**
	**  サブシェル毎のデータを初期化する
	**
		clr.l	hash_hits(a5)
		clr.l	hash_misses(a5)
		sf	hash_flag(a5)
	**
	**  動的データ・ブロックをallocする
	**
		moveq	#0,d1
		movea.l	PDB_envPtr(a4),a1		*  A1 : 親の環境のアドレス
		cmpa.l	#-1,a1
		beq	make_current_env_1

		move.l	(a1),d1				*  D1.L : 親の環境ブロックのサイズ
make_current_env_1:
		move.l	flag_e_size(a5),d0		*  D0.L : 環境ブロックの指定サイズ
		bsr	minmaxul
		move.l	#MINENVSIZE,d0
		bsr	minmaxul			*  D1.L : 環境ブロックのサイズ
		*
		*  動的ブロックをallocする
		*
		move.l	d1,d0				*  D0.L := 環境ブロックのサイズ
		add.l	#SHELLVARSIZE,d0		*        + シェル変数ブロックのサイズ
		add.l	#ALIASSIZE,d0			*        + 別名ブロックのサイズ
		add.l	#KMACROSIZE,d0			*        + キーボード・マクロ・ブロックのサイズ
		add.l	#DSTACKSIZE,d0			*        + ディレクトリ・スタックのサイズ
		move.l	d0,ddatasize(a5)

		move.l	#$00ffffff,-(a7)
		DOS	_MALLOC
		sub.l	#$81000000,d0
		move.l	d0,(a7)
		DOS	_MALLOC
		addq.l	#4,a7
		tst.l	d0
		bmi	cannot_allocate_data_block

		move.l	d0,ddatap(a5)
		bsr	setblock_ddata_0
		bmi	cannot_allocate_data_block
		*
		*  環境を初期化
		*
		movea.l	ddatap(a5),a2
		move.l	d1,d0
		lea	envwork(a5),a3
		bsr	init_block
		clr.b	(a0)
		cmpa.l	#-1,a1
		beq	make_current_env_4

		addq.l	#4,a1
		bsr	strazcpy
make_current_env_4:
		bsr	reset_bss
		*
		*  シェル変数を初期化
		*
		move.l	#SHELLVARSIZE,d0
		lea	shellvar(a5),a3
		bsr	init_var_block
		*
		*  別名を初期化
		*
		move.l	#ALIASSIZE,d0
		lea	alias(a5),a3
		bsr	init_var_block
		*
		*  キー・マクロを初期化
		*
		move.l	#KMACROSIZE,d0
		lea	keymacro(a5),a3
		bsr	init_var_block
		*
		*  ディレクトリ・スタックを初期化
		*
		move.l	#DSTACKSIZE,d0
		lea	dstack(a5),a3
		bsr	init_block
		move.l	#10,(a0)+		* +4 (4) : 使用量
		clr.w	(a0)			* +8 (2) : 要素数
		*
		*  履歴を初期化
		*
		clr.l	history_top(a5)
		clr.l	history_bot(a5)
		move.l	#1,current_eventno(a5)
	**
	**  ログインシェルならば $HOME に chdir する
	**  ［暫定］（/bin/login がやるべき）
	**
		tst.b	i_am_login_shell(a5)
		beq	chdir_home_done

		lea	word_upper_home,a0
		bsr	fish_getenv
		beq	no_home

		movea.l	d0,a0
		bsr	chdir
		bpl	chdir_home_done

		bsr	perror
		bra	chdir_home_done

no_home:
		lea	msg_no_home,a0
		bsr	enputs
chdir_home_done:
	**
	**  $0 と $argv を初期設定する
	**
		movea.l	argv0p(a5),a0
		clr.l	argv0p(a5)
		move.w	d5,d0
		beq	set_argv

		tst.b	flag_t(a5)			*  -t
		bne	set_argv

		btst	#2,flags(a5)			*  -s
		bne	set_argv

		tst.l	arg_command(a5)			*  -c
		bne	set_argv

		move.l	a0,argv0p(a5)
		bsr	strfor1
		subq.w	#1,d5
set_argv:
		move.w	d5,d0
		movea.l	a0,a1
		lea	word_argv,a0
		moveq	#0,d1
		bsr	set_svar
	**
	**  環境変数をシェル変数にインポートする
	**
		*
		*  path -> path
		*
		bsr	inport_path
		*
		*  temp -> temp
		*
		lea	word_temp,a2
		movea.l	a2,a1
		bsr	inportp
		*
		*  USER（無ければ LOGNAME） -> user
		*
		lea	word_user,a2
		lea	word_upper_user,a1
		bsr	inport
		bpl	inport_user_done

		lea	word_upper_logname,a1
		bsr	inport
inport_user_done:
		*
		*  TERM -> term
		*
		lea	word_term,a2
		lea	word_upper_term,a1
		bsr	inport
		*
		*  HOME -> home
		*
		lea	word_home,a2
		lea	word_upper_home,a1
		bsr	inportp
	**
	**  その他のシェル変数を初期設定する
	**
		moveq	#0,d1
		lea	initial_vars_stdin_mode,a2
		tst.l	argv0p(a5)
		beq	set_initial_vars

		lea	initial_vars_script_mode,a2
set_initial_vars:
		tst.l	(a2)
		beq	set_initial_vars_done

		move.l	(a2)+,a0			*  変数名
		move.l	(a2)+,a1			*  値
		move.w	(a2)+,d0			*  値の語数
		bsr	set_svar
		bra	set_initial_vars

set_initial_vars_done:
		*
		*  batshell
		*
		lea	init_batshell,a1
		lea	pathname_buf,a0
		bsr	make_sys_pathname
		bmi	set_batshell_done

		bsr	bsltosl
		movea.l	a0,a1
		lea	word_batshell,a0
		moveq	#1,d0
		bsr	set_svar
set_batshell_done:
		*
		*  shell
		*
		lea	init_shell,a1
		lea	pathname_buf,a0
		bsr	make_sys_pathname
		bsr	make_sys_pathname
		bmi	set_shell_done

		bsr	bsltosl
		movea.l	a0,a1
		lea	word_shell,a0
		moveq	#1,d0
		bsr	set_svar
set_shell_done:
		*
		*  cwd
		*
		bsr	reset_cwd
		*
		*  status
		*
		bsr	clear_status

**  シグナル処理ルーチンを設定する

		sf	interrupted(a5)
		lea	login_interrupted(pc),a0
		move.l	a0,mainjmp(a5)

		pea	manage_interrupt_signal(pc)
		move.w	#_CTRLVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7

		pea	manage_abort_signal(pc)
		move.w	#_ERRJVC,-(a7)
		DOS	_INTVCS
		addq.l	#6,a7

**  -V と -X を処理する

		btst	#7,flags(a5)			* -V
		beq	preset_verbose_done

		bsr	set_verbose
preset_verbose_done:
		btst	#6,flags(a5)			* -X
		beq	preset_echo_done

		bsr	set_echo
preset_echo_done:
**  -f が指定されていなければ $SYSROOT/etc/fishrc と ~/%fishrc を source する
		btst	#3,flags(a5)			* -f
		bne	fishrc_done

		lea	etc_fishrc,a1
		lea	pathname_buf,a0
		bsr	make_sys_pathname
		bmi	etc_fishrc_done

		bsr	run_source_if_any
etc_fishrc_done:
		lea	dot_fishrc,a1
		bsr	run_home_source_if_any
fishrc_done:
**  ログイン・シェルならば ~/%login を source する

		tst.b	i_am_login_shell(a5)
		beq	home_login_done

		lea	dot_login,a1
		bsr	run_home_source_if_any
home_login_done:
**  -f が指定されていなければ ~/%history を source -h する

		btst	#3,flags(a5)			* -f
		bne	load_history_done

		lea	dot_history,a1
		lea	pathname_buf,a0
		bsr	make_home_filename
		bmi	load_history_done

		moveq	#0,d0
		bsr	tfopen
		bmi	load_history_done

		bsr	read_source
load_history_done:
**  -v と -x を処理する

		btst	#5,flags(a5)			* -v
		beq	set_verbose_done

		bsr	set_verbose
set_verbose_done:
		btst	#4,flags(a5)			* -x
		beq	start_run

		bsr	set_echo
		bra	start_run

login_interrupted:
		st	interrupted(a5)
start_run:
**  実行開始
		lea	exit_shell_status(pc),a0
		move.l	a0,mainjmp(a5)

		tst.l	arg_command(a5)			* -c
		bne	do_argument

		tst.b	flag_t(a5)			* -t
		bne	do_tty_line

		bsr	rehash

		tst.l	argv0p(a5)
		bne	do_file

		tst.b	input_is_tty(a5)
		bne	noarg_argv0_ok

		lea	str_nul,a0
		move.l	a0,argv0p(a5)
noarg_argv0_ok:
		lea	main(pc),a0
		move.l	a0,mainjmp(a5)
		sf	exitflag(a5)
main:
		**** ［デバッグ］
		lea	hash_table(a5),a1
		lea	hash_table2(a5),a0
		move.l	#1024,d0
		bsr	memcmp
		beq	debug_ok

		lea	msg_hashtable_broken,a0
		bsr	enputs
debug_ok:
		bsr	do_line_getline
		tst.b	exitflag(a5)			* exit?
		bne	exit_shell_status

		tst.l	d0				* EOF?
		bpl	main

		tst.b	input_is_tty(a5)
		beq	shell_eof

		tst.b	flag_ignoreeof(a5)
		beq	shell_eof

		lea	msg_use_exit_to_leave_fish,a0
		tst.b	i_am_login_shell(a5)
		beq	ignore_eof

		lea	msg_use_logout_to_logout,a0
ignore_eof:
		bsr	enputs
		bra	main
*****************************************************************
do_tty_line:
		lea	ttymain(pc),a0
		move.l	a0,mainjmp(a5)
ttymain:
		bsr	do_line_getline
		bra	shell_eof
*****************************************************************
do_argument:
		tst.b	interrupted(a5)
		bne	exit_shell_status

		move.l	arg_command(a5),d0
		bmi	exit_shell_0

		movea.l	d0,a0
		bsr	strlen
		cmp.l	#MAXLINELEN,d0
		bhi	do_argment_too_long

		movea.l	a0,a1
		lea	line(a5),a0
		bsr	strcpy
		st	d0
		bsr	do_line_substhist
		bra	shell_eof

do_argment_too_long:
		bsr	too_long_line
		bra	exit_shell_1
*****************************************************************
do_file:
		tst.b	interrupted(a5)
		bne	exit_shell_status

		movea.l	argv0p(a5),a0
		bsr	OpenLoadRun_source
		bra	exit_shell_status
*****************************************************************
*  ルート・シェルやサブシェル毎のデータを初期化する
*****************************************************************
init_bss:
		movem.l	d0-d1/a0,-(a7)
		bsr	getitimer
		move.l	d1,shell_timer_high(a5)
		move.l	d0,shell_timer_low(a5)
		clr.l	current_source(a5)
		clr.l	current_argbuf(a5)
		clr.l	command_name(a5)
		move.w	#-1,save_stdin(a5)
		move.w	#-1,save_stdout(a5)
		move.w	#-1,save_stderr(a5)
		move.w	#-1,undup_input(a5)
		move.w	#-1,undup_output(a5)
		clr.b	pipe1_delete(a5)
		clr.b	pipe2_delete(a5)
		sf	pipe_flip_flop(a5)
		clr.b	prev_search(a5)
		clr.b	prev_lhs(a5)
		clr.b	prev_rhs(a5)
		sf	if_status(a5)
		clr.w	if_level(a5)
		clr.b	switch_status(a5)
		clr.w	switch_level(a5)
		clr.b	loop_status(a5)
		lea	loop_stack(a5),a0
		moveq	#MAXLOOPLEVEL,d0
clear_loop_stack:
		clr.l	LOOPINFO_STORE(a0)
		lea	LOOPINFOSIZE(a0),a0
		dbra	d0,clear_loop_stack

		bsr	clear_in_history
		movem.l	(a7)+,d0-d1/a0
		rts
*****************************************************************
clear_in_history:
		clr.l	in_history_ptr(a5)
		sf	keep_loop(a5)
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
.xdef inport_path

inport_path:
		lea	word_path,a0
		bsr	fish_getenv
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
		bsr	jstrchr
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
		bra	set_svar
****************
init_path_static:
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
		rts
****************************************************************
* inport - 環境変数をシェル変数にインポートする
*
* CALL
*      A1     環境変数名
*      A2     シェル変数名
*      D0.B   0 以外: \ を / に替える
*
* RETURN
*      D0.L   -1:環境変数は定義されていない  0:インポートした  1:エラー
*      CCR    TST.L D0
****************************************************************
inportp:
		st	d0
		bra	inportx

inport:
		sf	d0
inportx:
		movem.l	d1-d3/a0-a1,-(a7)
		move.b	d0,d3
		movea.l	a1,a0
		bsr	fish_getenv
		beq	not_inport

		movea.l	d0,a0
		bsr	strlen
		cmp.l	#MAXWORDLEN,d0
		bhi	inport_too_long

		link	a6,#-auto_word
		tst.b	d3
		beq	inport_set

		movea.l	a0,a1
		lea	-auto_word(a6),a0
		bsr	strcpy
		bsr	bsltosl
inport_set:
		movea.l	a0,a1
		movea.l	a2,a0
		moveq	#1,d0
		moveq	#0,d1
		bsr	set_svar
		unlk	a6
inport_return:
		movem.l	(a7)+,d1-d3/a0-a1
		rts

not_inport:
		moveq	#-1,d0
		bra	inport_return

inport_too_long:
		movea.l	a1,a0
		bsr	inport_too_long0
		bra	inport_return

inport_too_long0:
		bsr	pre_perror
		lea	msg_inport_too_long,a0
		bra	enputs
****************************************************************
.xdef setblock_ddata_0

setblock_ddata_0:
		move.l	ddatasize(a5),d0
setblock_ddata_1:
		move.l	d0,-(a7)
		move.l	ddatap(a5),-(a7)
		DOS	_SETBLOCK
		addq.l	#8,a7
		tst.l	d0
		rts
****************************************************************
.xdef try_enlarge_ddata

try_enlarge_ddata:
		move.l	ddatasize(a5),d0
		add.l	#16,d0
		bsr	setblock_ddata_1
		move.l	d0,-(a7)
		bsr	setblock_ddata_0
		move.l	(a7)+,d0
		rts
*****************************************************************
init_var_block:
		bsr	init_block
		move.l	#8,(a0)
		clr.w	4(a0)
		rts
*****************************************************************
init_block:
		movea.l	a2,a0
		adda.l	d0,a2
		move.l	a0,(a3)
		move.l	d0,(a0)+
		rts
****************************************************************
reset_bss:
		movem.l	d0/a0,-(a7)
		DOS	_GETPDB
		movea.l	d0,a0
		move.l	a5,PDB_dataPtr(a0)
		move.l	envwork(a5),PDB_envPtr(a0)
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
.xdef free_current_argbuf

free_current_argbuf:
		movem.l	d0/a0,-(a7)
free_current_argbuf_loop:
		move.l	current_argbuf(a5),d0
		beq	free_current_argbuf_return

		movea.l	d0,a0
		move.l	(a0),current_argbuf(a5)
		bsr	free
		move.l	current_argbuf(a5),d0
free_current_argbuf_return:
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
manage_abort_signal:
		move.l	#$3fc,d0		* D0 = 000003FC
		cmp.w	#$100,d1
		bcs	manage_signals

		addq.l	#1,d0			* D0 = 000003FD
		cmp.w	#$200,d1
		bcs	manage_signals

		addq.l	#2,d0			* D0 = 000003FF
		cmp.w	#$ff00,d1
		bcc	manage_signals

		cmp.w	#$f000,d1
		bcc	manage_signals

		move.b	d1,d0
		bra	manage_signals
****************
.xdef manage_interrupt_signal

manage_interrupt_signal:
		move.l	#$200,d0		* D0 = 00000200
****************
.xdef manage_signals

manage_signals:
		tst.b	in_fish
		beq	exit_user_command

		move.l	d0,d1				*  status をセーブ（スタックはまだ使えない）
		DOS	_GETPDB
		movea.l	d0,a0
		movea.l	PDB_dataPtr(a0),a5
		move.l	d1,d0				*  D0.L : status
break_shell:
		movea.l	stackp(a5),a7
		clr.l	command_name(a5)
		sf	exitflag(a5)
		bsr	reset_delete_io
		bsr	just_set_status
		*
		move.l	d0,-(a7)
		lea	tmpgetlinebufp,a0
		bsr	xfreep
		lea	user_command_env(a5),a0
		bsr	xfreep
		move.l	(a7)+,d0
		*
free_argbuf_loop:
		bsr	free_current_argbuf
		bne	free_argbuf_loop
		*
		tst.l	current_source(a5)
		beq	stop_running

		move.l	d0,d1
		clr.b	d1
		cmp.l	#$200,d1
		bne	stop_source

		move.l	current_source(a5),d1
		movea.l	d1,a0
		move.l	SOURCE_ONINTR_POINTER(a0),d1
		beq	stop_source

		cmp.l	#-1,d1				*  onintr -
		beq	run_source_loop

		bsr	source_goto_onintr
		sf	if_status(a5)
		clr.w	if_level(a5)
		clr.b	switch_status(a5)
		clr.w	switch_level(a5)
		bra	run_source_loop

stop_source:
		move.l	(a7)+,a7
		bsr	close_source
		tst.l	current_source(a5)
		bne	stop_source

		move.l	a7,stackp(a5)
stop_running:
		bsr	clear_in_history
		sf	if_status(a5)
		clr.w	if_level(a5)
		clr.b	switch_status(a5)
		clr.w	switch_level(a5)
		bsr	abort_loops

		tst.b	exit_on_error(a5)
		bne	exit_shell_d0

		tst.b	input_is_tty(a5)
		beq	exit_shell_d0

		movea.l	mainjmp(a5),a0
		jmp	(a0)
****************
.xdef logout

cannot_allocate_data_block:
		lea	msg_insufficient_memory,a0
		bsr	enputs
		bra	exit_shell_1

shell_eof:
		bsr	check_end
		beq	exit_shell_status
exit_shell_1:
		moveq	#1,d0
		bra	exit_shell_d0

exit_shell_0:
		moveq	#0,d0
		bra	exit_shell_d0

exit_shell_status:
		bsr	get_status
exit_shell_d0:
		bsr	reset_delete_io
		tst.b	i_am_login_shell(a5)
		beq	do_exit_shell

		lea	word_logout,a0
		bsr	nputs
logout:
		lea	logout_terminated(pc),a0
		move.l	a0,mainjmp(a5)
		lea	dot_logout,a1
		bsr	run_home_source_if_any
logout_terminated:
		bsr	reset_delete_io

		lea	word_savehist,a0
		bsr	find_shellvar
		beq	savehist_done

		addq.l	#2,a0
		tst.w	(a0)+				*  単語数をチェック
		beq	savehist_done

		bsr	strfor1				*  変数名をスキップ
		tst.b	(a0)				*  ヌル単語でないかどうかをチェック
		beq	savehist_done

		movea.l	a0,a2
		lea	dot_history,a1
		lea	pathname_buf,a0
		bsr	make_home_filename
		bmi	savehist_done

		bsr	create_normal_file
		bmi	savehist_fail

		move.w	d0,d1				* リダイレクト先を D1 にセットして
		move.w	d1,undup_output(a5)		*   undup_output に覚えておく

		moveq	#1,d0				* 標準出力を
		bsr	redirect			* リダイレクト
		bmi	savehist_fail

		move.w	d0,save_stdout(a5)		* 旧デスクリプタのコピーをセーブ

		st	d4				*  -h : true
		sf	d5				*  -r : false
		movea.l	a2,a0
		bsr	do_print_history
		bsr	reset_io
savehist_done:
		bsr	get_status
do_exit_shell:
		sf	in_fish
exit_user_command:
		move.l	d0,user_command_signal
		move.w	d0,-(a7)
		DOS	_EXIT2
exit_halt:
		bra	exit_halt

savehist_fail:
		bsr	reset_io
		bsr	perror
		moveq	#1,d0
		bra	do_exit_shell
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
			bsr	strfor1
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

		movem.l	(a7)+,d0-d3/a0
		rts

unmatched_paren:
		lea	msg_unmatched_parens,a0
		bra	print_shell_error

unmatched_accent:
		moveq	#'`',d0
unmatched:
		bsr	eputc
		bsr	eputc
		lea	msg_unmatched,a0
		bra	print_shell_error
*****************************************************************
* fork
*
* CALL
*      A0     単語並び または 文字列
*      D0.W   A0が単語並びならば単語数．A0が文字列ならば文字列の長さ
*      D1.B   A0が単語並びならば0以外
*      D2.B   -n フラグ
*
* RETURN
*      D0.L   ステータス
*****************************************************************
.xdef fork

fork:
		movem.l	d1-d7/a0-a4/a6,-(a7)
		movea.l	a0,a2				*  A2 : argv / line
		move.w	d0,d3				*  D3 : argc / linelen
		moveq	#1,d4				*  D4 : error flag

		*  BSSを複製する

		move.l	#bsssize+STACKSIZE,d0
		bsr	malloc
		beq	fork_fail1

		movea.l	d0,a4				*  A4 : 複製したBSS

		movea.l	a5,a1
		movea.l	a4,a0
		move.l	#bsssize,d0
		bsr	memmovi

		*  環境，シェル変数，別名，キー・マクロ，ディレクトリ・スタックを複製する

		movea.l	envwork(a5),a0
		move.l	(a0),d0
		movea.l	shellvar(a5),a0
		add.l	(a0),d0
		movea.l	alias(a5),a0
		add.l	(a0),d0
		movea.l	keymacro(a5),a0
		add.l	(a0),d0
		movea.l	dstack(a5),a0
		add.l	(a0),d0
		move.l	d0,d5
		bsr	malloc
		beq	fork_fail2

		movea.l	d0,a0
		move.l	a0,envwork(a4)
		movea.l	envwork(a5),a1
		move.l	d5,d0
		bsr	memmovi
		movea.l	envwork(a4),a0
		adda.l	(a0),a0
		move.l	a0,shellvar(a4)
		adda.l	(a0),a0
		move.l	a0,alias(a4)
		adda.l	(a0),a0
		move.l	a0,keymacro(a4)
		adda.l	(a0),a0
		move.l	a0,dstack(a4)

		*  履歴リストを複製する

		movem.l	d0-d1/a0-a3,-(a7)
		clr.l	history_top(a4)
		clr.l	history_bot(a4)
		movea.l	history_top(a5),a2
dup_history_loop:
		cmpa.l	#0,a2
		beq	dup_history_done

		move.w	HIST_NWORDS(a2),d0
		lea	HIST_BODY(a2),a0
		bsr	wordlistlen
		add.l	#HIST_BODY,d0
		move.l	d0,d1
		bsr	JustFitMalloc
		bmi	dup_history_done

		movea.l	d0,a3
		movea.l	a3,a0
		movea.l	a2,a1
		move.l	d1,d0
		bsr	memmovi
		movea.l	history_bot(a4),a0
		move.l	a0,HIST_PREV(a3)
		bne	dup_history_1

		move.l	a3,history_top(a4)
		bra	dup_history_2

dup_history_1:
		move.l	a3,HIST_NEXT(a0)
dup_history_2:
		clr.l	HIST_NEXT(a3)
		move.l	a3,history_bot(a4)
		movea.l	HIST_NEXT(a2),a2
		bra	dup_history_loop

dup_history_done:
		movem.l	(a7)+,d0-d1/a0-a3
		bmi	fork_fail3

		bsr	remember_misc_environments

		move.l	a5,-(a7)			*  親のBSSポインタを保存
		movea.l	a4,a5				*  このプロセスのBSSポインタをセット
		move.l	a7,fork_stackp(a5)		*  スタック・ポインタを保存
		lea	bsssize+STACKSIZE(a5),a7	*  このプロセスのスタック・ポインタをセット
		move.l	a7,stackp(a5)			*  stackp をセット
		lea	fork_ran(pc),a0
		move.l	a0,mainjmp(a5)			*  mainjmp をセット
		bsr	reset_bss
		bsr	init_bss
		move.b	d2,not_execute(a5)

		movea.l	a2,a1
		move.w	d3,d0
		tst.b	d1
		bne	fork_wordlist

		lea	line(a5),a0
		bsr	memmovi
		clr.b	(a0)
		lea	line(a5),a0
		sf	d0
		bsr	do_line_substhist
		bra	fork_ran0

fork_wordlist:
		lea	args(a5),a0
		bsr	copy_wordlist
		bsr	do_line
fork_ran0:
		bsr	get_status
fork_ran:
		move.l	d0,d3
		moveq	#0,d4
		movea.l	a5,a4
		movea.l	fork_stackp(a4),a7
		movea.l	(a7)+,a5
		bsr	reset_bss
		bsr	resume_misc_environments
****************
fork_fail3:
		movea.l	history_top(a4),a0
free_history_loop:
		cmpa.l	#0,a0
		beq	free_history_done

		movea.l	HIST_NEXT(a0),a1
		move.l	a0,d0
		bsr	free
		movea.l	a1,a0
		bra	free_history_loop

free_history_done:
		move.l	envwork(a4),d0
		bsr	free
****************
fork_fail2:
		move.l	a4,d0
		bsr	free
****************
fork_fail1:
		move.l	d3,d0
		tst.b	d4
		beq	fork_done

		lea	msg_fork_failure,a0
		bsr	cannot_because_no_memory
		moveq	#1,d0
****************
fork_done:
		movem.l	(a7)+,d1-d7/a0-a4/a6
		rts
*****************************************************************
.xdef close_source

close_source:
		tst.l	current_source(a5)
		beq	close_source_done

		movem.l	d0/a0,-(a7)
		movea.l	current_source(a5),a0
		move.l	SOURCE_PARENT(a0),current_source(a5)
		move.l	a0,d0
		bsr	free
		movem.l	(a7)+,d0/a0
		rts
*****************************************************************
* load_source
*
* CALL
*      A0     ファイル名
*      D0.W   ファイル・ハンドル
*
* RETURN
*      D0.L   成功ならば 0
*      CCR    TST.L D0
*      その他 破壊
*****************************************************************
load_source:
		move.w	d0,d2				*  D2.W : ファイル・ハンドル
		bsr	isblkdev
		bne	cannot_load_unseekable

		move.w	#2,-(a7)			*  EOF の位置
		clr.l	-(a7)				*  まで
		move.w	d2,-(a7)			*  ファイルを
		DOS	_SEEK				*  SEEK して，ファイルの長さを得る．
		addq.l	#8,a7
		move.l	d0,d3				*  D3.L : ファイルの長さ
		bmi	load_source_fail_1

		add.l	#SOURCE_HEADER_SIZE,d0		*  D0.L : ファイルの長さ+ヘッダの長さ
		move.l	d0,d1				*  D1.L : ファイルの長さ+ヘッダの長さ
		bsr	xmalloc
		beq	load_source_no_memory

		movea.l	d0,a2				*  A2 : バッファの先頭アドレス
		move.l	d1,SOURCE_SIZE(a2)
		move.l	a0,-(a7)
		movea.l	a0,a1
		lea	SOURCE_FILENAME(a2),a0
		bsr	strcpy
		movea.l	(a7)+,a0
		clr.l	SOURCE_LINENO(a2)
		lea	SOURCE_HEADER_SIZE(a2),a3	*  A3 : バッファ＋ヘッダ
		move.l	a3,SOURCE_POINTER(a2)
		clr.l	SOURCE_ONINTR_POINTER(a2)
		move.l	current_source(a5),SOURCE_PARENT(a2)
		move.l	a2,current_source(a5)

		clr.w	-(a7)				*  ファイルの先頭
		clr.l	-(a7)				*  まで
		move.w	d2,-(a7)			*  ファイルを
		DOS	_SEEK				*  SEEK する
		addq.l	#8,a7
		tst.l	d0
		bmi	load_source_fail_2

		move.l	d3,-(a7)			*  ファイルの長さだけ
		move.l	a3,-(a7)			*  バッファ＋ヘッダの位置に
		move.w	d2,-(a7)			*  ファイルから
		DOS	_READ				*  読み込む
		lea	10(a7),a7
		tst.l	d0
		bmi	load_source_fail_2

		cmp.l	d3,d0
		bne	load_source_fail_2

		moveq	#0,d0
load_source_done:
		tst.w	d2
		beq	load_source_done_return

		exg	d0,d2
		bsr	fclose
		exg	d0,d2
load_source_done_return:
		tst.l	d0
close_source_done:
		rts

load_source_no_memory:
		lea	msg_cannot_load_script,a0
		bsr	cannot_because_no_memory
		bra	load_source_done

cannot_load_unseekable:
		bsr	pre_perror
		lea	msg_cannot_load_unseekable,a0
		bsr	enputs1
		bra	load_source_done

load_source_fail_1:
		bsr	close_source
load_source_fail_2:
		bsr	pre_perror
		lea	msg_read_fail,a0
		bsr	enputs1
		bra	load_source_done
****************************************************************
make_home_filename:
		movem.l	d0/a0-a3,-(a7)
		movea.l	a0,a3
		movea.l	a1,a2
		lea	word_home,a0
		bsr	find_shellvar
		beq	make_home_filename_fail

		addq.l	#2,a0
		tst.w	(a0)+				*  単語数をチェック
		beq	make_home_filename_fail

		bsr	strfor1				*  変数名をスキップ
		tst.b	(a0)
		beq	make_home_filename_fail

		movea.l	a0,a1
		movea.l	a3,a0
		bsr	cat_pathname
make_home_filename_return:
		movem.l	(a7)+,d0/a0-a3
		rts

make_home_filename_fail:
		moveq	#-1,d0
		bra	make_home_filename_return
*****************************************************************
* run_source - run source until EOF
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
		bmi	run_source_return
run_source_if_any:
		moveq	#0,d0
		bsr	tfopen
		bmi	run_source_return

		bsr	LoadRun_source
		tst.l	d0
		bpl	run_source_return

		lea	word_exit,a0
		moveq	#1,d0
		bra	verbose

OpenLoadRun_source:
		cmpi.b	#'-',(a0)
		bne	OpenLoadRun_source_file

		tst.b	1(a0)
		bne	OpenLoadRun_source_file

		lea	str_stdin,a0
		moveq	#0,d0				*  stdin
		bra	LoadRun_source

OpenLoadRun_source_file:
		moveq	#0,d0
		bsr	tfopen
		bpl	LoadRun_source

		bsr	perror
		bra	shell_error

LoadRun_source:
		bsr	load_source
		bne	shell_error
run_source:
		move.l	stackp(a5),-(a7)
		move.l	a7,stackp(a5)
		sf	exitflag(a5)
run_source_loop:
		bsr	do_line_getline
		tst.l	d0				* EOF?
		bmi	run_source_eof

		tst.b	exitflag(a5)			* exit?
		beq	run_source_loop

		bsr	close_source
		sf	exitflag(a5)
		bra	run_source_done

run_source_eof:
		bsr	check_end
		bne	shell_error
run_source_done:
		move.l	(a7)+,stackp(a5)
run_source_return:
check_end_ok:
		rts
*****************************************************************
check_end:
		lea	msg_endif_not_found,a0
		tst.b	if_status(a5)
		bne	enputs1

		lea	msg_endsw_not_found,a0
		tst.b	switch_status(a5)
		bne	enputs1

		lea	msg_end_not_found,a0
		tst.b	loop_status(a5)
		bmi	enputs1

		rts
*****************************************************************
* do_line_getline - 行を入力し、履歴置換、単語分け、verbose表示、履歴登録し、実行する
*
* CALL
*      none.
*
* RETURN
*      D0.L    EOF ならば 負．さもなくば 0．
*      CCR     TST.L D0
*      その他  破壊
*****************************************************************
do_line_getline:
		move.l	in_history_ptr(a5),d1
		beq	do_line_getline_1

		DOS	_KEYSNS				*  To allow interrupt

		movea.l	d1,a1
		move.l	a1,save_sourceptr
		move.l	HIST_NEXT(a1),in_history_ptr(a5)
		move.w	HIST_NWORDS(a1),d0
		lea	HIST_BODY(a1),a1
		lea	args(a5),a0
		bsr	copy_wordlist
		bsr	verbose
		bra	do_line

do_line_getline_1:
		suba.l	a1,a1			*  A1 = NULL : プロンプト無し
		st	d2			*  D2.B = 1 : コメントを削除する
		tst.l	current_source(a5)
		bne	do_line_getline_script

		tst.b	interactive_mode(a5)
		beq	do_line_getline_3

		sf	d2			*  D2.B = 0 : コメントを削除しない
		tst.b	flag_t(a5)
		bne	do_line_getline_3

		lea	put_prompt_1(pc),a1	*  A1 : プロンプト出力ルーチン
		bra	do_line_getline_3

do_line_getline_script:
		movea.l	current_source(a5),a3
		movea.l	SOURCE_POINTER(a3),a3
		move.l	a3,save_sourceptr
do_line_getline_3:
		lea	line(a5),a0
		move.w	#MAXLINELEN,d1
		moveq	#0,d7
		lea	getline_phigical(pc),a2
		bsr	getline
		bmi	do_line_just_return
		bne	shell_error

		st	d0
*****************************************************************
* do_line_substhist - 行を履歴置換、単語分け、verbose表示、履歴登録し、実行する
*
* CALL
*      A0      行
*      D0.B    0 でなければ履歴登録する
*
* RETURN
*      D0.L    0
*      CCR     TST.L D0
*      その他  破壊
*****************************************************************
.xdef do_line_substhist

do_line_substhist:
		move.b	d0,d7
		**
		**  履歴の置換を行う
		**
		lea	tmpline(a5),a1
		move.w	#MAXLINELEN,d1
		clr.l	a2
		movem.l	a0-a1,-(a7)
		bsr	subst_history
		movem.l	(a7)+,a0-a1
		btst	#2,d0
		bne	shell_error

		movea.l	a1,a0
		move.b	d0,d2
		**
		**  単語を探す
		**
		lea	args(a5),a1
		tst.l	current_source(a5)
		beq	find_words_1

		movea.l	current_source(a5),a1
		lea	SOURCE_WORDLIST(a1),a1
find_words_1:
		move.w	#MAXWORDLISTSIZE,d1
		move.l	a1,-(a7)
		bsr	make_wordlist
		movea.l	(a7)+,a0
		bmi	shell_error
		**
		**  verbose 表示をする
		**
		bsr	verbose_0
		**
		**  履歴に登録する
		**
		tst.b	d7
		beq	skip_enter_history

		tst.l	current_source(a5)
		bne	skip_enter_history

		tst.b	interactive_mode(a5)
		beq	skip_enter_history

		bsr	enter_history
skip_enter_history:
		btst	#0,d2			*  !:p
		bne	do_line_return
*****************************************************************
* do_line - 単語分けされた行を実行する
*
* CALL
*      A0      単語並び（破壊される。MAXWORDLISTSIZEバイト必要）
*      D0.W    単語数
*
* RETURN
*      D0.L    0
*      CCR     TST.L D0
*      その他  破壊
*****************************************************************
.xdef do_line

do_line:
		clr.l	command_name(a5)

		tst.b	not_execute(a5)
		bne	do_line_skip_subst_alias

		bsr	test_line

		lea	tmpline(a5),a1
		move.w	#MAXLINELEN,d1
		move.w	d0,d3
		bsr	subst_alias
		bne	shell_error

		tst.b	d2
		beq	no_alias_substed

		moveq	#MAXALIASLOOP,d4		* D4 : 別名置換ループ・カウンタ
recurse_subst_alias:
		exg	a0,a1
		move.w	#MAXWORDLISTSIZE,d1
		move.l	a1,-(a7)
		bsr	make_wordlist
		movea.l	(a7)+,a1
		exg	a0,a1
		bmi	shell_error

		btst	#1,d2
		beq	no_more_alias

		subq.w	#1,d4
		bcc	alias_loop_ok

		lea	msg_alias_loop,a0
		bra	print_shell_error

alias_loop_ok:
		move.w	#MAXLINELEN,d1
		move.w	d0,d3
		bsr	subst_alias
		bne	shell_error

		tst.b	d2
		bne	recurse_subst_alias
no_alias_substed:
		move.w	d3,d0
no_more_alias:
		bsr	remove_dot_word
do_line_skip_subst_alias:
		tst.w	d0
		beq	do_line_return

		bsr	test_line

		lea	statement_table,a1
		bsr	search_builtin
		bne	do_line_Statement
	**
	**  制御文ではない
	**
		tst.b	if_status(a5)		*  if の状態が
		bne	do_line_return		*  '偽'ならば実行しない

		tst.b	switch_status(a5)	*  switch で
		bne	do_line_return		*  caseに到達してないかbreaksw後ならば実行しない

		tst.b	loop_status(a5)		*  loop を読んでいる最中
		bmi	do_line_return		*  ならば実行しない

		move.w	d0,d2
		bsr	strlen
		exg	d0,d2
		subq.l	#1,d2
		bcs	do_line_CommandList

		cmpi.b	#':',(a0,d2.l)
		bne	do_line_CommandList
	**
	**  ラベル
	**
		subq.w	#1,d0
		beq	do_line_return

		move.l	a0,command_name(a5)
		bsr	syntax_error
		bra	shell_error
	**
	**  制御ステートメント
	**
do_line_Statement:
		btst.b	#0,9(a1)
		bne	ignore_loop_status

		tst.b	loop_status(a5)
		bmi	do_line_return
ignore_loop_status:
		btst.b	#1,9(a1)
		bne	ignore_if_status

		tst.b	if_status(a5)
		bne	do_line_return
ignore_if_status:
		btst.b	#2,9(a1)
		bne	ignore_switch_status

		tst.b	switch_status(a5)
		bne	do_line_return
ignore_switch_status:
		tst.b	not_execute(a5)
		bne	do_line_return

		movea.l	a1,a2
		movea.l	a0,a1
		bsr	strfor1
		subq.w	#1,d0
		move.l	a2,command_name(a5)
		movea.l	10(a2),a2
		jsr	(a2)			* 文の処理
		tst.l	d0
		bne	shell_error

		clr.l	command_name(a5)
do_line_return:
		moveq	#0,d0
do_line_just_return:
		rts
	**
	**  コマンド・リスト
	**
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
input_nonoclobber  = output_nonoclobber-1
pad2               = input_nonoclobber-1		* 偶数に合わせる

do_line_CommandList:
		link	a6,#pad1
		link	a4,#pad2
		move.l	a0,nextptr(a6)
		move.w	d0,nwords_next(a6)
do_next_command_0:
		clr.b	last_connect_type(a4)
do_next_command:
		st	line_condition(a4)
start_DoCommandList:
		move.w	nwords_next(a6),d0
		movea.l	nextptr(a6),a0
		not.b	pipe_flip_flop(a5)
		clr.b	connect_type(a6)	* 次のコマンドとの接続形式
****************************************************************
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
		bsr	strfor1
		subq.w	#1,d7
		addq.w	#1,d1
		bra	extract_simple_list

extract_simple_list_redirect:
		bsr	skip_redirect_token
		bra	extract_simple_list

extract_simple_list_vline:
		tst.b	1(a0)
		bne	extract_simple_list_continue

		addq.w	#1,d1
		bsr	strfor1
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

		bsr	strfor1
		subq.w	#1,d7
		move.l	a0,nextptr(a6)
		move.w	d7,nwords_next(a6)
		tst.w	d1
		bne	not_null_ampersand

		bsr	is_invalid_null_command
		beq	invalid_null_command
not_null_ampersand:
		tst.b	line_condition(a4)
		beq	do_next_command_0

		movea.l	a1,a0
		move.w	d1,d0
		moveq	#1,d1
		move.b	not_execute(a5),d2
		bsr	fork
		bsr	clear_status
		bra	do_next_command_0
****************************************************************
no_ampersand:
		**
		**  コマンドの終わりを見つける
		**
		movea.l	a1,a0
		move.w	d1,d7			* D7.W : 語数カウンタ
		moveq	#0,d1			* D1.W : この単一コマンドの語数カウンタ
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
		beq	find_command_separation_semicolon

		cmp.b	#'|',d0
		beq	find_command_separation_vertical_line

		cmp.b	#'&',d0
		beq	find_command_separation_ampersand

		cmp.b	#'>',d0
		bne	find_command_separation_continue

		bsr	skip_redirect_token
		bra	find_command_separation

find_command_separation_continue:
		bsr	strfor1
		subq.w	#1,d7
		addq.w	#1,d1
		bra	find_command_separation
****************
find_command_separation_vertical_line:
		moveq	#TOR,d2
		tst.b	1(a0)
		bne	test_separator_2

		moveq	#TPIPE,d2
		bsr	strfor1
		subq.w	#1,d7
		bsr	check_out_both

		tst.b	line_condition(a4)
		bne	separator_found

		clr.b	connect_type(a6)
		bra	find_command_separation
****************
find_command_separation_ampersand:
		moveq	#TAND,d2
test_separator_2:
		cmp.b	1(a0),d0
		bne	find_command_separation_continue

		tst.b	2(a0)
		bne	find_command_separation_continue

		bra	list_found_1
****************
find_command_separation_semicolon:
		moveq	#TLST,d2
		tst.b	1(a0)
		bne	find_command_separation_continue
list_found_1:
		bsr	strfor1
		subq.w	#1,d7
separator_found:
		move.b	d2,connect_type(a6)
		move.l	a0,nextptr(a6)
		move.w	d7,nwords_next(a6)
separation_done:
		tst.b	line_condition(a4)
		bne	parse_redirection

		tst.w	d1
		bne	pipeline_done

		bsr	is_invalid_null_command
		beq	invalid_null_command
		bra	pipeline_done
********************************
parse_redirection:
		**
		**  入出力切り換えを認識する
		**
		movea.l	a1,a0
		move.w	d1,d7			* D7.W : 語数カウンタ

		lea	simple_args(a5),a1
		clr.w	argc(a5)

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
		add.w	d0,argc(a5)
		exg	a0,a2
		exg	a0,a1
		move.l	a2,d0
		sub.l	a1,d0
		bsr	memmovi
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

		cmp.b	#'<',d0
		bne	find_redirection_continue

		cmp.b	2(a0),d0
		bne	find_redirection_continue

		moveq	#2,d3
		tst.b	3(a0)
		beq	redirection_found
find_redirection_continue:
		subq.w	#1,d7
		addq.w	#1,argc(a5)
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

		bsr	strfor1
		subq.w	#1,d7
		move.b	d3,here_document(a4)		*  0:<  1:<<  2:<<<
		bne	heredoc_found

		sf	input_nonoclobber(a4)
		tst.w	d7
		beq	rd_in_get_filename

		cmpi.b	#'!',(a0)
		bne	rd_in_get_filename

		tst.b	1(a0)
		bne	rd_in_get_filename

		st	input_nonoclobber(a4)
		bsr	strfor1
		subq.w	#1,d7
rd_in_get_filename:
		lea	input_pathname(a4),a2		*  A2 : 入力先のファイル名格納処
		move.l	a2,d5				*  D5 : 入力先ファイル名を示す
		bra	get_redirect_filename
****************
redirect_out_found:
		cmpi.b	#TPIPE,connect_type(a6)
		beq	output_ambiguous

		tst.l	d6
		bne	output_ambiguous

		move.b	d3,output_cat(a4)		*  0:>  1:>>
		bsr	strfor1
		subq.w	#1,d7
		bsr	check_out_both
		sf	output_nonoclobber(a4)
		tst.w	d7
		beq	rd_out_get_filename

		cmpi.b	#'!',(a0)
		bne	rd_out_get_filename

		tst.b	1(a0)
		bne	rd_out_get_filename

		st	output_nonoclobber(a4)
		bsr	strfor1
		subq.w	#1,d7
rd_out_get_filename:
		lea	output_pathname(a4),a2		* A2 : 出力先ファイル名格納処
		move.l	a2,d6				* D6 : 出力先ファイル名を示す
get_redirect_filename:
		tst.w	d7
		beq	missing_redirect_filename

		link	a6,#-auto_word
		movea.l	a0,a3				* A3:ファイル名
		bsr	strfor1				* A0:次の単語
		subq.w	#1,d7
		exg	a0,a3				* A0:ファイル名  A3:次の単語
		movem.l	a0-a1,-(a7)
		lea	-auto_word(a6),a1
		moveq	#1,d0
		move.w	#MAXWORDLEN+1,d1
		bsr	subst_var
		movem.l	(a7)+,a0-a1
		beq	redirect_name_error1
		bmi	redirect_name_error1

		exg	a0,a3				* A0:次の単語  A3:ファイル名
		move.l	a0,-(a7)
		lea	-auto_word(a6),a0
		exg	a1,a2
		move.l	#MAXPATH,d1
		bsr	expand_a_word
		exg	a1,a2
		movea.l	(a7)+,a0
		unlk	a6
		bpl	find_redirection

		movea.l	a3,a0				* A0:ファイル名
		cmp.l	#-5,d0
		bne	redirect_name_error2

		moveq	#0,d0
		bra	redirect_name_error2

redirect_name_error1:
		unlk	a6
redirect_name_error2:
		cmp.l	#-4,d0
		beq	shell_error

		bsr	strip_quotes
		bsr	pre_perror

		tst.l	d0
		beq	missing_redirect_filename

		addq.l	#1,d0
		beq	redirect_name_ambiguous

		lea	msg_too_long_pathname,a0
		bra	print_shell_error

redirect_name_ambiguous:
		tst.b	d2
		beq	input_ambiguous
		bra	output_ambiguous

missing_redirect_filename:
		lea	msg_missing_input,a0
		tst.b	d2
		beq	print_shell_error

		lea	msg_missing_output,a0
		bra	print_shell_error
****************
heredoc_found:
		tst.w	d7
		beq	missing_heredoc_word

		move.l	a0,d5
		bsr	strfor1
		subq.w	#1,d7
		bra	find_redirection

missing_heredoc_word:
		lea	msg_missing_heredoc_word,a0
		bra	print_shell_error
********************************
find_redirection_done:
		move.w	argc(a5),d1
		bne	not_null_command

		bsr	is_invalid_null_command
		beq	invalid_null_command

		tst.l	d5
		bne	invalid_null_command

		tst.l	d6
		bne	invalid_null_command
not_null_command:
********************************
		**
		**  入力を切り換える
		**
		lea	pipe1_name(a5),a0
		lea	pipe1_delete(a5),a3
		tst.b	pipe_flip_flop(a5)
		bne	redirect_in_1

		lea	pipe2_name(a5),a0
		lea	pipe2_delete(a5),a3
redirect_in_1:
		cmpi.b	#TPIPE,last_connect_type(a4)
		beq	redirect_in_pipe

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
		tst.b	not_execute(a5)
		bne	redirect_in_done

		moveq	#0,d0				* 読み込みモードで
		bsr	tfopen				* 入力先ファイルをオープンする
		move.l	d0,d1				* デスクリプタを D1 にセット
		bmi	rd_perror

		move.w	d1,undup_input(a5)		* デスクリプタを undup_input に覚えておく

		bsr	isblkdev			* そいつがキャラクタ・デバイスで
		beq	redirect_in_ok			*   なければOK

		tst.b	input_nonoclobber(a4)
		bne	redirect_in_ok

		tst.b	flag_forceio(a5)
		bne	redirect_in_ok

		move.w	d1,-(a7)			* そいつが
		move.w	#6,-(a7)			* ファイルハンドルを介して入力可能か
		DOS	_IOCTRL				* 調べる
		addq.l	#4,a7
		tst.l	d0				* 入力可能ならば
		bne	redirect_in_ok			*   OK

		lea	msg_not_inputable_device,a1
		bra	rd_errorp
****************
redirect_in_here_document:
		tst.b	not_execute(a5)
		bne	heredoc_open_ok

		movea.l	a0,a2
		bsr	tmpfile
		bmi	shell_error

		move.w	d0,undup_input(a5)
		move.w	d0,d1				* D1.W : 埋め込み文書用一時ファイルのファイル・ハンドル
		move.b	#2,(a3)				* コマンド終了後即消去する
heredoc_open_ok:
		cmp.b	#1,here_document(a4)
		bne	here_string

		movea.l	d5,a0
		bsr	isquoted
		move.b	d0,d3				* D3 : 「クオートされている」フラグ
heredoc_loop:
		lea	line(a5),a0
		move.w	d1,-(a7)
		move.w	#MAXLINELEN,d1
		suba.l	a1,a1				* プロンプト無し
		moveq	#0,d0
		bsr	getline_phigical
		move.w	(a7)+,d1
		tst.l	d0
		bmi	heredoc_eof
		bne	shell_error

		lea	line(a5),a0
		movea.l	d5,a1
		bsr	strcmp
		beq	heredoc_end

		tst.b	d3
		bne	heredoc_subst_ok

		move.l	d1,-(a7)
		lea	tmpline(a5),a1
		move.w	#MAXLINELEN,d1
		moveq	#0,d0
		bsr	subst_var_2
		move.l	(a7)+,d1
		tst.l	d0
		bmi	heredoc_subst_error

		lea	tmpline(a5),a0
		lea	line(a5),a1
		move.l	d1,-(a7)
		move.w	#MAXLINELEN,d1
		bsr	subst_command_2
		move.l	(a7)+,d1
		tst.l	d0
		bmi	heredoc_subst_error
		bra	heredoc_subst_ok

here_string:
		movea.l	d5,a1
		lea	line(a5),a0
		moveq	#1,d0
		bsr	expand_wordlist_var
		tst.l	d0
		bmi	shell_error

		bsr	words_to_line
heredoc_subst_ok:
		tst.b	not_execute(a5)
		bne	heredoc_continue

		lea	line(a5),a0
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
heredoc_continue:
		cmp.b	#1,here_document(a4)
		beq	heredoc_loop
heredoc_end:
		tst.b	not_execute(a5)
		bne	redirect_in_done

		clr.w	-(a7)				* 先頭
		clr.l	-(a7)				* 　まで
		move.w	d1,-(a7)			*
		DOS	_SEEK				* 　シークする
		addq.l	#8,a7
		bra	redirect_in_ok

heredoc_eof:
		movea.l	d5,a0
		lea	msg_no_heredoc_terminator,a1
		bra	rd_errorp

heredoc_write_error:
		movea.l	a2,a0
		bra	rd_perror

heredoc_subst_error:
		cmp.l	#-4,d0
		beq	shell_error

		bsr	reset_delete_io
		bsr	too_long_line
		bra	shell_error
****************
redirect_in_ok:
		moveq	#0,d0				* 標準入力を
		bsr	redirect			*   リダイレクト
		bmi	rd_perror

		move.w	d0,save_stdin(a5)		* 旧デスクリプタのコピーをセーブ
redirect_in_done:
********************************
		**
		**  出力を切り換える
		**
		lea	pipe2_name(a5),a0
		lea	pipe2_delete(a5),a3
		tst.b	pipe_flip_flop(a5)
		bne	rd_pipe_1

		lea	pipe1_name(a5),a0
		lea	pipe1_delete(a5),a3
rd_pipe_1:
		tst.b	not_execute(a5)
		bne	redirect_out_done

		cmpi.b	#TPIPE,connect_type(a6)
		beq	redirect_out_pipe

		tst.l	d6
		beq	redirect_out_done

		movea.l	d6,a0

		moveq	#0,d0				* まず読み込みモードで
		bsr	tfopen				* 出力先ファイルをオープンしてみる
		move.l	d0,d2				* デスクリプタをD2にセット
		bpl	redirect_out_device_check	* オープンできたならデバイスチェック

		cmp.l	#-2,d0				* エントリがなければ
		beq	redirect_out_exist_check_done	*   チェック終わり

		bra	rd_perror
			* あとで本当にOPENしたときにもチェックするので不要と思うかも知れな
			* いが、CREATEではディレクトリへのアクセスが「このファイルは書き込
			* みできない」となってしまうので、ここで予めチェックしておく

redirect_out_device_check:
		bsr	isblkdev			* そいつがキャラクタ・デバイスかどうかを
		move.b	d0,d1				*   D1にセット
		moveq	#1,d0
		tst.b	d1				* キャラクタ・デバイスで
		beq	redirect_out_device_check_done	*   なければチェック終わり

		tst.b	output_nonoclobber(a4)
		bne	redirect_out_device_check_done

		tst.b	flag_forceio(a5)
		bne	redirect_out_device_check_done

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

		tst.b	flag_noclobber(a5)
		beq	redirect_out_create

		lea	msg_nofile,a1
		bra	rd_errorp

****************
redirect_out_not_cat:
		tst.l	d2				* 出力先ファイルが存在して
		bmi	redirect_out_create		* 　いないならばＯＫ．作成する

		tst.b	d1				* キャラクタ・デバイス
		bne	redirect_out_open		* 　ならばＯＫ．オープンする

		tst.b	output_nonoclobber(a4)
		bne	redirect_out_create

		tst.b	flag_noclobber(a5)
		beq	redirect_out_create

		lea	msg_file_exists,a1
		bra	rd_errorp
****************
redirect_out_pipe:
		clr.b	output_cat(a4)
		bsr	tmpfile
		bmi	shell_error

		move.b	#1,(a3)				* 次のコマンドの終了後には消去する
		bra	redirect_out_ready
****************
redirect_out_create:
		clr.b	output_cat(a4)
		bsr	create_normal_file
		bra	redirect_out_opened

redirect_out_open:
		moveq	#1,d0				* 書き込みモードで
		bsr	tfopen				* 出力先ファイルをオープンする
redirect_out_opened:
		bmi	rd_perror
redirect_out_ready:
		move.w	d0,d1				* リダイレクト先を D1 にセットして
		move.w	d1,undup_output(a5)		*   undup_output に覚えておく

		tst.b	output_cat(a4)			* >> で
		beq	do_redirect_out			*   なければシークしない

		bsr	isblkdev			* リダイレクト先がシーク不可
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

		move.w	d0,save_stdout(a5)		* 旧デスクリプタのコピーをセーブ

		tst.b	output_both(a4)
		beq	redirect_out_done

		moveq	#2,d0				* 警告出力を
		bsr	redirect			* リダイレクト
		bmi	rd_perror

		move.w	d0,save_stderr(a5)		* 旧デスクリプタのコピーをセーブ
redirect_out_done:
********************************
		**
		**  単一のコマンドを実行する
		**
		moveq	#0,d0
		sf	d1
		sf	d2
		unlk	a4
		bsr	DoSimpleCommand
		link	a4,#pad2
pipeline_done:
		move.b	connect_type(a6),d1
		move.b	d1,last_connect_type(a4)
		beq	command_done

		tst.b	not_execute(a5)
		bne	do_next_command

		move.b	last_connect_type(a4),d1
		cmp.b	#TOR,d1
		beq	test_or

		cmp.b	#TAND,d1
		bne	do_next_command
test_and:
		bsr	get_status
		bne	shell_error

		tst.l	d0
		seq	line_condition(a4)
		bra	start_DoCommandList

test_or:
		bsr	get_status
		bne	shell_error

		tst.l	d0
		sne	line_condition(a4)
		bra	start_DoCommandList

command_done:
		unlk	a4
		unlk	a6
		moveq	#0,d0
		rts


input_ambiguous:
		lea	msg_input_ambiguous,a0
		bra	print_shell_error

output_ambiguous:
		lea	msg_output_ambiguous,a0
		bra	print_shell_error

invalid_null_command:
		lea	msg_invalid_null_command,a0
		bra	print_shell_error

rd_errorp:
		bsr	reset_delete_io
		bsr	pre_perror
		movea.l	a1,a0
		bra	print_shell_error

rd_perror:
		bsr	reset_delete_io
		bsr	perror
		bra	shell_error
*****************************************************************
is_invalid_null_command:
		move.b	last_connect_type(a4),d0
		cmp.b	#TPIPE,d0
		beq	is_invalid_null_command_return

		cmp.b	#TOR,d0
		beq	is_invalid_null_command_return

		cmp.b	#TAND,d0
		beq	is_invalid_null_command_return

		move.b	connect_type(a6),d0
		cmp.b	#TPIPE,d0
		beq	is_invalid_null_command_return

		cmp.b	#TOR,d0
		beq	is_invalid_null_command_return

		cmp.b	#TAND,d0
is_invalid_null_command_return:
		rts
*****************************************************************
check_out_both:
		sf	output_both(a4)
		tst.w	d7
		beq	out_not_both

		cmpi.b	#'&',(a0)
		bne	out_not_both

		tst.b	1(a0)
		bne	out_not_both

		st	output_both(a4)
		bsr	strfor1
		subq.w	#1,d7
out_not_both:
		rts
*****************************************************************
.xdef verbose

verbose_0:
		tst.l	fork_stackp(a5)
		bne	print_verbose_done

		btst	#1,d2
		bne	verbose

		btst	#3,d2
		bne	do_print_verbose
verbose:
		tst.b	flag_verbose(a5)
		beq	print_verbose_done
do_print_verbose:
		bsr	echo_args
print_verbose_done:
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
		bsr	strfor1
		subq.w	#1,d7
		beq	skip_redirect_token_done

		cmpi.b	#'&',(a0)
		bne	skip_redirect_token_2

		tst.b	1(a0)
		bne	skip_redirect_token_2

		addq.w	#1,d1
		bsr	strfor1
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
		bsr	strfor1
		subq.w	#1,d7
skip_redirect_token_done:
		rts
*****************************************************************
* DoSimpleCommand - 単純コマンドを実行する
*
* CALL
*      simple_args
*      argc
*      D1.B   非0:必ず消費時間を標準出力に報告する
*      D2.B   非0:再帰である..変数展開をしない，入出力をリセットしない
*
* RETURN
*      全て   破壊
*****************************************************************
.xdef DoSimpleCommand

timer_start_low = -4
timer_start_high = timer_start_low-4
timer_search_low = timer_start_high-4
timer_search_high = timer_search_low-4
timer_load_low = timer_search_high-4
timer_load_high = timer_load_low-4
timer_exec_low = timer_load_high-4
timer_exec_high = timer_exec_low-4
timer_ok = timer_exec_high-1
time_always = timer_ok-1
recursed = time_always-1
arg_is_huge = recursed-1
pad = arg_is_huge-0

DoSimpleCommand:
		link	a6,#pad
		clr.l	user_command_signal
		clr.b	timer_ok(a6)
		move.b	d1,time_always(a6)
		move.b	d2,recursed(a6)
		move.w	argc(a5),d0
		beq	simple_command_done_0
	*
	*  コマンド・グループであるかどうかを調べる
	*
		lea	simple_args(a5),a0
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

		bsr	strforn
		cmpi.b	#')',(a0)
		bne	badly_placed_paren

		tst.b	1(a0)
		bne	badly_placed_paren

		subq.w	#1,d0
		bcs	simple_command_done_0

		movea.l	a1,a0
		bsr	strfor1
		moveq	#1,d1
		move.b	not_execute(a5),d2
		bsr	fork
		bra	simple_command_done

is_not_command_group:
	*
	*  コマンドはコマンド・グループではない
	*
		tst.b	recursed(a6)			*  再帰ならば
		bne	start_do_simple_command		*  変数置換はしない

		move.w	argc(a5),d0
		movea.l	a0,a1
		bsr	subst_var_wordlist
		bmi	shell_error

		move.w	d0,argc(a5)
		beq	simple_command_done_0

		tst.b	not_execute(a5)
		beq	start_do_simple_command

		movea.l	a0,a1
		bsr	expand_wordlist			* ただチェックのため
		bra	simple_command_done_0

start_do_simple_command:
	*
	*  コマンド名を展開する
	*
		lea	simple_args(a5),a0
		lea	command_pathname(a5),a1
		move.l	#MAXPATH,d1
		bsr	expand_a_word
		bpl	command_name_ok

		cmp.l	#-4,d0
		beq	shell_error

		bsr	strip_quotes
		bsr	pre_perror

		lea	msg_too_long_command_name,a0
		cmp.l	#-3,d0
		beq	print_shell_error

		cmp.l	#-2,d0
		beq	print_shell_error

		lea	msg_command_ambiguous,a0
		cmp.l	#-1,d0
		beq	print_shell_error

		lea	msg_missing_command_name,a0
		bra	print_shell_error

command_name_ok:
	*
	*  コマンド・プログラムを検索する
	*
		bsr	getitimer			* 検索を開始した時刻を記憶する
		move.l	d0,timer_start_low(a6)
		move.l	d1,timer_start_high(a6)
		lea	command_pathname(a5),a0
		moveq	#0,d0
		bsr	search_command			* 検索する
		move.l	d0,-(a7)
		bsr	getitimer			* 検索を終了した時刻を記憶する
		move.l	d0,timer_search_low(a6)
		move.l	d1,timer_search_high(a6)
		move.l	(a7)+,d0
		bmi	command_not_found

		add.l	#1,hash_hits(a5)
		cmp.l	#6,d0
		bls	simple_command_user_command
	*
	*  組み込みコマンド
	*
		move.l	d0,a1

		lea	simple_args(a5),a0
		move.w	argc(a5),d0

		btst.b	#2,9(a1)
		beq	builtin_normal

		tst.w	undup_output(a5)
		bmi	builtin_will_recurse
		*
		*  サブシェルで実行する
		*
		moveq	#1,d1
		move.b	not_execute(a5),d2
		bsr	fork
		bra	simple_command_done

builtin_will_recurse:
		not.b	pipe_flip_flop(a5)
builtin_normal:
		move.l	a1,command_name(a5)

		move.l	timer_search_low(a6),timer_load_low(a6)
		move.l	timer_search_high(a6),timer_load_high(a6)

		bsr	strfor1
		subq.w	#1,d0

		btst.b	#1,9(a1)
		bne	builtin_paren_ok

		bsr	check_paren
		bne	badly_placed_paren
builtin_paren_ok:
		*
		*  コマンドをエコーする
		*
		bsr	echo_command
		*
		*  status を 0 にしておく
		*
		move.w	d0,-(a7)
		bsr	clear_status
		move.w	(a7)+,d0
		*
		*  引数並びを展開する
		*  （コマンドによっては、ここではまだ展開しない）
		*
		btst.b	#0,9(a1)
		bne	run_builtin

		exg	a1,a2
		movea.l	a0,a1
		lea	simple_args(a5),a0
		bsr	expand_wordlist
		exg	a1,a2
		bmi	shell_error
run_builtin:
		*
		* 組み込みコマンドを実行する
		*
		movea.l	10(a1),a1
		move.l	a6,-(a7)
		jsr	(a1)
		movea.l	(a7)+,a6
		tst.l	d0
		bne	shell_error	* 組み込みコマンドのエラーは構文エラーと同じとする

		move.b	#1,timer_ok(a6)
		bra	simple_command_done_0

simple_command_user_command:
	*
	*  プログラム・ファイル
	*
		move.l	d0,d2				* D2.L : 拡張子コード

		lea	simple_args(a5),a0
		movea.l	a0,a1
		bsr	strfor1
		move.w	argc(a5),d0
		subq.w	#1,d0
		bsr	check_paren
		bne	badly_placed_paren
		*
		*  引数並びを展開する
		*
		exg	a0,a1
		bsr	expand_wordlist
		bmi	shell_error

		move.w	d0,argc(a5)
		*
		*  コマンドをエコーする
		*
		bsr	echo_command
		*
		*  実行可能か？
		*
		tst.l	d2
		beq	cannot_exec			*  0 : 実行不可
		*
		*  実際に起動するバイナリ・コマンド・ファイルのパス名と
		*  パラメータ行を決定する
		*
		lea	user_command_parameter(a5),a3	*  A3 : パラメータ行の先頭
		move.w	#MAXLINELEN,d3			*  D3.W : パラメータ行の最大文字数

		cmp.l	#1,d2				*  1 : 拡張子無し
		beq	do_exec_script

		cmp.l	#5,d2
		blo	do_binary_command		*  2, 3, 4 : .R, .Z, .X
		beq	do_BAT_command			*  5 : .BAT
do_exec_script:
		lea	command_pathname(a5),a0		*  コマンド・ファイルを
		moveq	#0,d0				*  読み込みモードで
		bsr	tfopen				*  オープンする
		move.l	d0,d1
		bmi	cannot_exec			*  オープンできない .. 実行不可

		move.w	d1,d0
		bsr	fgetc
		cmp.b	#'#',d0				*  先頭が # でなければ
		bne	cannot_exec_script		*  実行不可

		move.w	d1,d0
		bsr	fgetc
		cmp.b	#'$',d0				*  # の次の文字が $ ならば
		beq	do_fish_script			*  fish で実行

		cmp.b	#'!',d0				*  # の次の文字が ! でもなければ
		bne	cannot_exec_script		*  実行不可

		*  スクリプト・シェルのパス名を読み取る

		move.w	d1,d0
		bsr	fskip_space
		bmi	do_fish_script

		cmp.b	#LF,d0
		beq	do_fish_script

		move.w	d0,-(a7)
		lea	command_pathname(a5),a1		*  コマンドのパス名を
		lea	pathname_buf,a0			*  一時領域に
		bsr	strcpy				*  コピーしておく
		move.w	(a7)+,d0
		move.w	#MAXPATH,d2
get_shell_loop:
		subq.w	#1,d2
		bcs	explicit_shell_too_long

		move.b	d0,(a1)+
		move.w	d1,d0
		bsr	fgetc
		bmi	get_shell_done

		bsr	isspace
		bne	get_shell_loop
get_shell_done:
		clr.b	(a1)

		*  シェルに渡す引数を読み取る

		lea	congetbuf+2,a0			* ［暫定］
		clr.b	(a0)
		tst.l	d0
		bmi	get_shellarg_done

		cmp.b	#LF,d0
		beq	get_shellarg_done

		move.w	d1,d0
		bsr	fskip_space
		bmi	get_shellarg_done

		cmp.b	#LF,d0
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
		movea.l	a3,a0
		move.w	d3,d0

		lea	congetbuf+2,a1		* ［暫定］
		tst.b	(a1)
		beq	set_shellarg_done

		moveq	#1,d1
		bsr	EncodeHUPAIR
		bmi	simple_command_too_long_line
set_shellarg_done:
		movea.l	a0,a3
		move.w	d0,d3
		bra	do_script_2

explicit_shell_too_long:
		move.w	d1,d0
		bsr	fclose
		bra	shell_too_long
****************
do_fish_script:
		move.w	d1,d0
		bsr	fclose

		lea	command_pathname(a5),a1		* コマンドのパス名を
		lea	pathname_buf,a0			* 一時領域に
		bsr	strcpy				* コピーしておく
		lea	word_shell,a0
		bra	do_script_1
****************
do_BAT_command:
		lea	command_pathname(a5),a1
		lea	pathname_buf,a0			*  pathname_buf に
		bsr	strcpy				*  コピーして
		bsr	sltobsl				*  \ を / に変える
		lea	word_batshell,a0
do_script_1:
		clr.b	command_pathname(a5)
		bsr	find_shellvar
		beq	do_script_2

		addq.l	#2,a0
		tst.w	(a0)+
		beq	do_script_2

		bsr	strfor1				*  変数名をスキップ
		bsr	strlen				*  最初の単語の長さ
		cmp.l	#MAXPATH,d0
		bhi	shell_too_long

		movea.l	a0,a1
		lea	command_pathname(a5),a0
		bsr	strcpy
do_script_2:
statbuf = -(((54)+1)>>1<<1)
		link	a6,#statbuf
		lea	command_pathname(a5),a0
		lea	statbuf(a6),a1
		bsr	stat
		move.b	statbuf+21(a6),d1		*  ファイル・モード
		unlk	a6
		tst.l	d0
		bmi	shell_not_found

		btst	#3,d1				*  ボリューム・ラベル
		bne	shell_not_found

		btst	#4,d1				*  ディレクトリ
		bne	cannot_exec

		lea	pathname_buf,a1
		moveq	#1,d1
		movea.l	a3,a0
		move.w	d3,d0
		bsr	EncodeHUPAIR
		bmi	simple_command_too_long_line

		movea.l	a0,a3
		move.w	d0,d3
****************
do_binary_command:
		bsr	getitimer
		move.l	d0,timer_search_low(a6)
		move.l	d1,timer_search_high(a6)

		lea	simple_args(a5),a1
		move.w	argc(a5),d1
		movea.l	a3,a0
		move.w	d3,d0
		bsr	EncodeHUPAIR
		bmi	simple_command_too_long_line

		lea	user_command_parameter(a5),a1	*  A1 : パラメータ行の先頭
		move.w	#MAXLINELEN,d1			*  D1.W : パラメータ行の最大文字数
		bsr	SetHUPAIR
		bmi	simple_command_too_long_line

		cmp.w	d1,d0
		sne	arg_is_huge(a6)

		movea.l	envwork(a5),a0
		bsr	dupenv
		beq	exec_failure

		move.l	d0,user_command_env(a5)

		bsr	remember_misc_environments

		movem.l	a5-a6,-(a7)
		move.l	user_command_env(a5),-(a7)	*  環境のアドレス
		pea	user_command_parameter(a5)	*  パラメータのアドレス
		pea	command_pathname(a5)		*  起動するコマンドのパス名のアドレス
		move.w	#1,-(a7)			*  ファンクション : LOAD
		sf	in_fish
		DOS	_EXEC
		lea	14(a7),a7
		movem.l	(a7)+,a5-a6
		tst.l	d0
		bmi	loadprg_stop

		tst.l	user_command_signal
		bne	loadprg_stop			*  既に EXIT された

		tst.b	arg_is_huge(a6)
		beq	do_exec
****************
		*  ユーザ・プログラムへの引数が255バイトを超えている
		*
		*  コマンドが HUPAIR準拠かどうかを調べる
		*
		movea.l	a0,a3
		lea	2(a4),a0
		lea	str_hupair,a1
		bsr	strcmp
		beq	do_exec				*  HUPAIR準拠である .. 実行する
		*
		*  シェル変数 hugearg を調べる
		*
		lea	word_hugearg,a0			*  シェル変数 hugearg が
		bsr	find_shellvar			*  定義されて
		beq	ask_hugearg			*  いないならば，問い合わせる

		addq.l	#2,a0
		move.w	(a0)+,d2			*  単語数が
		beq	hugearg_abort			*  0ならアボートする

		bsr	strfor1				*  変数名をスキップ
		lea	word_force,a1			*  force
		bsr	strcmp
		beq	do_exec				*    ならば実行する

		lea	word_indirect,a1		*  indirect
		bsr	strcmp
		beq	hugearg_indirect		*    ならば indirect
hugearg_abort:						*  さもなくばアボートする
ask_hugearg:
		lea	hugearg_error(pc),a4
hugearg_abort1:
		movem.l	d0/a4-a6,-(a7)
		lea	fail_hugearg(pc),a1
		move.l	a1,$14(a3)
		move.l	a7,$3c(a3)
		DOS	_EXIT
fail_hugearg:
		movem.l	(a7)+,d0/a4-a6
		st	in_fish
		jmp	(a4)

hugearg_indirect:
		lea	str_indirect_flag,a1
		cmp.w	#2,d2
		blo	hugearg_indirect_flag_ok

		bsr	strfor1
		tst.b	(a0)
		beq	hugearg_indirect_flag_ok

		movea.l	a0,a1
hugearg_indirect_flag_ok:
		lea	argment_pathname,a0
		bsr	tmpfile
		bmi	hugearg_indirect_error

		move.w	d0,d2

		lea	user_command_parameter+1(a5),a0
		bsr	strlen
		move.l	d0,-(a7)
		move.l	a0,-(a7)
		move.w	d2,-(a7)
		DOS	_WRITE
		lea	10(a7),a7
		move.l	d0,d1
		move.w	d2,d0
		bsr	fclose
		exg	d0,d1
		tst.l	d0
		bmi	hugearg_indirect_perror

		exg	d0,d1
		tst.l	d0
		bmi	hugearg_indirect_perror

		bsr	stpcpy
		move.l	d0,d1
		lea	argment_pathname,a1
		bsr	strcpy
		bsr	sltobsl
		add.l	d1,d0
		cmp.l	#255,d0
		bhs	hugearg_indirect_too_long

		move.b	d0,user_command_parameter(a5)
		bra	do_exec

hugearg_indirect_too_long:
		lea	too_long_indirect_flag(pc),a4
		bra	hugearg_abort1

hugearg_indirect_error:
		lea	shell_error(pc),a4
		bra	hugearg_abort1

hugearg_indirect_perror:
		lea	simple_command_perror(pc),a4
		bra	hugearg_abort1
****************
do_exec:
		bsr	getitimer
		move.l	d0,timer_load_low(a6)
		move.l	d1,timer_load_high(a6)

		movem.l	a5-a6,-(a7)
		move.l	a4,-(a7)		*  エントリ・アドレス
		move.w	#4,-(a7)		*  ファンクション : EXEC
		DOS	_EXEC
		addq.l	#6,a7
		movem.l	(a7)+,a5-a6
loadprg_stop:
		st	in_fish
		movem.l	d0/a0,-(a7)
		lea	user_command_env(a5),a0
		bsr	xfreep
		movem.l	(a7)+,d0/a0
		bsr	resume_misc_environments
		tst.l	d0
		bmi	exec_failure

		cmp.l	#$10000,d0
		bcs	binary_command_done

		and.l	#$ff,d0
		or.l	#$100,d0
binary_command_done:
		move.b	#2,timer_ok(a6)
simple_command_done:
		move.l	d0,d1
		move.l	user_command_signal,d0
		bne	manage_signals

		move.l	d1,d0
		clr.b	d1
		cmp.l	#$200,d1
		beq	manage_signals

		cmp.l	#$300,d1
		beq	manage_signals

		bsr	set_status
simple_command_done_0:
		tst.b	timer_ok(a6)
		beq	count_command_time_ok

		bsr	getitimer
		move.l	d0,timer_exec_low(a6)
		move.l	d1,timer_exec_high(a6)
count_command_time_ok:
		clr.l	command_name(a5)

		tst.b	recursed(a6)
		bne	not_reset_io

		bsr	reset_io
not_reset_io:
		tst.b	timer_ok(a6)
		beq	simple_command_done_1

		tst.b	time_always(a6)
		bne	report_command_time

		cmp.b	#2,timer_ok(a6)
		blo	simple_command_done_1

		lea	word_time,a0
		bsr	svartou
		beq	simple_command_done_1		* time は定義されていない
		bmi	simple_command_done_1		* $time[1] はオーバーフロー

		move.l	d1,d4				* D4 : $time[1]の値
		move.l	timer_exec_low(a6),d0
		move.l	timer_exec_high(a6),d1
		move.l	timer_load_low(a6),d2
		move.l	timer_load_high(a6),d3
		bsr	count_time
		move.l	#100,d1
		bsr	divul
		cmp.l	d4,d0
		blo	simple_command_done_1
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
simple_command_done_1:
simple_command_return:
		unlk	a6
		rts


shell_not_found:
		moveq	#ENOFILE,d0
		lea	command_pathname(a5),a0
simple_command_perror:
		bsr	reset_delete_io
		bsr	perror
		bra	shell_error

simple_command_too_long_line:
		bsr	reset_delete_io
		bsr	too_long_line
		bra	shell_error

exec_failure:
		lea	msg_exec_failure,a1
		bra	simple_command_errorp

cannot_exec_script:
		move.w	d1,d0
		bsr	fclose
cannot_exec:
		lea	msg_cannot_exec,a1
		bra	simple_command_errorp

badly_placed_paren:
		lea	msg_badly_placed_paren,a0
		bra	print_shell_error

shell_too_long:
		lea	msg_shell_too_long,a0
		bra	print_shell_error

hugearg_error:
		lea	msg_too_long_arg_for_program,a0
		bra	print_shell_error

too_long_indirect_flag:
		lea	msg_too_long_indirect_flag,a0
		bra	print_shell_error

command_not_found:
		lea	msg_no_command,a1
simple_command_errorp:
		bsr	reset_io
		lea	command_pathname(a5),a0
		bsr	pre_perror
		movea.l	a1,a0
		bra	print_shell_error
****************************************************************
remember_misc_environments:
		movem.l	d0/a0,-(a7)
		lea	save_cwd(a5),a0
		bsr	getcwd
		movem.l	(a7)+,d0/a0
		rts
****************************************************************
resume_misc_environments:
		movem.l	d0/a0,-(a7)
		lea	save_cwd(a5),a0
		bsr	chdir
		bpl	resume_cwd_ok

		bsr	perror
resume_cwd_ok:
		bsr	reset_cwd
		movem.l	(a7)+,d0/a0
		rts
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
		bsr	strfor1
check_paren_continue:
		dbra	d0,check_paren_loop
check_paren_break:
		addq.w	#1,d0
		movem.l	(a7)+,d0/a0
not_echo_command:
		rts
****************************************************************
echo_command:
		tst.b	flag_echo(a5)
		beq	not_echo_command

		movem.l	d0/a0,-(a7)
		lea	command_pathname(a5),a0
		bsr	ecputs
		moveq	#' ',d0
		bsr	eputc
		movem.l	(a7)+,d0/a0
		bra	echo_args
****************************************************************
.xdef set_status
.xdef just_set_status

print_shell_error:
		bsr	reset_delete_io
		bsr	enputs
shell_error:
		moveq	#1,d0
		bra	break_shell

clear_status:
		moveq	#0,d0
		bra	just_set_status

set_status:
		tst.l	d0
		beq	just_set_status

		tst.b	exit_on_error(a5)
		bne	exit_shell_d0
just_set_status:
		link	a6,#-12
		movem.l	d0-d1/a0-a1,-(a7)
		lea	-12(a6),a0
		bsr	itoa
		movea.l	a0,a1
		lea	word_status,a0
		moveq	#1,d0
		moveq	#0,d1
		bsr	set_svar
		movem.l	(a7)+,d0-d1/a0-a1
		unlk	a6
		rts
*****************************************************************
* get_status - シェル変数 status の値を数値に変換する
*
* CALL
*      none
*
* RETURN
*      D0.L   $status[1]の値．ただし $status[1]の取得がエラーならば 1
*      CCR    $status[1]の取得がエラーならば NE
*
* NOTE
*      $status[1]の取得がエラーならばエラー・メッセージを表示する
*****************************************************************
get_status:
		movem.l	d1/a0,-(a7)
		lea	word_status,a0
		bsr	svartol
		exg	d0,d1
		cmp.l	#5,d1
		beq	get_status_ok

		lea	msg_bad_status,a0
		bsr	enputs
		moveq	#0,d0
		moveq	#1,d1
get_status_ok:
		movem.l	(a7)+,d1/a0
		rts
*****************************************************************
echo_args:
		movem.l	d0/a1,-(a7)
		lea	ecputs(pc),a1
		bsr	echo
		bsr	eput_newline
		movem.l	(a7)+,d0/a1
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
.xdef report_time

report_time:
		movem.l	d0-d1/d3/a0-a2,-(a7)
		lea	putc(pc),a1
		bsr	puts
		moveq	#' ',d3			* D3.B : pad文字
		lea	str_colon,a2		* A2 : 数値の後に出力する文字列
		cmp.l	#60*60*100,d0
		bhs	report_time_hour

		lea	space3,a0
		bsr	puts
		cmp.l	#60*100,d0
		bhs	report_time_minute

		bsr	puts
		bra	report_time_second

report_time_hour:
		move.l	#60*60*100,d1
		bsr	report_time_printi
report_time_minute:
		move.l	#60*100,d1
		bsr	report_time_printi
report_time_second:
		moveq	#100,d1
		lea	str_dot,a2
		bsr	report_time_printi

		moveq	#1,d1
		lea	str_newline,a2
		bsr	report_time_printi

		movem.l	(a7)+,d0-d1/d3/a0-a2
		rts

report_time_printi:
		bsr	divul
		lea	utoa(pc),a0
		movem.l	d1-d2,-(a7)
		moveq	#2,d1
		moveq	#0,d2
		bsr	printfi
		movem.l	(a7)+,d1-d2
		movea.l	a2,a0
		bsr	puts
		moveq	#'0',d3
		move.l	d1,d0
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
*****************************************************************
* find_command - コマンドを検索する
*
* CALL
*      A0     検索するコマンドのパス名
*             D0.B==0 のときは最大 4文字が (A0) の末尾に
*             付加されるので，その分の余裕があること
*
*      D0.B   0ならば拡張子を補って検索する
*
* RETURN
*      D0.L
*              1: 拡張子無し
*              2: .R
*              3: .Z
*              4: .X
*              5: .BAT
*              6: 上記以外の拡張子
*              0: 実行不可
*             -1: 見当たらない
*
*             これ以外: 組み込みコマンド表のアドレス
*
*      CCR    TST.L D0
*
* NOTE
*      拡張子の大文字と小文字は区別しない．
*      同じ優先順位ならば，後に検索された方が有効となる．
*****************************************************************
filebuf = -(((54)+1)>>1<<1)

find_command:
		link	a6,#filebuf
		movem.l	d1-d5/a0-a2,-(a7)
		move.b	d0,d3
		bsr	builtin_dir_match
		beq	find_disk_command

		move.b	(a0,d0.l),d1
		cmp.b	#'/',d1
		beq	find_bultin_command

		cmp.b	#'\',d1
		bne	find_disk_command
****************
find_bultin_command:
		lea	1(a0,d0.l),a0
		lea	command_table,a1
		bsr	search_builtin
		beq	command_file_not_found

		move.l	a1,d0
		bra	find_command_done
****************
find_disk_command:
		bsr	drvchkp
		bmi	command_file_not_found

		tst.b	d3
		bne	find_command_static

		movea.l	a0,a2
		bsr	strbot
		lea	ext_asta,a1
		bsr	strcpy
		exg	a0,a2
find_command_static:
		move.w	#$37,-(a7)			*  ボリューム・ラベル以外
		move.l	a0,-(a7)
		pea	filebuf(a6)
		DOS	_FILES
		lea	10(a7),a7
		tst.l	d0
		bmi	command_file_not_found

		moveq	#-1,d1
find_more_loop:
		lea	filebuf+30(a6),a0
		moveq	#1,d5
		bsr	suffix
		beq	check_extention_done

		lea	ext_table,a1
check_extention_loop:
		addq.l	#1,d5
		tst.b	(a1)
		beq	check_extention_done

		bsr	stricmp
		beq	check_extention_done

		exg	a0,a1
		bsr	strfor1
		exg	a0,a1
		bra	check_extention_loop

check_extention_done:
		cmp.l	d1,d5
		bhs	find_more_next

		move.l	d5,d1
		move.b	filebuf+21(a6),d4
		tst.b	d3
		bne	command_file_found

		movea.l	a0,a1
		movea.l	a2,a0
		bsr	strcpy
find_more_next:
		pea	filebuf(a6)
		DOS	_NFILES
		addq.l	#4,a7
		tst.l	d0
		bpl	find_more_loop

		cmp.l	#5,d1
		bls	command_file_found
command_file_not_found:
		add.l	#1,hash_misses(a5)
		moveq	#-1,d0
		bra	find_command_done

command_file_found:
		move.l	d1,d0
		*  D0.L : 拡張子コード
		*  D4.B : ファイル・モード
		and.b	#$18,d4
		beq	find_command_done

		moveq	#0,d0
find_command_done:
		movem.l	(a7)+,d1-d5/a0-a2
		unlk	a6
		tst.l	d0
		rts
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
*      D0.L
*              1: 拡張子無し
*              2: .R
*              3: .Z
*              4: .X
*              5: .BAT
*              6: 上記以外の拡張子
*              0: 実行不可
*             -1: 見当たらない
*             上記以外 : 組み込みコマンド表のアドレス
*
*      CCR    TST.L D0
*
* NOTE
*      拡張子の大文字と小文字は区別しない．
*      同じ優先順位ならば，後に検索された方が有効となる．
*****************************************************************
.xdef search_command

exp_command_name = -auto_pathname

search_command:
		link	a6,#exp_command_name
		movem.l	d1-d4/a0-a3,-(a7)
		move.b	d0,d4				*  D4 : 「仮想ディレクトリ無視」フラグ

		bsr	contains_dos_wildcard		*  Human のワイルドカードを含んで
		bne	search_command_not_found	*  いるならば無効

		bsr	split_pathname
		cmp.l	#MAXDIR,d1
		bhi	search_command_not_found

		*** TwentyOne 対応 --ここから--
		tst.l	d2
		beq	search_command_no_ext

		cmp.l	#1,d3
		bls	search_command_no_ext

		cmp.l	#MAXEXT,d3
		bls	search_command_ext_ok
search_command_no_ext:
		add.l	d3,d2
		moveq	#0,d3
search_command_ext_ok:
		*** TwentyOne 対応 --ここまで--
		cmp.l	#MAXFILE,d2
		bhi	search_command_not_found

		cmp.l	#MAXEXT,d3
		bhi	search_command_not_found

		move.b	(a3),d3				*  D3.B : ファイル名に‘.’あり

		tst.l	d0
		beq	search_command_in_pathlist
	*
	*  ドライブ＋ディレクトリ部がある .. このまま検索する
	*
		movea.l	a0,a2				*  A2 : arg
		movea.l	a2,a1
		lea	exp_command_name(a6),a0		*  A0 : buffer
		bsr	strcpy
		move.b	d3,d0
		bsr	find_command
		bmi	search_command_return

		movea.l	a0,a1
		bra	search_command_found

search_command_in_pathlist:
	*
	*  ディレクトリ部がない .. $path に従って検索する
	*
		lea	word_path,a0
		bsr	find_shellvar
		beq	search_command_not_found

		addq.l	#2,a0
		move.w	(a0)+,d1			*  D1.W : $path の要素数
		beq	search_command_not_found

		subq.w	#1,d1
		bsr	strfor1
		move.l	a0,-(a7)			*  pathlist のアドレスを退避

		moveq	#-1,d2
		tst.b	hash_flag(a5)
		beq	search_command_in_pathlist_hash_done

		movea.l	a2,a0
		bsr	hash
		lea	hash_table(a5),a0
		move.b	(a0,d0.l),d2
search_command_in_pathlist_hash_done:
		movea.l	(a7)+,a0			*  A0 : pathlist
		lea	exp_command_name(a6),a1		*  A1 : buffer
search_command_in_pathlist_loop:
		tst.b	(a0)
		beq	search_command_in_pathlist_next

		ror.b	#1,d2
		bcs	search_command_hash_hit

		*  ハッシュがヒットしていない．
		*  それでも，相対パス（仮想ディレクトリを除く）である場合には探す

		bsr	isfullpath
		beq	search_command_in_pathlist_next		*  絶対パスである

		bsr	is_builtin_dir
		beq	search_command_in_pathlist_next		*  仮想ディレクトリである

		bra	search_command_tryone

search_command_hash_hit:
		bsr	is_builtin_dir
		bne	search_command_tryone

		tst.b	d4
		bne	search_command_in_pathlist_next
search_command_tryone:
		cmpi.b	#'.',(a0)
		bne	search_command_tryone_cat

		tst.b	1(a0)
		bne	search_command_tryone_cat

		* カレントディレクトリ
		bsr	strfor1				*  A0:nextpath A1:buffer    A2:arg
		exg	a0,a1				*  A0:buffer   A1:nextpath  A2:arg
		exg	a1,a2				*              A1:arg       A2:nextpath
		bsr	strcpy
		exg	a1,a2				*              A1:nextpath  A2:arg
		bra	search_command_tryone_find

search_command_tryone_cat:
		exg	a0,a1				*  A0:buffer   A1:currpath  A2:arg
		bsr	cat_pathname			*              A1:nextpath
		exg	a0,a1				*  A0:nextpath A1:buffer
		bmi	search_command_in_pathlist_continue

		exg	a0,a1				*  A0:buffer   A1:nextpath
search_command_tryone_find:
		move.b	d3,d0
		bsr	find_command
		exg	a0,a1				*  A0:nextpath A1:buffer
		bmi	search_command_in_pathlist_continue
		beq	search_command_in_pathlist_continue
		bra	search_command_found

search_command_in_pathlist_next:
		bsr	strfor1
search_command_in_pathlist_continue:
		dbra	d1,search_command_in_pathlist_loop
search_command_not_found:
		moveq	#-1,d0
search_command_return:
		movem.l	(a7)+,d1-d4/a0-a3
		unlk	a6
		rts

search_command_found:
		movea.l	a2,a0
		move.l	d0,-(a7)
		bsr	strcpy
		move.l	(a7)+,d0
		bra	search_command_return
*****************************************************************
* expand_a_word - 1つの単語をコマンド置換、ファイル名展開して 1つの単語を得る
*
* CALL
*      A0     ソース単語（長さは MAXWORDLEN 以内であること）
*      A1     展開単語領域
*      D1.L   展開単語領域の大きさ（最後の NUL の分は含まない）
*
* RETURN
*      D0.L    0 : 成功．ファイル名展開は無かった
*              1 : 成功．ファイル名が 1つ以上展開された
*             -1 : 単語数が 2語以上になった
*             -2 : 単語の長さが長過ぎる
*             -4 : 他のさまざまなエラー（メッセージが表示される）
*             -5 : ファイル名展開以前に単語が無くなった
*
*      CCR    TST.L D0
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
		tst.b	flag_noglob(a5)		*  noglob が set されて
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
		tst.b	not_execute(a5)		*  あとの展開は実行時の状況次第で
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
		tst.b	flag_nonomatch(a5)	*  nonomatch が set されて
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
reset_delete_io:
		tst.b	pipe1_delete(a5)
		beq	reset_io_del_1

		move.b	#2,pipe1_delete(a5)
reset_io_del_1:
		tst.b	pipe2_delete(a5)
		beq	reset_io

		move.b	#2,pipe2_delete(a5)
reset_io:
		tst.b	not_execute(a5)
		bne	reset_io_return

		movem.l	d0-d1/a0,-(a7)

		moveq	#0,d0
		move.w	save_stdin(a5),d1
		bsr	unredirect
		move.w	d0,save_stdin(a5)
*
		moveq	#1,d0
		move.w	save_stdout(a5),d1
		bsr	unredirect
		move.w	d0,save_stdout(a5)
*
		moveq	#2,d0
		move.w	save_stderr(a5),d1
		bsr	unredirect
		move.w	d0,save_stderr(a5)
*
		move.w	undup_input(a5),d0
		bsr	fclosex
		move.w	#-1,undup_input(a5)
*
		move.w	undup_output(a5),d0
		bsr	fclosex
		move.w	#-1,undup_output(a5)
*
		cmp.b	#2,pipe1_delete(a5)
		bne	reset_io_5

		lea	pipe1_name(a5),a0
		bsr	remove
		clr.b	pipe1_delete(a5)
reset_io_5:
		cmp.b	#2,pipe2_delete(a5)
		bne	reset_io_6

		lea	pipe2_name(a5),a0
		bsr	remove
		clr.b	pipe2_delete(a5)
reset_io_6:
		lea	argment_pathname,a0
		tst.b	(a0)
		beq	reset_io_done

		bsr	remove
		clr.b	(a0)
reset_io_done:
		movem.l	(a7)+,d0-d1/a0
reset_io_return:
		rts
*****************************************************************
*****************************************************************
*****************************************************************
.data

.xdef command_table

.xdef str_nul
.xdef str_newline
.xdef str_space
.xdef str_current_dir
.xdef dos_allfile
.xdef word_upper_home
.xdef word_upper_term
.xdef word_upper_user
.xdef word_if
.xdef word_switch
.xdef word_alias
.xdef word_argv
.xdef word_cdpath
.xdef word_history
.xdef word_home
.xdef word_path
.xdef word_prompt
.xdef word_prompt2
.xdef word_shell
.xdef word_status
.xdef word_temp
.xdef word_term
.xdef word_unalias
.xdef word_user
.xdef msg_ambiguous
.xdef msg_too_long_pathname
.xdef msg_total_time
.xdef msg_unmatched

fish_copyright:	dc.b	'Copyright(C)1991 by Itagaki Fumihiko',0
fish_author:	dc.b	'板垣 史彦 ( Itagaki Fumihiko )',0

fish_version:	dc.b	'0',0		*  major version
		dc.b	'2',0		*  minor version
		dc.b	'1',0		*  patch level

.even
statement_table:
		dc.b	'case',0,0,0,0,0,4
		dc.l	state_case

		dc.b	'default',0,0,4
		dc.l	state_default

		dc.b	'default:',0,4
		dc.l	state_default

		dc.b	'else',0,0,0,0,0,2
		dc.l	state_else

		dc.b	'end',0,0,0,0,0,0,1+2+4
		dc.l	state_end

		dc.b	'endif',0,0,0,0,2
		dc.l	state_endif

		dc.b	'endsw',0,0,0,0,4
		dc.l	state_endsw

		dc.b	'foreach',0,0,1
		dc.l	state_foreach

word_if:	dc.b	'if',0,0,0,0,0,0,0,2
		dc.l	state_if

word_switch:	dc.b	'switch',0,0,0,4
		dc.l	state_switch

		dc.b	'while',0,0,0,0,1
		dc.l	state_while

		dc.b	0

.even
command_table:
		*  1 : コマンド置換・ファイル名展開は独自に行う
		*  2 : () をチェックしない
		*  4 : パイプの構成要素（最後を除く）ならばサブシェルで実行する
		*      さもなくばパイプのフリップ・フロップを反転する
		*
		dc.b	'@',0,0,0,0,0,0,0,0,1+2
		dc.l	cmd_set_expression

word_alias:	dc.b	'alias',0,0,0,0,1
		dc.l	cmd_alias

		dc.b	'alloc',0,0,0,0,0
		dc.l	cmd_alloc

		dc.b	'bind',0,0,0,0,0,1
		dc.l	cmd_bind

		dc.b	'breaksw',0,0,0
		dc.l	cmd_breaksw

		dc.b	'break',0,0,0,0,0
		dc.l	cmd_break

		dc.b	'cd',0,0,0,0,0,0,0,0
		dc.l	cmd_cd

		dc.b	'chdir',0,0,0,0,0
		dc.l	cmd_cd

		dc.b	'continue',0,0
		dc.l	cmd_continue

		dc.b	'dirs',0,0,0,0,0,0
		dc.l	cmd_dirs

		dc.b	'echo',0,0,0,0,0,0
		dc.l	cmd_echo

		dc.b	'eval',0,0,0,0,0,4
		dc.l	cmd_eval

word_exit:	dc.b	'exit',0,0,0,0,0,1+2
		dc.l	cmd_exit

		dc.b	'glob',0,0,0,0,0,0
		dc.l	cmd_glob

		dc.b	'goto',0,0,0,0,0,0
		dc.l	cmd_goto

		dc.b	'hashstat',0,0
		dc.l	cmd_hashstat

		dc.b	'history',0,0,0
		dc.l	cmd_history

word_logout:	dc.b	'logout',0,0,0,0
		dc.l	cmd_logout

		dc.b	'onintr',0,0,0,0
		dc.l	cmd_onintr

		dc.b	'popd',0,0,0,0,0,0
		dc.l	cmd_popd
.if 0
		dc.b	'printf',0,0,0,1+2
		dc.l	cmd_printf
.endif
		dc.b	'pushd',0,0,0,0,0
		dc.l	cmd_pushd

		dc.b	'pwd',0,0,0,0,0,0,0
		dc.l	cmd_pwd

		dc.b	'rehash',0,0,0,0
		dc.l	cmd_rehash

		dc.b	'repeat',0,0,0,1+2
		dc.l	cmd_repeat

		dc.b	'set',0,0,0,0,0,0,1+2
		dc.l	cmd_set

		dc.b	'setenv',0,0,0,1
		dc.l	cmd_setenv

		dc.b	'shift',0,0,0,0,0
		dc.l	cmd_shift

		dc.b	'source',0,0,0,4
		dc.l	cmd_source

word_time:	dc.b	'time',0,0,0,0,0,1
		dc.l	cmd_time

word_unalias:	dc.b	'unalias',0,0,1
		dc.l	cmd_unalias

		dc.b	'unhash',0,0,0,0
		dc.l	cmd_unhash

		dc.b	'unset',0,0,0,0,1
		dc.l	cmd_unset

		dc.b	'unsetenv',0,1
		dc.l	cmd_unsetenv

		dc.b	'which',0,0,0,0,0
		dc.l	cmd_which

		dc.b	0

ext_table:
		dc.b	'.R',0
		dc.b	'.Z',0
		dc.b	'.X',0
		dc.b	'.BAT',0
		dc.b	0

init_batshell:		dc.b	'/bin/COMMAND.X',0
init_shell:		dc.b	'/bin/fish.x',0
etc_fishrc:		dc.b	'/etc/fishrc',0
dot_fishrc:		dc.b	'%fishrc',0
dot_login:		dc.b	'%'
str_login:		dc.b	'login',0
dot_logout:		dc.b	'%logout',0
word_upper_home:	dc.b	'HOME',0
word_upper_logname:	dc.b	'LOGNAME',0
word_upper_term:	dc.b	'TERM',0
word_upper_user:	dc.b	'USER',0
word_argv:		dc.b	'argv',0
word_cdpath:		dc.b	'cd'	* "cdpath"
word_path:		dc.b	'path',0
word_batshell:		dc.b	'batshell',0
word_force:		dc.b	'force',0
dot_history:		dc.b	'%'	* "%history"
word_history:		dc.b	'history',0
word_home:		dc.b	'home',0
word_hugearg:		dc.b	'hugearg',0
word_indirect:		dc.b	'indirect',0
word_prompt:		dc.b	'prompt',0
word_prompt2:		dc.b	'prompt2',0
word_savehist:		dc.b	'savehist',0
word_shell:		dc.b	'shell',0
word_status:		dc.b	'status',0
word_temp:		dc.b	'temp',0
word_term:		dc.b	'term',0
word_user:		dc.b	'user',0
word_fish_author:	dc.b	'FISH_AUTHOR',0
word_fish_copyright:	dc.b	'FISH_COPYRIGHT',0
word_fish_version:	dc.b	'FISH_VERSION',0
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
str_stdin:		dc.b	'(標準入力)',0
str_newline:		dc.b	CR,LF,0

.even
initial_vars_stdin_mode:
			dc.l	word_prompt
			dc.l	init_prompt
			dc.w	1

			dc.l	word_prompt2
			dc.l	init_prompt2
			dc.w	1
initial_vars_script_mode:
			dc.l	word_fish_author
			dc.l	fish_author
			dc.w	1

			dc.l	word_fish_copyright
			dc.l	fish_copyright
			dc.w	1

			dc.l	word_fish_version
			dc.l	fish_version
			dc.w	3

			dc.l	0

msg_no_home:			dc.b	'環境変数 HOME が定義されていません',0
msg_insufficient_memory:	dc.b	'fishのデータ領域のためのメモリを確保できません',0
msg_dirnofile:			dc.b	' '
msg_nofile:			dc.b	'ファイルがありません',0
msg_nodir:			dc.b	'ディレクトリが見つかりません',0
msg_use_exit_to_leave_fish:	dc.b	CR,LF,'fishから抜けるには "~~/exit" を用いて下さい',0
msg_use_logout_to_logout:	dc.b	CR,LF,'ログアウトするには "~~/logout" を用いて下さい',0
msg_cannot_load_script:		dc.b	'スクリプトをロードできません',0
msg_read_fail:			dc.b	'読み込みに失敗しました',0
msg_unmatched_parens:		dc.b	'()'
msg_unmatched:			dc.b	'がつりあっていません',0
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
msg_fork_failure:		dc.b	'サブシェルをforkできません',0
msg_exec_failure:		dc.b	'execできませんでした',0
msg_too_long_command_name:	dc.b	'コマンド名が長過ぎます',0
msg_missing_command_name:	dc.b	'コマンド名がありません',0
msg_shell_too_long:		dc.b	'スクリプト・シェルのパス名が長過ぎます',0
msg_too_long_arg_for_program:	dc.b	'ユーザ・プログラムへの引数が255バイトを超えています',0
msg_too_long_indirect_flag:	dc.b	'間接引数が長過ぎます',0
msg_total_time:			dc.b	'トータル ',0
msg_exec_time:			dc.b	'実行     ',0
msg_load_time:			dc.b	'ロード   ',0
msg_search_time:		dc.b	'検索  '
space3:				dc.b	'   ',0
msg_endif_not_found:		dc.b	'endif がありません',0
msg_endsw_not_found:		dc.b	'endsw がありません',0
msg_end_not_found:		dc.b	'end がありません',0
msg_cannot_load_unseekable:	dc.b	'シークできないデバイスからはロードできません',0
msg_hashtable_broken:		dc.b	'ハッシュ表が壊れてる！',0
*****************************************************************
*****************************************************************
*****************************************************************
.bss

**  各シェル共通のデータ
**  ルート・シェルが初期設定する

.xdef tmpgetlinebufp
.xdef dummy

.even
pid_count:		ds.l	1
user_command_signal:	ds.l	1
tmpgetlinebufp:		ds.l	1
in_fish:		ds.b	1
dummy:			ds.b	1

**  各シェル共通の一時バッファ
**  （複数のシェルが同時には動かないので共用して構わない）

.xdef save_sourceptr
.xdef congetbuf
.xdef tmpargs
.xdef tmpword1
.xdef tmpword2
.xdef pathname_buf

.even
save_sourceptr:			ds.l	1
congetbuf:			ds.b	2+256
argment_pathname:		ds.b	MAXPATH+1	* ユーザ・コマンドへの引数を書いたファイル名
tmpword1:			ds.b	MAXWORDLEN*2+1	* glob
tmpword2:			ds.b	MAXWORDLEN*2+1	* globsub
tmpargs:			ds.b	MAXWORDLISTSIZE
pathname_buf:			ds.b	MAXPATH+1
*****************************************************************
.even
bsstop:

.offset 0

**  シェルおよびサブシェル毎のデータ

.xdef fork_stackp
.xdef dstack
.xdef ddatap
.xdef shellvar
.xdef alias
.xdef keymacro
.xdef command_name
.xdef hash_flag
.xdef hash_table
.xdef hash_table2			*  ［デバッグ用］
.xdef hash_hits
.xdef hash_misses
.xdef shell_timer_high
.xdef shell_timer_low
.xdef prev_search
.xdef prev_lhs
.xdef prev_rhs
.xdef current_source
.xdef current_argbuf
.xdef in_history_ptr
.xdef loop_top_eventno
.xdef envwork
.xdef line
.xdef tmpline
.xdef current_eventno
.xdef history_top
.xdef history_bot
.xdef argc
.xdef args
.xdef simple_args
.xdef exitflag
.xdef histchar1
.xdef histchar2
.xdef flag_ampm
.xdef flag_autolist
.xdef flag_ciglob
.xdef flag_cifilec
.xdef flag_echo
.xdef flag_forceio
.xdef flag_ignoreeof
.xdef flag_nobeep
.xdef flag_noclobber
.xdef flag_noglob
.xdef flag_nonomatch
.xdef flag_recexact
.xdef flag_usegets
.xdef flag_verbose
.xdef if_status
.xdef if_level
.xdef loop_stack
.xdef loop_status
.xdef loop_level
.xdef forward_loop_level
.xdef switch_level
.xdef switch_status
.xdef switch_string
.xdef keep_loop
.xdef not_execute
.xdef keymap
.xdef keymacromap

mainjmp:		ds.l	1
stackp:			ds.l	1
fork_stackp:		ds.l	1			*  プログラム・スタック・ポインタ
ddatasize:		ds.l	1			*  動的データサイズ
ddatap:			ds.l	1			*  動的データ・ポインタ
envwork:		ds.l	1			*  環境
shellvar:		ds.l	1			*  シェル変数
alias:			ds.l	1			*  別名
keymacro:		ds.l	1			*  キー・マクロ
dstack:			ds.l	1			*  ディレクトリ・スタック
history_top:		ds.l	1			*  履歴チェインの先頭ノード
history_bot:		ds.l	1			*  履歴チェインの後尾ノード
current_eventno:	ds.l	1			*  現在の履歴イベント番号
current_source:		ds.l	1			*  source ワーク・バッファのチェイン
current_argbuf:		ds.l	1			*  eval, repeat の引数のチェイン
in_history_ptr:		ds.l	1
loop_top_eventno:	ds.l	1
hash_hits:		ds.l	1
hash_misses:		ds.l	1
shell_timer_high:	ds.l	1
shell_timer_low:	ds.l	1
command_name:		ds.l	1
user_command_env:	ds.l	1
.even
loop_stack:		ds.b	(LOOPINFOSIZE)*(MAXLOOPLEVEL+1)
.even
argc:			ds.w	1
save_stdin:		ds.w	1
save_stdout:		ds.w	1
save_stderr:		ds.w	1
undup_input:		ds.w	1
undup_output:		ds.w	1
histchar1:		ds.w	1
histchar2:		ds.w	1
if_level:		ds.w	1
switch_level:		ds.w	1
loop_level:		ds.w	1
forward_loop_level:	ds.w	1
pipe_flip_flop:		ds.b	1
pipe1_delete:		ds.b	1
pipe2_delete:		ds.b	1
pipe1_name:		ds.b	MAXPATH+1
pipe2_name:		ds.b	MAXPATH+1
save_cwd:		ds.b	MAXPATH+1
hash_flag:		ds.b	1
hash_table:		ds.b	1024
hash_table2:		ds.b	1024			*  ［デバッグ用］
line:			ds.b	MAXLINELEN+1		* ［shucks! subst_command_2 で使ってる］
tmpline:		ds.b	MAXLINELEN+1		* ［shucks! subst_command で使ってる］
args:			ds.b	MAXWORDLISTSIZE+1	* ［+1は要らなくする］
simple_args:		ds.b	MAXWORDLISTSIZE
command_pathname:	ds.b	MAXPATH+1
prev_search:		ds.b	MAXSEARCHLEN+1
prev_lhs:		ds.b	MAXSEARCHLEN+1
prev_rhs:		ds.b	MAXSUBSTLEN+1
switch_string:		ds.b	MAXWORDLEN+1
flag_ampm:		ds.b	1
flag_autolist:		ds.b	1
flag_ciglob:		ds.b	1
flag_cifilec:		ds.b	1
flag_echo:		ds.b	1
flag_forceio:		ds.b	1
flag_ignoreeof:		ds.b	1
flag_nobeep:		ds.b	1
flag_noclobber:		ds.b	1
flag_noglob:		ds.b	1
flag_nonomatch:		ds.b	1
flag_recexact:		ds.b	1
flag_usegets:		ds.b	1
flag_verbose:		ds.b	1
exitflag:		ds.b	1
loop_status:		ds.b	1
if_status:		ds.b	1
switch_status:		ds.b	1
keep_loop:		ds.b	1
not_execute:		ds.b	1
keymap:			ds.b	128*3
.even
keymacromap:		ds.l	128*3

**  シェル毎のデータ

.xdef pid
.xdef argv0p
.xdef i_am_login_shell
.xdef last_congetbuf
.xdef linecutbuf

pid:			ds.l	1
argv0p:			ds.l	1
arg_command:		ds.l	1
flag_e_size:		ds.l	1
i_am_login_shell:	ds.b	1
input_is_tty:		ds.b	1
interactive_mode:	ds.b	1
exit_on_error:		ds.b	1
flag_t:			ds.b	1
flag_e:			ds.b	1
flags:			ds.b	1
interrupted:		ds.b	1
last_congetbuf:		ds.b	1+256
user_command_parameter:	ds.b	1+MAXLINELEN+1		* ユーザ・コマンドへの引数
linecutbuf:		ds.b	MAXLINELEN+1	** 行カット・バッファ

.even
bsssize:

.text

.end start
