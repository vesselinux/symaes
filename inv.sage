# InvSubBytes(1) == SubBytes(1) - inverse transformation
# calculate inverses mod 256
# inv_invt() is the same as invt()

# SubBytes(2) - inverse affine transformation
# 
#   y0   00100101   x0   1
#   y1   10010010   x1   0 
#   y2   01001001   x2   1
#   y3   10100100   x3   0
#   y4 = 01010010 * x4 + 0 = inv_m * byte + inv_v
#   y5   00101001   x5   0
#   y6   10010100   x6   0
#   y7   01001010   x7   0
# 
# afft() globals
#IM = MatrixSpace(R,8,8)
#inv_m = IM([[0,0,1,0,0,1,0,1],[1,0,0,1,0,0,1,0],[0,1,0,0,1,0,0,1],[1,0,1,0,0,1,0,0],[0,1,0,1,0,0,1,0],[0,0,1,0,1,0,0,1],[1,0,0,1,0,1,0,0],[0,1,0,0,1,0,1,0]])
#inv_v  = inv_m.new_matrix (8,1,[1, 0, 1, 0, 0, 0, 0, 0])
inv_m = matrix([[0,0,1,0,0,1,0,1],
                [1,0,0,1,0,0,1,0],
                [0,1,0,0,1,0,0,1],
                [1,0,1,0,0,1,0,0],
                [0,1,0,1,0,0,1,0],
                [0,0,1,0,1,0,0,1],
                [1,0,0,1,0,1,0,0],
                [0,1,0,0,1,0,1,0]])
inv_v  = vector([1,0,1,0,0,0,0,0])
#inv_m = M([[P(0),P(0),P(1),P(0),P(0),P(1),P(0),P(1)],[P(1),P(0),P(0),P(1),P(0),P(0),P(1),P(0)],[P(0),P(1),P(0),P(0),P(1),P(0),P(0),P(1)],[P(1),P(0),P(1),P(0),P(0),P(1),P(0),P(0)],[P(0),P(1),P(0),P(1),P(0),P(0),P(1),P(0)],[P(0),P(0),P(1),P(0),P(1),P(0),P(0),P(1)],[P(1),P(0),P(0),P(1),P(0),P(1),P(0),P(0)],[P(0),P(1),P(0),P(0),P(1),P(0),P(1),P(0)]])
#inv_v  = inv_m.new_matrix (8,1,[P(1),P(0),P(1),P(0),P(0),P(0),P(0),P(0)])
# 
def inv_afft(in_byte):

    # result
    out_byte = []
    # store one byte of the state in a matrix with one column
    #vector_byte = inv_m.new_matrix(8,1,in_byte)
    vector_byte = vector(in_byte)
    # apply the affine transformation on one byte
    aff_vector_byte = inv_m*vector_byte + inv_v
    # convert the vector to list
    aff_byte = aff_vector_byte.list()
    #print "aff: aff_byte",aff_byte
    # append each bit of the transformed byte to the output state
    for ibit in range(0,8):
        out_byte.append(aff_byte[ibit])
    #print "aff: out_byte",out_byte
    #return
    return out_byte

# SubBytes
# Rijndael SubBytes transformation: invt() + afft()
# the input is a list of 128 elements
def inv_sb(in_state):
    # result
    out_state = []
    # cycle through all bytes of the state
    for ibyte in range(0,16):
        one_byte = in_state[8*ibyte:(8*ibyte+8)]
        #print "sbox on byte[",ibyte,"]",one_byte
        # apply the inverse affine transformation on the byte
        # aff_byte = inv_afft(in_state[8*ibyte:(8*ibyte+8)])
        aff_byte = inv_afft(one_byte)
        #print "afft",aff_byte
        # calculate the multiplicative inverse of the byte
        byte = invt(aff_byte[0:8])
        #print "invt",byte
        # print "out_byte[",ibyte,"]=\n",out_byte
        # append each bit of the transformed byte to the output state
        for ibit in range(0,8):
            out_state.append(byte[ibit])
        # print "ibyte[",8*ibyte,":",8*ibyte+8,"]=",ibyte[8*ibyte:8*ibyte+8]
    #return
    return out_state

# InvShiftRows
#
# left shift constants for each row
# C0 = 0; C1 = 1; C2 = 2; C3 = 3
# number of bytes in a row Nb = 4
def inv_sr(in_state):
    # results
    out_state = []
    # list of shift constants
    C = [C0,C1,C2,C3]
    # left shift each row by the four constant resp.
    for irow in range(0,4):
        for ibyte in range(0,4):
            # index of shifted byte
            ishift = irow*4 + ((ibyte+(Nb-C[irow])) % Nb) # (!)
            # copy the bits of the shifted byte
            for ibit in range(0,8):
                out_state.append(in_state[ishift*8 + ibit])
                #test
                #print "appended bit ",byte*8 + ibit
    return out_state    

