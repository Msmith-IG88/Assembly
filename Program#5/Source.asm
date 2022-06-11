; Author: Michael Smith
; OSU email address: smitmic5@oregonstate.edu
; Course number/section: CS271
; Assignment Number: Program 4     Due Date: 02/27/22
; Description: This program asks the user to input a number within the range
; 15-200. An array the size of the users valid input will be created and filled
; with randomly generated numbers between 100 and 999. It will then display the 
; unsorted array and the median of the random numbers. Then a merge sort
; algorithm is used to sort and then display the sorted array.

INCLUDE Irvine32.inc

;user input range
MIN     EQU <15>
MAX     EQU <200>

;random number range
LO      EQU <100>
HI      EQU <999>

;array size
MAX_SIZE  EQU <200> 

.data

greeting  BYTE  "Welcome James Taylor",0
intro_1   BYTE  "Sorting Random Integers",0
intro_2   BYTE  "Programmed by Michael Smith",0
intro_3   BYTE  "This program generates random numbers in the range [100 .. 999],",0
intro_4   BYTE  "displays the original list, sorts the list, and calculates the",0
intro_5   BYTE  "median value. Finally, it displays the list sorted in descending order.",0
prompt_1  BYTE  "How many numbers should be generated? [15 .. 200]: ",0
valid_1   BYTE  "Invalid Input",0
spaces    BYTE  "     ",0
title_1   BYTE  "The unsorted random numebers:",0
title_2   BYTE  "The median is ",0
title_3   BYTE  "The sorted list:",0

goodbye_1 BYTE  "Thanks for using my program!",0
EC_1    BYTE  "**EC: Used a recursive Merge Sort algorithm",0
EC_3    BYTE  "**EC: Display a greeting message to one TA",0  

request   DWORD ?   ;user input for amount of random numbers to generate
leftMost  DWORD 0   ;left most value in the array
rightMost DWORD ?   ;right most value in the array

array   DWORD MAX_SIZE  DUP(?)

.code
main PROC

  call  Randomize   ;Irvine procedure initializes Random32 and RandomRange

  ;introduce program
  call  introduction  

  ;get valid user input for request
  push  OFFSET request  
  call  getData     

  ;Generate and fill array with random numbers
  push  OFFSET array  
  push  request     
  call  fillArray   

  ;calculate the right most value index in the array using input
  mov   eax, request
  dec   eax
  mov   rightMost, eax
  mov   eax, rightMost        

  ;display unsorted array
  push  OFFSET title_1
  push  OFFSET array
  push  request
  call  displayList

  ;sort the array in descending order
  push  rightMost
  push  leftMost
  push  OFFSET array
  call  sortList

  push  rightMost
  push  OFFSET array
  call  reverse

  ;calculate and display median
  push  OFFSET title_2
  push  request
  push  OFFSET array
  call  median

  ;display the sorted array
  push  OFFSET title_3
  push  OFFSET array
  push  request
  call  displayList

  ;display goodbye message
  call  CrLf
  mov   edx, OFFSET goodbye_1
  call  WriteString

  exit          
main ENDP


;Procedure to display introduction 
;returns: console output 

introduction  PROC
;Display extra credit greeting message
  mov   edx, OFFSET greeting
  call  WriteString
  call  CrLf

;Display program title
  mov   edx, OFFSET intro_1   
  call  WriteString       
  call  CrLf          

;Display description
  mov   edx, OFFSET intro_2   
  call  WriteString       
  call  CrLf
  mov   edx, OFFSET intro_3   
  call  WriteString       
  call  CrLf
  mov   edx, OFFSET intro_4   
  call  WriteString       
  call  CrLf
  mov   edx, OFFSET intro_5   
  call  WriteString       
  call  CrLf

;Display extra credit
  mov   edx, OFFSET EC_1
  call  WriteString       
  call  CrLf
  mov   edx, OFFSET EC_3  
  call  WriteString       
  call  CrLf

  ret
introduction  ENDP


;Procedure to get valid user input
;receives: address of parameter on stack 
;returns: valid user input value for amount of random numbers to generate 
;registers changed: eax, ebx, edx

getData     Proc
  push  ebp           ;set up stack
  mov   ebp, esp
  mov   ebx, [ebp+8]      ;get address of request into ebx

