INCLUDE = ../include
EXTLIBS = ../lib/ita.l

%.o : %.s
	has -i $(INCLUDE) $<

argtest.x : argtest.o
	hlk argtest.o $(EXTLIBS)
