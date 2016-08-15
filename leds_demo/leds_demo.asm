; Simple demo to display a pattern on the LEDs attached to digital output port 0.

; The I/O port connected to the digital outputs.
.define LEDS_PORT 0

start:
    ; Initialise stack pointer.
    movi C, 0x90
    movi D, 0x00
    putsp

    ; Initialise A.
    movi A, 0x01

    ; Update LEDs to contents of A.
    out LEDS_PORT
    
    ; Fall through to loop_left.

loop_left:
    ; Wait some time.
    rcall delay

    ; Logical-shift A left by one place.
    mov B, A
    add A, A, B

    ; Update LEDs with contents of A.
    out LEDS_PORT

    ; If A == 0x80, go to loop_right, else go to loop_left.
    skeqi 0x80      ; skip next instruction if A == 0x80
    rjmp loop_left  ; executed only if A != 0x80
    ; Otherwise, fall through to loop_right.

loop_right:
    ; Wait some time.
    rcall delay
    
    ; Logical-shift A right by one place.
    asr A, A
    andi A, A, 0x7F  ; The right shift is an arithmetic shift. We make it a logical shift by clearing the MSB, if it was set.

    ; Update LEDs with contents of A.
    out LEDS_PORT

    ; If A == 0x01, go to loop_left, else go to loop_right.
    skeqi 0x01       ; skip next instruction if A == 0x01
    rjmp loop_right  ; executed only if if A != 0x01
    rjmp loop_left   ; executed otherwise


; Delay for some time (a quarter of a second, assuming a 100 kHz clock).
; This subroutine clobbers C and D, but preserves B.
delay:
    ; Save contents of A.
    push
    ; Save return address (in registers C and D).
    mov A, D
    push
    mov A, C
    push
    
    ; How to calculate starting value of CD:
    ;   Let f = clock frequency, T = desired delay.
    ;   Clock period = Δt = 1/f.
    ;   Duration of one iteration of delay_loop = 17*Δt = 17/f.
    ;   Number of iterations of delay_loop = T/(17/f) = T*f/17.
    ;   Final value of CD counter = 0x00FF = 255 (loop ends as soon as C == 0).
    ;   Starting value = 255 + number of iterations
    ;                  = 255 + T*f/17
    ; For 250ms delay at 100 kHz clock,
    ;   Starting value = 255 + 0.25*100000/17
    ;                  = 1725
    ;                  = 0x06BD
    
    movi C, 0x06
    movi D, 0xBD
delay_loop:
    dec              ; (4 cycles) decrement CD
    mov A, C         ; (4 cycles) copy C to A
    skeqi 0x00       ; (4 cycles) skip next instruction if A == 0x00
    rjmp delay_loop  ; (5 cycles) executed only if A != 0
    
    ; Restore return address.
    pop
    mov C, A
    pop
    mov D, A
    ; Restore A.
    pop
    ; Return to caller.
    ljmp
