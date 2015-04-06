; Name:				Steve Fulton and Dan Martin
; Course:			cpsc 370
; Instructor:			Dr. Conlon
; Date started:			February 7, 2015
; Last modification:		April 01, 2015
; Purpose of programe:		snake game.

	.CR	6502		; Assemble 6502 language
	.LI	on,toff		; Listing on, no timing included.
	.TF 	snake.prg,BIN	; Object file and format

iobase	= $8800
iostat	= iobase+1
iocmd	= iobase+2
ioctrl	= iobase+3

playerLocL	= $15
playerLocH	= $16
direction	= $17
prevDir		= $27	;previous direction
tempDir		= $28	;"goal" direction before verified correctness

foodL	= $18
foodH	= $19

headStartL = $0a00
headStartH = $0a01
snakeIndexPtrL = $20
snakeIndexPtrH = $21
screenPtrL = $22
screenPtrH = $23
snakeBodyLength = $24 ; length of the snake

; w - #$77
; a - #$61
; s - #$73
; d - #$64
up		= $10
down	= $11
left	= $12
right	= $13

tempL	= $20
tempH	= $21

	
		.OR $0300
start	
		cli
		jsr clearScreen
		;jsr initBorder
		jsr initInput
		jsr initPlayer
		jsr initFood
		jmp gameLoop
brk	
		
initInput
		cli
		lda #%00001011
		sta iocmd
		lda #%00011010
		sta ioctrl
		lda #$00
		sta iostat
		
		lda #$77
		sta up
		lda #$73
		sta down
		lda #$61
		sta left
		lda #$64
		sta right
		rts
		
initPlayer
		; Beyond zero page there is an array of pointers to screen memory.
		; These pointers represent the snakes position on screen.
		; In order to access each pointer each byte of the pointer
		; must be copied back to zero page then used to access the screen.
		; If the array is made in zero page then it will begin to overflow
		; to page two which causes bad things to happen.

		; init the first snake body pointer (starting in page 10)
		lda #$c8		;low byte of middle of screen
		sta headStartL
		sta screenPtrL
		lda #$71		;high byte of middle of screen
		sta headStartH
		sta screenPtrH
		
		lda #8 ; the snakes body starts at 4 long
		sta snakeBodyLength
		
		;draw the head to the screen
		ldy #0
		lda #$21
		sta (screenPtrL),y	;draws the player in start loc
		
		lda #$64			;starts the player moving right
		sta direction
		rts
		
initFood		;this doesn't really work
		ldy #0
		lda #$20
		;sta (foodL),y
		lda iocmd
		adc playerLocH
		lsr
		sbc playerLocL
		and #%00000011
		clc
		adc #$70
		sta foodH
		
		lda playerLocL
		sbc tempL
		rol
		and #%01111111
		sta foodL
		lda (foodL),y
		cmp #$21
		beq newPos
		lda #$2a
		sta (foodL),y
		rts

newPos	;i don't think this works. i was just screwing around
		iny
		lda (foodL),y
		cmp #$21
		beq newPos
		ldy #$00
		rts
		
gameLoop
		jsr getInput		; gets and checks input from user
		jsr updatePlayer	; updates the player position (does not draw)
		jsr checkCollision	; checks the new position for collisions
		jsr drawPlayer		; if no collisions - draw player
		jsr delay			; delays the game so its playable
		jmp gameLoop		; do it all again

; checks the users input for a specific direction
checkDirection	;compares the "goal" direction with wasd
		lda tempDir		;loads in the input from user
		cmp up			;compares to 'w'
		beq checkDown	;branches to opposite direction 'd'
		cmp down
		beq checkUp
		cmp left
		beq checkRight
		cmp right
		beq checkLeft
		rts
		
;if "goal" direction is opposite of current direction do nothing		
checkUp
		lda prevDir				; loads the previous direction
		cmp up					; compares to 'w'
		bne updateDirection		; if they arent equal we will updateDirection
		rts
checkDown
		lda prevDir
		cmp down
		bne updateDirection
		rts
checkLeft
		lda prevDir
		cmp left
		bne updateDirection
		rts
checkRight
		lda prevDir
		cmp right
		bne updateDirection
		rts

doneInput
		rts	; all done with getting and checking the input

; gets and checks for valid input		
getInput
		lda iostat			; read the ACIA status
		and #%00001000		; checking if its empty
		beq doneInput		; branches if there was no input
		lda iobase			; loads the input into accumulator
		sta tempDir			; stores it in a temp direction
		lda direction		; loads current direction
		sta prevDir			; stores it into previous direction
		jsr checkDirection	; jumps to checkDirection
		rts

; updates the snakes direction		
updateDirection	;updates previous and current direction
		lda direction	;loads current direction
		sta prevDir		;stores it into previous
		lda iobase		;loads input direction
		sta direction	;stores it into direction
		rts
	
