# Explanation at http://stackoverflow.com/questions/5212213/ruby-equivalent-of-php-openssl-seal/9428217#9428217
 
# Implementation
 
  class EnvelopeEncryption
 
    require "openssl"
    require "base64"
    
 
    # This method takes in plaintext and produces ciphertext and an
    # encrypted key which can be used to decrypt the ciphertext after it
    # itself has been decrypted.
    def encrypt(plaintext, rsa_key)
      # Generate a random symmetric key (K1) and use it to generate
      # ciphertext (CT) from our plaintext (PT)
      
      aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
      aes.encrypt
      # generate a random IV
      iv = aes.random_iv
      # generate the session key
      session_key = aes.random_key
      # encrypt the payload with session key
      ciphertext = aes.update(plaintext) + aes.final
 
      # Key wrapping: at this point we (A) have CT and K1. The only way
      # to decrypt the CT back to PT is via K1. To securely transfer K1
      # to our receiver (B), we encrypt it with the provided (public) key
      
      # encrypt the session key with the public key
      encrypted_session_key = rsa_key.public_encrypt(session_key)
 
      [ciphertext, iv, encrypted_session_key]
    end
 
    def decrypt(ciphertext, iv, encrypted_session_key, rsa_key)
      # Reversing #encrypt, we need to unwrap the envelope key (K1)
      session_key = rsa_key.private_decrypt(encrypted_session_key)
 
      # Now to get the plaintext
      aes = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
      aes.decrypt
      aes.iv = iv
      aes.key = session_key
      aes.update(ciphertext) + aes.final
    end
  end
