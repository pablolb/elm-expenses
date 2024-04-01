import buildSample from './SampleData';
import { DbPort } from './DbPort';
import PouchDb from 'pouchdb-browser';

class DevApi {
    constructor(appPorts, dbPort, onNewDbPort) {
        this.appPorts = appPorts;
        this.dbPort = dbPort;
        this.onNewDbPort = onNewDbPort;
        this.pageSize = 50;
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

    async saveTransactions(transactions) {
        await this.dbPort.assureDbsOpened();
        return this.dbPort.saveTransactions(transactions);
    }

    async sendTransactionsToElm() {
        const transactions = await this.dbPort.getTransactions({
            maxPageSize: this.pageSize
        });
        this.appPorts.gotTransactions.send(transactions);
    }

    async importSample() {
        await this.dbPort.saveTransactions(buildSample());
    }

    async deleteDataDb() {
        await this.dbPort.deleteDataDb();
        const dbPort = new DbPort();
        await dbPort.openDbs();
        this.dbPort = dbPort;
        this.onNewDbPort(dbPort);
    }

    async deleteAllData() {
        await this.dbPort.deleteAllData();
        const dbPort = new DbPort();
        await dbPort.openDbs();
        this.dbPort = dbPort;
        this.onNewDbPort(dbPort);
    }

    syncWithRemote(settings) {
        return this.dbPort.sync(settings)
    }

    importJson(json) {
        this.appPorts.gotE2EJsonLoaded.send(json);
    }

    readRawDataFromDb(name) {
        const db = new PouchDb(name);
        return db.allDocs({include_docs: true}).then(results => results.rows.map(row => row.doc));
    }

    setPageSize(pageSize) {
        this.pageSize = pageSize;
    }
}

export { DevApi };