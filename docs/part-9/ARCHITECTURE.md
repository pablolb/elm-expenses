# Data Storage

Data is stored locally in the browser using [PouchDB](https://pouchdb.com/).

```mermaid
stateDiagram-v2
    [*] --> MaybeEncrypted
    MaybeEncrypted --> Loaded: No encryption
    MaybeEncrypted --> DecryptionError: Invalid password
    DecryptionError --> Loaded: Valid password
    DecryptionError --> DecryptionError: Invalid password
    Loaded --> [*]
```

## Encrypting Database

0. Lock DB
1. Create empty encrypted DB
2. Store `{"_id": "_encryption", "version": 1 }`
3. Copy all data
4. Rename
5. Unlock DB

## Opening DB

1. Open DB
2. GET `_encryption`
3. TryToDecrypt

```mermaid
---
title: DB State Machine With Encryption
---
stateDiagram-v2
    [*] --> Opening
    Opening --> Error: No encryption, has documents
    Opening --> Error: No documents, failed insert
    Error --> [*]
    Opening --> Open: Valid password
    Opening --> Encrypted: Invalid password
    Encrypted --> Open: Valid password
    Open --> [*]
```

```mermaid
---
title: DB State With No Encryption
---
stateDiagram-v2
    [*] --> Opening
    Opening --> Error: Has encryption
    Error --> [*]
    Opening --> Open
    Open --> [*]
```
