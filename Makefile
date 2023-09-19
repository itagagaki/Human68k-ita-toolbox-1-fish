#! A:/bin/MAKE.X -f
#  Makefile for Human68k ITA TOOLBOX #1 - FISH

BACKUP    = A:\bin\COPYALL.X -t
ARCHIVE   = A:\usr\pds\LHA.x a
RM        = -\usr\local\bin\rm -f

TOP       = A:\home\fish
DESTDIR   = A:\bin
BACKUPDIR = B:\fish

ARCHIVE_NAME  = FISH022.Lzh

ARCHIVE_FILES = \
	$(TOP)\doc\README \
	$(TOP)\doc\NOTICE \
	A:\home\newbin\DIRECTORY \
	$(TOP)\doc\CHANGES \
	$(TOP)\doc\FISH022.DOC \
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
	@$(BACKUP) $(TOP)\Mail.LZH $(BACKUPDIR)
	@$(BACKUP) $(TOP)\Makefile $(BACKUPDIR)
	@$(BACKUP) $(TOP)\src\*.* $(BACKUPDIR)\src
	@$(BACKUP) $(TOP)\prg\Makefile $(BACKUPDIR)\prg
	@$(BACKUP) $(TOP)\prg\fish.x $(BACKUPDIR)\prg
	@$(BACKUP) $(TOP)\prg\fishg.x $(BACKUPDIR)\prg
	@$(BACKUP) $(TOP)\lib\Makefile $(BACKUPDIR)\lib
	@$(BACKUP) $(TOP)\lib\*.s $(BACKUPDIR)\lib
	@$(BACKUP) $(TOP)\include\*.* $(BACKUPDIR)\include
	@$(BACKUP) $(TOP)\doc\*.* $(BACKUPDIR)\doc
	@$(BACKUP) $(TOP)\memo\*.* $(BACKUPDIR)\memo

###

archive:: $(ARCHIVE_NAME)

$(ARCHIVE_NAME): $(ARCHIVE_FILES)
	$(foreach i,$?,$(ARCHIVE) $@ $i$(newline))

clean::
	$(RM) $(ARCHIVE_NAME)

clobber::
	$(RM) $(ARCHIVE_NAME)

#backup::
#	@$(BACKUP) $(TOP)\$(ARCHIVE_NAME) $(BACKUPDIR)

###
