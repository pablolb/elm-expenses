import { buildDb } from "./Db";

const SETTINGS_DB_NAME = 'elm_expenses_settings';
const DATA_DB_NAME = 'elm_expenses_local';

class InitResponse {}
class InitResponseFirstRun extends InitResponse {};
class InitResponseOk extends InitResponse {
    constructor(settings) {
        super();
        this.settings = settings;
    }
}

const SETTINGS_ID = 'settings';

function mapDocFromElm(doc) {
    doc._id = doc.id;
    doc._rev = doc.version;
    delete doc.id;
    delete doc.version;
    return doc;
}
  
function mapDocToElm(doc) {
    doc.id = doc._id;
    doc.version = doc._rev;
    delete doc._id;
    delete doc._rev;
    return doc;
}

function setRandomTxnId(txn) {
    if (txn._id != "") {
      return;
    }
    txn._id = (txn.date + "-" + window.crypto.randomUUID());
    delete txn._rev;
}

class DbPort {

    constructor() {
        this.settingsDbName = SETTINGS_DB_NAME;
        this.dataDbName = DATA_DB_NAME;
    }

    /**
     * This method is used for our test-only APIs
     */
    async openDbs() {
        this.settingsDb = await buildDb(this.settingsDbName);
        this.dataDb = await buildDb(this.dataDbName);
    }

    /**
     * @returns {InitResponse}
     */
    async initialize() {
        await this.openDbs();
        try {
            const settings = await this.settingsDb.get(SETTINGS_ID);
            return new InitResponseOk(mapDocToElm(settings));
        } catch (e) {
            if (e.name === 'not_found') {
                return new InitResponseFirstRun();
            } else {
                throw e;
            }
        }
    }

    async saveSettings(elmSettings) {
        const settings = {...elmSettings};
        settings.id = "settings";
        mapDocFromElm(settings);
        const resp = await this.settingsDb.put(settings);
        settings._rev = resp.rev;
        return mapDocToElm(settings);
    }

    async getTransactions() {
        const result = await this.dataDb.allDocs({include_docs: true, descending: true});
        return result.rows.map(row => mapDocToElm(row.doc));
    }

    async saveTransaction(elmTxn) {
        const txn = mapDocFromElm(elmTxn);
        setRandomTxnId(txn);
        const resp = await this.dataDb.put(txn);
        txn._rev = resp.rev;
        return mapDocToElm(txn);
    }

    async saveTransactions(elmTransactions) {
        const transactions = elmTransactions.map(t => {
            setRandomTxnId(t);
            return t;
        });
        await this.dataDb.bulkDocs(transactions);
    }

    async deleteTransaction(id, version) {
        await this.dataDb.remove(id, version);
    }

    /**
     * Destroys the databases.
     */
    async deleteAllData() {
        await this.settingsDb.destroy();
        await this.dataDb.destroy();
        this.settingsDb = null;
        this.dataDb = null;
    }
}

export { DbPort, InitResponse, InitResponseFirstRun, InitResponseOk };