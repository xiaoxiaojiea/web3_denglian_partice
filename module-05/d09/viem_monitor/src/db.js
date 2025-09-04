import sqlite3 from "sqlite3";
sqlite3.verbose();

const db = new sqlite3.Database("./transfers.db");

db.run(`
  CREATE TABLE IF NOT EXISTS transfers (
    txHash TEXT PRIMARY KEY,
    fromAddr TEXT,
    toAddr TEXT,
    amount TEXT,
    blockNumber INTEGER,
    timestamp INTEGER
  )
`);

export default db;
