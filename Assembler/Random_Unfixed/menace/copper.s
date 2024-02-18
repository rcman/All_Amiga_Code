clist		DC.W	$0A01,$FF00
copperlist	DC.W	bplpt+0,$0000,bplpt+2,$0000
		DC.W	bplpt+8,$0000,bplpt+10,$0000
		DC.W	bplpt+16,$0000,bplpt+18,$0000
		DC.W	bplpt+4,$0000,bplpt+6,$0000
		DC.W	bplpt+12,$0000,bplpt+14,$0000
		DC.W	bplpt+20,$0000,bplpt+22,$0000
		DC.W	bplcon0,$6600
scroll.value	DC.W	bplcon1,$00FF,bpl1mod,$0036
		DC.W	bpl2mod,$002E,bplcon2,$0044
		DC.W	ddfstrt,$0028,ddfstop,$00D8
		DC.W	diwstrt,$1F78,diwstop,$FFC6

colours		DC.W	color+0,$0000,color+2,$0000
		DC.W	color+4,$0000,color+6,$0000
		DC.W	color+8,$0000,color+10,$0000
		DC.W	color+12,$0000,color+14,$0000
		DC.W	color+16,$0000,color+18,$0000
		DC.W	color+20,$0000,color+22,$0000
		DC.W	color+24,$0000,color+26,$0000
		DC.W	color+28,$0000,color+30,$0000
		DC.W	color+32,$0000,color+34,$0000
		DC.W	color+36,$0000,color+38,$0000
		DC.W	color+40,$0000,color+42,$0000
		DC.W	color+44,$0000,color+46,$0000
		DC.W	color+48,$0000,color+50,$0000
		DC.W	color+52,$0000,color+54,$0000
		DC.W	color+56,$0000,color+58,$0000
		DC.W	color+60,$0000,color+62,$0000

sprite		DC.W	sprpt+0,$0000,sprpt+2,$0000
		DC.W	sprpt+4,$0000,sprpt+6,$0000
		DC.W	sprpt+8,$0000,sprpt+10,$0000
		DC.W	sprpt+12,$0000,sprpt+14,$0000
		DC.W	sprpt+16,$0000,sprpt+18,$0000
		DC.W	sprpt+20,$0000,sprpt+22,$0000
		DC.W	sprpt+24,$0000,sprpt+26,$0000
		DC.W	sprpt+28,$0000,sprpt+30,$0000

		DC.W	$DF01,$FF00
		DC.W	bplcon1,$0000,bplcon0,$4200,ddfstrt,$0030
rastersplit2	DC.W	bplpt+0,$0000,bplpt+2,$0000
		DC.W	bplpt+4,$0000,bplpt+6,$0000
		DC.W	bplpt+8,$0000,bplpt+10,$0000
		DC.W	bplpt+12,$0000,bplpt+14,$0000
colours2	DC.W	color+20,$0000,color+30,$0000
		DC.W	color+2,$0000,color+4,$0000
		DC.W	color+6,$0000,color+8,$0000
		DC.W	color+10,$0000,color+12,$0000
		DC.W	color+14,$0000,color+16,$0000
		DC.W	color+18,$0000,color+22,$0000
		DC.W	color+24,$0000,color+26,$0000
		DC.W	color+28,$0000,color+0,$0000
		DC.W	bpl1mod,$0000,bpl2mod,$0000
		DC.W	$DF01,$FF00,intreq,$8010
		DC.W	$FFFF,$FFFE
