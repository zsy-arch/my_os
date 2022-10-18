struc DAP
	.PacketSize 	resb 1
	.Reserved 		resb 1
	.BlockCount 	resw 1
	.BufferOffset 	resw 1
	.BufferSegment 	resw 1
	.LBNLow 		resd 1
	.LBNHigh 		resd 1
endstruc
