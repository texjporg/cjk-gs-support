PROJECT=cjk-gs-integrate
TEXMF = $(shell kpsewhich -var-value=TEXMFHOME)

.PHONY: default install release
default: README.md


README.md: cjk-gs-integrate.pl
	perl cjk-gs-integrate.pl --markdown > README.md

install: README.md
	mkdir -p ${TEXMF}/doc/fonts/$(PROJECT)
	cp *.md ${TEXMF}/doc/fonts/$(PROJECT)/
	mkdir -p ${TEXMF}/scripts/$(PROJECT)
	cp *.pl ${TEXMF}/scripts/$(PROJECT)/
	mkdir -p ${TEXMF}/fonts/misc/$(PROJECT)
	cp database/*.dat ${TEXMF}/fonts/misc/$(PROJECT)/
	cp database/zrlistttc.lua ${TEXMF}/fonts/misc/$(PROJECT)/

release: README.md
	sh tools/release.sh
