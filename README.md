# xcconfig-crypt

Allows user to have more-diffable encrypted `.xcconfig` files to better show what keys have changed in a diff by encrypting each value individually.

For now, the nonce is zeroes for repeatability / idempotency.  A nonce header would require some additional processing, but would offer additional protection.
(Using a dynamic nonce will result in a differing encrypted value every time the script is run, which is undesirable for `diff` purposes.)
