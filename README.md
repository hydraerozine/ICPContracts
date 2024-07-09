# ReceiptHub

ReceiptHub is a decentralized application (dApp) built on the Internet Computer platform for managing and storing digital receipts. This project allows users to register, store receipts, and retrieve receipt information using a user-friendly dashboard interface.

## Features

- User registration
- Store digital receipts
- Retrieve individual receipts
- Get receipts by group ID
- Interactive dashboard 
- Interact with API canister


## Prerequisites

- Node.js (version 16.0.0 or higher)
- npm (version 7.0.0 or higher)
- dfx (DFINITY Canister SDK)

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/hydraerozine/ICPContracts.git
   cd receipthub
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file in the root directory and add necessary environment variables:
   ```plaintext
   DFX_NETWORK=local
   CANISTER_ID_RECEIPT=your_receipt_canister_id
   CANISTER_ID_INTERNET_IDENTITY=your_internet_identity_canister_id
    DFX_VERSION='your_version'
    DFX_NETWORK='local'
    CANISTER_CANDID_PATH_RECEIPT='your_path/canisters/RECEIPT/RECEIPT.did'

    CANISTER_ID_RECEIPT_FRONTEND=your_canister_id

    CANISTER_ID_RECEIPT=your_canister_id

    CANISTER_ID_API=your_canister_id

    CANISTER_CANDID_PATH='your_path/canisters/RECEIPT_frontend/assetstorage.did'

    INTERNET_IDENTITY_CANISTER_ID=your_canister_id
    II_URL=http://your_canister_id.localhost:your_port/

    RECEIPT_CANISTER_ID=your_canister_id

    LOCAL_NETWORK_URL_API='http://your_canister_id.localhost:your_port/'
   ```

## Running the Project

1. Start the local Internet Computer replica:
   ```bash
   dfx start --background --clean
   ```
2. Deploy the canisters:
   ```bash
   dfx deploy
   ```
3. Build the development server:
   ```bash
   npm run build
   ```
4. Start the development server:
   ```bash
   npm run start
   ```
   This will start a server at `http://localhost:8080`, proxying API requests to the replica at port 4943.

## Available Scripts

- `npm run build`: Build the project for production
- `npm start`: Start the development server
- `npm run Ogen`: Generate API key for mainnet API canister
- `npm run Otest`: Test the mainnet API canister
- `npm run gen`: Generate local API
- `npm run get`: Fetch a receipt
- `npm run getg`: Fetch receipts by group
- `npm run store`: Store a new receipt

## Canister Interaction

The project includes several scripts for interacting with the canisters:

- `src/FetchAPI/MakeAPI.js`: Create an API key
- `src/FetchAPI/GetReceipt.js`: Retrieve a specific receipt
- `src/FetchAPI/GetGroup.js`: Retrieve receipts for a group
- `src/FetchAPI/Store.js`: Store a new receipt example

To use these scripts, run them with Node.js. For example:
```bash
node src/FetchAPI/GetReceipt.js
```

## Frontend Development

The frontend is built using HTML, CSS, and JavaScript. The main files are:

- `src/RECEIPT_frontend/assets/index.html`: Main HTML file
- `src/RECEIPT_frontend/assets/index.js`: Main JavaScript file
- `src/RECEIPT_frontend/assets/styles.css`: Stylesheet

## Deployment

To deploy the project to the Internet Computer mainnet:

1. Configure your dfx.json for mainnet deployment
2. Run:
   ```bash
   dfx deploy --network ic
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