# InvMixColumn
#
# MC globals
# 
# the inverse MixColumn matrix
# 
# [[0E, 0B, 0D, 09],
#  [09, 0E, 0B, 0D],
#  [0D, 09, 0E, 0B],
#  [0B, 0D, 09, 0E]] = 
# 
# [[z^3+z^2+z, z^3+z+1,   z^3+z^2+1, z^3+1    ],
#  [z^3+1,     z^3+z^2+z, z^3+z+1,   z^3+z^2+1],
#  [z^3+z^2+1, z^3+1,     z^3+z^2+z, z^3+z+1  ],
#  [z^3+z+1,   z^3+z^2+1, z^3+1,     z^3+z^2+z]] 
# 
#  because: 
# 
#  0x0E = b1110 = z^3+z^2+z
#  0x09 = b1001 = z^3+1
#  0x0D = b1101 = z^3+z^2+1
#  0x0B = b1011 = z^3+z+1
# 
# define a matrix space on the fraction field of polynomials in z mod rp with coeffs in P 
#IMZ = MatrixSpace(R,4,4)
#imz = IMZ ([[z^3+z^2+z, z^3+z+1,   z^3+z^2+1, z^3+1    ], [z^3+1,     z^3+z^2+z, z^3+z+1,   z^3+z^2+1], [z^3+z^2+1, z^3+1,     z^3+z^2+z, z^3+z+1  ], [z^3+z+1,   z^3+z^2+1, z^3+1,     z^3+z^2+z]])
imz = matrix([[z^3+z^2+z, z^3+z+1,   z^3+z^2+1, z^3+1    ], 
              [z^3+1,     z^3+z^2+z, z^3+z+1,   z^3+z^2+1], 
              [z^3+z^2+1, z^3+1,     z^3+z^2+z, z^3+z+1  ], 
              [z^3+z+1,   z^3+z^2+1, z^3+1,     z^3+z^2+z]])
def inv_mc(in_state):
    # result
    out_state = []
    # list of polynomials in z (zpolys stands for "polynomials in z")
    zpolys = []
    # represent each byte of the state as a polynomial in z
    for ibyte in range(0,16):
        ipoly = 0
        for ibit in range(0,8):
            ipoly+= (in_state[ibyte*8+ibit])*z^ibit
        #print "ipoly[",ibyte,"]",ipoly
        zpolys.append(ipoly)
    # put the polynomials of the state in 4x4 matrix sz (stands for "state-polynomial in z")
    #sz = imz.new_matrix(4,4,[zpolys[0],zpolys[1],zpolys[2],zpolys[3],zpolys[4],zpolys[5],zpolys[6],zpolys[7],zpolys[8],zpolys[9],zpolys[10],zpolys[11],zpolys[12],zpolys[13],zpolys[14],zpolys[15]])
    sz = matrix([[zpolys[0], zpolys[1], zpolys[2], zpolys[3]],
                 [zpolys[4], zpolys[5], zpolys[6], zpolys[7]],
                 [zpolys[8], zpolys[9], zpolys[10],zpolys[11]],
                 [zpolys[12],zpolys[13],zpolys[14],zpolys[15]]])
    # multiply matrices modulo the rijndael polynomial
    mc = (imz*sz) % rp
    # put the coefficients of the polynomials of mc in the output state
    for irow in range(0,4):
        for ibyte in range(0,4):
            #print "mc[",irow,",",ibyte,"]=", mc[irow][ibyte]
            mcpoly = mc[irow][ibyte].list() # WARNING!
            for ibit in range(0,8):
                # get the polynomial representing each byte (the "mcpoly" polynomial)
                #print "mcpoly[",ibit,"]",mcpoly[ibit]
                # put the 8 coefficents of mcpoly into 8 of the bits of the state
                out_state.append(mcpoly[ibit])
    return out_state

# Rijndael inverse round transformation
# y = inv_round(x) : y->ARK(y)->ky->iMC(ky)->my->iSR(my)->ry->iSB(ry)->x
def inv_round(y, rkey):

    # AddRoundKey - should be before InvMixColumn!
    print "AddRoundKey"
    ky = ark(y,rkey)
    # test
    #for ibit in range(0,128):
    #    print "ky[",ibit,"]",ky[ibit],"\n"

    # InvMixColumns
    print "InvMixColumns";
    my = inv_mc(ky)
    # test
    #for i in range(0,128):
    #    print "x[",i,"]=",x[i],"\n"

    # InvShiftRows
    print "InvShiftRows";
    ry = inv_sr(my)
    # test
    #print "shift rows test:"
    #for i in range(0,128):
    #    print "ry=[",i,"]=",ry[i],"\n"

    # InvSubBytes
    print "InvSubBytes"
    x = inv_sb(ry)
    # test 
    # for i in range(0,128):
    #    print "sy[",i,"]=",sy[i],"\n"

    return x
