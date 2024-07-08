import { Actor, HttpAgent } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { idlFactory as receiptIdlFactory } from "../../declarations/RECEIPT/RECEIPT.did.js";

const receiptCanisterId = process.env.RECEIPT_CANISTER_ID || 'bd3sg-teaaa-aaaaa-qaaba-cai';
let receiptCanister;
let authClient;

// Utility function to stringify objects with BigInt values
function stringifyWithBigInt(obj) {
    return JSON.stringify(obj, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value
    );
}

document.addEventListener('DOMContentLoaded', async () => {
    await initAuth();

    document.getElementById('loginBtn').addEventListener('click', loginWithInternetIdentity);
    document.getElementById('logoutBtn').addEventListener('click', logout);
    document.getElementById('registerUser').addEventListener('click', registerUser);
    document.getElementById('getMyGroupId').addEventListener('click', getMyGroupId);
    document.getElementById('storeReceiptBtn').addEventListener('click', showStoreReceiptForm);
    document.getElementById('getReceiptsBtn').addEventListener('click', showGetReceiptsForm);

    // Add this line to handle navigation item clicks
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', handleNavItemClick);
    });
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
                displayResult(`Login failed: ${error}`);
            },
        });
    } catch (error) {
        console.error('Login process failed:', error);
        displayResult(`Login process failed: ${error}`);
    }
}

async function logout() {
    await authClient.logout();
    document.getElementById('loginBtn').style.display = 'block';
    document.getElementById('logoutBtn').style.display = 'none';
    displayResult('Logged out');
    disableButtons();
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
    document.getElementById('logoutBtn').style.display = 'block';
    displayResult('Logged in');
    
    enableButtons();
}

function enableButtons() {
    document.getElementById('registerUser').classList.remove('disabled');
    document.getElementById('getMyGroupId').classList.remove('disabled');
    document.getElementById('storeReceiptBtn').classList.remove('disabled');
    document.getElementById('getReceiptsBtn').classList.remove('disabled');
}

function disableButtons() {
    document.getElementById('registerUser').classList.add('disabled');
    document.getElementById('getMyGroupId').classList.add('disabled');
    document.getElementById('storeReceiptBtn').classList.add('disabled');
    document.getElementById('getReceiptsBtn').classList.add('disabled');
}

function handleNavItemClick(event) {
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
    });
    event.target.classList.add('active');
}

async function registerUser() {
    try {
        const result = await receiptCanister.registerUser();
        displayResult(`Registration result: ${stringifyWithBigInt(result)}`);
    } catch (error) {
        displayResult(`Error: ${error.message}`);
    }
}

async function getMyGroupId() {
    try {
        const result = await receiptCanister.getMyGroupId();
        displayResult(`Your Group ID: ${stringifyWithBigInt(result)}`);
    } catch (error) {
        displayResult(`Error: ${error.message}`);
    }
}

function showStoreReceiptForm() {
    const mainPanel = document.getElementById('mainPanel');
    mainPanel.innerHTML = document.getElementById('storeReceiptForm').innerHTML;
    document.getElementById('storeReceipt').addEventListener('click', storeReceipt);
}

function showGetReceiptsForm() {
    const mainPanel = document.getElementById('mainPanel');
    mainPanel.innerHTML = document.getElementById('getReceiptsForm').innerHTML;
    document.getElementById('getReceipt').addEventListener('click', getReceipt);
    document.getElementById('getGroupReceipts').addEventListener('click', getGroupReceipts);
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
        displayResult(`Store Receipt result: ${stringifyWithBigInt(result)}`);
    } catch (error) {
        displayResult(`Error: ${error.message}`);
    }
}

async function getReceipt() {
    try {
        const receiptId = document.getElementById('receiptId').value;
        const result = await receiptCanister.getReceipt(receiptId);
        displayResult(`Receipt: ${stringifyWithBigInt(result)}`);
    } catch (error) {
        displayResult(`Error: ${error.message}`);
    }
}

async function getGroupReceipts() {
    try {
        const groupId = document.getElementById('groupId').value;
        const result = await receiptCanister.getGroupReceipts(groupId);
        displayResult(`Group Receipts: ${stringifyWithBigInt(result)}`);
    } catch (error) {
        displayResult(`Error: ${error.message}`);
    }
}

function displayResult(message) {
    const resultDiv = document.getElementById('result');
    resultDiv.style.display = 'block';
    resultDiv.innerHTML = `<h3>Result</h3><p>${message}</p>`;
}

// Initialize by disabling buttons that require authentication
disableButtons();