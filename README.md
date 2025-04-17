# LForth
*shake hands with danger*

### Absolute Value
```
DUP 0 < 2 * 1 + *
```

Step-by-step stack, starting with 13:
```
13
13 13
13 13 0
13 0
13 0 2
13 0
13 0 1
13 1
13
```

Step-by-step stack, starting with -13:
```
-13
-13 -13
-13 -13 0
-13 -1
-13 -1 2
-13 -2
-13 -2 1
-13 -1
13
```

## IFELSE
`( a b n -- )`: If n == 0, then execute b. If n != 0, then execute a. First cleans up the stack such that a (or b) executes without \[a, b, or n\] on the stack. In summary:
- if n == 0, swap a and b (aka swap 1), POP, LINE
- if n != 0, swap b and b (aka swap 0), POP, LINE

So we need an f(x) such that f(0) -> 1, and f(not 0) -> 0. This can be defined as f(x) = ((x == 0) * -1). All together:
```
0 == -1 * SWAP POP LINE
```

## Naive CASE
`( c1 c2 c3 c4 x -- )`: Execute xth case. Number of cases must be known before runtime. Assuming c_ and x are already on the stack:
```
SWAP 3 SWAP POP POP POP LINE
```

## LOOP
Print `" a message "` 5 times. Code has to be written backwards.
```
LineStack+=('SELF')
LineStack+=('"" PMESS tI 0 DC DUP I 1 SWAP FORGET 1 - 1 SWAP ! tSELF 0 DC ? NADA I IFELSE "" TRIM SELF !')
LineStack+=('5 I !')
LineStack+=('DQ "" a message "" TRIM DQ "" "" 3 JOIN "" TRIM PRINT "" TRIM "" "" 2 JOIN PMESS !')
LineStack+=('"" " " NADA 2 JOIN "" DQ !')
LineStack+=('"" " " " " 0 DC "" 6 DC 2 DC 0 DC NADA !')
LineStack+=('"" 0 == -1 * SWAP POP LINE "" TRIM IFELSE !')
LineStack+=('"" 0 DC DUP LEN 1 - DC "" 0 DC DUP LEN 1 - DC TRIM !')
```

## Better CASE
`( c1 c2 ... cn n x -- )`: Execute xth case of n possible cases. Assuming nothing:
```
LineStack+=('CASE')
LineStack+=('"" X ! 1 - N ! X SWAP C ! CLEAR "" TRIM CASE !')
LineStack+=('"" POP tCLEAR 0 DC tC 0 DC N 1 - tN 0 DC DUP FORGET ! N IFELSE "" CLEAR !')
LineStack+=('4 1')
LineStack+=('"" DD "" TRIM DQQ')
LineStack+=('"" CC "" TRIM DQQ')
LineStack+=('"" BB "" TRIM DQQ')
LineStack+=('"" AA "" TRIM DQQ')
LineStack+=('"" DQ 1 SWAP DQ SPACE 3 JOIN tTRIM 0 DC tPRINT 0 DC SPACE 3 JOIN "" TRIM DQQ !')
LineStack+=('"" " " NADA 2 JOIN "" DQ !')
LineStack+=('"" " " " " "" 6 DC 2 DC SPACE !')
LineStack+=('"" " " " " 0 DC "" 6 DC 2 DC NADA !')
LineStack+=('"" 0 == -1 * SWAP POP LINE "" TRIM IFELSE !')
LineStack+=('"" 0 DC DUP LEN 1 - DC "" 0 DC DUP LEN 1 - DC TRIM !')
```

