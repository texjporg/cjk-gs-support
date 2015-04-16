
TESTGB = adobe-GB1_0-2 adobe-GB1_3-5
TESTK  = adobe-Korea1
TESTCNS = adobe-CNS1

TESTALL = $(TESTGB) $(TESTCNS) $(TESTK)

TESTPDF = $(patsubst %, %.pdf, $(TESTALL))

all: $(TESTPDF)
	echo $(TESTPDF)

%.dvi: %.tex
	platex $<

%.ps: %.dvi
	dvips $<

%.pdf: %.ps
	ps2pdf $<

