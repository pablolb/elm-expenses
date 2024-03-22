import * as Encryption from './encryption';

const EXCLUDED = ['_id', '_rev'];
const DATA_KEY = 'crypt';
const ALL_KEYS = EXCLUDED.concat([DATA_KEY]);


function encryptDoc(encryption, doc) {
  const transformed = {};
  const toEncrypt = {};
  Object.keys(doc).forEach(function(field) {
    if (EXCLUDED.includes(field)) {
      transformed[field] = doc[field];
    } else {
      toEncrypt[field] = doc[field];
    }
  });
  return encryption.encrypt(JSON.stringify(toEncrypt)).then(data => {
    transformed[DATA_KEY] = data;
    return transformed;
  });
}

function decryptDoc(encryption, doc) {
  if (!(DATA_KEY in doc)) {
    return doc;
  }
  const transformed = {};
  Object.keys(doc).forEach(function(field) {
    if (field != DATA_KEY) {
      transformed[field] = doc[field];
    }
  });
  return encryption.decrypt(doc[DATA_KEY]).then(data => {
    return { ...transformed, ...JSON.parse(data) };
  });
}

/**
 * @typedef {Object} Encryption
 * @property {function} encrypt Encrypt a PouchDB document
 * @property {function} decrypt Decrypt a PouchDB document
 * 
 * @param {String} passphrase 
 * @returns {Encryption}
 */
function buildEncryption(passphrase) {
  const enc = Encryption.default(passphrase);
  return {
    encrypt: d => encryptDoc(enc, d),
    decrypt: d => decryptDoc(enc, d)
  }
}


function EncryptionTransformation(db, passphrase) {
    const encryption = Encryption.default(passphrase);
  
    db.transform({
      incoming: d => encryptDoc(encryption, d),
      outgoing: d => decryptDoc(encryption, d)
    });
  }

function isEncrypted(doc) {
  const docKeys = Object.keys(doc);
  return docKeys.length === ALL_KEYS.length && docKeys.every(k => ALL_KEYS.includes(k));
}
  
export { EncryptionTransformation as default, buildEncryption, encryptDoc, decryptDoc, isEncrypted };