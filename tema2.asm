%include "include/io.inc"

extern atoi
extern printf
extern exit

; Functions to read/free/print the image.
; The image is passed in argv[1].
extern read_image
extern free_image
; void print_image(int* image, int width, int height);
extern print_image

; Get image's width and height.
; Store them in img_[width, height] variables.
extern get_image_width
extern get_image_height

section .data
	use_str db "Use with ./tema2 <task_num> [opt_arg1] [opt_arg2]", 10, 0
        revient db "revient", 10, 0
        revient_size dd 7
        raspuns db "C'est un proverbe francais.", 10, 0
        raspuns_size dd 27
        
section .bss
    task:       resd 1
    img:        resd 1
    img_width:  resd 1
    img_height: resd 1

section .text
global main

; void bruteforce_singlebyte_xor (int img_width, int img_height, int *img)
; functia gaseste prin xorare folosind bruteforce mesajul criptat
bruteforce_singlebyte_xor:
    push ebp
    mov ebp, esp
    ; in registrul ecx vom retine cheia cu care se aplica XOR pe pixeli
    ; cheia va lua valori cuprinse intre 0 si 255
    xor ecx, ecx
xor_cheie:
    ; in eax se va retine adresa imaginii
    mov eax, [ebp + 16]
    ; in registrul edx se retine linia curenta 
    xor edx, edx   
    ; parcurg matricea de pixeli pe linii, de la stanga la dreapta
parcurgere_pixeli:
    ; in edi se retine coloana curenta
    xor edi, edi
parcurgere_coloana:
    ; in ebx se retine adresa pixelului curent
    mov ebx, [eax + edi * 4]
    ; XOR intre pixelul curent si cheie
    xor ebx, ecx
    push edx
    xor esi, esi   
    ; pentru pixelul curent verificam daca este o litera a cuvantului revient
    ; daca este, trecem la litera urmatoare din cuvant si la pixelul urmator
    ; si verificam iar, samd pana ajungem la finalul cuvantului
verificam_revient:
    mov dl, BYTE[revient + esi]
    movzx edx, dl
    cmp edx, ebx
    ; daca nu e egal continua parcurgerea matricei
    jne continue
    inc edi
    ; trecem la pixelul urmator si aplicam XOR
    mov ebx, [eax + edi * 4]
    xor ebx, ecx
    ; verificam daca este final de linie
    cmp edi, [ebp + 8]
    jge continue
    inc esi
    ; verificam daca s-a ajung la finalul cuvantului "revient"
    cmp esi, [revient_size]
    jl verificam_revient
    pop edx
    ; daca s-a ajuns la finalul cuvantului, inseamna ca pe linia curenta se 
    ; afla mesajul
    jmp mesaj_gasit 
continue: 
    ; restaurarea liniei de pe stiva   
    pop edx
    inc edi
    ; daca nu s-a ajuns la finalul coloanei, continuam parcurgerea pe coloana
    cmp edi, [ebp + 8]
    jle parcurgere_coloana
    push edx
    dec edi
    mov ebx, eax
    mov eax, 4
    mul edi
    add ebx, eax
    ; eax va fi adresa primului pixelului de pe linia urmatoare
    mov eax, ebx
    pop edx
    inc edx
    ; se continua parcurgerea pixelilor, trecand la linia urmatoare
    cmp edx, [ebp + 12]
    jl parcurgere_pixeli
    ; trecem la urmatoarea cheie
    inc ecx
    cmp ecx, 255
    jl xor_cheie   
mesaj_gasit:
    ; in ecx va fi retinuta cheia cu care s-a realizat decriptat mesajul
    ; in edx va fi retinuta linia pe care se gaseste mesajul
    ; in eax va fi retinuta adresa primului pixel de pe linia pe care
    ; se afla mesajul   
    leave 
    ret   

; void mesaj_linie (int cheie, int *adresa_linie_mesaj)
mesaj_linie:
    push ebp
    mov ebp, esp
    ; punem pe stiva registrii pe care ii modifica functia
    push eax
    push ebx
    push ecx
    push edx
    ; in eax se retine adresa primului pixel de pe linia cu mesajul
    mov eax, [ebp + 12]
    ; in edx se retine cheie cu care trebuie xorata linia
    mov edx, [ebp + 8]
    xor ecx, ecx
