# 
# Helper functions for transforming an AES state reprsented as a s character string 
# (e.g. a test vector copied directly from the FIPS 197 documnet) to a list of bits 
# that can be used as input to SYMAES and vice versa.
# 

# NOTE: bits are ordered like this: 
#
# 0x1 = [1,0,0,0] = a, so that a[0]=1,a[1]=0,a[2]=0,a[3]=0 
#
# Similarly, for 8-bit words: a[0] is the LSB, a[7] is the MSB:
#
# a0 = a[0]; a1 = a[1]; a2 = a[2]; a3 = a[3]; a4 = a[4]; a5 = a[5]; a6 = a[6]; a7 = a[7]
#
# Therefore 0x76 = 0111'0110 is represented as a = [0,1,1,0,1,1,1,0] so that
#
# a[0] = 0
# a[1] = 1
# a[2] = 1
# a[3] = 0
# a[4] = 1
# a[5] = 1
# a[6] = 1
# a[7] = 0
# 

# 
# Helper functions
# 

# INPUT : list of 4 bits b, where b[0] is MSB
# OUTPUT: integer from 0 to 15
def bit2hex_4(b):
    assert(len(b) == 4)
    if   b==[0, 0, 0, 0]: return 0
    elif b==[1, 0, 0, 0]: return 1
    elif b==[0, 1, 0, 0]: return 2
    elif b==[1, 1, 0, 0]: return 3
    elif b==[0, 0, 1, 0]: return 4
    elif b==[1, 0, 1, 0]: return 5
    elif b==[0, 1, 1, 0]: return 6
    elif b==[1, 1, 1, 0]: return 7
    elif b==[0, 0, 0, 1]: return 8
    elif b==[1, 0, 0, 1]: return 9
    elif b==[0, 1, 0, 1]: return 0xa
    elif b==[1, 1, 0, 1]: return 0xb
    elif b==[0, 0, 1, 1]: return 0xc
    elif b==[1, 0, 1, 1]: return 0xd
    elif b==[0, 1, 1, 1]: return 0xe
    elif b==[1, 1, 1, 1]: return 0xf
    else: print "ERROR bit2hex_4() cannot convert",b

# INPUT : list of 8 bits b, where b[0] is MSB
# OUTPUT: integer from 0 to 255
def bit2hex_8(b):
    assert(len(b) == 8)
    lo = bit2hex_4(b[0:4])
    hi = bit2hex_4(b[4:8])
    n = (16 * hi) + lo
    return n

# INPUT : integer from 0 to 15
# OUTPUT: list of 4 bits b, where b[0] is MSB
def hex2bit_4(n):
    assert(n < 16)
    if   n==0x0: return [0, 0, 0, 0]
    elif n==0x1: return [1, 0, 0, 0]
    elif n==0x2: return [0, 1, 0, 0] 
    elif n==0x3: return [1, 1, 0, 0]
    elif n==0x4: return [0, 0, 1, 0]
    elif n==0x5: return [1, 0, 1, 0]
    elif n==0x6: return [0, 1, 1, 0] 
    elif n==0x7: return [1, 1, 1, 0]
    elif n==0x8: return [0, 0, 0, 1]
    elif n==0x9: return [1, 0, 0, 1]
    elif n==0xA: return [0, 1, 0, 1]
    elif n==0xB: return [1, 1, 0, 1]
    elif n==0xC: return [0, 0, 1, 1]
    elif n==0xD: return [1, 0, 1, 1]
    elif n==0xE: return [0, 1, 1, 1]
    elif n==0xF: return [1, 1, 1, 1]
    else: print "ERROR hex2bit_4() cannot convert",n

# INPUT  : integer from 0 to 255
# OUTPUT : list of 8 bits b, where b[0] is MSB
def hex2bit_8(n):
    assert(n < 256)
    (hi, lo) = divmod(n, 16)
    b = hex2bit_4(lo) + hex2bit_4(hi)
    return b

