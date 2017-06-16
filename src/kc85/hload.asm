    .module hload
    .include 'caos.inc'
    .include 'config.inc'

    .area _CODE
    .dw 0x7f7f
    .ascii 'HLOAD'
    .db 0x01
    ret
