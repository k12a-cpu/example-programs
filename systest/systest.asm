; IO port constants
.define IO_GPOUT0 0
.define IO_GPOUT1 1
.define IO_GPOUT2 2
.define IO_CTRL 3
.define IO_GPIN0 4
.define IO_SS0 4
.define IO_GPIN1 5
.define IO_SS1 5
.define IO_GPIN2 6
.define IO_LCD 6
.define IO_SPI 7

; Control register bitmask constants
.define CTRL_SS0HEX 0x01
.define CTRL_SS1HEX 0x02
.define CTRL_LCDRS 0x04
.define CTRL_LCDXFER 0x40
.define CTRL_SPIXFER 0x80
.define CTRL_SPIBUSY 0x80

; Terminate the program, showing the given exit code on the sevensegs.
; Arguments:
;   exit code (in B)
.macro %terminate
    ; Extract high byte of exit code, and write to seven-segment display 0.
    mov A, B
    asr A, A
    asr A, A
    asr A, A
    asr A, A
    andi A, A, 0x0F
    out IO_SS0
    ; Extract low byte of exit code, and write to seven-segment display 1.
    mov A, B
    andi A, A, 0x0F
    out IO_SS1
    ; Hang forever.
hang_M$$:
    halt
    rjmp hang_M$$
.endmacro

.macro %assert_not_skipped code
    rjmp success_M$$  ; This instruction should be executed.
    ; Control flow should not reach this point.
    movi B, code
    rjmp terminate
success_M$$:
.endmacro

.macro %assert_skipped code
    rjmp fail_M$$     ; This instruction should be skipped.
    ; Control flow should reach this point.
    rjmp success_M$$
fail_M$$:
    movi B, code
    rjmp terminate
success_M$$:
.endmacro

.macro %assert_equal val, code
    sknei val
    %assert_not_skipped code
.endmacro

main:
    ; Set SS0HEX and SS1HEX control bits, which set both seven-segment displays
    ; to display a hex digit.
    in IO_CTRL
    ori A, A, CTRL_SS0HEX|CTRL_SS1HEX
    out IO_CTRL

    ; Test rjmp.
    rjmp rjmp_ok
    ; Rjmp test failed.
    movi B, 0x01
    ; We can't rjmp to terminate, since we have no rjmp, so we'll just include
    ; the %terminate code inline. However, any other time we need to terminate,
    ; we can just rjmp to here.
terminate:
    %terminate
rjmp_ok:

    ; Test the basic test infrastructure (movi, skeq/skne, assertions).
    movi A, 0x84
    movi B, 0x84
    skeq
    %assert_skipped 0x02
    movi A, 0x38
    skeqi 0x44
    %assert_not_skipped 0x03

    movi A, 0x00
    sknei 0x1d
    %assert_skipped 0x04
    movi A, 0xab
    movi B, 0xab
    skne
    %assert_not_skipped 0x05

    ; Test skult and skuge.
    movi A, 0x44
    movi B, 0x68
    skult
    %assert_skipped 0x06
    movi A, 0x99
    movi B, 0x99
    skult
    %assert_not_skipped 0x07
    movi A, 0x93
    skulti 0x35
    %assert_not_skipped 0x08

    movi A, 0x32
    movi B, 0xae
    skuge
    %assert_not_skipped 0x09
    movi A, 0x00
    skugei 0x00
    %assert_skipped 0x0a
    movi A, 0xb0
    movi B, 0x2d
    skuge
    %assert_skipped 0x0b

    ; Test arithmetic operations (and, or, xor, add, sub, asr).
    movi A, 0xf5
    movi B, 0xc4
    and A, A, B
    %assert_equal 0xc4, 0x0c
    movi A, 0xd2
    andi A, A, 0x34
    %assert_equal 0x10, 0x0d

    movi A, 0x41
    movi B, 0x9b
    or A, A, B
    %assert_equal 0xdb, 0x0e
    movi A, 0x83
    ori A, A, 0x0f
    %assert_equal 0x8f, 0x0f

    movi A, 0x87
    movi B, 0x72
    xor A, A, B
    %assert_equal 0xf5, 0x10
    movi A, 0x74
    xori A, A, 0x63
    %assert_equal 0x17, 0x11

    movi A, 0xe4
    movi B, 0x23
    add A, A, B
    %assert_equal 0x07, 0x12
    movi A, 0x21
    addi A, A, 0x5c
    %assert_equal 0x7d, 0x13

    movi A, 0xe4
    movi B, 0x77
    sub A, A, B
    %assert_equal 0x6d, 0x14
    movi A, 0x3c
    subi A, A, 0xfa
    %assert_equal 0x42, 0x15

    movi A, 0x6e
    asr A, A
    %assert_equal 0x37, 0x16
    movi A, 0xc2
    asr A, A
    %assert_equal 0xe1, 0x17

    ; Test all 16 possible register-to-register moves.
    movi A, 0xAA
    movi B, 0x55
    movi C, 0x55
    movi D, 0x55
    mov B, A
    movi A, 0x55
    mov C, B
    movi B, 0x55
    mov D, C
    movi C, 0x55
    mov A, D
    movi D, 0x55
    mov C, A
    movi A, 0x55
    mov B, C
    movi C, 0x55
    mov D, B
    movi B, 0x55
    mov C, D
    movi D, 0x55
    mov A, C
    movi C, 0x55
    mov D, A
    movi A, 0x55
    mov B, D
    movi D, 0x55
    mov A, B
    %assert_equal 0xAA, 0x18

    ; Test loading from ROM.
    movi C, testbyte >> 8
    movi D, testbyte & 0xFF
    ld
    %assert_equal 0x88, 0x19

    ; Test storing to and loading from RAM.
    movi C, 0xa5
    movi D, 0x43
    movi A, 0x26
    st
    movi A, 0x00
    ld
    %assert_equal 0x26, 0x1a

    ; Test stack (getsp/putsp and ldd/std).
    movi C, 0xff
    movi D, 0x00
    putsp
    movi A, 0xd8
    push
    movi C, 0x00
    movi D, 0x00
    getsp
    mov A, C
    %assert_equal 0xfe, 0x1b
    mov A, D
    %assert_equal 0xff, 0x1c
    movi A, 0x00
    ldd 0
    %assert_equal 0xd8, 0x1d
    movi A, 0x61
    std 0
    movi A, 0x00
    pop
    %assert_equal 0x61, 0x1e
    getsp
    mov A, C
    %assert_equal 0xff, 0x1f
    mov A, D
    %assert_equal 0x00, 0x20

    ; Test inc/dec.
    movi C, 0xe6
    movi D, 0xff
    inc
    mov A, C
    %assert_equal 0xe7, 0x21
    mov A, D
    %assert_equal 0x00, 0x22
    dec
    mov A, C
    %assert_equal 0xe6, 0x23
    mov A, D
    %assert_equal 0xFF, 0x24
    putsp
    movi A, 0x00
    st
    movi A, 0x7c
    std 0
    movi A, 0x00
    ld
    %assert_equal 0x7c, 0x25

    ; All tests successful! Exit with code 0.
    movi B, 0
    rjmp terminate

testbyte:
    ;.byte 0x88
