#!/bin/bash
oIFS=$IFS
maxLineLength=0;
maxElementsInString=0;
notEmpty=1
i=1
declare -A data;
while [ "$notEmpty" != "0" ]; 
	do myData=$(sed -rn "/([\<]tr[/>])|([\<][t][r][ ]+[a-zA-Z0-9\=\"\-\#\.\& ]*[\/]?[\>])/H;//,/[<][\/]tr[>]/G;s/\n(\n[^\n]*){$i}$//p" $1);
	if [ "$(echo $myData|wc -w)" == "0" ]; 
		then notEmpty=0; 
	else
		myData=$(echo $myData|sed -r 's/([\<]tr[/>])|([\<][t][r][ ]+[a-zA-Z0-9\=\"\-\#\.\& ]*[\/]?[\>])/\n    /g;s/[<][\/]tr[>]//g');
		hasOtherTd=1
		j=1
		while [ "$hasOtherTd" != "0" ];
			do myTd=$(echo $myData|sed ':a;N;$!ba;s/\n//g'|sed 's/[<]\/td/\n<\/td/g;s/[<]\/th/\n<\/th/g'|sed -rn "/([\<]t[dh][/>])|([\<][t][dh][ ]+[a-zA-Z0-9\%\=\"\-\#\.\& ]*[\/]?[\>])/H;//,/[<][\/]t[dh][>]/G;s/\n(\n[^\n]*){$j}$//p"|sed 's/<[^>]*>//g')
			if [ "$(echo $myTd|wc -w)" == "0" ];
				then hasOtherTd=0;
			else
				if [ "$(echo $myTd|wc -m)" > 76 ];
					then IFS=$'\n';
					k=1; 
					for myWord in $(echo $myTd|fold -w75 -s); do
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


z=0;while [ "$z" -lt "$maxElementsInString" ]; do  formatVar+="%$((maxLineLength))s  "; z=$((z+1));done
formatVar+=$"\n"
myInfo=$(for key in "${!data[@]}"; do printf "%s\t%s\n" "$key" "${data[$key]}"; done | sort -n -t',' -k1 -k2 -k3);
maxElementsInString=$((maxElementsInString+1))
ids=$(echo "$myInfo"| while read l; do echo $l| cut -d',' -f1 ; done|sort|uniq)
for i in $ids ; 
	do myData[$i]=$(echo "$myInfo" |grep -E "^$i,"|sed -r 's/^[0-9]+\,//g');
	ids2=$(echo "${myData[$i]}"| while read l; do echo $l| cut -d',' -f1 ; done|sort|uniq); 

	for j in $ids2;
		do myString[$j]=$(echo "${myData[$i]}"|grep -E "^$j,"|sed -r 's/^[0-9]+\,//g'); 
		ids3=$(echo "${myString[$j]}"| while read l; do echo $l| cut -d' ' -f1 ; done|sort -n|uniq); 
		dataVar=''; z=1; 

		while [ "$z" -lt "$maxElementsInString" ]; 
			do dataVar+=$(echo "${myString[$j]}"|grep -E "^$z" -m1|sed -r 's/^[0-9]+[ \t]//g;s/$/\n/'); dataVar+=$'\n'; 
			z=$((z+1));
		done
		
		IFS=$'\n'; printf "`echo $formatVar`" `echo "$dataVar"`; 
		echo "printf "`echo $formatVar`" `echo "$dataVar"`";
	done
done
IFS=$oIFS