afisare_linie:
    ; in ebx se retine pixelul curent
    mov ebx, [eax + 4 * ecx]
    ; xor cu cheia data ca parametru
    xor ebx, edx
    ; verificam daca s-a ajuns la finalul mesajului, comparand cu terminatorul
    ; de sir
    cmp ebx, 0x0
    je final_propozitie
    PRINT_CHAR ebx
    inc ecx
    ; verificam daca s-a ajuns la finalul liniei
    cmp ecx, [img_width]
    jl afisare_linie 
final_propozitie: 
    ; restauram registrii de pe stiva
    pop edx
    pop ecx
    pop ebx
    pop eax
    leave
    ret

; void criptare_xor (int img_width, int img_height, int *img)
criptare_xor:
    push ebp
    mov ebp, esp
    ; apelam functia pentru a obtine cheia - ecx si linia - edx cu care a
    ; fost criptat mesajul initial
    push DWORD[ebp + 16]
    push DWORD[ebp + 12]
    push DWORD[ebp + 8]
    call  bruteforce_singlebyte_xor
    add esp, 12
    ; punem ecx, edx pe stiva
    push ecx 
    push edx    
    ; apelarea functiei in care aplicam XOR cu cheia gasita anterior
    push DWORD[ebp + 16]
    push ecx
    call xor_matrice
    add esp, 8
    ; restauram ecx, edx de pe stiva
    pop edx
    pop ecx
    push ecx    
    ; apelarea functiei ce adauga mesajul din "raspuns" pe linia urmatoare
    push DWORD[ebp + 16]
    push edx
    call adauga_mesaj
    add esp, 8
    pop ecx   
    ; apelarea functiei ce calculeaza noua cheie, va fi retinuta in eax
    push ecx
    call cheie_floor
    add esp, 4  
    ; apelarea functiei ce realizeaza XOR cu cheia nou gasita
    push DWORD[ebp + 16]
    push eax
    call xor_matrice
    add esp, 4 
    leave 
    ret
    
; void xor_matrice ( int cheie, int *img)
; functia aplica XOR cu cheia primita ca parametru pe matricea de pixeli
xor_matrice:
    push ebp
    mov ebp, esp
    ; voi calcula si retine in edx [img_width] * [img_height]
    mov ebx, [img_width]
    mov eax, [img_height]
    mul ebx
    mov edx, eax
    ; in eax retin adresa imaginii ce trebuie xorata
    mov eax, [ebp + 12]
    ; in edi retin cheia primita ca parametru
    mov edi, [ebp + 8]
    ; in ecx se va retine indicele curent al pixelui
    xor ecx, ecx    
    ; parcurg matricea pana la [img_width] * [img_height]
parcurgere:
    ; pixelul curent
    mov ebx, [eax + 4 * ecx]
    ; xor intre pixelul curent si cheia primita
    xor ebx, edi
    ; actualizarea pixelului
    mov [eax + 4 * ecx], ebx
    inc ecx
    cmp ecx, edx
    jl parcurgere
    leave
    ret    

; void adauga_mesaj (int linie, int *img)
; functia adauga mesajul din variabila raspuns pe linia urmatoare     
adauga_mesaj:
    push ebp
    mov ebp, esp
    ; in ebx retin adresa imaginii
    mov ebx, [ebp + 12]
    ; eax va fi linia primita ca parametru
    mov eax, [ebp + 8]
    ; incrementez linia pt a obtine adresa liniei pe care trebuie pus mesajul
    inc eax
    ; in eax voi retine adresa primului pixel de pe linia pe care trebuie
    ; inserat mesajul
    ; adresa = ebx + eax + [img_width] * 4 
    mul DWORD[img_width]
    mov edx, 4
    mul edx
    add eax, ebx
    xor ecx, ecx
    ; parcurg variabila "raspuns" byte cu byte pana la final si pun 
    ; caracterul curent in pixelul curent
mesaj:
    mov bl, BYTE [raspuns + ecx]
    movzx ebx, bl
    ; actualizez pixelul curent
    mov [eax + ecx * 4], ebx
    inc ecx
    cmp ecx, [raspuns_size]
    jl mesaj
    ; adaug terminatorul de sir 
    mov ebx, 0x0
    mov [eax + ecx * 4], ebx
    leave
    ret

