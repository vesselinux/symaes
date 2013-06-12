#load "defs.sage"
# rijndael RotByte
#in_word  = [byte[0], byte[1], byte[2], byte[3]]
def rotbyte (in_word):#in_word is composed of 4 bytes
    #out_word = [byte[1], byte[2], byte[3], byte[0]]
    out_word = []
    #copy bytes 1,2 and 3
    for ibit in range(8,32):
        #copy byte bit by bit
        out_word.append(in_word[ibit])
    #copy byte 0 in the end of out word
    for ibit in range(0,8):
        out_word.append(in_word[ibit])
    return out_word

# rijndael SubByte
#in_word  = [byte[0], byte[1], byte[2], byte[3]]
def subword (in_word):
    #print "subword(): in_word",in_word
    #out_word = [sbox(byte[0]), sbox(byte[1]), sbox(byte[2]), sbox(byte[3])]
    out_word = []
    for ibyte in range(0,4):
        byte = []
        #copy one input byte
        for ibit in range(0,8):
            byte.append(in_word[ibyte*8 + ibit])
        #apply the sbox on the byte
        sbyte = sbox(byte)
        #copy the sbox-ed byte to the out word
        for ibit in range(0,8):
            out_word.append(sbyte[ibit])
    return out_word

# rijndael Rcon
# the input is the number of the round for which a round constnt needs to be returned e.g. RC[ncon]
# the output is 32 bits long (1 word) equal to the rijndael round constant
def rcon (nround):
    # the changing part of the round constant (1 byte = 8 bits)
    RC = []
    #the round constant (32 bits = 4 bytes = 1 word) : rcon = [RC[nround], 0x00, 0x00, 0x00]
    rcon = []
    # 0x00
    zero = [0,0,0,0,0,0,0,0]
    # 0x01
    one = [1,0,0,0,0,0,0,0]
    # initialize RC with 1
    for ibit in range(0,8):
        RC.append(one[ibit])

    # calculate round constants for any round bigger than 1 (for round 1 RC==1)
    if (nround > 1):
       for icon in range(2,nround+1):
           # write RC as a polynomial in z
           rcpoly = 0
           for ibit in range(0,8):
               rcpoly+= (RC[ibit])*z^ibit
           # mutliply the RC polynomial by z (mod rijndael-polynomial)
           rcpoly = (rcpoly * z) % rp
           # Debug:
           # print "rcpoly",rcpoly
           rcpoly_coeffs = rcpoly.list()

           degree = rcpoly.degree()     
           assert degree < 8

           # padd the "missing" coefficients from degree+1 up to 7 with zeros
           for icoeff in range(degree+1,8):
               rcpoly_coeffs.append(0)

           # store the coefficients of the new RC polynomial as the new round constant
           for ibit in range(0,8):
               RC[ibit] = rcpoly_coeffs[ibit]
           # Debug
           # print "RC[",icon,"]",RC

    # out_word = [RC,zero,zero,zero]    
    for ibit in range(0,8):
        # copy the round constant first
        rcon.append(RC[ibit])
    # copy three times the zero byte
    for ibyte in range(0,3):
        for ibit in range(0,8):
            rcon.append(zero[ibit])

    # return the word of te calculated round constant
    return rcon

# k is the initial key (128 bits)
# w is the expanded key (128 bits X 11 rounds)
# the first 128 bits of w are equal to k
#
# kexp globals - number of rounds
Nr = 2
#Nr = 11
#
def kexp(k):

    # Debug
    # print "k",k
 
    # expanded key
    w = []
    # derive key w[0]: copy the original key to w
    for ibyte in range(0,16):
        for ibit in range(0,8):
            w.append(k[ibyte*8 + ibit])

    # derive keys: w[1]...w[Nr]
    # one Word is composed of 4 Bytes; a key is equal to 16 Bytes i.e. 4 Words
    # 4*(Nr+1) - for every round we have 4 words, so we have 4 times the number of rounds Nr or 4*Nr words in total; 
    # the total number of rounds is Nr; we add 1 to Nr i.e. (Nr+1), so that iword counts until Nr including Nr
    # we start counting from 4, because words 0,1,2 and 3 were calculated previously (they contain the original key)
    for iword in range (4,4*(Nr+1)): 
        # Debug
        print "iword",iword
        #for ibyte in range(iword*4,iword*4+4)
        temp_word = []
        # store the previous 4 bytes from the previous key in temp
        for ibyte in range((iword-1)*4,((iword-1)*4)+4):#(iword*4) gets the the sequence number of the byte at position (iword-1)
            for ibit in range(0,8):
                temp_word.append(w[ibyte*8 + ibit])
        # Debug
        # print "temp_word     ", temp_word
        # every 4-th word is treated differently than the others because
        # every 4-th word is the 1-st word of the next expanded key
        if ((iword % 4) == 0):
            rot_word = rotbyte(temp_word)
            # Debug
            # print "After RotWord ", rot_word
            sub_word = subword(rot_word)
            # Debug
            # print "After SubWord ", sub_word
            # print iword,"/ 4",iword/4
            rc = rcon(iword / 4)
            # calculate the XOR of the word sub_word(rot_word) with the word of the round constant
            for ibit in range(0,32):
                temp_word[ibit] = sub_word[ibit] + rc[ibit]
        # finally XOR temp_word with the word 4 positions before
        # for ibyte in range(iword*4,iword*4+4):
        for ibit in range(0,32):
            # (iword-4) gives the position of the word 4 places back
            # (iword-4)*4 gives the position of the first byte of the word 4 places back (1 word = 4 bytes)
            # (((iword-4)*4)*8) gives the position of the first bit of the first byte of the word 4 places back (1 byte = 8 bits)
            w.append(w[(((iword-4)*4)*8)+ibit] + temp_word[ibit]);
            #print iword-4, iword-1

    return w

#for i in range(0,120):
#for i in range(0,112):
#for i in range(0,128):
#    k[i] = randint(0,1)

#for i in range(0,(Nr+1)*128):
#    print "w[",i,"]",w[i]
#w = kexp(k)

