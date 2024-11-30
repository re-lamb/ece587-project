#once

#subruledef AREG
{   
    a0 => 0b000
    a1 => 0b001
    a2 => 0b010
    a3 => 0b011
    a4 => 0b100
    a5 => 0b101
    a6 => 0b110
    a7 => 0b111
    ra => 0b000
    sp => 0b111
}

#subruledef DREG
{   
    d0 => 0b000
    d1 => 0b001
    d2 => 0b010
    d3 => 0b011
    d4 => 0b100
    d5 => 0b101
    d6 => 0b110
    d7 => 0b111 
}

#subruledef disp8
{
    {label} => 
    {    
        assert((label & 0x0001) != 1, "branch offset misaligned!")
	    reladdr = (label - $) >> 1
	    assert(reladdr <=  0x7f, "word offset out of range!")
	    assert(reladdr >= !0x7f, "word offset out of range!")
	    reladdr`8
	}
}

#subruledef disp12
{
    {label} => 
    {    
        assert((label & 0x0001) != 1, " far branch offset misaligned!")
	    reladdr = (label - $) >> 1
	    assert(reladdr <=  0x7ff, "far word offset out of range!")
	    assert(reladdr >= !0x7ff, "far word offset out of range!")
	    reladdr`12
	}
}

#ruledef
{
    nop	    =>  0b0000_0000_0000_0000
    clrt	=>  0b0000_0000_0000_0001
    sett	=>  0b0000_0000_0000_0010
    nott	=> 	0b0000_0000_0000_0011
    rts		=>  0b0000_0000_0000_0100
    rte		=>  0b0000_0000_0000_0101
    intc	=>  0b0000_0000_0000_0110
    ints	=>  0b0000_0000_0000_0111
    ebreak	=>  0b0000_0000_0000_1000   ; sim only
    exit	=>  0b0000_0000_0000_1001   ; sim only
}

#ruledef
{
    movt	{m: DREG}	=>  0b0001_0 @ m @ 0b0000_0000
    dt		{m: DREG}	=>  0b0001_0 @ m @ 0b0000_0001
    dt		{m: AREG}	=>  0b0001_0 @ m @ 0b0000_0010
    braf	{m: AREG}	=>  0b0001_0 @ m @ 0b0000_0011
    bsrf	{m: AREG}	=>  0b0001_0 @ m @ 0b0000_0100
    jmp		{m: AREG}	=>  0b0001_0 @ m @ 0b0000_0101
    jsr		{m: AREG}	=>  0b0001_0 @ m @ 0b0000_0110
    sgz		{m: DREG}	=>  0b0001_0 @ m @ 0b0000_0111
    sgzu	{m: DREG}	=>  0b0001_0 @ m @ 0b0000_1000
}

#ruledef
{
    mov 	{n: DREG},{m: DREG}		=>	0b0010_0 @ m @ 0b0 @ n @ 0b0000
    mova 	{n: DREG},{m: AREG}		=>	0b0010_0 @ m @ 0b0 @ n @ 0b0001
    mova 	{n: AREG},{m: AREG}		=>	0b0010_0 @ m @ 0b0 @ n @ 0b0010
    mov 	{n: AREG},{m: DREG}		=>	0b0010_0 @ m @ 0b0 @ n @ 0b0011
    ld.b	@{n: AREG},{m: DREG}	=>	0b0010_0 @ m @ 0b0 @ n @ 0b0100
    ld.w	@{n: AREG},{m: DREG}	=>	0b0010_0 @ m @ 0b0 @ n @ 0b0101
    add		{n: DREG},{m: DREG}		=>	0b0010_0 @ m @ 0b0 @ n @ 0b1010
    addc	{n: DREG},{m: DREG}		=>	0b0010_0 @ m @ 0b0 @ n @ 0b1011
    addv	{n: DREG},{m: DREG}   	=>	0b0010_0 @ m @ 0b0 @ n @ 0b1100
    adda	{n: AREG},{m: AREG}   	=>	0b0010_0 @ m @ 0b0 @ n @ 0b1101
    adda	{n: DREG},{m: AREG}   	=>	0b0010_0 @ m @ 0b0 @ n @ 0b1110
    sub		{n: DREG},{m: DREG}   	=>	0b0010_0 @ m @ 0b0 @ n @ 0b1111
    subc	{n: DREG},{m: DREG}		=>	0b0010_0 @ m @ 0b1 @ n @ 0b0000
    subv	{n: DREG},{m: DREG}		=>	0b0010_0 @ m @ 0b1 @ n @ 0b0001
    suba	{n: AREG},{m: AREG}   	=>	0b0010_0 @ m @ 0b1 @ n @ 0b0010
    suba	{n: DREG},{m: AREG}   	=>	0b0010_0 @ m @ 0b1 @ n @ 0b0011
    and		{n: DREG},{m: DREG}   	=>	0b0010_0 @ m @ 0b1 @ n @ 0b0100
    tst		{n: DREG},{m: DREG}   	=>	0b0010_0 @ m @ 0b1 @ n @ 0b0101
    neg		{n: DREG},{m: DREG}   	=>	0b0010_0 @ m @ 0b1 @ n @ 0b0110
    negc	{n: DREG},{m: DREG}   	=>	0b0010_0 @ m @ 0b1 @ n @ 0b0111
    not		{n: DREG},{m: DREG}   	=>	0b0010_0 @ m @ 0b1 @ n @ 0b1000
    or		{n: DREG},{m: DREG}   	=>	0b0010_0 @ m @ 0b1 @ n @ 0b1001
    xor		{n: DREG},{m: DREG}   	=>	0b0010_0 @ m @ 0b1 @ n @ 0b1010
    seq		{n: DREG},{m: DREG}   	=>	0b0010_0 @ m @ 0b1 @ n @ 0b1011
    sge		{n: DREG},{m: DREG}		=>	0b0010_0 @ m @ 0b1 @ n @ 0b1100
    sgeu	{n: DREG},{m: DREG}		=>	0b0010_0 @ m @ 0b1 @ n @ 0b1101
    sgt		{n: DREG},{m: DREG}		=>	0b0010_0 @ m @ 0b1 @ n @ 0b1110
    sgtu	{n: DREG},{m: DREG}		=>	0b0010_0 @ m @ 0b1 @ n @ 0b1111
    exts	{n: DREG},{m: DREG}		=>	0b0010_1 @ m @ 0b0 @ n @ 0b0000
    extu	{n: DREG},{m: DREG}		=>	0b0010_1 @ m @ 0b0 @ n @ 0b0010
    sll		{n: DREG},{m: DREG}		=>	0b0010_1 @ m @ 0b0 @ n @ 0b0100
    srl		{n: DREG},{m: DREG}		=>	0b0010_1 @ m @ 0b0 @ n @ 0b0101
    sra		{n: DREG},{m: DREG}		=>	0b0010_1 @ m @ 0b0 @ n @ 0b0110
    rot		{n: DREG},{m: DREG}		=>	0b0010_1 @ m @ 0b0 @ n @ 0b0111
	mul   	{n: DREG},{m: DREG}     =>	0b0010_1 @ m @ 0b0 @ n @ 0b1001
	div   	{n: DREG},{m: DREG}     =>	0b0010_1 @ m @ 0b0 @ n @ 0b1100				
	mod   	{n: DREG},{m: DREG}     =>	0b0010_1 @ m @ 0b1 @ n @ 0b0101
}