; void cheie_floor (int vechea_cheie)
; functia calculeaza noua cheie dupa formula data
cheie_floor:
    push ebp
    mov ebp, esp
    ; in eax va fi retinuta cheia primita ca parametru
    mov eax, [ebp + 8]
    ; calculam cheia: cheie = floor ((2 * cheie_veche + 3) / 5) - 4
    mov ebx, 2
    mul ebx
    add eax, 3
    xor edx, edx
    mov ecx, 5
    ; eax o sa fie deimpartitul
    div ecx
    sub eax, 4
    ; rezultatul este retinut in eax
    leave
    ret

; void aplica_blur (int img_width, int img_height, int *img)
; functia aplica blur pe imaginea primita ca parametru
aplica_blur:
    push ebp
    mov ebp, esp
    ; apelarea functiei ce printeaza antetul imaginii, latimea, lungimea si 
    ; valoarea maxima     
    push 0x0
    push DWORD [ebp + 12]
    push DWORD [ebp + 8]
    call print_image
    add esp, 12
    ; in eax retin adresa imaginii
    mov eax, [ebp + 16]
    ; in edi retin height-ul imaginii
    mov edi, [ebp + 12]
    ; in esi retin width-ul imaginii
    mov esi, [ebp + 8]
    xor ecx, ecx
    ; afisez prima linie a matricei de pixeli care ramane nemodificata
afisare_prima_linie:
    ; in ebx e retinut pixelul curent
    mov ebx, [eax + ecx * 4]
    PRINT_DEC 4, ebx
    PRINT_STRING " "
    inc ecx
    cmp ecx, esi
    jl afisare_prima_linie    
    ; in eax va fi retinuta adresa primului pixel de pe linia a doua
    mov eax, 4
    mul esi
    mov ebx, [ebp + 16]
    add eax, ebx
    ; decrementez edi, esi pentru a parcurge pana la penultima coloana, 
    ; respectiv linie
    dec edi
    dec esi
    ; in edx va fi retinuta linia curenta
    xor edx, edx
    inc edx
linie_parc:
    ; in ecx va fi retinut coloana curenta
    xor ecx, ecx
    NEWLINE
    mov ebx, [eax + ecx * 4]
    ; afisez primul pixel de pe linie
    PRINT_DEC 4, ebx
    PRINT_STRING " "
    inc ecx
coloana_parc:
    ; pun pe stiva registrii ce vor fi modificati
    push eax
    push ecx
    push ebx
    push edx
    push esi
    push edi
    ; obtin valoarea pixelui curent si o pun pe stiva
    mov ebx, [eax + ecx * 4]
    push ebx 
    ; obtin valoarea pixelui din dreapta si o pun pe stiva
    mov ebx, [eax + ecx * 4 + 4] 
    push ebx
    ; obtin valoarea pixelui din stanga si o pun pe stiva
    mov ebx, [eax + ecx * 4 - 4] 
    push ebx
    ; obtin valoarea pixelui de sus
    push eax
    mov eax, 4
    mov ebx, [ebp + 8]
    mul ebx
    ; in ebx = 4 * width
    mov ebx, eax
    mov eax, 4
    mul ecx
    ; in edx = 4 * ecx (coloana curenta - ecx)
    mov edx, eax
    pop eax
    add eax, edx
    ; in esi = eax + 4 * ecx
    mov esi, eax
    ; in edi = 4 * width
    mov edi, ebx
    ; pixel_sus = eax + 4 * ecx - 4 * width
    sub eax, ebx
    mov ebx, [eax]
    ; pun valoarea pe stiva
    push ebx
    add esi, edi
    ; pixel_jos = eax + 4 * ecx + 4 * width
    mov eax, esi
    mov ebx, [eax]
    push ebx
    call medie_aritmetica
    add esp, 20
    ; afisez noul pixel
    PRINT_DEC 4, eax
    PRINT_STRING " "
    ; restaurarea registrilor de pe stiva
    pop edi
    pop esi
    pop edx
    pop ebx
    pop ecx
    pop eax
    ; trec la urmatorul pixel 
    mov ebx, [eax + ecx * 4]
    inc ecx    
    cmp ecx, esi
    jl coloana_parc
    mov ebx, [eax + ecx * 4]
    ; afisez ultimul pixel de pe linie, ce ramane nemodificat
    PRINT_DEC 4, ebx
    PRINT_STRING " "
    push edx
    inc ecx
    mov ebx, eax
    mov eax, 4
    mul ecx
    add ebx, eax
    ; eax va fi adresa primului pixel de pe urmatoarea linie
    ; eax = eax + 4 * width
    mov eax, ebx
    pop edx
    inc edx
    cmp edx, edi
    jl linie_parc
    NEWLINE
    ; afisez ultima linie a matricei de pixeli ce ramane nemodificata
    xor ecx, ecx   
