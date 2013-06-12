# definition of the boolean polynomial ring
load "defs.sage"                
# halper functions
load "helperfu.sage"
# aes-128 round function for encryption  (forward transformation)
load "fwd.sage"                 
# aes-128 round function for decryption  (inverse transformation)
load "inv.sage"                 
# key schedule (key exapnsion)
load "kexp.sage"           
# test vectors from FIPS-197
load "test-vectors.sage"

# applying the aes-128 encryption round function
#y = round(x, k)
#print "equations from one round of Rijndael",y

# applying the aes-128 decryption round fnction
#WARNING: next does not terminate as it is not possible to compute the SubBytes operation because the complexity of the expressions is too high 
#y = inv_round(x, k) 

