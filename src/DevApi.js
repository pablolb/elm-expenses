import buildSample from './SampleData';
import { DbPort } from './DbPort';
import PouchDb from 'pouchdb-browser';

class DevApi {
    constructor(appPorts, dbPort, onNewDbPort) {
        this.appPorts = appPorts;
        this.dbPort = dbPort;
        this.onNewDbPort = onNewDbPort;
    }

    async saveSettings(settings, password) {
        await this.dbPort.assureDbsOpened();
        const newSettings = await this.dbPort.saveSettings(settings, password);
        this.appPorts.gotInitOk.send(newSettings);
    }

    async saveTransaction(transaction) {
        await this.dbPort.assureDbsOpened();
        await this.dbPort.saveTransaction(transaction);
    }

    async sendTransactionsToElm() {
        const transactions = await this.dbPort.getTransactions();
        this.appPorts.gotTransactions.send(transactions);
    }

    async importSample() {
        await this.dbPort.saveTransactions(buildSample());
    }

    async deleteAllData() {
        await this.dbPort.deleteAllData();
        const dbPort = new DbPort();
        await dbPort.openDbs();
        this.dbPort = dbPort;
        this.onNewDbPort(dbPort);
    }

    readRawDataFromDb(name) {
        const db = new PouchDb(name);
        return db.allDocs({include_docs: true}).then(results => results.rows.map(row => row.doc));
    }
}

export { DevApi };