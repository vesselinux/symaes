#
# Test vectors for SYMAES round transformation and key schedule
# from the FIPS-197 document, p 35-36
#

# 
# Test the AES round transformation
# 
def test_round(x_hex, k_hex):

    a = state_char2bit_128(x_hex)
    k = state_char2bit_128(k_hex)
    b = round(a,k)
    y = state_bit2char_128(b)
    return y

# 
# Test the AES key schedule
# 
def test_kexp(k_hex):

    print "Number of round keys: ", Nr

    a = key_char2bit_128(k_hex)
    b = kexp(a)

    k_exp = []
    # Nr is the number of round keys to be computed from k_hex
    # Nr is a global veriable defined in kexp.sage
    for i in range(0,Nr):
        j = i*128
        k_exp.append(key_bit2char_128(b[j:j+128]))
    
    # Debug:
    # for i in range(0,Nr):
    #     print "k_exp[",i,"]",k_exp[i]

    return k_exp

#
# Test vector for the round transformation
# AES Example from FIPS 197 pg 35
# Plaintext = '00112233445566778899aabbccddeeff'
# Key = '000102030405060708090a0b0c0d0e0f'
# Use values from Round 1 
#
def tv_round():

    x_hex = '00102030405060708090a0b0c0d0e0f0' # input to round
    k_hex = 'd6aa74fdd2af72fadaa678f1d6ab76fe' # sub_key used for the round
    y_hex = '89d810e8855ace682d1843d8cb128fe4' # output of the round

    print "Test vector for the round transformation"
    print "x_hex ", x_hex
    print "k_hex ", k_hex
    print "y_hex ", y_hex

    y_test = test_round(x_hex,k_hex)

    print " y_hex", y_hex
    print "y_test", y_test
    print "(y_hex == y_test) is ", y_hex == y_test
    assert y_hex == y_test

#
# Test vector for the key schedule
# AES Example from FIPS 197 p 35
#
def tv_kexp():

    k_hex = '000102030405060708090a0b0c0d0e0f'
    # Expanded key from FIPS 197 p 35-36
    k_exp = ['000102030405060708090a0b0c0d0e0f', 
             'd6aa74fdd2af72fadaa678f1d6ab76fe',
             'b692cf0b643dbdf1be9bc5006830b3fe',
             'b6ff744ed2c2c9bf6c590cbf0469bf41',
             '47f7f7bc95353e03f96c32bcfd058dfd',
             '3caaa3e8a99f9deb50f3af57adf622aa',
             '5e390f7df7a69296a7553dc10aa31f6b',
             '14f9701ae35fe28c440adf4d4ea9c026',
             '47438735a41c65b9e016baf4aebf7ad2',
             '549932d1f08557681093ed9cbe2c974e',
             '13111d7fe3944a17f307a78b4d2b30c5']

    print "Test vector for the key schedule"
    print "k_hex ", k_hex

    k_exp_test = test_kexp(k_hex)

    for i in range(0,Nr):
        print "k_exp_test[",hex(i),"]",k_exp_test[i]
        print "k_exp_fips[",hex(i),"]",k_exp[i]
        assert(k_exp[i] == k_exp_test[i])
#    print "(k1_hex == k1_exp) is ", k1_hex == k1_exp

