class DecryptionError extends Error {
  constructor(...params) {
      super(...params);
  
      if (Error.captureStackTrace) {
        Error.captureStackTrace(this, DecryptionError);
      }
  
      this.name = "DecryptionError";
    }
}

const Helper = passphrase => {
    let keyPromise = null;
  
    async function getKey() {
      if (keyPromise) {
        return keyPromise;
      }
      const enc = new TextEncoder();
      const pwUtf8 = enc.encode(passphrase);
      const pwHash = await window.crypto.subtle.digest("SHA-256", pwUtf8);
      keyPromise = window.crypto.subtle.importKey(
        "raw",
        pwHash,
        "AES-GCM",
        true,
        ["encrypt", "decrypt"]
      );
      return keyPromise;
    }
  
    const fromHexString = hexString =>
      new Uint8Array(hexString.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
  
    const toHexString = bytes =>
      bytes.reduce((str, byte) => str + byte.toString(16).padStart(2, "0"), "");
  
    async function encrypt(data) {
      const enc = new TextEncoder();
      const key = await getKey();
      const encoded = enc.encode(data);
      const iv = window.crypto.getRandomValues(new Uint8Array(12));
      const ciphertext = await window.crypto.subtle.encrypt(
        {
          name: "AES-GCM",
          iv: iv
        },
        key,
        encoded
      );
      return `${toHexString(iv)}|${toHexString(new Uint8Array(ciphertext))}`;
    }
  
    async function decrypt(data) {
      const key = await getKey();
      const [iv, ciphertext] = data.split("|").map(s => fromHexString(s));
      try {
        let decrypted = await window.crypto.subtle.decrypt(
          {
            name: "AES-GCM",
            iv: iv
          },
          key,
          ciphertext.buffer
        );
        return new TextDecoder().decode(decrypted);
      } catch (e) {
        throw new DecryptionError("Could not decrypt: " + e.message);
      }
      
    }
  
    return {
      encrypt,
      decrypt
    };
  };
  
  export { Helper as default, DecryptionError };
  