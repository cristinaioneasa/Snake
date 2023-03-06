.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.data

window_title DB "Proiect", 0
area_width EQU 640
area_height EQU 480
area DD 0

counter DD 0 ; numara evenimentele de tip timer
counter_ok DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20

include digits.inc
include letters.inc
include simboluri_2.inc

size_simbol EQU 16

snake_x DD 100
snake_y DD 100

snake_x1 DD 116
snake_y1 DD 100

snake_x2 DD 132
snake_y2 DD 100
	
.code 
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'V'
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 23 ; de la 0 pana la 22 sunt litere, 23 e space
	lea esi, letters
	
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

;o procedura pentru desenarea snake-ului 
make_snake proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'W'
	sub eax, 'W'
	lea esi, simboluri_2
	jmp draw

draw:
	mov ebx, size_simbol
	mul ebx
	mov ebx, size_simbol
	mul ebx
	add esi, eax
	mov ecx, size_simbol
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, size_simbol
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
	;verde-000FF00h-1
	;gri-0808080h-2
	;rosu- 0FF0000h-3
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	cmp byte ptr [esi], 1
	je simbol_pixel_verde
	cmp byte ptr [esi], 2
	je simbol_pixel_gri
	cmp byte ptr [esi], 3
	je simbol_pixel_rosu
	
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
	jmp simbol_pixel_next
	
simbol_pixel_verde:
	mov dword ptr [edi], 000FF00h
	jmp simbol_pixel_next
	
simbol_pixel_gri:
	mov dword ptr [edi], 0808080h
	jmp simbol_pixel_next
	
simbol_pixel_rosu:
	mov dword ptr [edi], 0FF0000h
	jmp simbol_pixel_next
	
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_snake endp

;un macro ca sa apelam mai usor desenarea simbolului
make_snake_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_snake
	add esp, 16
endm

;macro pt desenarea unei linii orizontale
line_horizontal macro x, y, len, color
local bucla_linie
	mov eax, y ;eax=y
	mov ebx, area_width
	mul ebx ;eax=y*area_width
	add eax, x ;eax=y*area_width + x
	shl eax, 2 ;eax=(y*area_width + x) *4
	add eax, area 
	mov ecx, len
bucla_linie:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_linie
endm

;macro pt desenarea unei linii verticale
line_vertical macro x, y, len, color
local bucla_linie
	mov eax, y ;eax=y
	mov ebx, area_width
	mul ebx ;eax=y*area_width
	add eax, x ;eax=y*area_width + x
	shl eax, 2 ;eax=(y*area_width + x) *4
	add eax, area 
	mov ecx, len
bucla_linie:
	mov dword ptr[eax], color
	add eax, area_width*4
	loop bucla_linie
endm

;un macro pt desenatrea unui dreptunghi
rectangle macro button_x, button_y, button_w, button_l, color ;w de la width si l de la lengh

	line_horizontal button_x, button_y, button_l, color
	line_horizontal button_x, button_y+button_w, button_l, color
	line_vertical button_x, button_y, button_w, color
	line_vertical button_x+button_l, button_y, button_w, color
	
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer
	cmp eax, 3
	jz evt_keyboard
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	
	make_snake_macro 'Z', area, 130, 130
	make_snake_macro 'Z', area, 500, 50
	make_snake_macro 'Z', area, 600, 400
	make_snake_macro 'Z', area, 30, 300
	make_snake_macro 'Z', area, 320, 230
	
	
	rectangle 21, 1, 20, 597, 03333FFh
	rectangle 24, 4, 14, 590, 03FF33CCh
	
	rectangle 22, 458, 20, 597, 03333FFh
	rectangle 25, 461, 14, 590, 0FF33CCh
	
	rectangle 618, 1, 473, 20, 03333FFh
	rectangle 621, 4, 467, 14, 0FF33CCh
	
	rectangle 1, 1, 473, 20, 03333FFh
	rectangle 4, 4, 467, 14, 0FF33CCh
	
	rectangle 150, 150, 180, 20, 03333FFh
	rectangle 153, 153, 174, 14, 0FF33CCh
	
	rectangle 470, 150, 180, 20, 03333FFh
	rectangle 473, 153, 174, 14, 0FF33CCh
	
	rectangle 270, 200, 20, 100, 03333FFh
	rectangle 273, 203, 14, 94, 0FF33CCh
	
	rectangle 270, 260, 20, 100, 03333FFh
	rectangle 273, 263, 14, 94, 0FF33CCh
	
	jmp afisare_litere
	
