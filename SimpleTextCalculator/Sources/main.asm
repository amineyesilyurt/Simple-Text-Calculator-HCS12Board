;*****************************************************************
;* This stationery serves as the framework for a                 *
;* user application (single file, absolute assembly application) *
;* For a more comprehensive program that                         *
;* demonstrates the more advanced functionality of this          *
;* processor, please see the demonstration applications          *
;* located in the examples subdirectory of the                   *
;* Freescale CodeWarrior for the HC12 Program directory          *
;*****************************************************************

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data
STACK_PTR   EQU  $1000  ;keeps sp when calling subroitines because they use stack 
COUNTER_1   EQU  $1008  ;it can be maximum 5 because of maximum number has 5 digits(65535) 
KEEP_X      EQU  $1020  ;
COUNTER     EQU  $1030  ;for integer trace

; variable/data section

            ORG $1200
 ; Insert here your data definition.
OPERATION     FCC "65530.96 + 65530.86="
TEMP_SUM_INT1 DC.W 1
TEMP_SUM_DEC2 DC.B 1
TEMP_SUM      DC.W 1
TEMP_SUM_DEC  DC.B 1

              ORG $1400
              
SUM_INT1      DC.W 1 
SUM_DEC1      DC.B 1
SUM_INT2      DC.W 1
SUM_DEC2      DC.B 1
OPERATOR      DC.B 1
              


; code section
            ORG   ROMStart


Entry:
_Startup:
                  LDS   #RAMEnd+1       ; initialize the stack pointer

                  CLI                     ; enable interrupts
                
                  MOVB #$FF,DDRB 
                  MOVB #$55,PORTB        
                  LDX #0
                  MOVB #0,COUNTER_1 
                  STX TEMP_SUM            ;sum_temp has 2 bytes so used X to nitialize it.
                  STX SUM_INT1                 ;sum has 2 bytes so used X to nitialize it.
                  STX TEMP_SUM_INT1            ;sum_temp has 2 bytes so used X to nitialize it.
                  STX SUM_INT2                 ;sum has 2 bytes so used X to nitialize it.                  
                  LDX #$1200              ;X will point start of the string   
                  LDAA 0,X                ;assigned the first digit of the left number to X register        
                  JSR READ_INT_NUM1       ;will read all digits of integer part of the left number 
                                          ;read each digit then find the raal value of integer,used stack to do this 
                                          
                                          
                  MOVB #0,COUNTER_1 
                  MOVB #0,TEMP_SUM_DEC
                  MOVB #0,SUM_DEC1
                  JSR READ_DECIMAL_1
                  
                  LDAA 0,X
                  CMPA #$2B    ; is '+' operator
                  BNE  isminus
                  STAA OPERATOR
                  bra  read_space
                  
isminus           CMPA #$2D
                  BNE  read_space
                  STAA OPERATOR 
                  
read_space        INX
                  LDAA 0,X                  
                  INX
                  LDAA 0,X 
                  
                  
                                         
                  MOVB #0,COUNTER_1 
                  
                  JSR READ_INT_NUM2
                  
                  MOVB #0,COUNTER_1 
                  MOVB #0,TEMP_SUM_DEC2
                  MOVB #0,SUM_DEC2
                  JSR READ_DECIMAL_2
                  
                  LDAA OPERATOR
                  CMPA #$2B    ; if it is addition operator
                  BNE SUBSTRUCTION
                  
                  LDAA SUM_DEC1
                  LDAB SUM_DEC2
                  ABA 
                  STAA $1502    ;result of decimal part at $1500
                  LDD #0 
                  BCC no_cary_decimal
                  ADDD #1
                  
no_cary_decimal:  ADDD SUM_INT1     ;D += first integer 
                  ADDD SUM_INT2    ;D = first integer +second integer
                  BCC result 
                  MOVB #$FF,PORTB
                  BRA result
                  
                       

SUBSTRUCTION:     LDAA SUM_DEC1    ; dec1 > dec2 and int1 > int2
                  LDAB SUM_DEC2
                  SBA 
                  BLT condition_2
                  LDD  SUM_INT1
                  SUBD SUM_INT2
                  BLT  condition_4
                  LDAA SUM_DEC1
                  LDAB SUM_DEC2
                  SBA 
                  STAA $1502
                  LDD  SUM_INT1
                  SUBD SUM_INT2
                  BRA result
                  
                  
