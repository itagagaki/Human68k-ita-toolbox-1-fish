#! A:/bin/MAKE.X -f
#  Makefile for FISH product

BACKUP    = A:\bin\COPYALL.X -t
ARCHIVE   = A:\usr\pds\LHA.x a

TOP       = A:\home\fish
DESTDIR   = A:\bin
BACKUPDIR = B:\fish

ARCHIVE_NAME  = FISH010.Lzh

ARCHIVE_FILES = \
	$(TOP)\doc\README \
	$(TOP)\doc\NOTICE \
	$(TOP)\doc\PROBLEMS \
	$(TOP)\doc\FISH010.DOC \
	$(TOP)\doc\LOGIN00.DOC \
	$(TOP)\prg\fish.x \
	$(HOME)\newbin\login.x \
	$(TOP)\doc\Passwd \
	$(TOP)\doc\Pfishrc \
	$(TOP)\doc\Plogin \
	$(TOP)\doc\Plogout \
	$(TOP)\doc\HUPAIR.DOC \
	$(TOP)\lib\DecHUPAIR.s \
	$(TOP)\lib\EncHUPAIR.s

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
	@$(BACKUP) $(TOP)\Makefile $(BACKUPDIR)
	@$(BACKUP) $(TOP)\src\*.* $(BACKUPDIR)\src
	@$(BACKUP) $(TOP)\prg\Makefile $(BACKUPDIR)\prg
	@$(BACKUP) $(TOP)\prg\fish.x $(BACKUPDIR)\prg
	@$(BACKUP) $(TOP)\prg\fishg.x $(BACKUPDIR)\prg
	@$(BACKUP) $(TOP)\lib\Makefile $(BACKUPDIR)\lib\italib
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

backup::
	@$(BACKUP) $(TOP)\$(ARCHIVE_NAME) $(BACKUPDIR)

###
