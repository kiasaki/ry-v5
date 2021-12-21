all: ry

deps:
	chicken-install utf8
	chicken-install format
	chicken-install termbox
	chicken-install alist-lib
	chicken-install linenoise

ry:
	chicken-install

clean:
	rm ry

run:
	chicken-install && DEBUG=1 ry ry.scm
