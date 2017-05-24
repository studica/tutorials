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
TIMER = $20003000

macro Delay time {
  ;This function will take a millisecond value and delay for that long
  local .DelayLoop
						   D
  imm32 r13, #250000 ; Pi 3 core frequency is 250 MHz. Divided by 1000 to convert to cycles per ms
  imm32 r5, time    ; time in milliseconds to delay
  imm32 R10, #0     ; initialize R10 as a 32-bit value
  mov R9, #3	 ; move 3 into R9. Will use for division

  MUL R10, R13, R5  ; R10 = clock speed * time (milliseconds)
  sdiv r10, r10, R9 ; R10 = (clock speed * time) / 3

  .DelayLoop:
    subs r10,1 ; R10 = R10 - 1. 1 cycle
    bne .DelayLoop  ; If R10 != 0, loop again. 2 cycles if taken, 1 cycle if not taken
}

format binary as 'img'	; Allows compiler to save as a .img file, which the pi will read on startup
include 'LIB\FASMARM.INC' ; Allows us to use FASMARM libraries in our code.

; Start L1 Cache
mrc p15,0,r0,c1,c0,0 ; R0 = System Control Register
orr r0,$0004 ; Data Cache (Bit 2)
orr r0,$0800 ; Branch Prediction (Bit 11)
orr r0,$1000 ; Instruction Caches (Bit 12)
mcr p15,0,r0,c1,c0,0 ; System Control Register = R0

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
  Delay 500   ; delay for a number of cycles.

  mov r1,GPIO_17 ; R1 = GPIO_17 (0x20000)
  str r1,[r0,GPIO_GPCLR0]  ; store 0x20000 into R0 at offset 0x28 (GPIO_GPCLR0). THIS TURNS OFF PIN 17
  Delay 500

  mov r3,GPIO_22 ; R3 = GPIO_22 (0x400000)
  str r3,[r0,GPIO_GPSET0] ; store 0x400000 into R0 at offset 0x1C (GPIO_GPSET0). THIS TURNS ON PIN 22
  Delay 500

  mov r3,GPIO_22 ;  R3 = GPIO_22 (0x400000)
  str r3,[r0,GPIO_GPCLR0] ; store 0x400000 into R0 at offset 0x28 (GPIO_GPCLR0). THIS TURNS OFF PIN 22
  Delay 500

b loop ; branch to the top of the loop. This runs infinitely.