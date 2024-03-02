import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import PouchDb from 'pouchdb-browser';


async function main() {
  let db = new PouchDb('elm_expenses_local');

  const app = Elm.Main.init({
    node: document.getElementById('root')
  });

  app.ports.saveTransaction.subscribe(async function(elmTxn) {
    const txn = mapTxnFromElm(elmTxn);
    setRandomId(txn);
    await db.put(txn);
    await sendTransactionsToElm(); 
  });

  app.ports.deleteTransaction.subscribe(async function(idAndVersion) {
    const [id, version] = idAndVersion;
    await db.remove(id, version);
    await sendTransactionsToElm();
  });

  app.ports.deleteAllData.subscribe(async function() {
    await db.destroy();
    db = new PouchDb('elm_expenses_local');
    await sendTransactionsToElm(); 
  });

  app.ports.importSampleData.subscribe(async function() {
    const toImport = sample.map(t => {
      setRandomId(t);
      return t;
    });
    await db.bulkDocs(toImport);
    await sendTransactionsToElm(); 
  });

  async function sendTransactionsToElm() {
    const result = await db.allDocs({include_docs: true, descending: true});
    app.ports.gotTransactions.send(result.rows.map(row => mapTxnToElm(row.doc)));
  }

  await sendTransactionsToElm();
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
    "date": "2023-02-01",
    "description": "Rent payment",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 120000,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Housing",
      "amount": -120000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-02",
    "description": "Utilities bill",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 8500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Utilities",
      "amount": -8500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-02",
    "description": "Coffee shop latte",
    "destination": {
      "account": "Assets:Cash",
      "amount": 400,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Personal Care",
      "amount": -400,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-03",
    "description": "Streaming service subscription",
    "destination": {
      "account": "Liabilities:CreditCard",
      "amount": 900,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -900,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-03",
    "description": "Groceries",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 4200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Groceries",
      "amount": -4200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-06",
    "description": "Gym membership renewal",
    "destination": {
      "account": "Liabilities:CreditCard",
      "amount": 5900,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Health & Fitness",
      "amount": -5900,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-07",
    "description": "Movie tickets",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 2200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -2200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-08",
    "description": "Restaurant dinner",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 7800,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Dining Out",
      "amount": -7800,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-09",
    "description": "Phone bill",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 6200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Utilities",
      "amount": -6200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-10",
    "description": "Car wash",
    "destination": {
      "account": "Assets:Cash",
      "amount": 1400,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Auto",
      "amount": -1400,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-10",
    "description": "Haircut",
    "destination": {
      "account": "Assets:Cash",
      "amount": 3200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Personal Care",
      "amount": -3200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-13",
    "description": "Donation to charity",
    "destination": {
      "account": "Liabilities:CreditCard",
      "amount": 2500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Giving",
      "amount": -2500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-14",
    "description": "Lunch at work",
    "destination": {
      "account": "Assets:Cash",
      "amount": 1200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Dining Out",
      "amount": -1200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-15",
    "description": "Streaming service purchase",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 300,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -300,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-16",
    "description": "Coffee shop muffin",
    "destination": {
      "account": "Assets:Cash",
      "amount": 300,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Personal Care",
      "amount": -300,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-17",
    "description": "Gas fill-up",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 3800,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Auto",
      "amount": -3800,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-18",
    "description": "Online shopping purchase",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 4500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Other",
      "amount": -4500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-20",
    "description": "Concert tickets",
    "destination": {
      "account": "Assets:Cash",
      "amount": 6500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -6500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-21",
    "description": "Grocery delivery fee",
    "destination": {
      "account": "Assets:Cash",
      "amount": 500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Groceries",
      "amount": -500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-21",
    "description": "Birthday gift for friend",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 3000,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Gifts",
      "amount": -3000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-22",
    "description": "Streaming service tip",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-23",
    "description": "Public transportation pass",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 3200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Transportation",
      "amount": -3200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-24",
    "description": "Doctor's appointment copay",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 2000,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Health & Fitness",
      "amount": -2000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-25",
    "description": "Pizza delivery",
    "destination": {
      "account": "Assets:Cash",
      "amount": 2700,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Dining Out",
      "amount": -2700,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-27",
    "description": "Phone case purchase",
    "destination": {
      "account": "Liabilities:CreditCard",
      "amount": 1800,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Personal Care",
      "amount": -1800,
      "currency": "USD"
    }
  },
  {
    "date": "2023-02-28",
    "description": "Parking garage fee",
    "destination": {
      "account": "Assets:Cash",
      "amount": 1200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Transportation",
      "amount": -1200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-01",
    "description": "Streaming service subscription renewal",
    "destination": {
      "account": "Liabilities:CreditCard",
      "amount": 1200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -1200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-02",
    "description": "New book purchase",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 2400,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -2400,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-03",
    "description": "Lunch at work",
    "destination": {
      "account": "Assets:Cash",
      "amount": 1000,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Dining Out",
      "amount": -1000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-04",
    "description": "Donation to animal shelter",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 3500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Giving",
      "amount": -3500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-06",
    "description": "Coffee shop latte",
    "destination": {
      "account": "Assets:Cash",
      "amount": 400,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Personal Care",
      "amount": -400,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-07",
    "description": "Gym membership fee",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 3900,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Health & Fitness",
      "amount": -3900,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-08",
    "description": "Movie tickets for friends",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 3600,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -3600,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-09",
    "description": "Concert tickets",
    "destination": {
      "account": "Liabilities:CreditCard",
      "amount": 8500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -8500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-10",
    "description": "Grocery delivery fee",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 700,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Groceries",
      "amount": -700,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-11",
    "description": "Haircut",
    "destination": {
      "account": "Assets:Cash",
      "amount": 3800,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Personal Care",
      "amount": -3800,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-13",
    "description": "Streaming service purchase",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 400,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -400,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-14",
    "description": "Gas fill-up",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 4300,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Auto",
      "amount": -4300,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-15",
    "description": "Birthday gift for coworker",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 2000,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Gifts",
      "amount": -2000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-16",
    "description": "Coffee shop smoothie",
    "destination": {
      "account": "Assets:Cash",
      "amount": 500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Personal Care",
      "amount": -500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-17",
    "description": "Online shopping purchase (clothing)",
    "destination": {
      "account": "Liabilities:CreditCard",
      "amount": 6200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Other",
      "amount": -6200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-18",
    "description": "Restaurant dinner with family",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 12500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Dining Out",
      "amount": -12500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-20",
    "description": "Donation to environmental charity",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 5000,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Giving",
      "amount": -5000,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-21",
    "description": "Streaming service tip",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -200,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-22",
    "description": "New plant for home",
    "destination": {
      "account": "Assets:Cash",
      "amount": 3500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Other",
      "amount": -3500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-23",
    "description": "Phone repair",
    "destination": {
      "account": "Liabilities:CreditCard",
      "amount": 7800,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Other",
      "amount": -7800,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-24",
    "description": "Pizza delivery",
    "destination": {
      "account": "Assets:Cash",
      "amount": 2300,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Dining Out",
      "amount": -2300,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-25",
    "description": "Haircut (touch-up)",
    "destination": {
      "account": "Assets:Cash",
      "amount": 2500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Personal Care",
      "amount": -2500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-27",
    "description": "Coffee shop pastry",
    "destination": {
      "account": "Assets:Cash",
      "amount": 300,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Personal Care",
      "amount": -300,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-28",
    "description": "Movie rental",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Entertainment",
      "amount": -500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-29",
    "description": "Parking garage fee",
    "destination": {
      "account": "Assets:Cash",
      "amount": 1500,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Transportation",
      "amount": -1500,
      "currency": "USD"
    }
  },
  {
    "date": "2023-03-30",
    "description": "Grocery shopping",
    "destination": {
      "account": "Assets:Bank:Checking",
      "amount": 7200,
      "currency": "USD"
    },
    "source": {
      "account": "Expenses:Groceries",
      "amount": -7200,
      "currency": "USD"
    }
  }
];

main();

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
