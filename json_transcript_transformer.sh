#!/bin/bash
#Created June 2018 by Kevin Carter for WGBH Educational Foundation, Boston, MA, USA
#
#
#
#
# uses jq and BASH standard utilities basename, cat, cut, dirname, echo, grep, head, printf, pwd, sed, tr 
#
# input JSON file is reformatted to standard out
# get jq:  'https://github.com/stedolan/jq'
#
# NOTE: ASSUMPTIONS ABOUT INPUT FILE
#
# 0. it is valid JSON data
# 1. its parent directory has a meaningful name
# 2. the only meaningful part of its name is prior to the first '.'
#

function usage(){
	if [ ! -z "$(printf %s $1)" ]
	then
		echo "ERROR:"
		echo "	$1"
	fi
	echo "#"
	echo "	Usage: "
	echo "	$(basename $0) '/path/to/some_word_level.json' " ;
	echo "#"
	echo "	Result = standard output, phrase-level JSON suitable for FixIt game ingest"
	echo "#"
	echo
	echo
}

function reformat_X.XX() {
	echo $1 | sed -e 's#$#\.0\.0&#1' | tr '.' '\n' | head -3 | tr '\n' ' ' | sed -e 's# #\.#1;s# ##g;s#\...#& #1;s# .*$##g'
}

missingUtilString='' ;
for u in jq basename cat cut dirname echo grep head printf pwd sed tr
do
	if [ -z "$(which $u)" ]
	then
		missingUtilString="$missingUtilString"\ "$u" ;
	fi
done
if [ ! -z "$missingUtilString" ]
then
	usage 'missing executable(s) from $PATH:  '"$missingUtilString"
	exit 1
fi

if [ "$#" != 1 -o ! -f "$1" -o ! -r "$1" ]
then
	usage "A single, readable input file is required" ;
	exit 1
fi

kaldiFile="$1" ;
kaldiFileName=$(basename "$kaldiFile")

fixitData='{
"name": "'$(echo $(basename $(cd $(dirname "$kaldiFile");pwd -P))/"$kaldiFileName" | tr -s '/' | tr -d \")'",
"asset_name": "'$(echo "$kaldiFileName" | sed -e 's#\..*$##g' | tr -d \")'",
"phrases": []
}' ;
# { "name": "jq_work/cpb-aacip-507-028pc2tp1n.mp4.json", "asset_name": "cpb-aacip-507-028pc2tp1n", "phrases": [] }


start_time=0;
end_time=0;
duration=0;
firstPhraseNum=0 ;

phraseNum=$firstPhraseNum;
lastPhraseNum=$(jq ".words | length - $firstPhraseNum" "$kaldiFile") ;
newPhrasesList='' ;
phraseText='' ;
phraseRange='' ;
wordListArray=$(jq '[.words[].word]' "$kaldiFile") ;
# wordListString=$(jq '.words[].word' "$kaldiFile" | tr -s '\"\n\r' ' ' | cut -c2-) ;

for time in $(jq '.words[].time' "$kaldiFile" );
do 
	if [ "$phraseNum" == "$firstPhraseNum" ];
	then 
		start_time=$time;
		phraseRange="$phraseNum";
	fi;
# 	echo "start_time is $start_time" ;
	
	duration=$(echo $time | jq ". - $start_time " );
	
	if [ "$phraseNum" == "$lastPhraseNum" -o "$phraseNum" == "$firstPhraseNum" ]
	then
		end_time=$(echo $(jq ".words[$phraseNum].duration" "$kaldiFile" ) | tr -d \" | jq "$time + .") ;
	else
		end_time=$(echo $start_time | jq ". + $duration") ;
	fi
	
# 	echo "time is $time and duration is $duration" ;
	
	if [ "$(echo $duration | jq '. < 5')" != "true" -o "$phraseNum" == "$lastPhraseNum" ]
	then
# 		echo "end_time is $end_time" ;
		duration=0;
		phraseText=$(echo $wordListArray | jq "\" \" + .[$phraseRange]" | tr -d '\"\n\r' | cut -c2-) ; # cut the leading space
#		phraseText=$(echo $wordListString | cut -d ' ' -f $phraseRange) ;
# 		echo "phraseText is $phraseText" ;
# 	 	echo "phraseRange is $phraseRange" ;
#		newPhrasesArray=$(echo $fixitData | jq ".phrases + [{\"start_time\": \"$(reformat_X.XX $start_time)\",\"end_time\": \"$(reformat_X.XX $end_time)\",\"text\": \"$phraseText\" }]") ;
		newPhrasesList="$newPhrasesList"",{\"start_time\": \"$(reformat_X.XX $start_time)\",\"end_time\": \"$(reformat_X.XX $end_time)\",\"text\": \"$phraseText\" }" ;
#		fixitData=$(echo $fixitData | jq ".phrases = $newPhrasesArray") ;
		
		start_time=$end_time ;
		phraseRange="$phraseNum";
	else
		if [ "$phraseRange" != "$phraseNum" ]
		then
			phraseRange="$phraseRange"','"$phraseNum" ;
		fi
	fi
	phraseNum=$[1+$phraseNum] ;
done
fixitData=$(echo $fixitData | jq ".phrases = [$(echo $newPhrasesList | cut -c2-)]") ; # cut the leading comma 
echo "$fixitData"
