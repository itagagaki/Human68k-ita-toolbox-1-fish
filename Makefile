#! A:/bin/MAKE.X -f
#  Makefile for Human68k ITA TOOLBOX #1 - FISH

BACKUP    = A:\bin\COPYALL -d -t
BACKUP_R  = A:\bin\COPYALL -t
ARCHIVE   = A:\usr\pds\LHA a
RM        = -A:\usr\local\bin\rm -f

TOP       = A:\home\fish
DESTDIR   = A:\bin
BACKUPDIR = B:\fish

ARCHIVE_NAME  = FISH080.Lzh

ARCHIVE_FILES = \
	doc\MANIFEST \
	doc\README \
	doc\NOTICE \
	A:\home\toolbox\DIRECTORY \
	doc\CHANGES \
	doc\FAQ \
	doc\FISH.DOC \
	prg\fish.x \
	doc\Pfishrc \
	doc\Plogin \
	doc\Plogout \
	doc\Passwd

CONTRIB_FILES = \
	contrib\manscrpt.Lzh

define newline

endef

###

.PHONY : all install clean clobber backup archive

###

all::
	cd $(TOP)\lib || $(MAKE) all
	cd $(TOP)\prg || $(MAKE) all

install::
	cd $(TOP)\lib || $(MAKE) install
	cd $(TOP)\prg || $(MAKE) install

clean::
	cd $(TOP)\lib || $(MAKE) clean
	cd $(TOP)\prg || $(MAKE) clean

clobber::
	cd $(TOP)\lib || $(MAKE) clobber
	cd $(TOP)\prg || $(MAKE) clobber

backup::
	@$(BACKUP) Makefile $(BACKUPDIR)
	@$(BACKUP) src\*.* $(BACKUPDIR)\src
	@$(BACKUP) include\*.* $(BACKUPDIR)\include
	@$(BACKUP) prg\Makefile $(BACKUPDIR)\prg
	@$(BACKUP) prg\fish.x $(BACKUPDIR)\prg
	@$(BACKUP) prg\fishg.x $(BACKUPDIR)\prg
	@$(BACKUP) lib\Makefile $(BACKUPDIR)\lib
	@$(BACKUP) lib\*.s $(BACKUPDIR)\lib
	@$(BACKUP_R) extlib\*.* $(BACKUPDIR)\extlib

backup_doc::
	@$(BACKUP) doc\*.* $(BACKUPDIR)\doc

backup_misc::
	@$(BACKUP) FISH_MailList $(BACKUPDIR)\misc
	@$(BACKUP) Mail.LZH $(BACKUPDIR)\misc
	@$(BACKUP) NewsLetter.Lzh $(BACKUPDIR)\misc

###

archive:: $(ARCHIVE_NAME)

$(ARCHIVE_NAME):: $(ARCHIVE_FILES)
	$(ARCHIVE) $@ $?

$(ARCHIVE_NAME):: $(CONTRIB_FILES)
	$(ARCHIVE) -x $@ $?

clean::
	$(RM) $(ARCHIVE_NAME)

clobber::
	$(RM) $(ARCHIVE_NAME)

#backup::
#	@$(BACKUP) $(ARCHIVE_NAME) $(BACKUPDIR)

###
