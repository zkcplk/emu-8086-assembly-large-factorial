;-----------------------------
; Klavyeden girilen (en fazla 2 basamakl�) say�, 
; girildikten sonra ENTER tu�una bas�ld���nda fakt�riyelini hesaplayan 
; ve sonucunu ekrana ve dosyaya yazan assembly program kodu.
;----------------------------------------------------------------------

org 100h
jmp basla 

;---------------------
; De�i�kenler/Diziler 
;---------------------
sonuc db 160 dup(0)    ; en b�y�k sonu� (99 fakt�riyel), maksimum 156 karakter olacakt�r.
girilen dw 0
sayiGirMsg db 0dh,0ah,"Faktoriyeli alinacak sayiyi girin: $"
sonucMsg db 0dh,0ah,0dh,0ah,"Girilen sayinin faktoriyeli: $" 
dosyaMsg db 0dh,0ah,0dh,0ah,"Cikan sonuc, ...\vdrive\C\odevSonuc.txt dizinine yazdirildi!$" 
dosya db "C:\odevSonuc.txt",0 
dosyaHandle dw ? 
dosyaBuffer db 160 dup(' ')     
dosyaSize dw 0
 
basla:
    lea si,sonuc
    mov byte ptr [si],01h
    
    call sayiGirMesaji
    call girilenSayiyiBelirle
    
    mov dl,al 
    cmp dl,0       ; girilen say� 0 ise. 
    jne devam
    mov dl,01h     ; 0! = 1
    mov al,dl         
    
    devam:
        cmp dl,25               ; 25!'e kadar, hesaplamadan ��kan sonucun basamak say�s�, girilen say�dan d���k oluyor.
        jb yirmiBesAsagi        ; 25! sonras�, hesaplamadan ��kan sonucun basamak say�s�, girilen say�dan b�y�k oluyor.
        jmp yirmiBesveYukari    ; maksimum 99!'in sonucu, 156 basamakl� bir say� oluyor. 
            
    yirmiBesAsagi:
        mov girilen,ax          ; 25!'in alt�ndaki hesaplamalar i�in, girilen say�n�n kendisini verebiliriz.
        jmp faktoriyel          ; B�ylece 25! alt�ndaki hesaplamalar i�in daha az zaman harcam�� oluyoruz.
        
    yirmiBesveYukari:
        mov girilen,ax  
        add girilen,60
        
    faktoriyel:
        push dx
        call hesapla
        pop dx
        dec dl
        jnz faktoriyel 
        
    call ekranaYazdir 
    call dosyayaYazdir
hlt

;-------------
; Prosed�rler 
;-------------
sayiGirMesaji proc
	mov dx,offset sayiGirMsg
	mov ah,09h
	int 21h 
	ret
sayiGirMesaji endp

girilenSayiyiBelirle proc
	mov bx,0000h
	mov dx,0000h
	mov cx,000Ah
				
	yeniKarakterGirisi:
		push bx				; bx, girilmi� karakterler ile olu�turulan esas say�d�r.
		
		mov ah,01h			; burada klavyeden girilen karakter okunur.
		int 21h             ; al=girilen karakter
		
		mov ah,00h
		pop bx              ; �nceki bx, di�er i�lemlerden etkilenmesin diye stack belle�e at�l�r.
		
		cmp al,0dh			; girilen karakterin, enter olup olmad���na bak�l�r.
		jz tamamdir		    ; enter ise karakter girme i�lemi tamamlanm��t�r.
		sub al,30h			; enter de�ilse, girilen ascii karakter, say�sal de�ere �evrilir.
		
		push ax				; �nceki say� 10 ile �arp�l�r ve bir say� elde edilir, sonraki karakter o say�ya eklenir.
		mov ax,bx
		mul cx				
		mov bx,ax
		pop ax
		add bx,ax
		jmp yeniKarakterGirisi 
		
	tamamdir:
		mov ax,bx			; girilen esas say� bx'ten ax'e aktar�l�r.
	    ret
girilenSayiyiBelirle endp

hesapla proc
    cmp dl,01h
    jz sonucBir   
    
    lea si,sonuc
    mov dh,10
    mov bx,0000h
    mov cx,girilen 
    
    donDolasYineGel:
        mov al,[si]
        mov ah,00h
        mul dl
        add ax,bx
        div dh                  ; ��kan sonucu s�rekli 10'a b�lerek, her bir basamak de�erini elde ediyoruz.
        mov [si],ah             ; her bir basamak de�erini, sonuc dizimize birer eleman olarak ekliyoruz.
        inc si
        mov bl,al
        loop donDolasYineGel
    
    sonucBir:  
        ret
hesapla endp   

ekranaYazdir proc
    mov dx,offset sonucMsg
    mov ah,09h
    int 21h
           
    mov bp,0                    ; hesaplaman�n sonucu, basamak basamak sonuc dizisinde ters olarak kay�tl�d�r.
    lea si,sonuc                ; sonuc dizisini tersten okuyup, karakter karakter sonucu ekrana yazd�r�yoruz.
    mov di,si
    mov cx,girilen
    add di,cx
    dec di   
    
    zekiCIPLAK:
        cmp byte ptr [di],00h
        jne zkcplk
        dec di
        jmp zekiCIPLAK
    
    zkcplk:
        mov ah,02h
    
    yaz:
        mov dl,[di]
        add dl,30h  
        mov dosyaBuffer[bp],dl  ; dosyaya yazarken kullanmak i�in dosyaBuffer dizisini dolduruyoruz.
        inc bp
        int 21h 
        cmp si,di
        je bitis
        dec di
        loop yaz
    
    bitis: 
        mov dosyaSize,bp
        ret
ekranaYazdir endp  

dosyayaYazdir proc
    mov ah,3Ch                  ; yaz�lacak dosyay� olu�turuyoruz. 
    mov cx,0000h 
    mov dx,offset dosya
    mov ah,3Ch
    int 21h   
    
    mov dosyaHandle,ax          ; dosyaHandle ile art�k dosyaya her t�rl� i�lemi yapt�rabiliriz. 
    
    mov ah,40h                  ; dosyaya yazma i�lemi
    mov bx,dosyaHandle
    lea dx,dosyaBuffer 
    mov cx,dosyaSize
    int 21h                     ; C:\emu8086\vdrive\C dizininde odevSonuc.txt dosyas�na yaz�lacakt�r.
    
    mov ah,3eh                  ; burada dosyay� kapat�yoruz.
    mov bx,dosyaHandle
    int 21h  
    
    mov dx,offset dosyaMsg      ; dosyan�n ba�ar�yla yaz�ld���n� ekranda bildiriyoruz.
    mov ah,09h
    int 21h
    ret
dosyayaYazdir endp

; Zeki �IPLAK