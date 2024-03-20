import buildSample from './SampleData';

class DevApi {
    constructor(appPorts, dbPort, onDeleteAllData) {
        this.appPorts = appPorts;
        this.dbPort = dbPort
        this.onDeleteAllData = onDeleteAllData;
    }

    async saveSettings(settings) {
        const newSettings = await this.dbPort.saveSettings(settings);
        this.appPorts.gotInitOk.send(newSettings);
    }

    async saveTransaction(transaction) {
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
        this.onDeleteAllData();
    }
}

export { DevApi };