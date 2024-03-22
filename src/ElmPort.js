import { InitResponseFirstRun, InitResponseOk, InitResponseEncrypted, InvalidPassphrase } from './DbPort';
import buildSample from './SampleData';

function buildGlue(app, dbPortIn) {

    let dbPort = dbPortIn;

    app.ports.initialize.subscribe(async () => {
        try {
          const resp = await dbPort.initialize();
          if (resp instanceof InitResponseFirstRun) {
            app.ports.gotFirstRun.send();
          } else if (resp instanceof InitResponseOk) {
            app.ports.gotInitOk.send(resp.settings);
          } else if (resp instanceof InitResponseEncrypted) {
            app.ports.gotEncryptedSettings.send();
          } else {
            console.error('Unknown response', resp);
            app.ports.gotInitError.send(`Unknown response ${JSON.stringify(resp)}`);
          }
        } catch (e) {
          console.error(e);
          app.ports.gotInitError.send(e.message);
        }
    });

    app.ports.decryptSettings.subscribe(async function(password) {
      try {
        await dbPort.openDbs(password);
        const settings = await dbPort.getSettings();
        app.ports.decryptedSettings.send(password);
        app.ports.gotInitOk.send(settings);
      } catch (e) {
        if (e instanceof InvalidPassphrase) {
          app.ports.decryptedSettingsError.send();
        } else {
          console.error(e);
          app.ports.gotInitError.send(e.message);
        }
      }
    });
    
      app.ports.getTransactions.subscribe(async () => {
        try {
          const transactions = await dbPort.getTransactions();
          app.ports.gotTransactions.send(transactions);
        } catch (e) {
          console.error(e);
          app.ports.gotTransactionsError.send(e.message);
        }
      });
    
      app.ports.saveSettings.subscribe(async (saveSettingsArgs) => {
        const [elmSettings, password] = saveSettingsArgs;
        try {
          const newElmSettings = await dbPort.saveSettings(elmSettings, password);
          app.ports.settingsSaved.send(newElmSettings);
        } catch (e) {
          console.error(e);
          app.ports.settingsSavedError.send(e.message);
        }
      });
    
      app.ports.saveTransaction.subscribe(async (txn) => {
        try {
          const saved = await dbPort.saveTransaction(txn);
          app.ports.transactionSaved.send(saved);
        } catch (e) {
          console.error(e);
          app.ports.transactionSavedError.send(e.message);
        }
      });
    
      app.ports.deleteTransaction.subscribe(async function(idAndVersion) {
        try {
          const [id, version] = idAndVersion;
          await dbPort.deleteTransaction(id, version);
          app.ports.transactionDeleted.send();
        } catch (e) {
          console.error(e);
          app.ports.transactionDeletedError.send(e.message);
        }
      });
    
      app.ports.deleteAllData.subscribe(async () => {
        await dbPort.deleteAllData();
        app.ports.deletedAllData.send();
      });
    
      app.ports.importSampleData.subscribe(async () => {
        await dbPort.saveTransactions(buildSample());
        app.ports.importedSampleData.send();
      });
    
      app.ports.showDeleteModal.subscribe(() => {
        $('.ui.modal')
          .modal({
            detachable: false,
            closable: false,
            onDeny: () => {
              app.ports.deleteCancelled.send();
              return true;
            },
            onApprove: () => {
              app.ports.deleteConfirmed.send();
              return true;
            }
          })
          .modal('show');
      });
    
      app.ports.showDeleteAllModal.subscribe(() => {
        $('.ui.modal')
          .modal({
            detachable: false,
            closable: false,
            onDeny: () => {
              app.ports.deleteAllCancelled.send();
              return true;
            },
            onApprove: () => {
              app.ports.deleteAllConfirmed.send();
              return true;
            }
          })
          .modal('show');
      });

    return {
        setDbPort(newDbPort) {
            dbPort = newDbPort;
        }
    };

}

export { buildGlue };