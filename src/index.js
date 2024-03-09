import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import PouchDb from 'pouchdb-browser';

const exposeJsApi = process.env.ELM_APP_EXPOSE_TEST_JS == 'true';


async function main() {
  let db = new PouchDb('elm_expenses_local');
  let settingsDb = new PouchDb('elm_expenses_settings');

  const app = Elm.Main.init({
    node: document.getElementById('root')
  });

  async function loadSettings() {
    try {
      const settings = await settingsDb.get('settings');
      await sendSettingsToElm(settings);
      await sendTransactionsToElm();
    } catch (e) {
      if (e.name == "not_found") {
        app.ports.gotFirstRun.send();
      } else {
        console.log("Error loading settings", e);
      }
    }
  }

  async function saveSettings(elmSettings) {
    const settings = {...elmSettings};
    settings._id = "settings";
    if (settings.version != "") {
      settings._rev = settings.version;
    }
    delete settings.version;
    const resp = await settingsDb.put(settings);
    settings._rev = resp.rev;
    await sendSettingsToElm(settings);
  }
  app.ports.saveSettings.subscribe(saveSettings);


  async function saveTransaction(elmTxn) {
    const txn = mapTxnFromElm(elmTxn);
    setRandomId(txn);
    await db.put(txn);
    await sendTransactionsToElm(); 
  }
  app.ports.saveTransaction.subscribe(saveTransaction);

  app.ports.deleteTransaction.subscribe(async function(idAndVersion) {
    const [id, version] = idAndVersion;
    await db.remove(id, version);
    await sendTransactionsToElm();
  });

  async function deleteAllData() {
    await db.destroy();
    db = new PouchDb('elm_expenses_local');
    await settingsDb.destroy();
    settingsDb = new PouchDb('elm_expenses_settings');
    await sendTransactionsToElm();
  }

  app.ports.deleteAllData.subscribe(deleteAllData);

  async function importSampleData() {
    const toImport = sample.map(t => {
      setRandomId(t);
      return t;
    });
    await db.bulkDocs(toImport);
    await sendTransactionsToElm(); 
  }
  app.ports.importSampleData.subscribe(importSampleData);

  async function sendTransactionsToElm() {
    const result = await db.allDocs({include_docs: true, descending: true});
    app.ports.gotTransactions.send(result.rows.map(row => mapTxnToElm(row.doc)));
  }

  async function sendSettingsToElm(settings) {
    settings.version = settings._rev;
    delete settings._rev;
    delete settings.id;
    app.ports.gotSettings.send(settings);
  }

  async function putTransaction(txnInput) {
    const txn = {
      id: "",
      version: "",
      date: txnInput.date,
      description: txnInput.description,
      destination: {
        account: txnInput.destination,
        currency: txnInput.currency,
        amount: txnInput.amount
      },
      source: {
        account: txnInput.source,
        currency: txnInput.currency,
        amount: -1 * txnInput.amount
      }
    };
    return saveTransaction(txn);
  }

  if (exposeJsApi) {
    window.ElmExpenses = {
      deleteAllData,
      importSampleData,
      putTransaction,
      saveSettings,
    };
  }

  await loadSettings();
}

function mapTxnFromElm(doc) {
  doc._id = doc.id;
  doc._rev = doc.version;
  delete doc.id;
  delete doc.version;
  return doc;
}

function mapTxnToElm(doc) {
  doc.id = doc._id;
  doc.version = doc._rev;
  delete doc._id;
  delete doc._rev;
  return doc;
}

function setRandomId(txn) {
  if (txn._id != "") {
    return;
  }
  txn._id = (txn.date + "-" + window.crypto.randomUUID());
  delete txn._rev;
}