validationLoop:           ;data post-test validation loop
  ;get integer for number
  mov   edx, OFFSET prompt_1
  call  WriteString
  call  ReadInt
  mov   [ebx], eax        ;store user input address in ebx

  ;compound condition: input greater than lower limit and less than upper limit
  cmp   eax, MIN        ;check condition 1
  jl    falseBlock        ;number < LOWER_LIMIT
  cmp   eax, MAX        ;check condition 2
  jg    falseBlock        ;number > UPPER_LIMIT

;trueBlock
  jmp   endBlock

falseBlock:
  mov   edx, OFFSET valid_1   ;Display invalid message
  call  WriteString
  call  CrLf
  
  ;Get another input and repeat        
  jmp   validationLoop

endBlock:
  pop   ebp           ;restore stack
  ret   4           ;pop 4 additional byes off stak 
getData     ENDP


; Procedure to put number of random numbers into the array.
; receives: array (reference), request (value)
; returns: array filled with random numbers
; preconditions: request is initialized in the range [15, 200]
; registers changed: eax, ecx, edi

fillArray   PROC
  push  ebp           ;set up stack
  mov   ebp, esp
  mov   edi, [ebp+12]     ;start address of array in edi
  mov   ecx, [ebp+8]      ;request loop counter in ecx

again:                ;loop for adding random numbers to array
  ;generate a random number in eax, 100 - 999
  mov   eax, HI         ;999        
  sub   eax, LO         ;999 - 100 = 899
  inc   eax           ;900
  call  RandomRange       ;eax is [0, 900 - 1] => [0, 899]
  add   eax, LO         ;eax is [100, 999]

  ;add random number to array
  mov   [edi], eax
  add   edi, 4
  loop  again

  pop   ebp
  ret   8
fillArray   ENDP


; Procedure sort array in descending order
; receives: rightMost index of array, leftMost index of array, address of array
; returns: sorted array
; preconditions: request is initialized in the range [15, 200]
; and array is filled with request number of random numbers
; registers changed: eax, ebx, ecx, edx, esi, edi

sortList    PROC
  pushad              ;save all registers on stack, pushes an additional 32 bytes on stack
  mov   ebp, esp        ;set up stack

  ;create space for 3 local variable, i, j, pivot. Where i, j are left and right indexes of the array
  sub   esp, 12         ;make space for 3 DWORDS on the stack
  i_local     EQU DWORD PTR [ebp-4]
  j_local     EQU DWORD PTR [ebp-8]
  pivot_local   EQU DWORD PTR [ebp-12]
  
  mov   edx, [ebp+44]     ;rightMost index in edx
  mov   ecx, [ebp+40]     ;leftMost index in ecx
  mov   esi, [ebp+36]     ;address to array in esi

  ;set up i and j with their values
  mov   i_local, ecx      ;i = initial low index of array, leftMost
  mov   j_local, edx      ;j = initial high index of array, rightMost
  
  ;set pivot as the midpoint of the array
  mov   eax, ecx        ;eax = i
  add   eax, edx        ;eax = i = i + j 
  cdq               ;edx = 0
  mov   ebx, 2          ;ebx = 2
  div   ebx           ;eax/ebx => quotient in eax, remainder in edx, no change ebx
                  ;eax now the midpoint of the array
  mov   ecx, [esi+eax*4]    ;move actual midpoint array value into ecx
  mov   pivot_local, ecx    
  
whileLoop1:             ;while(i <= j), leftMost is less than or equal to rightMost
  mov   eax, i_local  
  cmp   eax, j_local
  jg    endWhileLoop1     ;jump if greater (leftOp > rightOp)

whileLoop2:             ;while(array[i] < pivot) => increment i
  mov   ecx, i_local
  mov   eax, [esi+ecx*4]    ;move value of array[i] into eax
  cmp   eax, pivot_local
  jge   endWhileLoop2     ;jump is greater than or equal
  inc   i_local
  jmp   whileLoop2        ;continue while loop
endWhileLoop2:

whileLoop3:             ;while(array[j] > array[pivot]) => decrement j
  mov   ecx, j_local
  mov   eax, [esi+ecx*4]    ;move value of array[j] into eax
  cmp   eax, pivot_local
  jle   endWhileLoop3     ;jump is less than or equal
  dec   j_local
  jmp   whileLoop3        ;continue while loop
endWhileLoop3:

;compare i and j
  mov   ecx, i_local
  mov   ebx, j_local
  cmp   ecx, ebx
  jg    endCompare;         ;eventually jumps to whileLoop1

