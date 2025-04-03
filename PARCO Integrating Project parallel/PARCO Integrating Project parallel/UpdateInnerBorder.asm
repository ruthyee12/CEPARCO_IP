section .data
; REMEMBER TO ADJUST HISTORY_IMAGES in this file if "NUMBER_OF_HISTORY_IMAGES" in sequential.c is adjusted.
    height_1 dq 0
    x_column dq 0
    index dq 0
    shift dq 0
    fmt_string db "%p", 10, 0  ; "%p\n", 10 (newline), null terminator
    
    ; to determine from what ptr we are column-lead accessing 32 pixels
    jump_ptr dq 0
    position_ptr dq 0
    neighbor_ptr dq 0
    image_ptr dq 0  
    updating_mask_ptr dq 0 
    historyImage_ptr dq 0 
    historyBuffer_ptr dq 0
    
    remaining_loops dd 0
    incrementor_rndm dq 0 ; to be used when determining which solo "index"
    ; to use

section .text
    default rel
    global UpdateInnerBorder
    extern printf
    
    ; width, height, *jump, *position, *neighbor, *image_data, *updating_mask, *historyImage, *historyBuffer
    ; rcx width, rdx height, r8 jump, r9 *position, [rbp + 32] *neighbor, [rbp + 40] *image_data, 
    ; [rbp + 48] *updating_mask, [rbp + 56] *historyImage, [rbp + 64] *historyBuffer
    
    ;for segmentation pala ;for absdiff, use PMAXUB, PMINUB, PSUBB, PCEMPQB
    
    ; main ideas:
    ; 1. Use ymm to evaluate 32 column-pixels at once
    ; 2. Use the leading row pixel "will vary over time" as basis for jump[shift],
    ; neighbor[shift], and position[shift]
    ; 3. packed compare all pixel values if == COLOR_BACKGROUND [compare, sum] {
    ; 
    ;}
    ; else, inc shift reg, modify indX reg with += [jump + shift]

UpdateInnerBorder:
    ; handle pushes
    push rbp
    push rsi
    push rdi
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbp, rsp
    add rbp, 72 ; from bottom of stack: r15, r14, r13, r12, rbx, rdi, rsi, rbp, return
    ; sub rsp, 32 for each ymm6+ reg
    ; vmovdqu [rsp], ymm6+
    ; sub rsp, 16 for each xmm6+ reg
    ; vmovdqu [rsp], xmm6+
    
    mov r10, rcx ; r10 = width (uint32_t)
    mov r11, rdx ; r11 = height (uint32_t)
    
    ;storing the pointers:
    mov [jump_ptr], r8
    mov [position_ptr], r9
    mov rsi, [rbp + 32]
    mov [neighbor_ptr], rsi
    mov rsi, [rbp + 40]
    mov [image_ptr], rsi
    mov rsi, [rbp + 48]
    mov [updating_mask_ptr], rsi
    mov rsi, [rbp + 56]
    mov [historyImage_ptr], rsi
    
    mov rsi, [rbp + 64]
    mov [historyBuffer_ptr], rsi
    
    ;access 32 pixels at a time
    
    ;rdx = height
    dec rdx ; rdx = height - 1
    mov [height_1], rdx
    dec rcx ; rcx = width - 1
    dec rcx ; rcx = width - 2
    mov rax, rcx ; rax = width - 2
    xor rdx, rdx
    mov rbx, 32 ; idea is to remove everything in rbx, then put 32
    div rbx ; how many times to 32px loop is in eax. Conducted r32m for the sake of implicited zero-extension
    ; rax = last value of iteration for our 32 pixel accesses
    ; rdx = remaining single loops (to be handled after 32 width pixel-wise handling)
    mov dword [remaining_loops], edx ; remaining loops in rdx
    mov r12d, eax ; r12d = has the widthforLoopcounters
    dec r12d
    mov rsi, 1 ; for x = 1 (index for the width)
    vxorps ymm1, ymm1 ; for 0 comparison of COLOR_BACKGROUND == 0
    vxorps xmm1, xmm1 ; for 0 comparison of COLOR_BACKGROUND == 0
    
    InnerBorder_forLoop:
    ; free right now, r8, r9, rdi, rax, r14, r15, rcx
    ; randomization
    ;imul r8, rsi, r10 ; r8 now has the no. of pixels/addresses skipped after rsi*width
    rdtsc                   ; Read time-stamp counter
    xor rdx, rdx            
    mov rbx, r11            ; Modulo height
    div rbx                 ; EDX = Remainder (random number)
    ; rdx is now shift
    
    mov rbx, rdx
    ; put jump[shift] in r13 = indY
    mov rax, dword [jump_ptr]
    mov r13d, dword [rax + rdx] ; r13 = indY = jump[shift]

    
    ;upon new width iteration, modify x accordingly (in this case, rcx)
    ;x = (rsi-1)*32 + 1
    mov rcx, rsi
    dec rcx
    imul rcx, rcx, 32
    inc rcx ; x
    mov [x_column], rcx
        
        InnerBorder_heightWhileLoop:
       
        
        ; obtain int index
        ; r13 = indY
        mov r9, r13 ; r9 = indY
        imul r9, r10 ;r9 = IndY*width
        
        mov rcx, [x_column] ; rcx = x
        add r9, rcx ; r9 = index = x + IndY*width
        
        ;check all 32 px width if == COLOR_BACKGROUND
        mov rax, [updating_mask_ptr]
        vmovdqu ymm0, [rax + r9]
        vpcmpeqb ymm2, ymm1, ymm0 ; check if all are 0
        ; now ymm2 has FF in each byte if == 0
        vpmovmskb r14, ymm2
        cmp r14d, 0xFFFFFFFF ; checks all 32 byte MSBs if they were 1
        ; free right now, r8, rdi, rax, rbx, r14, r15
        
        je all_zeroes_ymm
        jne not_all_zeroes_ymm
        
        zero_handling_done:
        
        ;at this point, all background or non-background pixels in 
        ;our 32 pixel wide selection have been "actioned" accordingly
        
        ;free rn r8, r9, rdi, rax, rcx, rbx, r14, r15
        
        inc rdx ; ++shift;
        mov rax, [jump_ptr] ; rax = jump[]
        mov ecx, dword [rax + rdx] ; eax = jump[shift]
        add r13d, ecx ; indY += jump[shift];
        
        
        mov rcx, [height_1] ; rcx = height-1
        
        cmp r13, rcx    ; indY < height - 1
        jl InnerBorder_heightWhileLoop
        
    inc esi
    cmp esi, r12d ; x <= (width  - 2)/32
    jle InnerBorder_forLoop
    
    ;at this point, all 32px width handle-ables are "actioned" 'appropriately'

    ;handle remaining 
    ;use remaining_loops dd 0 for boundary of individual
    ; rsi is now for the column of the remaining
    
    rdtsc                   ; Read time-stamp counter
    xor rdx, rdx            
    mov rbx, r11            ; Modulo height
    div rbx                 ; EDX = Remainder (random number)
    ; rdx is now shift
    
    ; put jump[shift] in r13 = indY
    mov rax, [jump_ptr]
    add rax, rdx
    mov r13d, dword [rax] ; r13 = indY = jump[shift]
    mov r12d, dword [remaining_loops] ;r12 to be used against rbx if < r12
    add r12d, 32
    ;x = (rsi-1)*32 + 1
    mov rcx, rsi
    dec rcx
    imul rcx, rcx, 32
    inc rcx ; x
    mov [x_column], rcx
    
    jmp handleRemaining_heightWhileLoop

