
 include 'include/franco.i'

_custom		equ	$dff000


		XREF ObjClip
		XREF FlipX
		XREF ObjInit
		XREF ObjInq
		XREF ObjSet
		XREF ObjLoadV
		XREF Sprite
		XREF ObjLoad


		jsr	Sprite
		rts


