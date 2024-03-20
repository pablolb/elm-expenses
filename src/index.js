import './main.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';
import { DbPort} from './DbPort';
import { DevApi } from './DevApi';
import { buildGlue } from './ElmPort';

const exposeJsApi = process.env.ELM_APP_EXPOSE_TEST_JS == 'true';

async function main() {

  const app = Elm.Main.init({
    node: document.getElementById('root')
  });

  let dbPort = new DbPort();

  const glue = buildGlue(app, dbPort);

  if (exposeJsApi) {

    /**
     * This function creates a DevApi instance that re-creates
     * itself after deleteAllData is called.
     * 
     * It assigns window.ElmExpenses to the latest one.
     */
    const buildDevApi = () => {
      
      window.ElmExpenses = new DevApi(app.ports, dbPort, async () => {
        dbPort = new DbPort();
        glue.setDbPort(dbPort);
        buildDevApi();
        await dbPort.openDbs();
      });
    }

    buildDevApi();
  }

}

main();

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