const sample = [
  {
    "date": "2021-01-10",
    "description": "Utility bill payment",
    "destination": {
      "account": "Expenses:Utilities",
      "amount": 6000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -6000,
      "currency": "USD"
    }
  },
  {
    "date": "2021-02-18",
    "description": "Healthcare expenses",
    "destination": {
      "account": "Expenses:Healthcare",
      "amount": 8500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Cash",
      "amount": -8500,
      "currency": "USD"
    }
  },
  {
    "date": "2021-03-05",
    "description": "Home office supplies",
    "destination": {
      "account": "Expenses:Office:HomeOffice",
      "amount": 4200,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -4200,
      "currency": "USD"
    }
  },
  {
    "date": "2021-04-15",
    "description": "Car fuel purchase",
    "destination": {
      "account": "Expenses:Transportation:Fuel",
      "amount": 3000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -3000,
      "currency": "USD"
    }
  },
  {
    "date": "2021-05-20",
    "description": "Grocery shopping",
    "destination": {
      "account": "Expenses:Groceries",
      "amount": 4800,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -4800,
      "currency": "USD"
    }
  },
  {
    "date": "2021-06-12",
    "description": "Home improvement",
    "destination": {
      "account": "Expenses:Home:Improvement",
      "amount": 10500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -10500,
      "currency": "USD"
    }
  },
  {
    "date": "2021-07-08",
    "description": "Entertainment expenses",
    "destination": {
      "account": "Expenses:Entertainment",
      "amount": 3800,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Cash",
      "amount": -3800,
      "currency": "USD"
    }
  },
  {
    "date": "2021-08-25",
    "description": "Electronics purchase",
    "destination": {
      "account": "Expenses:Electronics",
      "amount": 6700,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -6700,
      "currency": "USD"
    }
  },
  {
    "date": "2021-09-14",
    "description": "Gym membership renewal",
    "destination": {
      "account": "Expenses:Health:Gym",
      "amount": 9000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -9000,
      "currency": "USD"
    }
  },
  {
    "date": "2021-10-03",
    "description": "Clothing purchase",
    "destination": {
      "account": "Expenses:Clothing",
      "amount": 3200,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -3200,
      "currency": "USD"
    }
  },
  {
    "date": "2021-11-18",
    "description": "Dental checkup",
    "destination": {
      "account": "Expenses:Health:Dental",
      "amount": 6000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -6000,
      "currency": "USD"
    }
  },
  {
    "date": "2021-12-22",
    "description": "Holiday gift shopping",
    "destination": {
      "account": "Expenses:Gifts",
      "amount": 4800,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -4800,
      "currency": "USD"
    }
  },
  {
    "date": "2022-01-05",
    "description": "Internet bill payment",
    "destination": {
      "account": "Expenses:Utilities:Internet",
      "amount": 5500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -5500,
      "currency": "USD"
    }
  },
  {
    "date": "2022-02-20",
    "description": "Medical expenses",
    "destination": {
      "account": "Expenses:Health:Medical",
      "amount": 8000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Cash",
      "amount": -8000,
      "currency": "USD"
    }
  },
  {
    "date": "2022-03-10",
    "description": "Clothing purchase",
    "destination": {
      "account": "Expenses:Clothing",
      "amount": 3500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -3500,
      "currency": "USD"
    }
  },
  {
    "date": "2022-04-15",
    "description": "Home energy bill",
    "destination": {
      "account": "Expenses:Utilities:Energy",
      "amount": 7500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -7500,
      "currency": "USD"
    }
  },
  {
    "date": "2022-05-08",
    "description": "Office supplies",
    "destination": {
      "account": "Expenses:Office",
      "amount": 4200,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -4200,
      "currency": "USD"
    }
  },
  {
    "date": "2022-06-22",
    "description": "Car maintenance",
    "destination": {
      "account": "Expenses:Transportation:CarMaintenance",
      "amount": 9800,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -9800,
      "currency": "USD"
    }
  },
  {
    "date": "2022-07-12",
    "description": "Movie night",
    "destination": {
      "account": "Expenses:Entertainment:Movies",
      "amount": 2500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Cash",
      "amount": -2500,
      "currency": "USD"
    }
  },
  {
    "date": "2022-08-30",
    "description": "Home improvement",
    "destination": {
      "account": "Expenses:Home:Improvement",
      "amount": 10500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -10500,
      "currency": "USD"
    }
  },
  {
    "date": "2022-09-18",
    "description": "Dental checkup",
    "destination": {
      "account": "Expenses:Health:Dental",
      "amount": 6500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -6500,
      "currency": "USD"
    }
  },
  {
    "date": "2022-10-05",
    "description": "Subscription renewal",
    "destination": {
      "account": "Expenses:Subscriptions",
      "amount": 2000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -2000,
      "currency": "USD"
    }
  },
  {
    "date": "2022-11-15",
    "description": "Hiking equipment",
    "destination": {
      "account": "Expenses:Outdoor:Equipment",
      "amount": 8900,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -8900,
      "currency": "USD"
    }
  },
  {
    "date": "2022-12-22",
    "description": "Holiday travel expenses",
    "destination": {
      "account": "Expenses:Travel",
      "amount": 12000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -12000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-01-01",
    "description": "Grocery shopping",
    "destination": {
      "account": "Expenses:Groceries",
      "amount": 4500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -4500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-15",
    "description": "Monthly rent",
    "destination": {
      "account": "Expenses:Rent",
      "amount": 150000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -150000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-05",
    "description": "Dinner at a restaurant",
    "destination": {
      "account": "Expenses:Dining",
      "amount": 3500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -3500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-04-20",
    "description": "Gasoline purchase",
    "destination": {
      "account": "Expenses:Transportation",
      "amount": 2500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Cash",
      "amount": -2500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-05-10",
    "description": "Phone bill payment",
    "destination": {
      "account": "Expenses:Utilities:Phone",
      "amount": 6000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -6000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-06-08",
    "description": "Bookstore purchase",
    "destination": {
      "account": "Expenses:Books",
      "amount": 1800,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -1800,
      "currency": "USD"
    }
  },
  {
    "date": "2023-07-15",
    "description": "Health insurance payment",
    "destination": {
      "account": "Expenses:Insurance:Health",
      "amount": 12000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -12000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-08-22",
    "description": "Electronics store purchase",
    "destination": {
      "account": "Expenses:Electronics",
      "amount": 7500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -7500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-09-10",
    "description": "Gym membership renewal",
    "destination": {
      "account": "Expenses:Health:Gym",
      "amount": 9000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -9000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-10-05",
    "description": "Home maintenance supplies",
    "destination": {
      "account": "Expenses:Home:Maintenance",
      "amount": 3500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -3500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-11-18",
    "description": "Car insurance premium",
    "destination": {
      "account": "Expenses:Insurance:Auto",
      "amount": 18000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -18000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-12-03",
    "description": "Holiday gift shopping",
    "destination": {
      "account": "Expenses:Gifts",
      "amount": 5000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -5000,
      "currency": "USD"
    }
  },
  {
    "date": "2024-01-08",
    "description": "Internet subscription renewal",
    "destination": {
      "account": "Expenses:Utilities:Internet",
      "amount": 5500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -5500,
      "currency": "USD"
    }
  },
  {
    "date": "2024-02-14",
    "description": "Medical checkup",
    "destination": {
      "account": "Expenses:Health:MedicalCheckup",
      "amount": 7200,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Cash",
      "amount": -7200,
      "currency": "USD"
    }
  },
  {
    "date": "2024-03-02",
    "description": "Home office equipment",
    "destination": {
      "account": "Expenses:Office:HomeOfficeEquipment",
      "amount": 9500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -9500,
      "currency": "USD"
    }
  },
  {
    "date": "2024-04-15",
    "description": "Car repair",
    "destination": {
      "account": "Expenses:Transportation:CarRepair",
      "amount": 12500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -12500,
      "currency": "USD"
    }
  },
  {
    "date": "2024-05-20",
    "description": "Grocery shopping",
    "destination": {
      "account": "Expenses:Groceries",
      "amount": 5200,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -5200,
      "currency": "USD"
    }
  },
  {
    "date": "2024-06-10",
    "description": "Home renovation",
    "destination": {
      "account": "Expenses:Home:Renovation",
      "amount": 18500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -18500,
      "currency": "USD"
    }
  },
  {
    "date": "2024-07-08",
    "description": "Concert tickets",
    "destination": {
      "account": "Expenses:Entertainment:Concerts",
      "amount": 4200,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Cash",
      "amount": -4200,
      "currency": "USD"
    }
  },
  {
    "date": "2024-08-25",
    "description": "Electronics upgrade",
    "destination": {
      "account": "Expenses:Electronics",
      "amount": 8500,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -8500,
      "currency": "USD"
    }
  },
  {
    "date": "2024-09-14",
    "description": "Fitness classes",
    "destination": {
      "account": "Expenses:Health:FitnessClasses",
      "amount": 7200,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -7200,
      "currency": "USD"
    }
  },
  {
    "date": "2024-10-03",
    "description": "Clothing and accessories",
    "destination": {
      "account": "Expenses:Clothing",
      "amount": 3800,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -3800,
      "currency": "USD"
    }
  },
  {
    "date": "2024-11-18",
    "description": "Dental cleaning",
    "destination": {
      "account": "Expenses:Health:DentalCleaning",
      "amount": 6000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:Bank",
      "amount": -6000,
      "currency": "USD"
    }
  },
  {
    "date": "2024-12-22",
    "description": "Holiday travel expenses",
    "destination": {
      "account": "Expenses:Travel",
      "amount": 11000,
      "currency": "USD"
    },
    "source": {
      "account": "Assets:CreditCard",
      "amount": -11000,
      "currency": "USD"
    }
  }
];

main();

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