RETURN_C:
    ; handle pops
    ; vmovdqu xmm6+, [rsp]
    ; add rsp, 16
    ; vmovdqu ymm6+, [rsp]
    ; add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rdi
    pop rsi
    pop rbp
    ret
    
handleRemaining_heightWhileLoop:
    ;rsi is at the remaining width column
   
    ; obtain int index
    ; r13 = indY
    mov r9, r13 ; r9 = indY
    imul r9, r10 ;r9 = IndY*width
    
    mov rcx, [x_column] ; rcx = x
    add r9, rcx ; r9 = index = x + IndY*width
    mov [index], r9
    xor rbx, rbx
    handleRemaining_widthLoop:
        ;do individual handling
        mov r9, [index]
        add r9, rbx ; index += column iterator
        mov rax, [updating_mask_ptr]
        mov r8b, byte [rax + r9] ; r8b = updating_mask[index]
        cmp r8b, 0 ; updating_mask[index] == COLOR_BACKGROUND
        je rem_individual_zero
        ;if not zero, then do nothing, proceed to next column
    rem_individual_zero_handling_finished:
    
        inc rbx
        cmp ebx, r12d
        jl handleRemaining_widthLoop
        
        ;add here ending for while width
        inc rdx ; ++shift;
        lea rax, [jump_ptr] ; rax = jump[]
        mov ecx, dword [rax + rdx] ; eax = jump[shift]
        add r13d, ecx ; indY += jump[shift];
        
        
        mov rcx, [height_1] ; rcx = height-1
        
        cmp r13, rcx    ; indY < height - 1
        jl handleRemaining_heightWhileLoop
        
        ;congrats, finished the whole double loop... z_z
        jmp RETURN_C
        
        
    rem_individual_zero:
        mov rax, [image_ptr]
        mov r8b, byte [rax + r9]
        ; xmm0 has value = image_data[index]
        ; rdx = shift, r9  = index
        mov rax, [neighbor_ptr]
        xor r14, r14
        mov r14d, dword [rax + rdx] ; r14 = neighbor[shift]
        add r14d, r9d ; r14 = index_neighbor = index + neighbor[shift];
        
        mov rax, [position_ptr]
        xor r15, r15
        mov r15d, dword [rax + rdx] ; r15 = position[shift]
        
        cmp r15d, 2
        jl rem_indiv_zero_if_pos_lessthan_num_History_Images
        jge rem_indiv_zero_else_pos_lessthan_num_History_Images
        
        rem_indiv_zero_if_pos_lessthan_num_History_Images:
        ; r9 + r15*r10*r11 = index + position[shift] * width * height
        mov rdi, r11
        imul rdi, r10
        imul rdi, r15 ; position[shift]*width*height
        add r9, rdi ; r9 + r15*r10*r11 = index + position[shift] * width * height
        add r14, rdi ; r14 + r15*r10*r11 = index_neighbor + position[shift] * width * height
        mov rax, [historyImage_ptr]
        
    rem_indiv_transfering:
        mov byte [rax+r9], r8b
        mov byte [rax+r14], r8b
        
        jmp rem_individual_zero_handling_finished
        
        rem_indiv_zero_else_pos_lessthan_num_History_Images:
        sub r15, 2 ; pos = position[shift] - NUMBER_OF_HISTORY_IMAGES
        imul r9, 18 ; index * numberOfTests [20-2]
        imul r14, 18 ; index_neighbor * numberOfTests [20-2]
        add r9, r15 ; index * numberOfTests + pos
        add r14, r15 ; index_neighbor * numberOfTests + pos
        mov rax, [historyBuffer_ptr]
        
        jmp rem_indiv_transfering
         
    
