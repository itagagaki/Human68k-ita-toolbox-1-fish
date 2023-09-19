* substali.s
* Itagaki Fumihiko 11-Feb-91  Create.

.xref strlen
.xref memcmp
.xref strmove
.xref strfor1
.xref strforn
.xref copy_wordlist
.xref skip_paren
.xref is_word_separator
.xref find_var
.xref subst_history
.xref too_long_line

.xref alias

.text

****************************************************************
* count_command_word - �P��̃R�}���h�̒P�ꐔ�𐔂���
*
* CALL
*      A0     �P�����
*      D5.W   �P�ꐔ
*
* RETURN
*      D2.W   �P��̃R�}���h�̒P�ꐔ
****************************************************************
count_command_word:
		movem.l	d0-d1/a0,-(a7)
		moveq	#0,d2				* D2.W �ɐ�����
		move.w	d5,d1				* D1.W : �J�E���^
count_command_word_loop:
		tst.w	d1
		beq	count_command_word_no_separator

		move.b	(a0),d0
		cmp.b	#'(',d0
		bne	count_command_word_1

		move.w	d1,d0
		bsr	skip_paren
		exg	d0,d1
		sub.w	d1,d0
		add.w	d0,d2
		bra	count_command_word_continue

count_command_word_1:
		cmp.b	#';',d0
		beq	semicolon_found

		cmp.b	#'|',d0
		beq	vertical_line_found

		cmp.b	#'&',d0
		beq	ampersand_found
count_command_word_continue:
		bsr	strfor1
		addq.w	#1,d2
		subq.w	#1,d1
		bra	count_command_word_loop

count_command_word_no_separator:
		move.w	d5,d2
		bra	count_command_word_done

semicolon_found:
		tst.b	1(a0)
		bra	test_separator_tail

vertical_line_found:
		tst.b	1(a0)
		beq	count_command_word_done
ampersand_found:
		cmp.b	1(a0),d0
		bne	count_command_word_continue

		tst.b	2(a0)
test_separator_tail:
		bne	count_command_word_continue
count_command_word_done:
		movem.l	(a7)+,d0-d1/a0
		rts
