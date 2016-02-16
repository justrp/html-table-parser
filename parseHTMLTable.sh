#!/bin/bash
oIFS=$IFS
if [ -z "$1" ]
then
    echo "usage: $0 <table-file.html> [<maximum length of cell>]"
    echo "Script parses html file to catch a table and print it without htmltags but in nice-formatted view"
    exit 1
fi

maximumStrLength=75; # maximum length of cell in our view. Customer asked 75.

if [ -n "$2" ]
then
    maximumStrLength=$2
fi

maxLineLength=0; #we need to know it to format output (cell width)
maxElementsInString=0; #we need to know it to format output (number of cols)
notEmpty=1 #flag for dummy-reading through file until we have read something we need
i=1 #NB! everything starts from 1 here, not 0
declare -A data; # 3D-array. data[rowN, doubleRowN, colN]. doubleRowN - is something we need since there could be a situation that one cell contains too many text - so wee need to put breakspace - but dont want to crush our table-style-view. So, we will print data[1,1,1], data[1,1,2], data[1,1,3], \n, data[1,2,1], data[1,2,2], data[1,2,3], \n, data[2,1,1] etc...
while [ "$notEmpty" != "0" ]; 
	do myData=$(sed -rn "/([\<]tr[/>])|([\<][t][r][ ]+[a-zA-Z0-9\=\"\-\#\.\& ]*[\/]?[\>])/H;//,/[<][\/]tr[>]/G;s/\n(\n[^\n]*){$i}$//p" $1);
	#first of all we get everything inside <tr> tags. while we have something in, we look into
	if [ "$(echo $myData|wc -w)" == "0" ]; 
		then notEmpty=0; 
	else
		myData=$(echo $myData|sed -r 's/([\<]tr[/>])|([\<][t][r][ ]+[a-zA-Z0-9\=\"\-\#\.\& ]*[\/]?[\>])/\n    /g;s/[<][\/]tr[>]//g');
		#split every <tr></tr> via \n
		hasOtherTd=1 #flag [have cell inside]
		j=1
		while [ "$hasOtherTd" != "0" ];
			do myTd=$(echo $myData|sed ':a;N;$!ba;s/\n//g'|sed 's/[<]\/td/\n<\/td/g;s/[<]\/th/\n<\/th/g'|sed -rn "/([\<]t[dh][/>])|([\<][t][dh][ ]+[a-zA-Z0-9\%\=\"\-\#\.\& ]*[\/]?[\>])/H;//,/[<][\/]t[dh][>]/G;s/\n(\n[^\n]*){$j}$//p"|sed 's/<[^>]*>//g')
			#here we're catching every cell inside of row (<td> inside of <tr>) 
			if [ "$(echo $myTd|wc -w)" == "0" ];
				then hasOtherTd=0;
			else
				#here we're catching very_large_cell_situation:
				if [ "$(echo $myTd|wc -m)" > "$(echo $((maximumStrLength+1)))" ];
					then IFS=$'\n';
					k=1; 
					#if cell is too large, we need to split it to some rows (other cells in that 'virtual row' will be empty (if their parents are not as large as this)
					for myWord in $(echo $myTd|fold -w$(echo $((maximumStrLength))) -s); do
						if [ "$(echo $myWord|wc -m)" -gt "$maxLineLength" ] ; then maxLineLength=$(echo $myWord|wc -m);fi;
						if [ $j -gt "$maxElementsInString" ]; then maxElementsInString=$j; fi
						data["$i,$k,$j"]=$(echo $myWord);
						k=$((k+1));
					done;
				else
					if [ "$(echo $myTd|wc -m)" -gt "$maxLineLength" ] ; then maxLineLength=$(echo $myTd|wc -m);fi;
					data["$i,1,$j"]=$(echo $myTd);
				fi
			fi;
			j=$((j+1));

		done;


	fi
	i=$((i+1)); 
done

# ok, now we have three-dimensional array data[rowN,extraRowN,colN] with all data we need. let's print it!
# but since bash doesnt have multi-dimensional arrays, we should sort our data and work like that:

# first of all we create $formatVar with string we will use in printf <FORMAT>
z=0;while [ "$z" -lt "$maxElementsInString" ]; do  formatVar+="%$((maxLineLength))s  "; z=$((z+1));done
formatVar+=$"\n"

#here we sort our data to have a nice view
myInfo=$(for key in "${!data[@]}"; do printf "%s\t%s\n" "$key" "${data[$key]}"; done | sort -n -t',' -k1 -k2 -k3);
maxElementsInString=$((maxElementsInString+1)); # since we start from 1, not from 0

#getting numbers of rows
ids=$(echo "$myInfo"| while read l; do echo $l| cut -d',' -f1 ; done|sort|uniq)
for i in $ids ; 
	do myData[$i]=$(echo "$myInfo" |grep -E "^$i,"|sed -r 's/^[0-9]+\,//g');
	#getting numbers of extraRows (look at comments at the beginning of this file)
	ids2=$(echo "${myData[$i]}"| while read l; do echo $l| cut -d',' -f1 ; done|sort|uniq); 

	for j in $ids2;
		do myString[$j]=$(echo "${myData[$i]}"|grep -E "^$j,"|sed -r 's/^[0-9]+\,//g'); 

		#and now we can get numbers of cols in row:
		ids3=$(echo "${myString[$j]}"| while read l; do echo $l| cut -d' ' -f1 ; done|sort -n|uniq); 
		dataVar=''; z=1; 

		#here we're pushing every cell's data to our dataVar separated by \n
		while [ "$z" -lt "$maxElementsInString" ]; 
			do dataVar+=$(echo "${myString[$j]}"|grep -E "^$z" -m1|sed -r 's/^[0-9]+[ \t]//g;s/$/\n/'); dataVar+=$'\n'; 
			z=$((z+1));
		done
	
		#here is our well-formatted print	
		IFS=$'\n'; printf "`echo $formatVar`" `echo "$dataVar"`; 
	done
done
IFS=$oIFS
#sorry for your eyepain.
