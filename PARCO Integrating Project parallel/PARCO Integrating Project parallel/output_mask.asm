section .data

section .text
default rel
global output_mask

output_mask:

	; rcx = width * height 
	; rdx = address of mask
	; r8 = COLOR_FOREGROUND
	; r9 = -1

	MOV RAX, 32 ; does 32 elements at a time
	MOVQ XMM2, R8
	VPBROADCASTB YMM2, XMM2 ; ymm2 filled with COLOR_FOREGROUND
	VPXOR YMM1, YMM1
	MOVQ XMM3, R9
	VPBROADCASTB YMM3, XMM3 ; ymm3 filled with -1

L1:
	CMP RAX, RCX
	JG FINIS

	; pack move values
	VMOVDQU YMM0, [RDX]

	; results > 0?
	VPCMPGTB YMM4, YMM0, YMM1 ; if true, cell = -1 (11111111b), 0 otherwise

	VPAND YMM5, YMM2, YMM4	; COLOR_FOREGROUND in correct cells, others are 0
	VPXOR YMM4, YMM4, YMM3	; flip bits of ymm4 (condition results register)
	VPAND YMM0, YMM0, YMM4	; original mask values in original spots, others are 0
	VPADDB YMM0, YMM0, YMM5	; add COLOR_FOREGROUND in correct cells + original mask values in original spots
	
	VMOVDQU [RDX], YMM0

	ADD RDX, 32 ; 32 ints * 1 byte
	ADD RAX, 32
	JMP L1

FINIS:
	SUB RAX, 32
	SUB RCX, RAX


ret
