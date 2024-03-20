import PouchDb from 'pouchdb-browser';

/**
 * 
 * @param {String} name 
 * @returns {PouchDB.Database}
 */
async function buildDb(name) {
    return new PouchDb(name);
}

export { buildDb };