condition_2:      LDD SUM_INT1     ;dec1 < dec2 and int1 > int2
                  SUBD SUM_INT2
                  BLT condition_3                  
                  SUBD #1
                  STD $1500
                  LDAA SUM_DEC1    
                  LDAB SUM_DEC2
                  SBA
                  ADDA #100
                  STAA $1502
                  BRA OVERRR
                  
condition_3:      LDAA SUM_DEC2         ;dec1 < dec2 and int1 < int2 
                  LDAB SUM_DEC1
                  SBA 
                  STAA $1502
                  LDD SUM_INT2
                  SUBD SUM_INT1
                  BRA result
                  
                  
condition_4:      LDAA SUM_DEC2         ;dec1 > dec2 and int1 < int2 
                  LDAB SUM_DEC1
                  SBA 
                  ADDA #100
                  STAA $1502
                  LDD SUM_INT2
                  SUBD SUM_INT1
                  SUBD #1
                  BRA result
                              
                 
                   
result:           STD $1500 
                                                                                                     
OVERRR            JMP THE_END 
                                   
                  
;------------------start of subroitine-------------------------          
READ_INT_NUM1:    LDY SP            ;load  stack pointer value to Y  
                  STY STACK_PTR     ;keeps stack pointer at STACK_PTR
                  LDS #$4000        ;initialize  stack pointer 
              
NEXT_DIGIT:       CMPA #$2E         ; controls if it is dot.
                  BEQ COMPUTE 
                  PSHA  
                  INC COUNTER_1       
                  INX                  
                  LDAA 0,X                                                                                ;
                  BRA  NEXT_DIGIT
                  
COMPUTE:          
                  STX KEEP_X       ;keeps the string pointer at KEEP_X
                  MOVB #1,COUNTER  ;counter to find coefficient (1,10,100 etc) for example if counter is 3, X will 1000

NEXT_PUL:         JSR INITALIZE_X  ;initialize x with (10000 or 1000 or 100 or 10 or 1)
                  PULB             ;keeps integer digit as hex format
                  SUBB #$30        ;keeps integer digit as natural format
                  JSR MULTIPLY     ; Y=B x X (DIGIT x COEFFIENT)
                  STY TEMP_SUM
                  LDD SUM_INT1
                  ADDD TEMP_SUM
                  STD SUM_INT1
 
                  INC COUNTER      ;next digit place
                  LDAA COUNTER     ;A keeps next index of digit place
                  DECA             ;A =A -1
                  CMPA COUNTER_1
                  BNE NEXT_PUL                  
                  
                  
                  LDX KEEP_X        ;Point dor operator  again
                  INX               ;point after dot operator (first digit of decimal part)
                  
                  LDS #STACK_PTR 
                  RTS
;------------------end of subroitine--------------------------- 











;------------------start of subroitine-------------------------  

INITALIZE_X:
                  LDAA COUNTER
                  CMPA #1
                  BNE IF2
                  LDX  #1
IF2:              CMPA #2
                  BNE IF3
                  LDX #10
IF3:              CMPA #3
                  BNE IF4
                  LDX #100
IF4:              CMPA #4
                  BNE IF5
                  LDX #1000
IF5:              CMPA #5
                  BNE OVER_INIT
                  LDX #10000                                                                               
OVER_INIT:        RTS
;------------------end of subroitine--------------------------- 






;------------------start of subroitine-------------------------          
MULTIPLY:                        
                 LDY #0 ; D=0; will keep the result
ADDDING:         ABY  
                 DEX
                 BNE ADDDING
                  
                 RTS
;------------------end of subroitine--------------------------- 








;------------------start of subroitine-------------------------          
READ_DECIMAL_1:   LDY SP            ;load  stack pointer value to Y  
                  STY STACK_PTR     ;keeps stack pointer at STACK_PTR
                  LDS #$4000        ;initialize  stack pointer 
                  LDAA 0,X
     
NEXT_DIGIT_2:     CMPA #$20    ; controls if it is space
                  BEQ COMPUTE_DEC_1
                  CMPA #$2B    ; controls if it is '+'
                  BEQ COMPUTE_DEC_1
                  CMPA #$2D    ; controls if it is '-'
                  BEQ COMPUTE_DEC_1
                  
                  PSHA  
                  INC COUNTER_1       
                  INX                  
                  LDAA 0,X                                                                                ;
                  BRA  NEXT_DIGIT_2
                  
