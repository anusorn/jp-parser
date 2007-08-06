#Makefile for jp_parser

manpath=$(subst :, ,${MANPATH})

ifndef mandir
ifneq ($(filter /usr/local/share/man,${manpath}),)
mandir=/usr/local/share/man
endif
endif

ifndef mandir
ifneq ($(filter /usr/share/man,${manpath}),)
mandir=/usr/share/man
endif
endif


binpath=$(subst :, ,${PATH})

ifndef bin
ifneq ($(filter /usr/bin,${binpath}),)
bin=/usr/bin
endif
endif

ifndef bin
ifneq ($(filter /usr/local/bin,${binpath}),)
bin=/usr/local/bin
endif
endif

ifndef bin
ifneq ($(filter /bin,${binpath}),)
bin=/bin
endif
endif

mandir1=${mandir}/man1/
mandir3=${mandir}/man3/
mandir5=${mandir}/man5/

currentdir=$(shell pwd)

archivfiles = $(wildcard *.pm) jp_parser jp_parser.conf makefile LICENSE artistic.txt gpl-2.0.txt README
archiv = jp_parser.tar.gz
tar = /usr/bin/tar -z


help: exec
	@echo "Aufruf:"
	@echo "make install: Installiert Verknüpfung nach /usr/bin/jp_parser(oder ein anderes bin-Verzeichnis im $PATH) und installier die man-Pages"
	@echo "make documentation: Erzeugt die man-Pages im Verzeichnis ./doc/"
	@echo "make clean: Entfernt die erzeugten Dateien"



mandirs:
	@test -n ${mandir} || echo "Kann man-Verzeichnis(z.B. /usr/share/man) nicht finden. Manuelle Eingabe über 'make mandir=/path/to/manpages' [target]."
	@test -n ${mandir}
	@test -w ${mandir} || "Kann nicht in ${mandir} schreiben. Root-Rechte?"
	@test -w ${mandir}
	@test -d ${mandir1} || mkdir ${mandir1}
	@test -d ${mandir3} || mkdir ${mandir3}
	@test -d ${mandir5} || mkdir ${mandir5}

install: doc mandirs exec
	@test -n ${bin} || echo "Kann bin-Verzeichnis(z.B. /usr/bin) nicht finden. Manuelle Eingabe über 'make bin=/path/to/bin' [target]."
	@test -n ${bin}
	@test -w ${bin} || echo "Kann Verknüpfung ${bin}/jp_parser nicht erzeugen. Keine Schreibrechte."
	@test -w ${bin}
	@test -L ${bin}/jp_parser || echo "ln -s ${currentdir}/jp_parser ${bin}/jp_parser"
	@test -L ${bin}/jp_parser || ln -s ${currentdir}/jp_parser ${bin}/jp_parser
	grep -sc 'use lib "${currentdir}";' ${currentdir}/jp_parser || sed -in '/use lib "$$FindBin::Bin";/ a\use lib "${currentdir}";' ${currentdir}/jp_parser
	cp ./doc/jp_parser.1 ${mandir1}/jp_parser.1
	cp ./doc/jp_parser.conf.5 ${mandir5}/jp_parser.conf.5
	cp ./doc/jp_*.3 ${mandir3}

exec:
@test -x ./jp_parser || chmod a+x ./jp_parser

tar:
	${tar}cf ${archiv} ${archivfiles}

doc: documentation

documentation: dir exec
	@test -w doc || echo "Kann nicht in Verzeichnis ./doc/ schreiben."
	@test -w doc
	pod2man --section 1 jp_parser > ./doc/jp_parser.1
	pod2man --section 5 jp_parser.conf > ./doc/jp_parser.conf.5
	pod2man --section 3 jp_commands.pm > ./doc/jp_commands.pm.3
	pod2man --section 3 jp_interface.pm > ./doc/jp_interface.pm.3
	pod2man --section 3 jp_vrouter.pm > ./doc/jp_vrouter.pm.3
	pod2man --section 3 jp_vsys.pm > ./doc/jp_vsys.pm.3
	pod2man --section 3 jp_zone.pm > ./doc/jp_zone.pm.3
	
dir:
	@test -d doc || test -w ./ || echo "Kann nicht in Verzeichnis ./ schreiben."
	@test -d doc || test -w ./
	@test -d doc || mkdir doc
   
	
clean:
	rm -f ./doc/jp_parser.1 
	rm -f ./doc/jp_parser.conf.5
	rm -f ./doc/jp_commands.pm.3
	rm -f ./doc/jp_interface.pm.3
	rm -f ./doc/jp_vrouter.pm.3
	rm -f ./doc/jp_vsys.pm.3
	rm -f ./doc/jp_zone.pm.3
	-rmdir doc
	rm -f ${bin}/jp_parser
	rm -f ${mandir1}/jp_parser.1 
	rm -f ${mandir5}/jp_parser.conf.5
	rm -f ${mandir3}/jp_commands.pm.3
	rm -f ${mandir3}/jp_interface.pm.3
	rm -f ${mandir3}/jp_vrouter.pm.3
	rm -f ${mandir3}/jp_vsys.pm.3
	rm -f ${mandir3}/jp_zone.pm.3
	-rmdir ${mandir1}
	-rmdir ${mandir3}
	-rmdir ${mandir5}
	
.PHONY: clean