evt_keyboard:
	cmp byte ptr [ebp+arg2], 'A'
	je press_A
	
	cmp byte ptr [ebp+arg2], 'D'
	je press_D
	
	cmp byte ptr [ebp+arg2], 'S'
	je press_S
	
	cmp byte ptr [ebp+arg2], 'W'
	je press_W
	
press_A:	
	make_snake_macro 'Y', area, snake_x2, snake_y2
	mov ecx, snake_x1
	mov snake_x2, ecx
	mov ecx, snake_y1
	mov snake_y2, ecx
	make_snake_macro 'X', area, snake_x2, snake_y2
	mov ecx, snake_x
	mov snake_x1, ecx
	mov ecx, snake_y
	mov snake_y1, ecx
	make_snake_macro 'X', area, snake_x1, snake_y1
	mov ecx, snake_x
	sub ecx, size_simbol
	mov snake_x, ecx
	make_snake_macro 'W', area, snake_x, snake_y
	
	jmp verificare_coliziuni1
	
press_D:
	make_snake_macro 'Y', area, snake_x2, snake_y2
	mov ecx, snake_x1
	mov snake_x2, ecx
	mov ecx, snake_y1
	mov snake_y2, ecx
	make_snake_macro 'X', area, snake_x2, snake_y2
	mov ecx, snake_x
	mov snake_x1, ecx
	mov ecx, snake_y
	mov snake_y1, ecx
	make_snake_macro 'X', area, snake_x1, snake_y1
	mov ecx, snake_x
	add ecx, size_simbol
	mov snake_x, ecx
	make_snake_macro 'W', area, snake_x, snake_y

	jmp verificare_coliziuni1
	
press_S:
	make_snake_macro 'Y', area, snake_x2, snake_y2
	mov ecx, snake_x1
	mov snake_x2, ecx
	mov ecx, snake_y1
	mov snake_y2, ecx
	make_snake_macro 'X', area, snake_x2, snake_y2
	mov ecx, snake_x
	mov snake_x1, ecx
	mov ecx, snake_y
	mov snake_y1, ecx
	make_snake_macro 'X', area, snake_x1, snake_y1
	mov ecx, snake_y
	add ecx, size_simbol
	mov snake_y, ecx
	make_snake_macro 'W', area, snake_x, snake_y
	
	jmp verificare_coliziuni1

press_W:
	make_snake_macro 'Y', area, snake_x2, snake_y2
	mov ecx, snake_x1
	mov snake_x2, ecx
	mov ecx, snake_y1
	mov snake_y2, ecx
	make_snake_macro 'X', area, snake_x2, snake_y2
	mov ecx, snake_x
	mov snake_x1, ecx
	mov ecx, snake_y
	mov snake_y1, ecx
	make_snake_macro 'X', area, snake_x1, snake_y1
	mov ecx, snake_y
	sub ecx, size_simbol
	mov snake_y, ecx
	make_snake_macro 'W', area, snake_x, snake_y

	jmp verificare_coliziuni1

	
verificare_coliziuni1:
	cmp snake_x, 22
	jl game_over
	cmp snake_y, 22
	jl game_over
	cmp snake_x, 616
	jg game_over
	cmp snake_y, 450
	jg game_over
;verificare pentru coliziunea cu primul dreptunghi
	cmp snake_y, 134
	jg verificare1
	jmp verificare_coliziuni2
verificare1:
	cmp snake_y, 330
	jl verificare2
	jmp verificare_coliziuni2
verificare2:
	cmp snake_x, 134
	jg verificare3
	jmp verificare_coliziuni2
verificare3:
	cmp snake_x, 170
	jl game_over
	jmp verificare_coliziuni2
	
;verificare pentru coliziunea cu al doilea dreptunghi
verificare_coliziuni2:
	cmp snake_y, 130
	jg verificare4
	jmp verificare_coliziuni3