#ruledef
{
    bclr 	#{imm: u5},{m: DREG}	=>	0b0011_0 @ m @ imm[4:4] @ 0b000 @ imm[3:0]
    bset 	#{imm: u5},{m: DREG}    =>	0b0011_0 @ m @ imm[4:4] @ 0b001 @ imm[3:0]
    bnot	#{imm: u5},{m: DREG}    =>	0b0011_0 @ m @ imm[4:4] @ 0b010 @ imm[3:0]
    btst 	#{imm: u5},{m: DREG}    =>	0b0011_0 @ m @ imm[4:4] @ 0b011 @ imm[3:0]
    slli	#{imm: u5},{m: DREG}    =>	0b0011_0 @ m @ imm[4:4] @ 0b100 @ imm[3:0]
    srli	#{imm: u5},{m: DREG}    =>	0b0011_0 @ m @ imm[4:4] @ 0b101 @ imm[3:0]
    srai	#{imm: u5},{m: DREG}    =>	0b0011_0 @ m @ imm[4:4] @ 0b110 @ imm[3:0]
    roti	#{imm: u5},{m: DREG}    =>	0b0011_0 @ m @ imm[4:4] @ 0b111 @ imm[3:0]
}


#ruledef
{
	lda		@({d: s5},{n: AREG}),{m: AREG}	    =>	0b0100_0 @ m @ d[4:4] @ n @ d[3:0]
	sta		{m: AREG},@({d: s5},{n: AREG})		=>	0b0100_1 @ m @ d[4:4] @ n @ d[3:0]
	ld.b	@({d: s5},{n: AREG}),{m: DREG}		=>	0b0101_0 @ m @ d[4:4] @ n @ d[3:0]
	st.b	{m: DREG},@({d: s5},{n: AREG})   	=>	0b0101_1 @ m @ d[4:4] @ n @ d[3:0]
	ld.w	@({d: s5},{n: AREG}),{m: DREG}   	=>	0b0110_0 @ m @ d[4:4] @ n @ d[3:0]
	st.w	{m: DREG},@({d: s5},{n: AREG})   	=>	0b0110_1 @ m @ d[4:4] @ n @ d[3:0]
}

#ruledef
{
    andi	#{imm: u8},d0	=> 0b1000_0000 @ imm
	ori		#{imm: u8},d0   => 0b1000_0001 @ imm
	xori	#{imm: u8},d0   => 0b1000_0010 @ imm
	tsti	#{imm: u8},d0   => 0b1000_0011 @ imm
	mului	#{imm: u8},d0   => 0b1000_0100 @ imm
	divui	#{imm: u8},d0   => 0b1000_0101 @ imm
	modi 	#{imm: u8},d0   => 0b1000_0110 @ imm	
	muli	#{imm: i8},d0   => 0b1000_1000 @ imm
	divi 	#{imm: i8},d0   => 0b1000_1001 @ imm
	bf		{label: disp8}  => 0b1000_1010 @ label
	bt		{label: disp8}	=> 0b1000_1011 @ label
}

#ruledef
{
	ld.w	@({d: s8},PC),{m: DREG}         => 0b1001_0 @ m @ d
	lda 	@({d: s8},PC),{m: AREG}	        => 0b1010_0 @ m @ d 
	addi	#{imm: i8},{m: DREG}			=> 0b1011_0 @ m @ imm
	addi	#{imm: i8},{m: AREG}			=> 0b1011_1 @ m @ imm
	seq		#{imm: i8},{m: DREG}			=> 0b1100_0 @ m @ imm
	movi 	#{imm: i8},{m: DREG}			=> 0b1100_1 @ m @ imm
}

#ruledef
{
    bra		{label: disp12} => 0b1110 @ label
    bsr		{label: disp12} => 0b1111 @ label
}

#ruledef	; pseudo ops
{
    ld.w    {label: disp8},{m: DREG}      	=> 0b1001_0 @ m @ label
    lda 	{label: disp8},{m: AREG}      	=> 0b1010_0 @ m @ label
	clr 	{m: DREG}					  	=>	asm { xor {m}, {m} }
}
