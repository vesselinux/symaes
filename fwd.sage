# version flag
nver = 2 #nver = 3

#
# inv_a = a^254 (mod rijndael-polynomial)
#
# a^254 = ((((((a^2)^4)^8)^16)^32)^64)^128 = a^2*a^4*a^8*a^16*a^32*a^64*a^128 where '*' is multiplication (mod rp)
# 2+4+8+16+32+64+128 = 254
#
# pseudo algorithm for computing (x^254 (mod rp))
# inv = 1
#   a = a^2 (mod rp) == a^2
# inv = inv*a (mod rp)                == a^2
#   a = a^2 (mod rp) == a^4 
# inv = inv*a (mod rp) == a^2*a^4     == a^6
#   a = a^2 (mod rp) == a^8
# inv = inv*a (mod rp) == a^6*a^8     == a^14
#   a = a^2 (mod rp) == a^16
# inv = inv*a (mod rp) == a^14*a^16   == a^30
#   a = a^2 (mod rp) == a^32
# inv = inv*a (mod rp) == a^30*a^32   == a^62
#   a = a^2 (mod rp) == a^64
# inv = inv*a (mod rp) == a^62*a^64   == a^126
#   a = a^2 (mod rp) == a^128
# inv = inv*a (mod rp) == a^126*a^128 == a^254
#
#def calculate_inverse(a):
def inverse(a):

    #a0 = a[0]; a1 = a[1]; a2 = a[2]; a3 = a[3]; a4 = a[4]; a5 = a[5]; a6 = a[6]; a7 = a[7]
    apoly = 0

    # represent a as a polynomial in z
    for i in range(0,8):
        apoly+=(a[i])*z^i
        #apoly+=(a[i])*z^(7-i)   # inverse order

    # initial
    inv_apoly = 1
    
    # ((((((((inv_poly^2)^2)^2)^2)^2)^2)^2)^2) = inv_poly^256
    power = 1
    for i in range(1,8):# 7 times lift a to the power of 2 (a^2,a^4,a^8,a^16,a^32,a^64,a^128)
        #print "calculate power of",2^i
        # lift a to the power of 2
        apoly = (apoly * apoly) % rp
        # multiply a to the accumulated product
        inv_apoly = (inv_apoly * apoly) % rp
        # next for printing the power to which a was just lifted

    #print "inv_apoly",inv_apoly
    inv_coeff = inv_apoly.list()

    # get the degree of the polynomial; if it is less than 7, padd the missing coeffs with zeros
    degree = inv_apoly.degree()     
    assert degree < 8

    # padd the "missing" coefficients from degree+1 up to 7 with zeros
    for icoeff in range(degree+1,8):
        inv_coeff.append(0)

    #print "inverse(): inv_coeff",inv_coeff
    # invert the order of coefficients
    #result = [None]*8
    #for i in range(0,8):
    #    result[7-i] = inv_coeff[i]
    #print "inverse(): result",result

    #return result
    return inv_coeff

# SubBytes(1) - inverse transformation
# calculate inverses mod 256
# invt() is just a wrapper for inverse()
def invt(in_byte):
     # result: inverses mod 256 of all  bytes of the state
     out_byte = []
     # calculate the inverse of one byte mod 256
     out_byte = inverse(in_byte)
     #return
     return out_byte

