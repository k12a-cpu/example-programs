; Simple demo to display a pattern on the LEDs.

; The I/O port connected to the LED outputs.
@define LEDS_PORT 2

start:
    ; Initialise A.
    mov A, 0x01

    ; Update LEDs to contents of A.
    out LEDS_PORT, A
    
    ; Fall through to loop_left.

loop_left:
    ; Wait some time.
    mov B, A  ; The subroutine clobbers A, so save it in B.
    rcall delay
    mov A, B  ; Restore contents of A.

    ; Logical-shift A left by one place.
    mov B, A
    mov A, A+B

    ; Update LEDs with contents of A.
    out LEDS_PORT, A

    ; If A == 0x80, go to loop_right, else go to loop_left.
    skzi A, 0x80    ; skip next instruction if A - 0x80 == 0
    rjmp loop_left  ; executed only if A - 0x80 != 0
    ; Otherwise, fall through to loop_right.

loop_right:
    ; Wait some time.
    mov B, A  ; The subroutine clobbers A, so save it in B.
    rcall delay
    mov A, B  ; Restore contents of A.
    
    ; Logical-shift A right by one place.
    mov A, A >> 1
    mov A, A & 0x7F  ; The right shift is an arithmetic shift. We make it a logical shift by clearing the MSB, if it was set.

    ; Update LEDs with contents of A.
    out LEDS_PORT, A

    ; If A == 0x01, go to loop_left, else go to loop_right.
    skzi A, 0x01     ; skip next instruction if A - 0x01 == 0
    rjmp loop_right  ; executed only if if A - 0x01 != 0
    rjmp loop_left   ; executed otherwise


; Delay for some time (a quarter of a second, assuming a 100 kHz clock).
; This subroutine clobbers A, C and D, but preserves B.
delay:
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
    
    mov C, 0x06
    mov D, 0xBD
delay_loop:
    dec              ; decrement CD
    mov A, C         ; copy C to A
    skzi A, 0x00     ; skip next instruction if A - 0x00 == 0
    rjmp delay_loop  ; executed only if A != 0
    
    ; Return.
    mov C, A
    pop
    mov D, A
    pop
    ljmp