verificare4:
	cmp snake_y, 329
	jl verificare5
	jmp verificare_coliziuni3
verificare5:
	cmp snake_x, 454
	jg verificare6
	jmp verificare_coliziuni3
verificare6:
	cmp snake_x, 490
	jl game_over
	jmp verificare_coliziuni3
	
;coliziunea pentru al treilea dreptunghi
verificare_coliziuni3:
	cmp snake_y, 190
	jg verificare7
	jmp verificare_coliziuni4
verificare7:
	cmp snake_y, 220
	jl verificare8
	jmp verificare_coliziuni4
verificare8:
	cmp snake_x, 260
	jg verificare9
	jmp verificare_coliziuni4
verificare9:
	cmp snake_x, 370
	jl game_over
	jmp verificare_coliziuni4

;coliziunea pentru al patrulea dreptunghi
verificare_coliziuni4:
	cmp snake_y, 260
	jg verificare10
	jmp ver_mancare
verificare10:
	cmp snake_y, 280
	jl verificare11
	jmp ver_mancare
verificare11:
	cmp snake_x, 259
	jg verificare12
	jmp ver_mancare
verificare12:
	cmp snake_x, 371
	jl game_over
	jmp ver_mancare

ver_mancare:
	cmp snake_y, 127
	jg v1
	jmp v_m_2
v1:
	cmp snake_y, 148
	jl v2
	jmp v_m_2
v2:
	cmp snake_x, 127
	jg v3
	jmp v_m_2
v3:
	cmp snake_x, 148
	jl mananca1
	jmp v_m_2

v_m_2:
	cmp snake_y, 44
	jg v4
	jmp v_m_3
v4:
	cmp snake_y, 72
	jl v5
	jmp v_m_3
v5:
	cmp snake_x, 494
	jg v6
	jmp v_m_3
v6:
	cmp snake_x, 522
	jl mananca2
	jmp v_m_3

v_m_3:
	cmp snake_y, 395
	jg v7
	jmp v_m_4
v7:
	cmp snake_y, 420
	jl v8
	jmp v_m_4
v8:
	cmp snake_x, 595
	jg v9
	jmp v_m_4
v9:
	cmp snake_x, 620
	jl mananca3
	jmp v_m_4

v_m_4:
	cmp snake_y, 295
	jg v10
	jmp v_m_5
v10:
	cmp snake_y, 320
	jl v11
	jmp v_m_5
v11:
	cmp snake_x, 25
	jg v12
	jmp v_m_5
v12:
	cmp snake_x, 50
	jl mananca4
	jmp v_m_5

v_m_5:
	cmp snake_y, 225
	jg v13
	jmp v_m_6
v13:
	cmp snake_y, 240
	jl v14
	jmp v_m_6
v14:
	cmp snake_x, 315
	jg v15
	jmp v_m_6
v15:
	cmp snake_x, 340
	jl mananca5
	jmp v_m_6
	
v_m_6:

	jmp afisare_litere

mananca1:
	make_snake_macro 'Y', area, 130, 130
	add counter, 100
	jmp afisare_litere
	
mananca2:
	add counter, 100
	make_snake_macro 'Y', area, 500, 50
	jmp afisare_litere
	
mananca3:
	add counter, 100
	make_snake_macro 'Y', area, 600, 400 
	jmp afisare_litere
	
mananca4:
	add counter, 100
	make_snake_macro 'Y', area, 30, 300 
	jmp afisare_litere
	
mananca5:
	add counter, 100
	make_snake_macro 'Y', area, 320, 230 
	jmp afisare_litere
	
	
