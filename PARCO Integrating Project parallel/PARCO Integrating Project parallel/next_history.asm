section .data

section .text
default rel
global next_history

next_history:

	; setup stack
	push rsi
	push rbp
	mov rbp, rsp
	add rbp, 16
	add rbp, 8
	push rbx

	; rcx = width * height 
	; rdx = matchingThreshold
	; r8 = matchingNumber-1
	; r9 = adderss of pels
	; rbp+32 = address of image_data
	; rbp+40 = address of segmentation_map

	MOV R10, [rbp+32]
	MOV R11, [rbp+40]
	MOV RAX, 32 ; does 32 elements at a time
	MOVQ XMM2, RDX
	VPBROADCASTB YMM2, XMM2 ; ymm2 filled with matchingThreshold
	MOVQ XMM3, R8
	VPBROADCASTB YMM3, XMM3 ; ymm3 filled with should-be value (matchingNumber-1)

L1:
	CMP RAX, RCX
	JG FINIS

	; result = abs(image_data - pels)
	VMOVDQU YMM0, [R9]
	VMOVDQU YMM1, [R10]
	VPSUBB YMM1, YMM0
	VPABSB YMM1, YMM1

	; results > matchingThreshold?
	VPCMPGTB YMM1, YMM1, YMM2 ; if true, cell = -1 (11111111b), 0 otherwise

	VPSUBB YMM0, YMM3, YMM1
	VMOVDQU [R11], YMM0

	ADD R9, 32 ; 32 ints * 1 byte
	ADD R10, 32
	ADD R11, 32
	ADD RAX, 32
	JMP L1

FINIS:
	SUB RAX, 32
	SUB RCX, RAX

LASTCHECK:
	CMP RCX, 0
	JLE RETURN
	MOV RAX, [R10]
	SUB RAX, [R9]

	; absolute value
	MOV RBX, RAX
	SAR RBX, 31
	XOR RAX, RBX
	SUB RAX, RBX

	CMP RAX, RDX
	JLE LESSTHAN
	MOV [R11], R8
	JMP CONT
	
LESSTHAN: MOV RAX, 1
	MOV [R11], RAX
	JMP CONT

CONT:
	ADD R9, 32 ; 32 ints * 1 byte
	ADD R10, 32
	ADD R11, 32
	DEC RCX
	JMP LASTCHECK

RETURN: 
	; pop stack
	pop rbx
	pop rbp
	pop rsi

ret
