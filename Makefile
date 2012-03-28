regionNum	= 78
regionName	= st-petersburg
vrn		= 100100028713299

host		= www.$(regionName).vybory.izbirkom.ru
baseUrl		= $(host)/region/region/
initalUrl	= $(regionName)?action=show&root=1&tvd=100100028713304&vrn=$(vrn)&region=$(regionNum)&global=null&sub_region=null&prver=0&pronetvd=null&vibid=100100028713304&type=233


test:
	echo "http://$(baseUrl)$(initalUrl)"

download: $(host)

$(host): 
	wget -nc -np -r -R "jpg,css,xls,png,gif,js" "http://$(baseUrl)$(initalUrl)"

data-html-all: $(host)
	rm -rf $@;
	cp -r $(baseUrl) $@;
	cd $@; \
		rm -f "$(initalUrl)"; \
		rename "&type=233" ".html" -- *; \
		rename "$(regionName)?action=show&tvd=" "tvd" -- *; \
		rename "&vrn=$(vrn)&region=$(regionNum)&global=null&sub_region=$(regionNum)&prver=0&pronetvd=null&vibid=" ".vibid" -- *; \

# LANG=ru_RU.cp1251 grep `echo 'УИК' | iconv -t cp1251` *.html -L
# and
# grep "TEXT-DECORATION: none" *.html -l
# does the same

data-html-clean: data-html-all
	rm -rf $@;
	cp -r data-html-all $@;
	cd $@; \
		grep "TEXT-DECORATION: none" *.html -l | xargs rm; \

data-raw.csv: data-html-clean
	./extract.sh data-html-clean > $@;
	
data-links.csv: data-raw.csv
	cat data-raw.csv \
		| sed -r ' s/ tvd([0-9]*)\.vibid([0-9]*)\.html/\0; http:\/\/$(host)\/region\/region\/$(regionName)?action=show\&tvd=\1\&vrn=$(vrn)\&region=$(regionNum)\&global=null\&sub_region=$(regionNum)\&prver=0\&pronetvd=null\&vibid=\2\&type=233/' \
		| replace ' Файл' ' Файл; Ссылка' \
		> $@
		
url-list.txt:
	ls $(host)/region/region/ | sed 's/^/http:\/\/$(host)\/region\/region\//' > $@

data-0-html-raw.tar.xz: $(host)
	tar -caf $@ $(host)

data-0-html-raw.tar.lzop: $(host)
	tar -caf $@ $(host)

data-1-html-all.tar.xz: data-html-all
	tar -caf $@ data-html-all

data-2-html-clean.tar.xz: data-html-clean
	tar -caf $@ data-html-clean

data-3-csv-raw.tar.xz: data-raw.csv
	tar -caf $@ data-raw.csv
	
data-4-csv-links.tar.xz: data-links.csv
	tar -caf $@ data-links.csv

info:
	du -hs $(baseUrl);
	ls -R $(baseUrl) | wc -w;

