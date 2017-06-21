; Create definitions (numerical constants) for the memory addresses that we will need. This will help keep our code readable.
; These memory addresses can be found in the Broadcom 2835 manual
; https://www.raspberrypi.org/app/uploads/2012/02/BCM2835-ARM-Peripherals.pdf

PERIPHERAL_BASE = $3F000000
GPIO_BASE =  $200000
GPIO_GPSET0 = $1C
GPIO_GPCLR0 = $28
GPIO_GPFSEL1 = $4
GPIO_GPFSEL2 = $8
GPIO_17 = $20000
GPIO_22 = $400000
TIMER_BASE = $3000 ; timer peripheral base
TIMER_CNT = $4	; offset for timer

macro Timer time {

 ; Our time variable will be in milliseconds.
 ; However, hardware clock uses microseconds. We must convert
 local .wait
 imm32 r13, #1000  ; used for getting microseconds from milliseconds
 imm32 r5, time    ; r5 = time_in_milliseconds
 mul r10, r13, r5 ; get microseconds from milliseconds. R10 = 1000 * time_in_milliseconds

 mov r6, PERIPHERAL_BASE ; Get the Pi peripheral address. R6 = 0x3F000000
 orr r6, r6, TIMER_BASE ; r6 = (0x3F000000 | 0x00003000) = 0x3F003000

 ldr r7, [r6, TIMER_CNT] ; r7 = time in microseconds given by timer at 0x3F003004.

.wait:
    ldr r8, [r6, TIMER_CNT] ; R8 = time in microseconds from timer at 0x3F003004

    SUB R8, R8, R7 ; R8 = current time - initial time
    CMP R8, R10 ; compare R8 to specified time in microseconds
    BLT .wait	; if R9 < time specified, loop again.
}

format binary as 'img'	; Allows compiler to save as a .img file, which the pi will read on startup
include 'LIB\FASMARM.INC' ; Allows us to use FASMARM libraries in our code.

; Start L1 Cache
mrc p15,0,r0,c1,c0,0 ; R0 = System Control Register

mov r0, PERIPHERAL_BASE ; set R0 to 3F000000 (this is peripheral address of Pi 2 and 3
orr r0, r0, GPIO_BASE  ; R0 = R0 | 200000. R0 will now equal 3F200000
mov r1, #1   ; R1 = 1
lsl r1, #21  ; Shift R1 to the left by 21. 7th set of 3 bits (7 * 3) for GPIO 17
str r1,[r0,GPIO_GPFSEL1]    ; Store the value in R1 into R0 at offset 0x4, which is equal to GPIO_GPFSEL1 in Lemon's library

mov r1, #1   ; R1 = 1
lsl r1, #6   ; Shift R1 left by 6. 2nd set of 3 bits (2 * 3) for GPIO 22. 0th set is 0 (20), 1st set is 1 (21), 2nd set is 2 (22), etc.
str r1, [r0, GPIO_GPFSEL2]    ; Store value of R1 into R0 at offset 0x8 (GPIO_GPFSEL2)

loop:
  mov r1, GPIO_17  ; R1 = GPIO_17, which is equal to 0x20000
  str r1,[r0,GPIO_GPSET0]    ; Store 0x20000 into R0, at offset 0x1C (GPIO_GPSET0). THIS TURNS ON PIN 17
  Timer 1000  ; delay for 500 milliseconds

  mov r1,GPIO_17 ; R1 = GPIO_17 (0x20000)
  str r1,[r0,GPIO_GPCLR0]  ; store 0x20000 into R0 at offset 0x28 (GPIO_GPCLR0). THIS TURNS OFF PIN 17
  Timer 1000  ; delay for 500 milliseconds

  mov r3,GPIO_22 ; R3 = GPIO_22 (0x400000)
  str r3,[r0,GPIO_GPSET0] ; store 0x400000 into R0 at offset 0x1C (GPIO_GPSET0). THIS TURNS ON PIN 22
  Timer 1000  ; delay for 500 milliseconds

  mov r3,GPIO_22 ;  R3 = GPIO_22 (0x400000)
  str r3,[r0,GPIO_GPCLR0] ; store 0x400000 into R0 at offset 0x28 (GPIO_GPCLR0). THIS TURNS OFF PIN 22
  Timer 1000  ; delay for 500 milliseconds

b loop ; branch to the top of the loop. This runs infinitely.