****************************************************************
dup_a_word:
		bsr	strlen
		sub.w	d0,d1
		bcs	dup_a_word_return		*  cs : �������I�[�o�[

		exg	a0,a1
		bsr	strmove
		exg	a0,a1
		subq.l	#1,a1
		subq.w	#1,d5
		beq	dup_a_word_return		*  eq : �����\�[�X�P��͖���

		move.b	#' ',(a1)+
		clr.b	(a1)
		tst.w	d5				*  �K�� ne
dup_a_word_return:
		rts
****************************************************************
* subst_alias - �ʖ��u��������
*
* CALL
*      A0     �\�[�X�i�P����сj�̐擪
*      A1     �W�J�o�b�t�@�̐擪
*      D0.W   �\�[�X�P�ꐔ
*      D1.W   �W�J�o�b�t�@�̗e�ʁi�Ō�� NUL �̕��͊܂܂Ȃ��j
*
* RETURN
*      D0.L   �����Ȃ�� 0�D�����Ȃ��� 1�i�G���[�E���b�Z�[�W�͂����ŕ\�������j
*      D1.W   �W�J�o�b�t�@�̎c��e��
*      D2.B   0 �Ȃ�΁A 1�x���u���͍s���Ȃ�����
*             1 �Ȃ�΁A���Ȃ��Ƃ� 1�x�͒u�����s��ꂽ���A����ȏ�u���͋N����Ȃ�
*             3 �Ȃ�΁A�X�ɒu�������\��������
*      CCR    TST.L D0
****************************************************************
.xdef subst_alias

subst_alias:
		movem.l	d3-d7/a0-a2,-(a7)
		moveq	#0,d7				* D7.B : �u�u�������v�t���O
		move.w	d0,d5				* D5.W : �\�[�X�P�ꐔ
		beq	subst_alias_done
subst_alias_loop:
	*
	*  �P��̃R�}���h�̒P�ꐔ�𐔂���
	*
		bsr	count_command_word
		tst.w	d2
		beq	expand_command_done		* �R�}���h�̒P�ꐔ�� 0 �Ȃ�Βu�����Ȃ�

		cmpi.b	#'(',(a0)
		bne	subst_alias_1

		tst.b	1(a0)
		beq	dup_args			* �T�u�V�F���Ȃ�Βu�����Ȃ�
subst_alias_1:
	*
	*  �R�}���h���� '.' �Ȃ�΁A�R�}���h���ƈ�����P�ɃR�s�[����
	*
		cmpi.b	#'.',(a0)
		bne	recursion_ok

		tst.b	1(a0)
		beq	dup_args
recursion_ok:
	*
	*  �P�� '.' ���������Ⴄ
	*  ����́A�u�����R�}���h�͂���ȏ�ʖ��u�����Ȃ��v�Ƃ�����
	*
		subq.w	#2,d1
		bcs	subst_alias_over

		move.b	#'.',(a1)+
		move.b	#' ',(a1)+
	*
	*  �ʖ����ǂ����𒲂ׂ�
	*
		movea.l	a1,a2				* A2 : �o�b�t�@�E�|�C���^
		movea.l	a0,a1				* A1 : �R�}���h�̐擪
		movea.l	alias(a5),a0
		bsr	find_var			* �ʖ����ǂ����𒲂ׂ�
		movea.l	a1,a0				* A0 : �R�}���h�̐擪
		movea.l	a2,a1				* A1 : �o�b�t�@�E�|�C���^
		beq	dup_args			* �ʖ��ł͂Ȃ� .. �P�ɃR�s�[����
	*
	*  �ʖ���W�J����
	*
		movea.l	a0,a2				* A2 : �R�}���h�̐擪
		movea.l	d0,a0
		addq.l	#2,a0				* ���̃G���g���̃o�C�g���F�Ƃ΂�
		move.w	(a0)+,d4			* D4.W : ���̃G���g���̒P�ꐔ
		bsr	strfor1				* �G���g�������Ƃ΂�
		*
		* �����ŁA
		*      A0     �{����`�P�����
		*      A1     �W�J�o�b�t�@�E�|�C���^
		*      A2     �ʖ��Q�ƒP�����
		*      D1.W   �W�J�o�b�t�@�̗e��
		*      D2.W   �ʖ��Q�Ƃ̒P�ꐔ
		*      D4.W   �{���̒P�ꐔ
		*
		bset	#0,d7				* �u�u�������v�t���O�𗧂Ă�
	*
	*  �ʖ��Ɩ{���������łȂ���΁A�X�ɒu������邱�Ƃ��������߂�
	*  ��ɉ������P�� '.' ���폜����
	*
		tst.w	d4
		beq	allow_more_alias

		exg	a0,a2
		bsr	strlen
		move.l	d0,d3
		exg	a1,a2
		bsr	memcmp
		exg	a1,a2
		exg	a0,a2
		bne	allow_more_alias

		move.b	(a0,d3.l),d0
		beq	not_allow_more_alias

		bsr	is_word_separator
		beq	not_allow_more_alias
allow_more_alias:
		subq.l	#2,a1
		addq.w	#2,d1
		bset	#1,d7				* �u�ċA�̉\������v�t���O�𗧂Ă�
not_allow_more_alias:
		moveq	#0,d6				* D6 : �u!�u�������v�t���O
		bra	expand_alias_start

expand_alias_loop:
		move.w	d6,d3
		bsr	subst_history
		or.b	d0,d6
		moveq	#1,d0
		btst	#2,d6
		bne	subst_alias_return

		btst	#1,d6
		bne	subst_alias_return

		subq.w	#1,d1
		bcs	subst_alias_over

		move.b	#' ',(a1)+
expand_alias_start:
		dbra	d4,expand_alias_loop

		movea.l	a2,a0
		btst	#3,d6
		beq	expand_alias_dup_args

		move.w	d2,d0
		bsr	strforn
		sub.w	d0,d5
		bra	expand_command_done

expand_alias_dup_args:
		bsr	strfor1
		subq.w	#1,d5
		subq.w	#1,d2
		bra	dup_args

dup_args_loop:
		bsr	dup_a_word
		bcs	subst_alias_over
dup_args:
		dbra	d2,dup_args_loop
expand_command_done:
		tst.w	d5
		beq	subst_alias_done
	*
	*  �R�}���h��؂�P����R�s�[����
	*
		bsr	dup_a_word
		bcs	subst_alias_over
		bne	subst_alias_loop
subst_alias_done:
		move.l	d7,d2
		moveq	#0,d0
subst_alias_return:
		clr.b	(a1)
		movem.l	(a7)+,d3-d7/a0-a2
		tst.l	d0
		rts

subst_alias_over:
		bsr	too_long_line
		bra	subst_alias_return
****************************************************************
.xdef remove_dot_word

remove_dot_word:
		movem.l	d2-d3/d5/a0-a1,-(a7)
		move.w	d0,d3				* D3.W : �o�͒P�ꐔ
		move.w	d0,d5				* D5.W : �P�ꐔ�J�E���^
remove_dot_loop:
		bsr	count_command_word
		tst.w	d2
		beq	remove_dot_skip_args

		cmpi.b	#'.',(a0)
		bne	remove_dot_skip_args

		tst.b	1(a0)
		bne	remove_dot_skip_args

		lea	2(a0),a1
		subq.w	#1,d5
		move.w	d5,d0
		bsr	copy_wordlist			* '.' ���폜
		subq.w	#1,d3
		subq.w	#1,d2
remove_dot_skip_args:
		move.w	d2,d0
		bsr	strforn
		sub.w	d2,d5
		beq	remove_dot_done

		bsr	strfor1
		subq.w	#1,d5
		bra	remove_dot_loop

remove_dot_done:
		move.w	d3,d0
		movem.l	(a7)+,d2-d3/d5/a0-a1
		rts

.end
