%.r : %.x
	-cv /r $<

%.x : %.o
	lk /t$(temp) /x $<

%.o : %.s
	as /t$(temp) $<

PROGRAM = cbreak.r cmddate.r df.r screen.r cmdtime.r cverify.r humanver.r \
          lock.r mf.r pause.r vol.r

.PHONY: program clean moreclean deletegarbage

program: $(PROGRAM)

$(PROGRAM) : doscall.h chrcode.h
vol.r : filemode.h

backup:
	copyall -t *.* b:\newbin

clean:
	@-rm $(PROGRAM)

moreclean: deletegarbage clean

deletegarbage:
	@-rm *.bak *.$$* *.o *.x