afisare_ultima_linie:
    mov ebx, [eax + ecx * 4]
    PRINT_DEC 4, ebx
    PRINT_STRING " "
    inc ecx
    cmp ecx, esi
    jle afisare_ultima_linie
    NEWLINE
    leave
    ret  
    
; void medie_aritmetica  (int pixel_jos, int pixel_sus, int pixel_stanga,
; int pixel_dreapta, int pixel_curent)            
medie_aritmetica:
    push ebp
    mov ebp, esp
    xor ecx, ecx
    xor eax, eax
    mov ecx, 2
medie:    
    ; primul argument se afla la valoarea [ebp + 8], iar ultimul [ ebp + 28]
    add eax, [ebp + ecx * 4]
    inc ecx
    cmp ecx, 7
    jl medie
    ; in eax va fi retinuta suma pixelilor - deimpartitul
    xor edx, edx
    mov ebx, 5
    div ebx
    ; in eax se afla catul 
    leave
    ret
main:
    ; Prologue
    ; Do not modify!
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]
    cmp eax, 1
    jne not_zero_param

    push use_str
    call printf
    add esp, 4

    push -1
    call exit

not_zero_param:
    ; We read the image. You can thank us later! :)
    ; You have it stored at img variable's address.
    mov eax, [ebp + 12]
    push DWORD[eax + 4]
    call read_image
    add esp, 4
    mov [img], eax

    ; We saved the image's dimensions in the variables below.
    call get_image_width
    mov [img_width], eax

    call get_image_height
    mov [img_height], eax

    ; Let's get the task number. It will be stored at task variable's address.
    mov eax, [ebp + 12]
    push DWORD[eax + 8]
    call atoi
    add esp, 4
    mov [task], eax

    ; There you go! Have fun! :D
    mov eax, [task]
    cmp eax, 1
    je solve_task1
    cmp eax, 2
    je solve_task2
    cmp eax, 3
    je solve_task3
    cmp eax, 4
    je solve_task4
    cmp eax, 5
    je solve_task5
    cmp eax, 6
    je solve_task6
    jmp done

solve_task1:
    ; apelarea functiei pentru a gasi prin xorare mesajul criptat
    push DWORD[img]
    push DWORD[img_height]
    push DWORD[img_width]
    call bruteforce_singlebyte_xor
    add esp, 12    
    ;apelarea functiei pentru printarea mesajului gasit
    push eax
    push ecx
    call mesaj_linie
    add esp, 8    
    ; printarea cheii cu care s-a xorat mesajul
    NEWLINE
    PRINT_DEC 4, ecx
    NEWLINE
    ; printarea liniei pe care se gaseste mesajul
    PRINT_DEC 4, edx
    jmp done
    
solve_task2:
    ; apelarea functiei pentru aplicarea operatiei XOR pe matrice si 
    ; introducerea mesajului stocat in variabila raspuns
    push DWORD[img]
    push DWORD[img_height]
    push DWORD[img_width]
    call criptare_xor
    add esp, 12
    ; apelarea functiei pentru printarea matricei
    push DWORD[img_height]
    push DWORD[img_width]
    push DWORD[img]
    call print_image
    add esp, 12           
    jmp done
solve_task3: 
    ; TODO Task3            
    jmp done
solve_task4:
    ; TODO Task4
    jmp done
solve_task5:
    ; TODO Task5
    jmp done

; apelarea functiei care blureaza imaginea        
solve_task6:
    push DWORD[img]
    push DWORD[img_height]
    push DWORD[img_width]
    call aplica_blur
    add esp, 12
    jmp done

    ; Free the memory allocated for the image.
done:
    push DWORD[img]
    call free_image
    add esp, 4

    ; Epilogue
    ; Do not modify!
    xor eax, eax
    leave
    ret