all_zeroes_ymm:
     mov rax, [image_ptr]
     vmovdqu ymm0, [rax + r9]
     ; ymm0 has value = image_data[index]
     ; rdx = shift, r9  = index
    mov rax, [neighbor_ptr]
    xor r14, r14
    mov r14d, dword [rax + rdx] ; r14 = neighbor[shift]
    add r14d, r9d ; r14 = index_neighbor = index + neighbor[shift];
    
    mov rax, [position_ptr]
    xor r15, r15
    mov r15d, dword [rax + rdx] ; r15 = position[shift]
    
    cmp r15d, 2
     jl all_zeroes_ymm_if_pos_lessthan_num_History_Images
     jge all_zeroes_ymm_else_pos_lessthan_num_History_Images
     
     all_zeroes_ymm_if_pos_lessthan_num_History_Images:
     ; r9 + r15*r10*r11 = index + position[shift] * width * height
     mov rdi, r11
     imul rdi, r10
     imul rdi, r15 ; position[shift]*width*height
     add r9, rdi ; r9 + r15*r10*r11 = index + position[shift] * width * height
     add r14, rdi ; r14 + r15*r10*r11 = index_neighbor + position[shift] * width * height
     mov rax, [historyImage_ptr]
ymm_transfering:
     vmovdqu [rax+r9], ymm0
     vmovdqu [rax+r14], ymm0
     
     jmp zero_handling_done
     
     all_zeroes_ymm_else_pos_lessthan_num_History_Images:
     sub r15, 2 ; pos = position[shift] - NUMBER_OF_HISTORY_IMAGES
     imul r9, 18 ; index * numberOfTests [20-2]
     imul r14, 18 ; index_neighbor * numberOfTests [20-2]
     add r9, r15 ; index * numberOfTests + pos
     add r14, r15 ; index_neighbor * numberOfTests + pos
     mov rax, [historyBuffer_ptr]
     
     jmp ymm_transfering
     

     
not_all_zeroes_ymm:
    ; idea is to check all if first half is zeroes, then if not, do individual
    ; for second half, do the same, check if all are zeroes, then if not, do individual
    ; r9 = index, rcx = x,
     ;check all 32 px width if == COLOR_BACKGROUND
    xor rbx, rbx ; column iterator
    xor rcx, rcx ; iterator for how many xmm loops
    mov [index], r9
NAZ_xmm_loop:
    mov r9, [index]
    add r9, rbx ; index += column iterator
    mov rax, [updating_mask_ptr]
    vmovdqu xmm0, [rax + r9]
    vpcmpeqb xmm2, xmm1, xmm0 ; check if all 16 px are 0
    vpmovmskb r14d, xmm2
    cmp r14d, 0xFFFF ; checks all 16 byte MSBs if they were 1
    
    ;at these two points, assume r9 is the 
    
    je all_zeroes_xmm0
    jne not_all_zeroes_xmm0

    zero_handling_done_xmm:
    
    add rbx, 16
    
    zero_handling_done_indiv:
    
    inc rcx
    cmp rcx, 2
    jl NAZ_xmm_loop
    jmp zero_handling_done ;after the two xmms, go back to one ymm done handling
    
                    
                                                            
