.286
.model small
.stack 100h

.data
    file_name db 'c:\data.txt'
    sourceId dw 0
    temp_file db 80 dup(0)
    ;temp_file db 'c:\temp.txt'
    tempId dw 0
       
    line_buffer db 1024 dup('$')
    buffer db ?
    last db 0
    string db 200 dup('$')
    string_length dw 0
    
    
    errCreate db 'Error create file',0dh,0ah,'$'
    endofprogram db 'End program',0dh,0ah,'$'
    cmdErr db 'cmd Error',0dh,0ah,'$'
    msg db 0dh,0ah,'Enter string:',0dh,0ah,'$'
    cant_open_file db 'Error open files!',0dh,0ah,'$'
    error dw 0
.code

enter_string proc
    pusha
    xor ax,ax
    mov ah,0ah
    mov dx,offset string
    int 21h
    
    mov si,offset string
    inc si
    xor ax,ax
    mov al,[si]
    mov string_length,ax
    popa
    ret
endp    
;;;;
open_files proc
    pusha
    xor cx,cx
    mov dx,offset file_name
    mov ah,3dh;open exists file
    mov al,00;only read    
    int 21h
    jc cant_open
    
    mov sourceId,ax
    
    mov ah,3ch;create new file
    xor cx,cx
    mov dx,offset temp_file
    int 21h
    
    mov tempId,ax
    jmp end_open_files
    
cant_open:
    mov error,1    
end_open_files:    
    popa
    ret
endp
;;;   
main_proc proc
    pusha          
    
    xor ax,ax
    xor cx,cx
    
    
    mov si,offset line_buffer
read_line_loop:       
    mov ah,3fh
    mov bx,sourceId
    mov cx,1
    mov dx,offset buffer
    int 21h  
    cmp ax,cx
    jnz read_last_line
    
    
    xor ax,ax
    mov al,buffer
    mov [si],al
    inc si
    cmp al,0ah   
    je search  
obratno:  
    jmp read_line_loop    

search:
    call search_line 
    mov si,offset line_buffer  
    jmp obratno
read_last_line:
    dec si
    mov [si],0dh  
    inc si
    mov [si],0ah 
    mov last,1
    call search_line
    
    
       
    mov ah,3eh
    mov bx,sourceId
    int 21h
    mov bx,tempId
    int 21h

       
    popa
    ret
endp   
;;;;;;;;;;
search_line proc
    pusha    
    mov di,0;line buffer
    mov si,2;string
    
start_check:
    cmp line_buffer[di],' '
    jne x
    inc di
    jmp start_check   
x:;naiden pervii symbol
    mov bl,line_buffer[di]
    cmp string[si],bl
    jnz bad_symbol
    
good_symbol:
    inc di
    inc si
    cmp string[si],0dh
    je final_check
    
    jmp x
bad_symbol:
    mov si,2
a:  
    inc di
    cmp line_buffer[di],' '
    je start_check
    cmp line_buffer[di],0dh  
    je not_found
    jmp a
    
final_check:
    cmp line_buffer[di],' '
    je found
    cmp line_buffer[di],0dh
    je found   
    jmp bad_symbol
found: 
    call write_to_temp
    jmp found_end
not_found: 
found_end:
    popa
    ret
endp
;;;;;;;;;;;
write_to_temp proc
    pusha    
    mov si,0  
    
    mov ah,40h
    mov bx,tempId
    mov cx,1
    mov dx,offset buffer
    
    cmp last,1   
    jne write_loop
last_loop:
    mov al,line_buffer[si]
    mov buffer,al  
    
    cmp buffer,0dh
    je exit_write     
    
    mov ah,40h
    mov bx,tempId
    mov cx,1
    mov dx,offset buffer
    int 21h
        
   
    inc si        
    jmp last_loop 
            
write_loop:   
    mov al,line_buffer[si]
    mov buffer,al  
    
    mov ah,40h
    mov bx,tempId
    mov cx,1
    mov dx,offset buffer
    int 21h
    
    cmp buffer,0ah
    je exit_write
    inc si
        
    jmp write_loop 

exit_write:     
    popa
    ret
endp
;;;
getOutputName proc
    pusha
    
    mov di,offset temp_file
    
    xor cx,cx
      
    mov si,80h 
    mov cl,es:[si];dlina  
    cmp cl,0
    je cmdError
    
    
    add si,2
    mov al,es:[si]
    cmp al,' '
    je cmdError
    cmp al,0dh
    je cmdError    
    
copyCmd:
    mov ds:[di],al
    inc di
    inc si
    mov al,es:[si]
    cmp al,' '
    je cmdError
    cmp al,0dh
    je endCmd
    loop copyCmd
        
cmdError:
    print_str_macro cmderr
    jmp to_end         
endcmd:    
    popa
    ret
endp 
;;;;;;;;;;;
print_str_macro macro out_str
    mov ah,9
    mov dx,offset out_str
    int 21h
endm

start:
    mov ax,@data
    mov ds,ax
    mov ax,3
    int 10h
    
    call getOutputName
    
    print_str_macro temp_file
    
    print_str_macro msg
    
    call enter_string
    
    call open_files   
    cmp error,1
    je eror    
    
    call main_proc   
    jmp to_end
eror:
    print_str_macro cant_open_file   
to_end:  
    print_str_macro endofprogram
    mov ah,4ch
    int 21h
end start