game_over:
	
	make_snake_macro 'Y', area, 130, 130
	make_snake_macro 'Y', area, 500, 50
	make_snake_macro 'Y', area, 600, 400
	make_snake_macro 'Y', area, 30, 300
	make_snake_macro 'Y', area, 320, 230
	
	
	rectangle 21, 1, 20, 597, 0FFFFFFh
	rectangle 24, 4, 14, 590, 0FFFFFFh
	
	rectangle 22, 458, 20, 597, 0FFFFFFh
	rectangle 25, 461, 14, 590, 0FFFFFFh
	
	rectangle 618, 1, 473, 20, 0FFFFFFh
	rectangle 621, 4, 467, 14, 0FFFFFFh
	
	rectangle 1, 1, 473, 20, 0FFFFFFh
	rectangle 4, 4, 467, 14, 0FFFFFFh
	
	rectangle 150, 150, 180, 20, 0FFFFFFh
	rectangle 153, 153, 174, 14, 0FFFFFFh
	
	rectangle 470, 150, 180, 20, 0FFFFFFh
	rectangle 473, 153, 174, 14, 0FFFFFFh
	
	rectangle 270, 200, 20, 100, 0FFFFFFh
	rectangle 273, 203, 14, 94, 0FFFFFFh
	
	rectangle 270, 260, 20, 100, 0FFFFFFh
	rectangle 273, 263, 14, 94, 0FFFFFFh
	
	make_text_macro 'G', area, 260, 230
	make_text_macro 'A', area, 270, 230
	make_text_macro 'M', area, 280, 230
	make_text_macro 'E', area, 290, 230

	make_text_macro 'O', area, 310, 230
	make_text_macro 'V', area, 320, 230
	make_text_macro 'E', area, 330, 230
	make_text_macro 'R', area, 340, 230
	jmp final_draw

evt_click:
	 
	make_snake_macro 'W', area, snake_x, snake_y
	make_snake_macro 'X', area, snake_x1, snake_y1
	make_snake_macro 'X', area, snake_x2, snake_y2
	
	jmp afisare_litere
	
evt_timer:

afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 40, 20
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 20
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 20
	
	;scriem un mesaj
	make_text_macro 'S', area, 20, 40
	make_text_macro 'N', area, 30, 40
	make_text_macro 'A', area, 40, 40
	make_text_macro 'K', area, 50, 40
	make_text_macro 'E', area, 60, 40
	
	cmp counter, 600
	je finish
	jmp final_draw 
finish:
	make_snake_macro 'Y', area, 130, 130
	make_snake_macro 'Y', area, 500, 50
	make_snake_macro 'Y', area, 600, 400
	make_snake_macro 'Y', area, 30, 300
	make_snake_macro 'Y', area, 320, 230
	
	
	rectangle 21, 1, 20, 597, 0FFFFFFh
	rectangle 24, 4, 14, 590, 0FFFFFFh
	
	rectangle 22, 458, 20, 597, 0FFFFFFh
	rectangle 25, 461, 14, 590, 0FFFFFFh
	
	rectangle 618, 1, 473, 20, 0FFFFFFh
	rectangle 621, 4, 467, 14, 0FFFFFFh
	
	rectangle 1, 1, 473, 20, 0FFFFFFh
	rectangle 4, 4, 467, 14, 0FFFFFFh
	
	rectangle 150, 150, 180, 20, 0FFFFFFh
	rectangle 153, 153, 174, 14, 0FFFFFFh
	
	rectangle 470, 150, 180, 20, 0FFFFFFh
	rectangle 473, 153, 174, 14, 0FFFFFFh
	
	rectangle 270, 200, 20, 100, 0FFFFFFh
	rectangle 273, 203, 14, 94, 0FFFFFFh
	
	rectangle 270, 260, 20, 100, 0FFFFFFh
	rectangle 273, 263, 14, 94, 0FFFFFFh
	
	make_text_macro 'C', area, 260, 230
	make_text_macro 'O', area, 270, 230
	make_text_macro 'N', area, 280, 230
	make_text_macro 'G', area, 290, 230
	make_text_macro 'R', area, 300, 230
	make_text_macro 'A', area, 310, 230
	make_text_macro 'T', area, 320, 230
	make_text_macro 'U', area, 330, 230
	make_text_macro 'L', area, 340, 230
	make_text_macro 'A', area, 350, 230
	make_text_macro 'T', area, 360, 230
	make_text_macro 'I', area, 370, 230
	make_text_macro 'O', area, 380, 230
	make_text_macro 'N', area, 390, 230
	make_text_macro 'S', area, 400, 230
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	push 0
	call exit
end start
