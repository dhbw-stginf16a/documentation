failure:
	if [ ! -d "reveal.js" ]; then \
		wget https://github.com/hakimel/reveal.js/archive/master.tar.gz; \
		tar xzvf master.tar.gz; \
		mv reveal.js-master reveal.js; \
		rm master.tar.gz; \
	fi
	pandoc -t revealjs -s -o failure.html failure.md
