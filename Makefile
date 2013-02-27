commit:
	pod2markdown bin/vokab > README.md
	sed -i -e "/^#/s/\([A-Z]\)\([A-Z]*\)/\1\L\2/g" README.md
	git add README.md
	git commit

test:
	perl test.pl
