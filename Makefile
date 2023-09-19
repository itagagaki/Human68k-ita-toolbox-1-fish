#! A:/bin/MAKE.X -f
#  Makefile for Human68k ITA TOOLBOX #1 - FISH

BACKUP    = A:\bin\COPYALL.X -t
ARCHIVE   = A:\usr\pds\LHA.x a
RM        = -\usr\local\bin\rm -f

TOP       = A:\home\fish
DESTDIR   = A:\bin
BACKUPDIR1 = B:\fish
BACKUPDIR2 = C:\fish

ARCHIVE_NAME  = FISH060.Lzh

ARCHIVE_FILES = \
	$(TOP)\doc\MANIFEST \
	$(TOP)\doc\README \
	$(TOP)\doc\NOTICE \
	A:\home\newbin\DIRECTORY \
	$(TOP)\doc\CHANGES \
	$(TOP)\doc\FAQ \
	$(TOP)\doc\FISH.DOC \
	$(TOP)\prg\fish.x \
	$(TOP)\doc\Pfishrc \
	$(TOP)\doc\Plogin \
	$(TOP)\doc\Plogout \
	$(TOP)\doc\Passwd

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
	@$(BACKUP) $(TOP)\Makefile $(BACKUPDIR1)
	@$(BACKUP) $(TOP)\__main\*.* $(BACKUPDIR1)\__main
	@$(BACKUP) $(TOP)\src\*.* $(BACKUPDIR1)\src
	@$(BACKUP) $(TOP)\test\*.* $(BACKUPDIR1)\test
	@$(BACKUP) $(TOP)\prg\Makefile $(BACKUPDIR1)\prg
	@$(BACKUP) $(TOP)\prg\fish.x $(BACKUPDIR1)\prg
	@$(BACKUP) $(TOP)\prg\fishg.x $(BACKUPDIR1)\prg
	@$(BACKUP) $(TOP)\lib\Makefile $(BACKUPDIR1)\lib
	@$(BACKUP) $(TOP)\lib\*.s $(BACKUPDIR1)\lib
	@$(BACKUP) $(TOP)\extlib\*.Lzh $(BACKUPDIR1)\extlib
	@$(BACKUP) $(TOP)\include\*.* $(BACKUPDIR1)\include
	@$(BACKUP) $(TOP)\doc\*.* $(BACKUPDIR1)\doc

backup_misc::
	@$(BACKUP) $(TOP)\FISH_MailList $(BACKUPDIR2)
	@$(BACKUP) $(TOP)\Mail.LZH $(BACKUPDIR2)
	@$(BACKUP) $(TOP)\NewsLetter.Lzh $(BACKUPDIR2)
	@$(BACKUP) $(TOP)\memo\*.* $(BACKUPDIR2)\memo

###

archive:: $(ARCHIVE_NAME)

$(ARCHIVE_NAME): $(ARCHIVE_FILES)
	$(foreach i,$?,$(ARCHIVE) $@ $i$(newline))

clean::
	$(RM) $(ARCHIVE_NAME)

clobber::
	$(RM) $(ARCHIVE_NAME)

#backup::
#	@$(BACKUP) $(TOP)\$(ARCHIVE_NAME) $(BACKUPDIR1)

###
