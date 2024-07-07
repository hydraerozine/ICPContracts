import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory as receiptIdlFactory } from "../../declarations/RECEIPT/RECEIPT.did.js";

const receiptCanisterId = 'bkyz2-fmaaa-aaaaa-qaaaq-cai';
let receiptCanister;

document.addEventListener('DOMContentLoaded', async () => {
    // Initializing the agent and creating an actor
    const agent = new HttpAgent();
    receiptCanister = await Actor.createActor(receiptIdlFactory, { 
        agent, 
        canisterId: receiptCanisterId 
    });

    // Adding event listeners
    document.getElementById('registerUser').addEventListener('click', registerUser);
    document.getElementById('getMyGroupId').addEventListener('click', getMyGroupId);
    document.getElementById('storeReceipt').addEventListener('click', storeReceipt);
    document.getElementById('getReceipt').addEventListener('click', getReceipt);
    document.getElementById('getGroupReceipts').addEventListener('click', getGroupReceipts);
});

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