COMPUTE_DEC_1:                     
                  STX KEEP_X       ;keeps the string pointer at KEEP_X
                  LDAA COUNTER_1
                  CMPA #2
                  BNE  L1
                  PULB
                  SUBB #$30
                  LDAA #1
                  MUL
                  STAB TEMP_SUM_DEC
                  
                   
                  PULB
                  SUBB #$30
                  LDAA #10
                  MUL
                  LDAA TEMP_SUM_DEC
                  ABA 
                  STAA SUM_DEC1
                  BRA  overr_d1
                         
L1:               PULB 
                  SUBB #$30
                  LDAA #10
                  MUL
                  STAB SUM_DEC1                 
                  
overr_d1:         LDX KEEP_X        ;Point dot operator  again
                  INX               ;point after space , '+' or '-'
                  
                  LDS #STACK_PTR 
                  RTS
;------------------end of subroitine--------------------------- 





;------------------start of subroitine-------------------------          
READ_INT_NUM2:    LDY SP            ;load  stack pointer value to Y  
                  STY STACK_PTR     ;keeps stack pointer at STACK_PTR
                  LDS #$4000        ;initialize  stack pointer 
              
next_digit:       CMPA #$2E         ; controls if it is dot operator.
                  BEQ compute 
                  PSHA  
                  INC COUNTER_1       
                  INX                  
                  LDAA 0,X                                                                                ;
                  BRA  next_digit
                  
compute:          
                  STX KEEP_X       ;keeps the string pointer at KEEP_X
                  MOVB #1,COUNTER  ;counter to find coefficient (1,10,100 etc) for example if counter is 3, X will 1000

next_pul:        JSR INITALIZE_X  ;initialize x with (10000 or 1000 or 100 or 10 or 1)
                  PULB             ;keeps integer digit as hex format
                  SUBB #$30        ;keeps integer digit as natural format
                  JSR MULTIPLY     ; Y=B x X (DIGIT x COEFFIENT)
                  STY TEMP_SUM_INT1
                  LDD SUM_INT2
                  ADDD TEMP_SUM_INT1
                  STD SUM_INT2
 
                  INC COUNTER      ;next digit place
                  LDAA COUNTER     ;A keeps next index of digit place
                  DECA             ;A =A -1
                  CMPA COUNTER_1
                  BNE next_pul                  
                  
                  
                  LDX KEEP_X        ;Point dor operator  again
                  INX               ;point after dot operator (first digit of decimal part)
                  
                  LDS #STACK_PTR 
                  RTS
;------------------end of subroitine--------------------------- 





;------------------start of subroitine-------------------------          
READ_DECIMAL_2:   LDY SP            ;load  stack pointer value to Y  
                  STY STACK_PTR     ;keeps stack pointer at STACK_PTR
                  LDS #$4000        ;initialize  stack pointer 
                  LDAA 0,X
     
next__:           CMPA #$20    ; controls if it is space
                  BEQ COMPUTE_DEC_2
                  CMPA #$3D    ; controls if it is '='
                  BEQ COMPUTE_DEC_2
                  
                  
                  PSHA  
                  INC COUNTER_1       
                  INX                  
                  LDAA 0,X                                                                                ;
                  BRA  next__
                  
COMPUTE_DEC_2:                     
                  STX KEEP_X       ;keeps the string pointer at KEEP_X
                  LDAA COUNTER_1
                  CMPA #2
                  BNE  l1
                  PULB
                  SUBB #$30
                  LDAA #1
                  MUL
                  STAB TEMP_SUM_DEC2
                  
                   
                  PULB
                  SUBB #$30
                  LDAA #10
                  MUL
                  LDAA TEMP_SUM_DEC2
                  ABA 
                  STAA SUM_DEC2
                  BRA  overr_d2
                         
l1:               PULB 
                  SUBB #$30
                  LDAA #10
                  MUL
                  STAB SUM_DEC2    
                  
overr_d2          LDX KEEP_X        ;Point dot operator  again
                  INX               ;point after space , '+' or '-'
                  
                  LDS #STACK_PTR 
                  RTS
;------------------end of subroitine--------------------------- 


THE_END:          NOP

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector
