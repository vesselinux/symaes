SYMAES: A Fully Symbolic Polynomial System Generator for AES-128

Usage Instructions

NOTE: Tested with Sage Version 4.1.1, Release Date: 2009-08-14

SYMAES constructs symbolic equations for the round function and the key schedule of AES-128. SYMAES is written in Python for the computer algebra system Sage http://www.sagemath.org/.

Files

"defs.sage"  # definition of the boolean polynomial ring
"fwd.sage"   # aes-128 round function for encryption  (forward transformation)
"inv.sage"   # aes-128 round function for decryption  (inverse transformation)
"kexp.sage"  # key schedule (key expansion)
"round.sage" # main

How to use

1 Put all files in one directory e.g. "/home/alice/symaes". 

2 Run Sage. 

alice@host:~/$ ./sage
----------------------------------------------------------------------
| Sage Version 4.1.1, Release Date: 2009-08-14                       |
| Type notebook() for the GUI, and license() for information.        |
----------------------------------------------------------------------

sage: 

3 In Sage type:

sage: load "/home/alice/symaes/round.sage"

One round of AES-128 is computed:

SubBytes
ShiftRows
MixColumns
AddRoundKey

The input and the key are stored in the symbolic variables x and k respectively. The output is stored in y. Each output bit y[i], 0 <= i < 128, represents a symbolic equation in the input variables x[i] and the key variables k[i]. 

4 Type y to see all equations

sage: y

Type y[i] to see the i-th equation (for any 0 <= i < 128). E.g. for i=3:

sage: y[3]

5 In order to compute the key expansion equations for one round type:

sage: kex = kexp(k)

The result is returned in the variable 'kex', which is a vector of 256 elements. kex[0],...,kex[127] represent the original AES key; kex[128],...,kex[255] represent each key bit of one round key as function of the bits of the original key.

Type kex to see all key equations

sage: kex

Type kex[i] to see the i-th equation (for any 0 <= i < 255). E.g. for i=128:

sage: kex[128]

End

contact: un3_14qliar@yahoo.com