# SubBytes(2) - affine transformation
# 
#   y0   10001111   x0   1
#   y1   11000111   x1   1 
#   y2   11100011   x2   0
#   y3   11110001   x3   0
#   y4 = 11111000 * x4 + 0 = m * byte + v
#   y5   01111100   x5   1
#   y6   00111110   x6   1
#   y7   00011111   x7   0
# 
# afft() globals
#M = MatrixSpace(R,8,8)
#m = M ([[P(1),P(0),P(0),P(0),P(1),P(1),P(1),P(1)],[P(1),P(1),P(0),P(0),P(0),P(1),P(1),P(1)],[P(1),P(1),P(1),P(0),P(0),P(0),P(1),P(1)],[P(1),P(1),P(1),P(1),P(0),P(0),P(0),P(1)],[P(1),P(1),P(1),P(1),P(1),P(0),P(0),P(0)],[P(0),P(1),P(1),P(1),P(1),P(1),P(0),P(0)],[P(0),P(0),P(1),P(1),P(1),P(1),P(1),P(0)],[P(0),P(0),P(0),P(1),P(1),P(1),P(1),P(1)]])
#v = m.new_matrix (8,1,[P(1),P(1),P(0),P(0),P(0),P(1),P(1),P(0)])
m = matrix([[1,0,0,0,1,1,1,1],
             [1,1,0,0,0,1,1,1],
             [1,1,1,0,0,0,1,1],
             [1,1,1,1,0,0,0,1],
             [1,1,1,1,1,0,0,0],
             [0,1,1,1,1,1,0,0],
             [0,0,1,1,1,1,1,0],
             [0,0,0,1,1,1,1,1]])
v =   vector([1,1,0,0,0,1,1,0])# 0x63 = b0110'0011 
# 
def afft(in_byte):
    #print "in_byte", in_byte
    # result
    out_byte = []
    # store one byte of the state in a matrix with one column
    #vector_byte = m.new_matrix(8,1,in_byte)
    vector_byte = vector(in_byte)
    # apply the affine transformation on one byte
    aff_vector_byte = m*vector_byte + v
    # convert the vector to list
    aff_byte = aff_vector_byte.list()
    #print "aff: aff_byte",aff_byte
    # append each bit of the transformed byte list to the output state
    for ibit in range(0,8):
        out_byte.append(aff_byte[ibit])
    #print "aff: out_byte",out_byte
    #return
    return out_byte

# SubBytes
# Rijndael SubBytes transformation: invt() + afft()
# the input is a list of 128 elements
def sb(in_state):
    # result
    out_state = []
    # cycle through all bytes of the state
    for ibyte in range(0,16):
        # calculate the multiplicative inverse of the byte
        if nver == 2:           # if code version 2: calculate inverse
            #print in_state[8*ibyte:(8*ibyte+8)]
            inv_byte = invt(in_state[8*ibyte:(8*ibyte+8)])
        elif nver == 3:         # if code version 3: introduce new unknown for the inverse
            inv_byte = s[8*ibyte:(8*ibyte+8)]
        # apply the affine transformation on the byte
        out_byte = afft(inv_byte)
        #print "out_byte[",ibyte,"]=\n",out_byte
        # append each bit of the transformed byte to the output state
        for ibit in range(0,8):
            out_state.append(out_byte[ibit])
        # print "ibyte[",8*ibyte,":",8*ibyte+8,"]=",ibyte[8*ibyte:8*ibyte+8]
    #return
    return out_state

# this is SubByte applied on only one byte
def sbox(in_byte):
    # result
    out_byte = []
    # calculate the multiplicative inverse of the byte
    inv_byte = invt(in_byte)
    # apply the affine transformation on the byte
    out_byte = afft(inv_byte)
    # print "out_byte[",ibyte,"]=\n",out_byte
    #return
    return out_byte

# ShiftRows
#
# left shift constants for each row
C0 = 0; C1 = 1; C2 = 2; C3 = 3
# number of bytes in a row
Nb = 4
def sr(in_state):
    # results
    out_state = []
    # list of shift constants
    C = [C0,C1,C2,C3]
    # left shift each row by the four constant resp.
    for irow in range(0,4):
        for ibyte in range(0,4):
            # index of shifted byte
            ishift = irow*4 + ((ibyte+C[irow]) % Nb)
            # copy the bits of the shifted byte
            for ibit in range(0,8):
                out_state.append(in_state[ishift*8 + ibit])
                #test
                #print "appended bit ",byte*8 + ibit
    return out_state    