;swap array[i] and array[j] elements as i is less than or equal to j, then inc i and dec j
  ;set up stack before calling swap procdure
  mov   ecx, i_local 
  mov   ebx, j_local 
  mov   esi, [ebp+36]     ;address of array in esi
  lea   edi, [esi+ecx*4]    ;load address of array[i] in edi
  push  edi           
  lea   edi, [esi+ebx*4]    ;load address of array[j] in edi
  push  edi
  call  swap      
  inc   i_local
  dec   j_local
endCompare:
  jmp   whileLoop1

endWhileLoop1:
  ;quicksort is recursive, here is the recursion component of the algorithm
  ;set up stack before calling quicksort again
  mov   eax, [ebp+40]     ;move leftMost into eax
  cmp   eax, j_local      
  jge   byPass          ;leftMost is greater than or equal to rightMost
  mov   ebx, j_local      
  push  ebx           ;push rightMost j index
  push  eax           ;push leftMost i index
  push  esi           ;push address of array
  call  sortList

byPass:
  mov   eax, [ebp+44]     ;move rightMost ino eax
  cmp   i_local, eax
  jge   endQuicksort      
  mov   ebx, i_local
  push  eax
  push  ebx
  push  esi
  call  sortList

endQuicksort:
  mov   esp, ebp        ;clear local variables from stack
  popad             ;restore general purpose registers
  ret   12
sortList    ENDP


; Procedure to swap elements between two arrays
; receives: address of specific array 1 element, address of specific array 2 element
; array[i] address, array[j] address
; returns: swapped values in arrays
; preconditions: reference to array 1 and array 2 on stack
; registers changed: eax, ebx, esi, edi

swap    PROC
  push  ebp           ;set up stack
  mov   ebp, esp        
  pushad              ;save general purpose registers

  ;set up array registers for swap
  mov   esi, [ebp+8]      ;address of specific source array element 
  mov   edi, [ebp+12]     ;address of specific destination array element

  ;perform swap
  mov   eax, [esi]        ;eax now has source array element value
  mov   ebx, [edi]        ;ebx now has destination array element value
  mov   [esi], ebx        ;destination value, ebx => replaces source value [esi]
  mov   [edi], eax        ;source value, eax => replaces destination value [edi]

  popad             ;restore general purpose registers
  pop   ebp
  ret   8
swap    ENDP


; Procedure to reverse the order of elements in array
; receives: value of the right most index of the array, address of array
; returns: swaps values in the reference array
; preconditions: correct array size index and reference array passed
; registers changed: eax, ebx, ecx, edx, esi, edi

reverse     PROC
  push  ebp
  mov   ebp, esp        ;set up stack

  ;create space for 2 local variable, i, j. Where i and j are the left and right indexes of the array, respectively 
  sub   esp, 8          ;make space for 2 DWORDS on the stack (8 bytes) 
  i_local     EQU DWORD PTR [ebp-4]
  j_local     EQU DWORD PTR [ebp-8]

  mov   esi, [ebp+8]      ;address of array is in esi
  mov   ecx, 0          ;left most array index is in ecx
  mov   ebx, [ebp+12]     ;right most array index is in ebx

  ;set up i and j with their values
  mov   i_local, ecx      ;i = initial low index of array, leftMost
  mov   j_local, ebx      ;j = initial high index of array, rightMost

  ;check if the rightMost index is even,

  mov   ecx, [ebp+12]     ;request (size of array) in ecx

  ;check if right most array index is odd
  mov   eax, ebx        ;rightMost index is in now eax
  cdq
  mov   ebx, 2
  div   ebx           ;eax/ebx => quotient in eax, remainder in edx, no change ebx
  cmp   edx, 1          ;compare the remainder with 1. 1 means the right most array index is odd
  jne   oddReversal       ;right most index is even, there is an odd number of elements in the array