all_zeroes_xmm0:
    ;same process as ymm0, after xmm register handling,
    ; add rbx, 16, inc rcx, then check if < 2, jl NAZ_xmm_loop
    mov rax, [image_ptr]
    vmovdqu xmm0, [rax + r9]
    ; xmm0 has value = image_data[index]
    ; rdx = shift, r9  = index
    mov rax, [neighbor_ptr]
    xor r14, r14
    mov r14d, dword [rax + rdx] ; r14 = neighbor[shift]
    add r14d, r9d ; r14 = index_neighbor = index + neighbor[shift];
    
    mov rax, [position_ptr]
    xor r15, r15
    mov r15d, dword [rax + rdx] ; r15 = position[shift]
    
    cmp r15d, 2
    jl all_zeroes_xmm_if_pos_lessthan_num_History_Images
    jge all_zeroes_xmm_else_pos_lessthan_num_History_Images
    
    all_zeroes_xmm_if_pos_lessthan_num_History_Images:
    ; r9 + r15*r10*r11 = index + position[shift] * width * height
    mov rdi, r11
    imul rdi, r10
    imul rdi, r15 ; position[shift]*width*height
    add r9, rdi ; r9 + r15*r10*r11 = index + position[shift] * width * height
    add r14, rdi ; r14 + r15*r10*r11 = index_neighbor + position[shift] * width * height
    mov rax, [historyImage_ptr]
    
xmm_transfering:
    vmovdqu [rax+r9], xmm0
    vmovdqu [rax+r14], xmm0
    
    jmp zero_handling_done_xmm
    
    all_zeroes_xmm_else_pos_lessthan_num_History_Images:
    sub r15, 2 ; pos = position[shift] - NUMBER_OF_HISTORY_IMAGES
    imul r9, 18 ; index * numberOfTests [20-2]
    imul r14, 18 ; index_neighbor * numberOfTests [20-2]
    add r9, r15 ; index * numberOfTests + pos
    add r14, r15 ; index_neighbor * numberOfTests + pos
    mov rax, [historyBuffer_ptr]
    
    jmp xmm_transfering
    
not_all_zeroes_xmm0:
    ;do individual handling

    mov r9, [index]
    add r9, rbx ; index += column iterator
    mov rax, [updating_mask_ptr]
    mov r8b, byte [rax + r9] ; r8b = updating_mask[index]
    cmp r8b, 0 ; updating_mask[index] == COLOR_BACKGROUND
    je individual_zero
    ;if not zero, then do nothing, proceed to next column
individual_zero_handling_finished:

    inc rbx
    cmp rbx, 16
    je zero_handling_done_indiv
    cmp rbx, 32
    je zero_handling_done_indiv
    
    jmp not_all_zeroes_xmm0 ; loop back until 16 is achieved, or 32 is achieved
    
    
individual_zero:
    mov rax, [image_ptr]
    mov r8b, byte [rax + r9]
    ; xmm0 has value = image_data[index]
    ; rdx = shift, r9  = index
    mov rax, [neighbor_ptr]
    mov r14d, dword [rax + rdx] ; r14 = neighbor[shift]
    xor r14, r14
    add r14d, r9d ; r14 = index_neighbor = index + neighbor[shift];
    
    mov rax, [position_ptr]
    xor r15, r15
    mov r15d, dword [rax + rdx] ; r15 = position[shift]
    
    cmp r15d, 2
    jl indiv_zero_if_pos_lessthan_num_History_Images
    jge indiv_zero_else_pos_lessthan_num_History_Images
    
    indiv_zero_if_pos_lessthan_num_History_Images:
    ; r9 + r15*r10*r11 = index + position[shift] * width * height
    mov rdi, r11
    imul rdi, r10
    imul rdi, r15 ; position[shift]*width*height
    add r9, rdi ; r9 + r15*r10*r11 = index + position[shift] * width * height
    add r14, rdi ; r14 + r15*r10*r11 = index_neighbor + position[shift] * width * height
    mov rax, [historyImage_ptr]
    
indiv_transfering:
    mov byte [rax+r9], r8b
    mov byte [rax+r14], r8b
    
    jmp individual_zero_handling_finished
    
    indiv_zero_else_pos_lessthan_num_History_Images:
    sub r15, 2 ; pos = position[shift] - NUMBER_OF_HISTORY_IMAGES
    imul r9, 18 ; index * numberOfTests [20-2]
    imul r14, 18 ; index_neighbor * numberOfTests [20-2]
    add r9, r15 ; index * numberOfTests + pos
    add r14, r15 ; index_neighbor * numberOfTests + pos
    mov rax, [historyBuffer_ptr]
    
    jmp indiv_transfering
     
     
     
     
     
     
     
     