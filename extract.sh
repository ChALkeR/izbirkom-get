#!/bin/bash

dir=$1
inf=99999999

fields=$2
if [ -z "$fields" ]; then
	echo "Auto-detecting fields count…" > /dev/stderr
	fields_auto=`grep '<td width="5%" style="color:black">' "$dir" -r -c | sed s/'.*:'// | uniq`
	if [ "`echo \"$fields_auto\" | wc -l`" -ne "1" ]; then
		echo "Error: auto-detected fields count is not constant" > /dev/stderr
		exit -1;
	fi
	fields=$fields_auto
	echo "Fields count determined and validated: $fields" > /dev/stderr
fi

height=$(($fields+1))

function parse_file() {
	local file="$dir/$1"
	local name="`cat $file \
		| grep "Наименование Избирательной комиссии" -A 2 \
		| tail -1 \
		| sed -r 's/(\r|<[^>]*>)//g' \
		| sed -r 's/(^\s*|\s*$)//g' \
		`"
	local catg="`cat $file \
		| grep '&gt;' \
		| sed -r 's/(\r|<[^>]*>)//g' \
		| sed -r 's/(^\s*|\s*$)//g' \
		| sed -r 's/&gt;\s*//' \
		| grep '&gt;' \
		| sed -r 's/\s*&gt;.*//g'
		`"
	local data="`cat $file \
		| grep '<td width="90%">' -A $inf \
		| grep '</table><br></div></td>' -B $inf \
		| grep '<nobr>' \
		| sed -r 's/(\r|<[^>]*>)//g' \
		| sed -r 's/(^\s*|\s*$)//g' \
		`"
	local width=`echo "$data" | grep -c 'УИК'`

	local size=`echo "$data" | wc -l`
	local size0=$(($height*$width))
	if [[ $size -ne $size0 ]]
	then
		echo "Error: $size != $size0 in $file" > /dev/stderr
		exit -1
	fi

	for ((i=0; i<$width; i++))
	do
		echo -n "$catg; $name; "
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
	local data="`cat $file \
		| grep '<td style="height:100%;" valign="top" align="left">' -A $inf \
		| grep '<nobr>' \
		| grep '</nobr>' \
		| sed -r 's/(\r|<[^>]*>)//g' \
		| sed -r 's/(^\s*|\s*$)//g' \
		| grep ' ' \
		| head -$fields
		`"
	echo -n "Регион; ИК; УИК; "
	echo "$data" | tr '\n' ';' | replace ';' '; '
	echo "Файл"
}

head_shown=
for i in `ls "$dir"`
do
	if [[ -z $head_shown ]]
	then
		show_head $i
		head_shown=1
	fi
	parse_file $i;
done;