; updates the players position (does not draw the player)	
updatePlayer
		; change all of the snake pointers
		jsr moveBody
		;update the head of the snake based on input
		lda direction	; loads direction into accumulator
		cmp up			; compare to 'w'
		beq moveUp		; branches if they are equal to move up
		cmp down
		beq moveDown
		cmp left
		beq moveLeft
		cmp right
		beq moveRight
		rts

; moves the snake up		
moveUp
		sec				; set the carry
		lda headStartL	; load headStartL into accumulator
		sbc #40			; subtract with carry decimal 40
		sta headStartL	; store it back into headStartL
		lda headStartH	; load headStartH into accumulator
		sbc #0			; subtract with carry decimal 0
		sta headStartH	; store it back into headStartH
		rts
moveDown
		clc				; clear the carry
		lda headStartL	; load headStartL into accumulator
		adc #40			; add with carry decimal 40
		sta headStartL	; store it back into headStartL
		lda headStartH
		adc #0
		sta headStartH
		rts
moveLeft
		sec
		lda headStartL
		sbc #1			; decimal 1 because we aren't moving a row
		sta headStartL
		lda headStartH
		sbc #0
		sta headStartH
		rts

moveRight
		clc
		lda headStartL
		adc #1
		sta headStartL
		lda headStartH
		adc #0
		sta headStartH
		rts
		
moveBody
		jsr erase ;erase the old tail position
		jsr shift
		rts
		
shift
		;push all of the snake but the tail onto the stack
		ldx #00
pushStack
		lda headStartL,x
		pha
		inx
		cpx snakeBodyLength
		bne pushStack
		
		ldx snakeBodyLength
		inx
bodyLoop
		pla
		sta headStartL,x
		dex
		cpx #01
		bne bodyLoop
		rts

erase
		ldy #0
		
		;make sure the snakeIndexPrt is pointing to the tail of the snake
		clc
		lda #$00
		adc snakeBodyLength	; add the body length
		sta snakeIndexPtrL
		lda #$0a
		adc #$00
		sta snakeIndexPtrH
		
		; init the screen pointer to the last snake pointer
		lda (snakeIndexPtrL),y
		sta screenPtrL
		iny
		lda (snakeIndexPtrL),y
		sta screenPtrH
		
		dey
		lda #$20
		sta (screenPtrL),y	;erases the player pos
		rts
		
checkCollision
		jsr borderCheck	; checks for snake collisions with the border
		jsr selfCheck	; checks collision with the snake itself
		jsr foodCheck	; checks for food collision
		rts

; checks for the snake colliding into itself		
selfCheck
		ldy #00
		lda headStartL
		sta screenPtrL	
		lda headStartH
		sta screenPtrH
		lda (screenPtrL),y
		cmp #$21
		beq gameOver
		rts
	
; checks for the snake colliding into the border	
borderCheck
		ldy #00
		lda headStartL
		sta screenPtrL
		lda headStartH
		sta screenPtrH
		lda (screenPtrL),y
		cmp #$00
		beq gameOver
		rts
	
; checks for the snake colliding into food	
foodCheck
		ldy #00
		lda headStartL
		sta screenPtrL
		lda headStartH
		sta screenPtrH
		lda (screenPtrL),y
		cmp #$2a
		beq eatFood
		rts
	
; eats the food if there was food collision	
eatFood
		jsr initFood
		clc
		lda #6
		adc snakeBodyLength
		sta snakeBodyLength
		rts

; draws the player based on the updated position of the player
drawPlayer
		ldy #00
		lda headStartL
		sta screenPtrL
		lda headStartH
		sta screenPtrH
		lda #$21
		sta (screenPtrL),y
		rts
	
; game is over. jump back to the start of the game	
gameOver
		jmp start
	
; clears the screen and makes the border	
clearScreen 
		lda #$29
		sta $03		;storing the low byte of the screen
		lda #$70
		sta $04		;storing the high byte of the screen
		ldy #0
		ldx #23
		
clear
		lda #$20	;loading space into accumulator
		sta ($03),y	;storing space into the appropriate screen address
		iny
		cpy #$26	;test if row was cleared
		bne clear
		
		;changing rows
		clc
		ldy #0	;reseting the y register
		lda $03	;loading the value in memory 03
		adc #40	;adding 40 to that value
		sta $03	;storing it back into memory 03
		lda $04
		adc #00
		sta $04
		dex		;decrementing x for the row counter
		cpx #$00 ;if the x register is 0 then we have cleared the screen
		bne clear	;branches if we aren't done clearing the screen
		rts
	
; delays the speed of the game so its playable and smooth	
delay
		txa
		pha
		tya
		pha
		ldy $ff
bigDelay
		ldx $ff
		tya
		pha
		lda #00
delayLoop
		dex
		ldy #$01
loop3	
		;sbc #10
		dey
		cpy #$00
		bne loop3
		
		cpx $00
		bne delayLoop
		pla
		tay
		dey
		cpy $00
		bne bigDelay
		
		pla
		tay
		pla
		tax
		rts
