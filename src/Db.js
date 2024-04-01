import {isEncrypted, buildEncryption} from './EncryptionTransformation';
import PouchDb from 'pouchdb-browser';
import { DecryptionError } from './encryption';
import MemoryAdapter from 'pouchdb-adapter-memory';

PouchDb.plugin(MemoryAdapter);


const ENCRYPTED_ID = "encryption-mark";
const mark = {
    _id: ENCRYPTED_ID,
    encryption: true,
    uuid: "2358ac53-feeb-49cf-afcd-84dcd0142a35" 
};

function isDecryptedMarkError(decryptedMark) {
    return !(Object.keys(decryptedMark).length === 4
        && decryptedMark._id == mark._id
        && decryptedMark.encryption
        && decryptedMark.uuid == mark.uuid);
}

class InvalidPassphrase extends Error {
    constructor(...params) {
        super(...params);
    
        if (Error.captureStackTrace) {
          Error.captureStackTrace(this, InvalidPassphrase);
        }
    
        this.name = "InvalidPassphrase";
      }
}

class NotEncrypted extends Error {
    constructor(...params) {
        super(...params);
    
        if (Error.captureStackTrace) {
          Error.captureStackTrace(this, NotEncrypted);
        }
    
        this.name = "NotEncrypted";
      }
}

class MaybeEncrypted extends Error {
    constructor(...params) {
        super(...params);
    
        if (Error.captureStackTrace) {
          Error.captureStackTrace(this, MaybeEncrypted);
        }
    
        this.name = "MaybeEncrypted";
      }
}

class NotEmpty extends Error {
    constructor(...params) {
        super(...params);
    
        if (Error.captureStackTrace) {
          Error.captureStackTrace(this, NotEmpty);
        }
    
        this.name = "NotEmpty";
      }
}

function getSyncUrl(settings) {
    const url = new URL(settings.url);
    url.username = settings.username;
    url.password = settings.password;
    return url.href;
}

function remoteDb(settings) {
    if (settings.url.startsWith('pouchdb://')) {
        return new PouchDb(settings.url.substr(10));
    }
    if (settings.url.startsWith('memory://')) {
        return new PouchDb(settings.url.substr(9), {adapter: 'memory'});
    }
    return new PouchDb(getSyncUrl(settings));
}

class Db {
    constructor(name) {
        this.name = name;
        this.db = new PouchDb(name);
    }

    async initialize() {
        try {
            await this.db.get(ENCRYPTED_ID);
            throw new MaybeEncrypted('We might have a encryption mark');
        } catch (e) {
            if (e.name == "not_found") {
                // ignore, happy path!
            } else {
                throw e;
            }
        }    
    }

    put(doc, ...params) {
        return this.db.put(doc, ...params);
    }

    get(id) {
        return this.db.get(id);
    }

    remove(...params) {
        return this.db.remove(...params);
    }

    allDocs(...params) {
        return this.db.allDocs(...params);
    }

    bulkDocs(...params) {
        return this.db.bulkDocs(...params);
    }

    destroy() {
        return this.db.destroy();
    }

    isEncrypted() {
        return false;
    }

    getPassphrase() {
        return null;
    }

    async encrypt(passphrase) {
        const result = await this.db.allDocs({include_docs: true});
        const docs = result.rows.map(row => {
            delete row.doc._rev;
            return row.doc;
        });
        await this.db.destroy();
        const encrypted = new EncryptedDb(this.name, passphrase);
        await encrypted.initialize();
        await encrypted.bulkDocs(docs);
        return encrypted;

    }

    decrypt() {
        // no-op
        return Promise.resolve();
    }

    oneShotSync(settings) {
        const remote = remoteDb(settings);
        return new Promise((resolve, reject) => {
            this.db.sync(remote)
                .on('complete', info => resolve(info))
                .on('error', error => reject(error))
        });
    }

}

class EncryptedDb extends Db {
    constructor(db, passphrase) {
        super(db);
        this.passphrase = passphrase;
        this.encryption = buildEncryption(passphrase);
    }

    async initialize() {
        const info = await this.db.info();
        if (info.doc_count === 0) {
            await this.db.put(await this.encryption.encrypt(mark));
        } else {
            try {
                const maybeEncrypted = await this.db.get(ENCRYPTED_ID);
                if (isEncrypted(maybeEncrypted)) {
                    const decryptedMark = await this.encryption.decrypt(maybeEncrypted);
                    if (isDecryptedMarkError(decryptedMark)) {
                        throw new InvalidPassphrase("The encryption passphrase is invalid");
                    }
                    // OK!
                } else {
                    throw new NotEncrypted("The encryption mark is not encrypted");
                }
            } catch (e) {
                if (e instanceof DecryptionError) {
                    console.error(e);
                    throw new InvalidPassphrase("The encryption passphrase is invalid");
                }
                if (e.name == "not_found") {
                    throw new NotEmpty("The DB has documents but no encryption mark");
                }
                throw e;
            }
        }
    }

    put(doc, ...params) {
        return this.encryption.encrypt(doc).then(enc => this.db.put(enc, ...params));
    }

    get(id) {
        return this.db.get(id).then(enc => this.encryption.decrypt(enc));
    }

    async allDocs(options) {
        let truncate = null;
        if (options && options.limit !== undefined) {
            truncate = options.limit;
            options.limit += 1;
        }
        const result = await this.db.allDocs(options);
        const rows = result.rows.filter(row => row.id != ENCRYPTED_ID);
        for (const row of rows) {
            if (row.doc) {
                row.doc = await this.encryption.decrypt(row.doc);
            }
        }
        result.rows = truncate ? rows.slice(0, truncate) : rows;
        return result;
    }

    async bulkDocs(docs, ...params) {
        const encrypted = [];
        for (const doc of docs) {
            encrypted.push(await this.encryption.encrypt(doc));
        }
        return this.db.bulkDocs(encrypted, ...params);
    }

    isEncrypted() {
        return true;
    }

    getPassphrase() {
        return this.passphrase;
    }

    async encrypt(passphrase) {
        if (passphrase == this.passphrase) {
            // no-op
            return Promise.resolve(this);
        }
        const result = await this.allDocs({include_docs: true});
        const docs = result.rows.map(row => {
            delete row.doc._rev;
            return row.doc;
        });
        await this.db.destroy();
        const encrypted = new EncryptedDb(this.name, passphrase);
        await encrypted.initialize();
        await encrypted.bulkDocs(docs);
        return encrypted;

    }

    async decrypt() {
        const result = await this.allDocs({include_docs: true});
        const docs = result.rows.map(row => {
            delete row.doc._rev;
            return row.doc;
        });
        await this.db.destroy();
        const decrypted = new Db(this.name);
        await decrypted.initialize();
        await decrypted.bulkDocs(docs);
        return decrypted;
    }
}



/**
 * 
 * @param {String} name
 * @param {String} passphrase
 * @returns {PouchDB.Database}
 */
async function buildDb(name, passphrase = null) {
    const db = passphrase === null ? new Db(name) : new EncryptedDb(name, passphrase);
    await db.initialize();
    return db;
}

function destroyDb(name) {
    const db = new PouchDb(name);
    return db.destroy();
}

export { buildDb, destroyDb, InvalidPassphrase, MaybeEncrypted, NotEncrypted, NotEmpty };

