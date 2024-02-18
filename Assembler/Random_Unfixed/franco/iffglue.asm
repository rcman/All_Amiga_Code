* IFF library C to Assembler interface for the Manx C compiler (32 bit ints).
* Version 18.4, 28-Feb-90 by Christian A. Weber
* If you use Aztec C V3.6, you should assemble this file ('as IFFGlue.asm')
* and link it to all programs which use the IFF library.


		XREF	_IFFBase

		XDEF	_OpenIFF
_OpenIFF:	move.l	4(SP),a0
		move.l	_IFFBase,a6
		jmp	-30(a6)

		XDEF	_CloseIFF
_CloseIFF:	move.l	4(SP),a1
		move.l	_IFFBase,a6
		jmp	-36(a6)

		XDEF	_FindChunk
_FindChunk:	move.l	4(SP),a1
		move.l	8(SP),d0
		move.l	_IFFBase,a6
		jmp	-42(a6)

		XDEF	_GetBMHD
_GetBMHD:	move.l	4(SP),a1
		move.l	_IFFBase,a6
		jmp	-48(a6)

		XDEF	_GetColorTab
_GetColorTab:	move.l	4(SP),a1
		move.l	8(SP),a0
		move.l	_IFFBase,a6
		jmp	-54(a6)

		XDEF	_DecodePic
_DecodePic:	move.l	4(SP),a1
		move.l	8(SP),a0
		move.l	_IFFBase,a6
		jmp	-60(a6)

		XDEF	_SaveBitMap
_SaveBitMap:	move.l	a2,-(SP)
		movem.l	8(SP),a0/a1/a2
		move.l	20(SP),d0
		move.l	_IFFBase,a6
		jsr	-66(a6)
		move.l	(SP)+,a2
		rts

		XDEF	_SaveClip
_SaveClip:	movem.l	d4/a2,-(SP)
		movem.l	24(SP),d0-d4
		movem.l	12(SP),a0-a2
		move.l	_IFFBase,a6
		jsr	-72(a6)
		movem.l	(SP)+,d4/a2
		rts

		XDEF	_IffError
_IffError:	move.l	_IFFBase,a6
		jmp	-78(a6)

		XDEF	_GetViewModes
_GetViewModes:	move.l	4(SP),a1
		move.l	_IFFBase,a6
		jmp	-84(a6)

		XDEF	_NewOpenIFF
_NewOpenIFF:	move.l	4(SP),a0
		move.l	8(SP),d0
		move.l	_IFFBase,a6
		jmp	-90(a6)

		XDEF	_ModifyFrame
_ModifyFrame:	move.l	4(SP),a1
		move.l	8(SP),a0
		move.l	_IFFBase,a6
		jmp	-96(a6)
