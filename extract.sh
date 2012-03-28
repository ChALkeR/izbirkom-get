#!/bin/bash

dir=$1
inf=99999999
fields=25
search="`echo 'Наименование Избирательной комиссии' | iconv -t cp1251`"
height=$(($fields+1))

function parse_file() {
	local file="$dir/$1"
	local name="`LANG=ru_RU.cp1251 grep "$search" $file -A 2 \
		| tail -1 \
		| sed -r 's/(\r|<[^>]*>)//g' \
		| sed -r 's/(^\s*|\s*$)//g' \
		| iconv -f cp1251 -t utf-8`"
	local data=`cat "$file" \
		| grep '<td width="90%">' -A $inf \
		| grep '</table><br></div></td>' -B $inf \
		| grep '<nobr>' \
		| sed -r 's/(\r|<[^>]*>)//g' \
		| sed -r 's/(^\s*|\s*$)//g' \
		| iconv -f cp1251 -t utf-8`
	local width=`echo "$data" | grep -c 'УИК'`

	local size=`echo "$data" | wc -l`
	local size0=$(($height*$width))
	if [[ $size -ne $size0 ]]
	then
		echo "Error" > /dev/stderr
		exit -1
	fi

	for ((i=0; i<$width; i++))
	do
		echo -n "$name; "
		local rowNums=''
		for ((j=0; j<=$height; j++))
		do
			local curr=$(($i+$j*$width+1))
			rowNums="$rowNums""$curr"'p;'
		done
		echo "$data" | sed -n $rowNums | tr '\n' ';' | replace ';' '; '
		echo "$1"
	done
}

function show_head {
	local file="$dir/$1"
	local data=`cat "$file" \
		| grep '<td style="height:100%;" valign="top" align="left">' -A $inf \
		| grep '<nobr>' \
		| grep '</nobr>' \
		| sed -r 's/(\r|<[^>]*>)//g' \
		| sed -r 's/(^\s*|\s*$)//g' \
		| grep ' ' \
		| iconv -f cp1251 -t utf-8 \
		| head -$fields`
	echo -n "ИК; УИК; "
	echo "$data" | tr '\n' ';' | replace ';' '; '
	echo "Файл"
}

head_shown=
for i in `ls $1`
do
	if [[ -z $head_shown ]]
	then
		show_head $i
		head_shown=1
	fi
	parse_file $i;
done;
