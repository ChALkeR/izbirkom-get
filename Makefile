#################################################
# This sets the election number and type.
#
# Examples
# 2011-12-04: vrn=100100028713299, type=233
# 2012-03-04: vrn=100100031793505, type=227
#
#################################################
vrn	= 100100031793505
type	= 227
#################################################


#################################################
# Sets the number of data fields in the table.
# Empty means auto-detect.
# You probably will not need to specify this.
#
# Examples
# 2011-12-04: fields=25
# 2012-03-04: fields=23
#
#################################################
fields	=
#################################################


#################################################
# We need to specify some region to get all data.
# This doesn't affect the data.
# This probably doesn't need to be changed.
#################################################
regionNum	= 78
regionName	= st-petersburg
#################################################


#################################################
# Adress parameters.
# This doesn't need to be changed.
# Changing this will break things.
#################################################
host		= www.$(regionName).vybory.izbirkom.ru
baseUrl		= $(host)/region/region/
initalUrl	= $(regionName)?action=show&vrn=$(vrn)&type=$(type)
part0		= $(regionName)?action=show&tvd=
part1		= &vrn=$(vrn)&region=$(regionNum)&global=null&sub_region=$(regionNum)&prver=0&pronetvd=null&vibid=
part2		= &type=$(type)
baseUrlHttp	= http://$(baseUrl)
downloadUrl	= $(baseUrlHttp)$(initalUrl)
#################################################

sedify		= | replace '/' '\/' '&' '\&'

all: data-2-html-clean.tar.xz data-3-csv-raw.tar.xz data-4-csv-links.tar.xz data-5-csv-light.tar.xz

test:
	@echo "$(downloadUrl)"

download: $(host)

$(host): 
	wget -nc -np -r -R "jpg,css,xls,png,gif,js" "$(downloadUrl)"

data-html-all: $(host)
	rm -rf $@;
	cp -r $(baseUrl) $@;
	cd $@; \
		rm -f "$(initalUrl)"; \
		rename "$(part2)" ".html" -- *; \
		rename "$(part0)" "tvd" -- *; \
		rename "$(part1)" ".vibid" -- *; \

data-html-all-utf: data-html-all
	rm -rf $@;
	mkdir $@;
	cd data-html-all; \
		find . -type f -exec iconv -f cp1251 -t utf-8 "{}" -o "../$@/{}" \;

data-html-clean: data-html-all-utf
	rm -rf $@;
	cp -r data-html-all-utf $@;
	cd $@; \
		grep '<form name="go_reg"' -rl | xargs -n10 -r rm;

data-raw.csv: data-html-clean
	./extract.sh data-html-clean $(fields) > $@;

data-links.csv: data-raw.csv
	cat data-raw.csv \
		| sed -r "s/ tvd([0-9]*)\.vibid([0-9]*)\.html/\0; "`echo "$(baseUrlHttp)$(part0)" $(sedify)`"\1"` echo "$(part1)" $(sedify)`"\2"` echo "$(part2)" $(sedify)`"/" \
		| replace ' Файл' ' Файл; Ссылка' \
		> $@

data-light.csv: data-raw.csv
	cat data-raw.csv \
		| sed -r "s/; tvd([0-9]*)\.vibid([0-9]*)\.html//" \
		| replace '; Файл' '' \
		> $@

url-list.txt:
	ls $(host)/region/region/ | sed "s/^/"`echo "$(baseUrlHttp)" $(sedify)`"/" > $@

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

data-5-csv-light.tar.xz: data-light.csv
	tar -caf $@ data-light.csv

info:
	du -hs $(baseUrl);
	ls -R $(baseUrl) | wc -w;

