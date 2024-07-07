import { Actor, HttpAgent } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { idlFactory as receiptIdlFactory } from "../../declarations/RECEIPT/RECEIPT.did.js";

const receiptCanisterId = process.env.RECEIPT_CANISTER_ID || 'bkyz2-fmaaa-aaaaa-qaaaq-cai';
let receiptCanister;
let authClient;

document.addEventListener('DOMContentLoaded', async () => {
    await initAuth();

    document.getElementById('loginBtn').addEventListener('click', loginWithInternetIdentity);
    document.getElementById('registerUser').addEventListener('click', registerUser);
    document.getElementById('getMyGroupId').addEventListener('click', getMyGroupId);
    document.getElementById('storeReceipt').addEventListener('click', storeReceipt);
    document.getElementById('getReceipt').addEventListener('click', getReceipt);
    document.getElementById('getGroupReceipts').addEventListener('click', getGroupReceipts);
});

async function initAuth() {
    authClient = await AuthClient.create();
    if (await authClient.isAuthenticated()) {
        handleAuthenticated();
    }
}

async function loginWithInternetIdentity() {
    try {
      const iiUrl = process.env.II_URL || `http://${process.env.INTERNET_IDENTITY_CANISTER_ID}.localhost:4943/`;
      console.log("Internet Identity URL:", iiUrl);
      console.log("Internet Identity Canister ID:", process.env.INTERNET_IDENTITY_CANISTER_ID);
      await authClient.login({
        identityProvider: iiUrl,
        onSuccess: () => {
          console.log("Login successful");
          handleAuthenticated();
        },
        onError: (error) => {
          console.error('Login failed:', error);
          document.getElementById('loginStatus').innerText = `Login failed: ${error}`;
        },
      });
    } catch (error) {
      console.error('Login process failed:', error);
      document.getElementById('loginStatus').innerText = `Login process failed: ${error}`;
    }
  }

async function handleAuthenticated() {
    const identity = await authClient.getIdentity();
    const agent = new HttpAgent({ identity });
    
    if (process.env.NODE_ENV !== "production") {
        agent.fetchRootKey().catch(err => {
            console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
            console.error(err);
        });
    }

    receiptCanister = await Actor.createActor(receiptIdlFactory, { 
        agent, 
        canisterId: receiptCanisterId 
    });

    document.getElementById('loginBtn').style.display = 'none';
    document.getElementById('loginStatus').innerText = 'Logged in';
    
    document.getElementById('registerUser').disabled = false;
    document.getElementById('getMyGroupId').disabled = false;
    document.getElementById('storeReceipt').disabled = false;
    document.getElementById('getReceipt').disabled = false;
    document.getElementById('getGroupReceipts').disabled = false;
}

async function registerUser() {
    try {
        const result = await receiptCanister.registerUser();
        document.getElementById('result').innerText = `Registration result: ${result}`;
    } catch (error) {
        document.getElementById('result').innerText = `Error: ${error.message}`;
    }
}

async function getMyGroupId() {
    try {
        const result = await receiptCanister.getMyGroupId();
        document.getElementById('result').innerText = `Your Group ID: ${result}`;
    } catch (error) {
        document.getElementById('result').innerText = `Error: ${error.message}`;
    }
}

async function storeReceipt() {
    try {
        const form = document.getElementById('receiptForm');
        const items = JSON.parse(document.getElementById('items').value);
        const args = [
            form.customerName.value,
            form.managerOnDuty.value,
            form.phoneNumber.value,
            form.address.value,
            items,
            parseFloat(form.subtotal.value),
            parseFloat(form.tax.value),
            parseFloat(form.total.value),
            parseFloat(form.debitTend.value),
            parseFloat(form.changeDue.value),
            form.lastFourDigits.value,
            form.paymentSuccessful.checked
        ];
        const result = await receiptCanister.storeReceipt(...args);
        document.getElementById('result').innerText = `Store Receipt result: ${result}`;
    } catch (error) {
        document.getElementById('result').innerText = `Error: ${error.message}`;
    }
}

async function getReceipt() {
    try {
        const receiptId = document.getElementById('receiptId').value;
        const result = await receiptCanister.getReceipt(receiptId);
        document.getElementById('result').innerText = `Receipt: ${JSON.stringify(result, null, 2)}`;
    } catch (error) {
        document.getElementById('result').innerText = `Error: ${error.message}`;
    }
}

async function getGroupReceipts() {
    try {
        const groupId = document.getElementById('groupId').value;
        const result = await receiptCanister.getGroupReceipts(groupId);
        document.getElementById('result').innerText = `Group Receipts: ${JSON.stringify(result, null, 2)}`;
    } catch (error) {
        document.getElementById('result').innerText = `Error: ${error.message}`;
    }
}

// Initialize by disabling buttons that require authentication
document.getElementById('registerUser').disabled = true;
document.getElementById('getMyGroupId').disabled = true;
document.getElementById('storeReceipt').disabled = true;
document.getElementById('getReceipt').disabled = true;
document.getElementById('getGroupReceipts').disabled = true;