# MixColumn
# 
# [[02, 03, 01, 01],
#  [01, 02, 03, 01],
#  [01, 01, 02, 03],
#  [03, 01, 01, 02]] = 
# 
# [[z  ,z+1,1  ,1  ],
#  [1  ,z  ,z+1,1  ],
#  [1  ,1  ,z  ,z+1],
#  [z+1,1  ,1  ,z  ]]
# 
#  because: 
# 
#  0x02 = b0010 = z 
#  0x01 = b0001 = 1
#  0x01 = b0001 = 1
#  0x03 = b0011 = z+1
#
# MC globals 
# define a matrix space on the fraction field of polynomials in z mod rp with coeffs in P 
#MZ = MatrixSpace(R,4,4)
#mz = MZ ([[z,z+1,1,1],[1,z,z+1,1],[1,1,z,z+1],[z+1,1,1,z]])
mz = matrix ([[z,z+1,1,1],
              [1,z,z+1,1],
              [1,1,z,z+1],
              [z+1,1,1,z]])
def mc(in_state):
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
    #sz = mz.new_matrix(4,4,[zpolys[0],zpolys[1],zpolys[2],zpolys[3],zpolys[4],zpolys[5],zpolys[6],zpolys[7],zpolys[8],zpolys[9],zpolys[10],zpolys[11],zpolys[12],zpolys[13],zpolys[14],zpolys[15]])
    sz = matrix([[zpolys[0], zpolys[1], zpolys[2], zpolys[3]],
                 [zpolys[4], zpolys[5], zpolys[6], zpolys[7]],
                 [zpolys[8], zpolys[9], zpolys[10],zpolys[11]],
                 [zpolys[12],zpolys[13],zpolys[14],zpolys[15]]])
    # multiply matrices modulo the rijndael polynomial
    mc = (mz*sz) % rp
    # put the coefficients of the polynomials of mc in the output state
    for irow in range(0,4):
        for ibyte in range(0,4):
            #print "mc[",irow,",",ibyte,"]=", mc[irow][ibyte]
            mcpoly = mc[irow][ibyte].list() # WARNING!

            # get the degree of the polynomial; if it is less than 7, padd the missing coeffs with zeros
            degree = mc[irow][ibyte].degree()     
            assert degree < 8
            # pad the "missing" coefficients from degree+1 up to 7 with zeros
            for icoeff in range(degree+1,8):
                mcpoly.append(0)

            for ibit in range(0,8):
                # get the polynomial representing each byte (the "mcpoly" polynomial)
                #print "mcpoly[",ibit,"]",mcpoly[ibit]
                # put the 8 coefficents of mcpoly into 8 of the bits of the state
                out_state.append(mcpoly[ibit])
    return out_state

# AddRoundKey
def ark(in_state,rk):
    #result
    out_state = []
    # add round key
    for ibit in range(0,128):
        out_bit = in_state[ibit] + rk[ibit]
        out_state.append(out_bit)
    return out_state

# Rijndael/Lex round transformation
# y = round(x) : x->SB(x)->sx->SR(sx)->rx->MC(rx)->mx->ARK(mx)->y
def round(x, rkey):


    # SubBytes
    print "SubBytes"
    sx = sb(x)

    # ShiftRows
    print "ShiftRows";
    rx = sr(sx)

    # MixColumns
    print "MixColumns";
    mx = mc(rx)

    # AddRoundKey
    print "AddRoundKey"
    y = ark(mx,rkey)

    return y

# generating equations from one full round of Rijndael
def generate_round_eqs(x, k):

    eqlist = []

    rx = round(x, k)

    # calculate plaintext-ciphertext equations: p = c
    for ibit in range(0,128):
        eqlist.append(rx[ibit])

    # store p=c equations
    f = open('round.sage','w')
    #f.write("\n---full equations describing one round of LEX---\n")
    f.write("def lex_round_eqs(x,k):\n")
    f.write("\n    e = [None]*128\n")
    for ieq in range(0,128):
        f.write("\n")
        f.write("    e["+str(ieq)+"]=")
        f.write(str(eqlist[ieq]))
        #f.write(str(y[ieq]))
        f.write("\n")
    f.write("\n    return e\n")
    f.close()

    return eqlist

