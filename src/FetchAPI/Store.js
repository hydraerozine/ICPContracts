import { Actor, HttpAgent } from "@dfinity/agent";
import fetch from 'node-fetch';

global.fetch = fetch;

const API_CANISTER_ID = "bkyz2-fmaaa-aaaaa-qaaaq-cai";
const LOCAL_NETWORK = "http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/";
const API_INTERFACE = ({ IDL }) => {
  return IDL.Service({
    'storeReceipt': IDL.Func(
      [IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Vec(IDL.Record({ name: IDL.Text, quantity: IDL.Nat, price: IDL.Float64 })), IDL.Float64, IDL.Float64, IDL.Float64, IDL.Float64, IDL.Float64, IDL.Text, IDL.Bool],
      [IDL.Opt(IDL.Text)],
      []
    ),
  });
};

const storeReceipt = async (apiKey, customerName, managerOnDuty, phoneNumber, address, items, subtotal, tax, total, debitTend, changeDue, lastFourDigits, paymentSuccessful) => {
  const agent = new HttpAgent({ host: LOCAL_NETWORK });
  await agent.fetchRootKey();

  const API = Actor.createActor(API_INTERFACE, {
    agent,
    canisterId: API_CANISTER_ID,
  });

  try {
    const receiptId = await API.storeReceipt(apiKey, customerName, managerOnDuty, phoneNumber, address, items, subtotal, tax, total, debitTend, changeDue, lastFourDigits, paymentSuccessful);
    console.log("Stored Receipt ID:", receiptId);
  } catch (error) {
    console.error("Failed to store receipt:", error);
  }
};

storeReceipt("your-api-key", "John Doe", "Manager1", "123-456-7890", "123 Main St", [{ name: "Item1", quantity: 2, price: 10.99 }], 21.98, 1.76, 23.74, 25.00, 1.26, "1234", true); // Replace with actual values
