:: Set project folder
cd "C:\users\fgaetan\downloads\amiga\harddrive\blitz2\copyblock\"
:: Copy all _win source files and at the same time convert end of line coding to unix style
::ConvertEOL unix HelloWorld_include_win.bb2 HelloWorld_include.bb2
ConvertEOL unix copyblock_win.bb2 copyblock.bb2
:: Show the WinUAE window


:: Run the ARexx script
:: (First bb2 file is main source file, the following are included
:: files. BLITZ: in this example is a virtual harddrive set up in
:: WinUAE set to a folder where I store my BB2 projects.)
WinUAEArexx blitzbasic2 1000 "dh0:BLITZ2/copyblock/copyblock.bb2"
BringToFront "[A1200314.uae] - winuae"