#
# INPUT : a string of 32 characters representing 16 Bytes of the state of AES e.g. s_in = '00102030405060708090a0b0c0d0e0f0'
# OUTPUT: a bit vector x of 128 elements arranged accoring to the AES state (see above) e.g.
#
# Example: s_in = '00 10 20 30 |40 50 60 70 |80 90 a0 b0 |c0 d0 e0 f0'
#
# For input s_in = '00102030405060708090a0b0c0d0e0f0', 
# the output is the bit vector x[0:128] where s_in maps to x as follows:
# 
# 00 40 80 c0    x[0:8]    x[8:16]    x[16:24]   x[24:32] 
# 10 50 90 d0  = x[32:40]  x[40:48]   x[48:56]   x[56:64]
# 20 60 a0 e0    x[64:72]  x[72:80]   x[80:88]   x[88:96]
# 30 70 b0 f0    x[96:104] x[104:112] x[112:120] x[120:128]
#
def state_char2bit_128(s_in):

    x = []
    assert(len(s_in) == 32)
    
    index = 0
    i = 0
    # iterate over rows
    while(i < 8):
        j = 0
        # iterate over elements in a row
        while(j < 32):
            s_byte = '0x' + s_in[i+j] + s_in[i+j+1]
            lo = eval('0x' + s_in[i+j])
            hi = eval('0x' + s_in[i+j+1])
            x_byte = hex2bit_4(hi) + hex2bit_4(lo)
            index = index + 1
            x = x + x_byte
            # Debug
            # print "[",i*16+j,":",i*16+j+8,"]","w[",index,"]",s_byte,x_byte
            j = j + 8
        i = i + 2    
    return x

#
# INPUT : a bit vector x of 128 elements arranged accoring to the AES state (see above) e.g.
# OUTPUT: a string of 32 characters representing 16 Bytes of the AES state e.g. s_out = '00102030405060708090a0b0c0d0e0f0'
#
def state_bit2char_128(x):

    assert(len(x) == 128)

    s_out = ''
    i = 0
    # iterate over columns
    while(i < 32):
        j = 0
        # iterate over 
        while(j < 4):
            k = j*32 + i
            #x[k : k + 8]
            n = bit2hex_8(x[k : k + 8])
            s = hex(n)
            # strip off the leading '0x'
            if (s[0] == '0') and (s[1] == 'x'):
                s = s[2:len(s)]
            # if n is one digit, prepend a zero to make it two digits
            if n < 0x10:
                s = '0' + s                 
            s_out = s_out + s
            # Debug
            # print "x[",k,":",k+8,"]",s
            j = j + 1
        i = i + 8
    return s_out

#
# INPUT : a string of 32 characters representing 16 Bytes of the AES key e.g. s_in = '00102030405060708090a0b0c0d0e0f0'
# OUTPUT: a bit vector x of 128 elements arranged accoring to the AES key srrangement e.g.
#
# Example: s_in = '00 10 20 30 |40 50 60 70 |80 90 a0 b0 |c0 d0 e0 f0'
#
# For input s_in = '00102030405060708090a0b0c0d0e0f0', 
# the output is the bit vector x[0:128] where s_in maps to x as follows:
# 
# 00 10 20 30    x[0:8]    x[8:16]    x[16:24]   x[24:32] 
# 40 50 60 70  = x[32:40]  x[40:48]   x[48:56]   x[56:64]
# 80 90 a0 b0    x[64:72]  x[72:80]   x[80:88]   x[88:96]
# c0 d0 e0 f0    x[96:104] x[104:112] x[112:120] x[120:128]
#
def key_char2bit_128(s_in):

    x = []
    assert(len(s_in) == 32)
    
    index = 0
    i = 0
    while(i < 32):
        s_byte = '0x' + s_in[i] + s_in[i+1]
        lo = eval('0x' + s_in[i])
        hi = eval('0x' + s_in[i+1])
        x_byte = hex2bit_4(hi) + hex2bit_4(lo)
        index = index + 1
        x = x + x_byte
        i = i + 2    
    return x

#
# INPUT : a bit vector x of 128 elements arranged accoring to the AES key srrangement
# OUTPUT: a string of 32 characters representing 16 Bytes of the AES key e.g. s_in = '00102030405060708090a0b0c0d0e0f0'
#
def key_bit2char_128(x):

    assert(len(x) == 128)

    s_out = ''
    i = 0
    # iterate over columns
    while(i < 128):
        #x[k : k + 8]
        n = bit2hex_8(x[i : i + 8])
        s = hex(n)
        # strip off the leading '0x'
        if (s[0] == '0') and (s[1] == 'x'):
            s = s[2:len(s)]
        # if n is one digit, prepend a zero to make it two digits
        if n < 0x10:
            s = '0' + s                 
        s_out = s_out + s
        i = i + 8
    return s_out

