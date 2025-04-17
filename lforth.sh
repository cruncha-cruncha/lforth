#!/bin/bash
# chmod +x ./lforth.sh 
# shake hands with danger

ValStack=() # value stack
LineStack=() # line stack
HeadStack=() # headword stack
HeadDefStack=() # headword definitions stack
KnownStack=() # known word stack
KnownDefStack=() # known word definitions stack
RetStack=() # return stack

I_VAL=-1 # top of ValStack
I_LINE=-1 # top of LineStack
I_HEAD=-1 # top of HeadStack
I_KNOWN=-1 # top of KnownStack
I_RET=-1 # top of RetStack

F_L=0 # flag for literal mode

function buildKnown {
	KnownStack+=("DUP") # ( x -- x x ) duplicate top element of stack
	KnownDefStack+=('ValStack+=("${ValStack[$I_VAL]}") && I_VAL=$(( I_VAL + 1 ))')
	
	KnownStack+=("POP") # ( x -- ) remove top element of stack
	KnownDefStack+=('unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	KnownStack+=("SWAP") # ( x ... y n -- y ... x ) pop, then swap with nth entry
	KnownDefStack+=('
		I_VAL=$(( I_VAL - 1 )) && tmp=${ValStack[$I_VAL]} && tmp_i=$(( I_VAL - ValStack[(( $I_VAL + 1 ))] )) &&
		ValStack[$I_VAL]=${ValStack[$tmp_i]} && ValStack[$tmp_i]=$tmp &&
		unset "ValStack[(( $I_VAL + 1 ))]"')
	
	KnownStack+=("RAND") # ( -- x ) random integer between 0-99 (inclusive)
	KnownDefStack+=('ValStack+=("$(($RANDOM % 100))") && I_VAL=$(( I_VAL + 1 ))')

	KnownStack+=("TIME") # ( -- x ) seconds since Unix epoch
	KnownDefStack+=('ValStack+=("$(date +%s)")')

	KnownStack+=("*")  # ( x y -- m ) multiply
	KnownDefStack+=('ValStack[(( I_VAL - 1 ))]=$(( ValStack[(( I_VAL - 1 ))] * ValStack[$I_VAL] )) && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	KnownStack+=("/") # ( x y -- m ) divide (floor)
	KnownDefStack+=('ValStack[(( I_VAL - 1 ))]=$(( ValStack[(( I_VAL - 1 ))] / ValStack[$I_VAL] )) && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	KnownStack+=("+") # ( x y -- m ) add
	KnownDefStack+=('ValStack[(( I_VAL - 1 ))]=$(( ValStack[(( I_VAL - 1 ))] + ValStack[$I_VAL] )) && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	KnownStack+=("-") # ( x y -- m ) subtract
	KnownDefStack+=('ValStack[(( I_VAL - 1 ))]=$(( ValStack[(( I_VAL - 1 ))] - ValStack[$I_VAL] )) && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	KnownStack+=("MOD") # ( x y -- m ) x modulo y
	KnownDefStack+=('ValStack[(( I_VAL - 1 ))]=$(( ValStack[(( I_VAL - 1 ))] % ValStack[$I_VAL] )) && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	KnownStack+=("<<") # ( x y -- m ) bitwise shift x left by y bits
	KnownDefStack+=('ValStack[(( I_VAL - 1 ))]=$(( ValStack[(( I_VAL - 1 ))] << ValStack[$I_VAL] )) && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	KnownStack+=(">>") # ( x y -- m ) bitwise shift x right by y bits
	KnownDefStack+=('ValStack[(( I_VAL - 1 ))]=$(( ValStack[(( I_VAL - 1 ))] >> ValStack[$I_VAL] )) && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	# false = all bits unset (aka 0)
	# true = all bits set (aka -1)
	# true = anything not false (aka non-zero)

	KnownStack+=("<") # ( x y -- m ) greater than
	KnownDefStack+=('
		I_VAL=$(( I_VAL - 1 )) &&
		if [ ${ValStack[$I_VAL]} -lt ${ValStack[(( I_VAL + 1 ))]} ]; then tmp=-1; else tmp=0; fi &&
		ValStack[$I_VAL]=$tmp && unset "ValStack[(( I_VAL + 1 ))]"')

	KnownStack+=(">") # ( x y -- m ) less than
	KnownDefStack+=('
		I_VAL=$(( I_VAL - 1 )) &&
		if [ ${ValStack[$I_VAL]} -gt ${ValStack[(( I_VAL + 1 ))]} ]; then tmp=-1; else tmp=0; fi &&
		ValStack[$I_VAL]=$tmp && unset "ValStack[(( I_VAL + 1 ))]"')

	KnownStack+=("==") # ( x y -- m ) equal to than
	KnownDefStack+=('
		I_VAL=$(( I_VAL - 1 )) &&
		if [ ${ValStack[$I_VAL]} = ${ValStack[(( I_VAL + 1 ))]} ]; then tmp=-1; else tmp=0; fi &&
		ValStack[$I_VAL]=$tmp && unset "ValStack[(( I_VAL + 1 ))]"')
	
	KnownStack+=("AND") # ( x y -- m ) bitwise and, not logical
	KnownDefStack+=('
		I_VAL=$(( I_VAL - 1 )) &&
		if (( ${ValStack[$I_VAL]} & ${ValStack[(( I_VAL + 1 ))]} )); then tmp=-1; else tmp=0; fi &&
		ValStack[$I_VAL]=$tmp && unset "ValStack[(( I_VAL + 1 ))]"')

	KnownStack+=("OR") # ( x y -- m ) bitwise or, not logical
	KnownDefStack+=('
		I_VAL=$(( I_VAL - 1 )) &&
		if (( ${ValStack[$I_VAL]} | ${ValStack[(( I_VAL + 1 ))]} )); then tmp=-1; else tmp=0; fi &&
		ValStack[$I_VAL]=$tmp && unset "ValStack[(( I_VAL + 1 ))]"')

	KnownStack+=("NOT") # ( x -- x' ) bitwise not, not logical
	KnownDefStack+=('ValStack[$I_VAL]=$(( ~ ${ValStack[$I_VAL]} ))')

	KnownStack+=("LEN") # ( x -- l ) number of characters in string x
	KnownDefStack+=('ValStack[$I_VAL]=${#ValStack[$I_VAL]}')

 	# ( s ss -- n ) How many times does substring ss occur in big string s?
	KnownStack+=("OCCUR")
	KnownDefStack+=('
		tmp_j="${#ValStack[$I_VAL]}" && I_VAL=$(( I_VAL - 1 )) &&
		tmp_i="${#ValStack[$I_VAL]}" &&
		ValStack[$I_VAL]="${ValStack[$I_VAL]//${ValStack[(( $I_VAL + 1 ))]}/}" &&
		unset "ValStack[(( $I_VAL + 1 ))]" &&
		tmp=$(( $tmp_i - ${#ValStack[$I_VAL]} )) &&
		ValStack[$I_VAL]=$(( $tmp / $tmp_j ))')

	# ( s x -- s1 s2 ... ) split string s on string x
	KnownStack+=("SPLIT")
	KnownDefStack+=('
		tmp=${ValStack[$I_VAL]} && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 )) &&
		old_IFS="$IFS" && IFS="$tmp" &&
		huh=$tmp read -ra outArr <<< "${ValStack[$I_VAL]}" && 
		unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 )) &&
		for ((i = 0; i < "${#outArr[@]}"; i++)); do
		ValStack+=("${outArr[$i]}"); I_VAL=$(( I_VAL + 1 )); done &&
		IFS="$old_IFS"')
	
	# ( s1 s2 ... sn x n -- s ) join n strings on stack together, inserting x between each
	KnownStack+=("JOIN")
	KnownDefStack+=('
		tmp_i=${ValStack[$I_VAL]} && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 )) &&
		tmp=${ValStack[$I_VAL]} && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 )) &&
		old_IFS="$IFS" && IFS="$tmp" && tmp=() &&
		for ((i = ( $I_VAL - $tmp_i + 1 ); i <= $I_VAL; i++)); do
    	tmp+=("${ValStack[i]}"); done && 
		for ((i = $I_VAL; i > ( $I_VAL - $tmp_i ); i--)); do
    	unset "ValStack[i]"; done && I_VAL=$(( $I_VAL - $tmp_i + 1 )) &&
		ValStack[$I_VAL]="${tmp[*]}" && IFS="$old_IFS"')

	KnownStack+=("DC") # ( s n -- s' ) delete char at n in string s
	KnownDefStack+=('
		tmp_i=${ValStack[$I_VAL]} && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 )) &&
		ValStack[$I_VAL]="${ValStack[$I_VAL]:0:$tmp_i}${ValStack[$I_VAL]:(( $tmp_i + 1 ))}"')

	KnownStack+=("IC") # ( s x n -- s' ) insert char x into string s at n
	KnownDefStack+=('
		tmp_i=${ValStack[$I_VAL]} && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 )) &&
		tmp=${ValStack[$I_VAL]} && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 )) &&
		ValStack[$I_VAL]="${ValStack[$I_VAL]:0:$tmp_i}$tmp${ValStack[$I_VAL]:$tmp_i}"')

	# ( d h -- ) create a new definition (d) for some headword (h)
	KnownStack+=("!")
	KnownDefStack+=('
		HeadStack+=("${ValStack[$I_VAL]}") && I_HEAD=$(( I_HEAD + 1 )) &&
		unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))
		HeadDefStack+=("${ValStack[$I_VAL]}") &&
		unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')
	
	# ( h -- d ) write the definition (d) of some headword (h) onto val stack
	KnownStack+=("?")
	KnownDefStack+=('
		tmp="${ValStack[$I_VAL]}" && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 )) &&
		for ((i=I_HEAD; i>=0; i--)); do
		if [ "${HeadStack[$i]}" = "$tmp" ]; then
		ValStack+=("${HeadDefStack[$i]}") && I_VAL=$(( I_VAL + 1 ));
		fi; done')
	
	# ( h -- ) forget the first found definition of some headword
	# TODO: this is broken, use something similar to DC instead:
	# tmp_i=${ValStack[$I_VAL]} && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 )) &&
	# ValStack[$I_VAL]="${ValStack[$I_VAL]:0:$tmp_i}${ValStack[$I_VAL]:(( $tmp_i + 1 ))}"')
	KnownStack+=("FORGET")
	KnownDefStack+=('
		tmp="${ValStack[$I_VAL]}" && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 )) &&
		for ((i=I_HEAD; i>=0; i--)); do 
		if [ "${HeadStack[$i]}" = "$tmp" ]; then
		HeadStack=( "${HeadStack[@]:0:$i}" "${HeadStack[@]:(( $i + 1 ))}" ) &&
		HeadDefStack=( "${HeadDefStack[@]:0:$i}" "${HeadDefStack[@]:(( $i + 1 ))}" ) &&
		I_HEAD=$(( I_HEAD - 1 )) && break;
		fi; done')
	
	# ( -- ) print all debug info
	KnownStack+=("DEBUG")
	KnownDefStack+=('debug 31')

 	# ( -- v ) get depth of stack
	KnownStack+=("DV")
	KnownDefStack+=('ValStack+=("$(( I_VAL + 1 ))") && I_VAL=$(( I_VAL + 1 ))')

 	# ( l -- ) interpret top of val stack as a line
	KnownStack+=("LINE")
	KnownDefStack+=('
		LineStack+=("${ValStack[$I_VAL]}") &&
		RetStack+=("tokenize 0 1") && I_RET=$(( I_RET + 1 )) &&
		unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	# ( -- s ) stdin onto the top of the stack
	KnownStack+=("READ")
	KnownDefStack+=('tmp=$(cat; echo x) && tmp=${tmp%x} && ValStack+=("$tmp") && I_VAL=$(( I_VAL + 1 ))')

	# ( s -- ) print to stdout
	KnownStack+=("PRINT")
	KnownDefStack+=('printf '"'"'%s\n'"'"' "${ValStack[$I_VAL]}" && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	# ( s -- ) print to stderr
	KnownStack+=("ERR")
	KnownDefStack+=('printf '"'"'%s\n'"'"' "${ValStack[$I_VAL]}" 1>&2 && unset "ValStack[$I_VAL]" && I_VAL=$(( I_VAL - 1 ))')

	# ( -- ) quit
	KnownStack+=("EXIT")
	KnownDefStack+=('exit')
	
	I_KNOWN=$(( ${#KnownStack[@]} - 1 ))
} && buildKnown

# print contents of all "stacks"
# 1 = indices
# 2 = val stack
# 4 = line stack
# 8 = head stack
# 16 = known stack
# 32 = ret stack
function debug {
	I_VAL=$(( ${#ValStack[@]} - 1 ))
	I_LINE=$(( ${#LineStack[@]} - 1 ))
	I_HEAD=$(( ${#HeadStack[@]} - 1 ))
	I_KNOWN=$(( ${#KnownStack[@]} - 1 ))
	I_RET=$(( ${#RetStack[@]} - 1 ))

	echo "DEBUG"

	if [ $(( $1 & 1 )) -ge 1 ]; then
		echo "indices"
		echo "I_VAL: $I_VAL"
		echo "I_LINE: $I_LINE"
		echo "I_HEAD: $I_HEAD"
		echo "I_KNOWN: $I_KNOWN"
		echo "I_RET: $I_RET"
	fi

	if [ $(( $1 & 1 << 1 )) -ge 1 ]; then
		echo "val stack"
		for ((i=I_VAL; i>=0; i--)); do
		    echo "$i" "${ValStack[$i]}"
		done
	fi

	if [ $(( $1 & 1 << 2 )) -ge 1 ]; then
		echo "line stack"
		for ((i=I_LINE; i>=0; i--)); do
		    echo "$i" "${LineStack[$i]}"
		done
	fi

	if [ $(( $1 & 1 << 3 )) -ge 1 ]; then
		echo "head stack"
		for ((i=I_HEAD; i>=0; i--)); do
		    echo "$i" "${HeadStack[$i]}"
		done
	fi

	if [ $(( $1 & 1 << 4 )) -ge 1 ]; then
		echo "known stack"
		for ((i=I_KNOWN; i>=0; i--)); do
		    echo "$i" "${KnownStack[$i]}"
		done
	fi

	if [ $(( $1 & 1 << 5 )) -ge 1 ]; then
		echo "ret stack"
		for ((i=I_RET; i>=0; i--)); do
		    echo "$i" "${RetStack[$i]}"
		done
	fi
}

# remove line from linestack (because tokenizer has reached the end)
function pop_line {
	I_LINE=$(( ${#LineStack[@]} - 1 ))
	unset "LineStack[$I_LINE]"
	I_LINE=$(( I_LINE - 1 ))
}

function tokenize {
	# update I_LINE
	I_LINE=$(( ${#LineStack[@]} - 1 ))

	# if T_START >= len(line): callback pop line, return
	if [ "$1" -ge ${#LineStack[$I_LINE]} ]; then
		RetStack+=("pop_line")
		return
	fi

	# if T_END <= T_START: callback "tokenize T_START T_START+1", return
	if [ "$2" -le "$1" ]; then
		RetStack+=("tokenize $1 $(( $1 + 1 ))")
		return
	fi

	# if T_END >= len(line): callback pop line, callback "triage_token $1 $2", return
	if [ "$2" -ge ${#LineStack[$I_LINE]} ]; then
		RetStack+=("pop_line")
		RetStack+=("triage_token $1 $2")
		return
	fi
	
	# is T_START whitespace?
	local SW=0
	case ${LineStack[$I_LINE]:$1:1} in
	    [[:space:]])
	        SW=1
	        ;;
	esac

	# is T_END whitespace?
	local EW=0
	case ${LineStack[$I_LINE]:$2:1} in
	    [[:space:]])
	        EW=1
	        ;;
	esac
	
	# if T_START is whitespace and T_END is whitespace: callback "tokenize T_START T_END+1", return
	# if T_START is non-whitespace and T_END is non-whatespace: callback "tokenize T_START T_END+1", return
	if [[ "$SW" -eq "$EW" ]]; then
		RetStack+=("tokenize $1 $(( $2 + 1 ))")
		return
	fi

	# callback "tokenize T_END T_END+1", callback "triage_token T_START T_END", return
	RetStack+=("tokenize $2 $(( $2 + 1 ))")
	RetStack+=("triage_token $1 $2")
	return
}

function triage_token {
	# local word= chars from lineStack[$I_LINE][$1] up to but not including lineStack[$I_LINE][$2]
	local word=${LineStack[$I_LINE]:$1:$(( $2 - $1 ))}

	# if \"\": toggle literal mode, return
	if [ "$word" = "\"\"" ]; then
		if [[ $F_L -eq 0 ]]; then
			I_VAL=$(( I_VAL + 1 ))
			ValStack+=""
			F_L=1
		else
			F_L=0
		fi		
		return
	fi
	 
	# if in literal mode: push word onto stack, return
	if [ "$F_L" -eq 1 ]; then
		ValStack[$I_VAL]+="$word"
		return
	fi
	
	# if first char of word is whitespace: assume all whitespace and do nothing, return
	case ${LineStack[$I_LINE]:$1:1} in
	    [[:space:]])
	        return
	        ;;
	esac
	
	# if word is integer: push onto ValStack, return
	if [[ $word =~ ^-?[0-9]+$ ]]; then
		I_VAL=$(( I_VAL + 1 ))
		ValStack+=("$word")
		return
	fi

	# if word in head dictionary: get index i, push "exec_headword $i" onto RetStack, return
	for ((i=I_HEAD; i>=0; i--)); do
	    if [ "$word" = "${HeadStack[$i]}" ]; then
	    	RetStack+=("exec_headword $i")
	    	return
	    fi
	done

	# if word in known dictionary: get index i, push "exec_known $i" onto RetStack, return
	for ((i=I_KNOWN; i>=0; i--)); do
	    if [ "$word" = "${KnownStack[$i]}" ]; then
	    	RetStack+=("exec_known $i")
	    	return
	    fi
	done

	# warn, push unknown word onto stack
	# echo "unknown word $word in triage_token"
	I_VAL=$(( I_VAL + 1 ))
	ValStack+=("$word")
	return
}

function exec_headword {
	# push HeadDefStack[$1] onto LineStack
	LineStack+=("${HeadDefStack[$1]}")
	# echo "headly ${HeadDefStack[$1]}"
	# (( I_LINE++ ))

	# push "tokenize 0 1" onto RetStack
	RetStack+=("tokenize 0 1")
	# (( I_RET++ ))

	return
}

function exec_known {
	eval "${KnownDefStack[$1]}"
	return
}

function run {
	# while true do
	while true; do
		I_RET=$(( ${#RetStack[@]} - 1 ))

		if [[ $I_RET -le -1 ]]; then
			I_LINE=$(( ${#LineStack[@]} - 1 ))
			if [[ $I_LINE -ge 0 ]]; then
			    RetStack+=("tokenize 0 1")
			    I_RET=0
		  	else
		    	break
		    fi
		fi

		# get top element on RetStack
		local next_eval=${RetStack[$I_RET]}
		
		# pop it
		unset "RetStack[$I_RET]"
		
		# eval it 
		eval "$next_eval"
	done
}

# just some fun stuff
LineStack+=('"" trim "" trim FORGET')
LineStack+=('"" trim "" trim ?')
LineStack+=("12 13 14 15 POP 1 SWAP 15 8 1 >>")
LineStack+=("a,b,c , SPLIT : 3 JOIN PRINT")
LineStack+=("ab DUP PRINT occurs PRINT acbbabcbcbaabbcb DUP 2 SWAP OCCUR PRINT \"\" times in \"\" trim PRINT PRINT")
LineStack+=('"" 0 DC DUP LEN 1 - DC "" trim !')

# print "a message" 5 times, aka LOOP
# LineStack+=('SELF')
# LineStack+=('"" PMESS tI 0 DC DUP I 1 SWAP FORGET 1 - 1 SWAP ! tSELF 0 DC ? NADA I IFELSE "" TRIM SELF !')
# LineStack+=('5 I !')
# LineStack+=('DQ "" a message "" TRIM DQ "" "" 3 JOIN "" TRIM PRINT "" TRIM "" "" 2 JOIN PMESS !')
# LineStack+=('"" " " NADA 2 JOIN "" DQ !')
# LineStack+=('"" " " " " 0 DC "" 6 DC 2 DC 0 DC NADA !')
# LineStack+=('"" 0 == -1 * SWAP POP LINE "" TRIM IFELSE !')
# LineStack+=('"" 0 DC DUP LEN 1 - DC "" 0 DC DUP LEN 1 - DC TRIM !')

# execute a CASE statement
# LineStack+=('CASE')
# LineStack+=('"" X ! 1 - N ! X SWAP C ! CLEAR "" TRIM CASE !')
# LineStack+=('"" POP tCLEAR 0 DC tC 0 DC N 1 - tN 0 DC DUP FORGET ! N IFELSE "" CLEAR !')
# LineStack+=('4 1')
# LineStack+=('"" DD "" TRIM DQQ')
# LineStack+=('"" CC "" TRIM DQQ')
# LineStack+=('"" BB "" TRIM DQQ')
# LineStack+=('"" AA "" TRIM DQQ')
# LineStack+=('"" DQ 1 SWAP DQ SPACE 3 JOIN tTRIM 0 DC tPRINT 0 DC SPACE 3 JOIN "" TRIM DQQ !')
# LineStack+=('"" " " NADA 2 JOIN "" DQ !')
# LineStack+=('"" " " " " "" 6 DC 2 DC SPACE !')
# LineStack+=('"" " " " " 0 DC "" 6 DC 2 DC NADA !')
# LineStack+=('"" 0 == -1 * SWAP POP LINE "" TRIM IFELSE !')
# LineStack+=('"" 0 DC DUP LEN 1 - DC "" 0 DC DUP LEN 1 - DC TRIM !')

run

# debug 63 # all stacks
# debug 7 # val, line, and head stack
debug 47