evenReversal:           ;there is an even number of elements in the array 
  ;set up stack before calling swap procdure
  mov   ecx, i_local 
  mov   ebx, j_local 
  lea   edi, [esi+ecx*4]    ;load address of array[i] in edi
  push  edi           
  lea   edi, [esi+ebx*4]    ;load address of array[j] in edi
  push  edi
  call  swap  

  inc   i_local         ;increment i (left index)
  dec   j_local         ;decrement j (left index)
  mov   ecx, i_local 
  mov   ebx, j_local
  
  ;check if the swap has reached the two middle values
  inc   ecx
  cmp   ecx,ebx
  jl    evenReversal

  ;swap the remaining two middle values
  ;set up stack before calling swap procdure
  mov   ecx, i_local 
  mov   ebx, j_local 
  inc   ecx
  dec   ebx
  lea   edi, [esi+ecx*4]    ;load address of array[i] in edi
  push  edi           
  lea   edi, [esi+ebx*4]    ;load address of array[j] in edi
  push  edi
  call  swap

  jmp   endReversal 
  
oddReversal:            
  ;set up stack before calling swap procdure
  mov   ecx, i_local 
  mov   ebx, j_local 
  lea   edi, [esi+ecx*4]    ;load address of array[i] in edi
  push  edi           
  lea   edi, [esi+ebx*4]    ;load address of array[j] in edi
  push  edi
  call  swap
    
  inc   i_local         ;increment i (left index)
  dec   j_local         ;decrement j (left index)
  mov   ecx, i_local 
  mov   ebx, j_local 
  cmp   ecx,ebx         ;check if the swap has reached the absolute middle
  jne   oddReversal   
  
endReversal:
  mov   esp, ebp    ;clear local variables from stack
  pop   ebp
  ret   12
reverse   ENDP


; Procedure to calculate and display the median value, rounded to the nearest integer
; receives: address of an array, size of array
; returns: none 
; preconditions: array is sorted
; registers changed: eax, ebx, ecx, edx, esi

median      PROC
  push  ebp
  mov   ebp, esp        ;set up stack

  ;print the list title
  call  CrLf
  mov   edx, [ebp+16]     ;address of title_3 is in edx
  call  WriteString

  mov   esi, [ebp+8]      ;(starting) address of array in esi
  mov   ecx, [ebp+12]     ;request (size of array) in ecx

  ;check if the number of elements in the array is odd
  mov   eax, ecx
  cdq
  mov   ebx, 2
  div   ebx           ;eax/ebx => quotient in eax, remainder in edx, no change ebx
  cmp   edx, 1          ;compare the remainder with 1. 1 means the number of elements in the array is odd
  je    oddArray        ;median will by the middle number of the array

;else the number of elements is even (~middle of array is in eax)
  mov   ebx, eax        
  dec   ebx           ;the median is now between ebx and eax
  mov   ecx, [esi+eax*4]    ;put the right median value in ecx
  mov   edx, [esi+ebx*4]    ;put the left median value in edx
  add   ecx, edx        ;the sum of the two values is now in ecx

  ;calculate and display median to the nearest integer for an even number of elements
  mov   eax, ecx
  cdq
  mov   ebx, 2
  div   ebx           ;eax/ebx => quotient in eax, remainder in edx, no change ebx
  call  WriteDec
    
  jmp   endMedian

  ;display the median for an odd number off elements
oddArray:             ;middle array index is in eax
  mov   ebx, eax        ;move the middle array index into ebx
  mov   eax, [esi+ebx*4]
  call  WriteDec
        
endMedian:
  call  CrLf
  pop   ebp
  ret   12  
median      ENDP


; Procedure to display array in current state (10 numbers per line)
; receives: address of array, value of request (size,count), and address of the title on system stack
; returns: displays the contents of the array
; preconditions: request is initialized in the range [10, 200]
; and the array is filled with request number of numbers
; registers changed: eax, ebx, ecx, edx, esi

displayList   PROC
  push  ebp
  mov   ebp, esp        ;set up stack frame

  ;print the list title
  mov   edx, [ebp+16]     ;address of title_1 is in edx
  call  WriteString
  call  CrLf

  ;set up other parameters
  mov   esi, [ebp+12]     ;(starting) address of array in esi
  mov   ecx, [ebp+8]      ;address of request (size, count) in ecx
  mov   ebx, 0          ;terms per line counter

more:
  mov   eax, [esi]        ;get current element
  call  WriteDec
  mov   edx, OFFSET spaces    ;puts spaces between terms
  call  WriteString
  add   esi, 4          ;next element

  ;manage terms per line
  inc   ebx
  cmp   ebx, 10
  je    newLine
  jmp   resume

newLine:
  mov   ebx, 0

resume:
  loop  more

endMore:
  pop   ebp
  ret   12            ;title_1, array, request => 4, 4, 4 bytes
displayList   ENDP

END main
