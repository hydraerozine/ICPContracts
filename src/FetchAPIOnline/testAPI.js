import { Actor, HttpAgent } from "@dfinity/agent";
import fetch from 'node-fetch';

global.fetch = fetch;

const API_CANISTER_ID = "oq7qj-tiaaa-aaaap-qhn6a-cai";
const MAINNET = "https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.icp0.io/?id=oq7qj-tiaaa-aaaap-qhn6a-cai";

const API_INTERFACE = ({ IDL }) => {
  return IDL.Service({
    'generateApiKey': IDL.Func([], [IDL.Text], []),
    'storeReceipt': IDL.Func([IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Vec(IDL.Record({ name: IDL.Text, quantity: IDL.Nat, price: IDL.Float64 })), IDL.Float64, IDL.Float64, IDL.Float64, IDL.Float64, IDL.Float64, IDL.Text, IDL.Bool], [IDL.Opt(IDL.Text)], []),
    'getReceipt': IDL.Func([IDL.Text, IDL.Text], [IDL.Opt(IDL.Record({
      receiptId: IDL.Text,
      groupId: IDL.Text,
      customerName: IDL.Text,
      managerOnDuty: IDL.Text,
      phoneNumber: IDL.Text,
      address: IDL.Text,
      items: IDL.Vec(IDL.Record({ name: IDL.Text, quantity: IDL.Nat, price: IDL.Float64 })),
      subtotal: IDL.Float64,
      tax: IDL.Float64,
      total: IDL.Float64,
      debitTend: IDL.Float64,
      changeDue: IDL.Float64,
      lastFourDigits: IDL.Text,
      paymentSuccessful: IDL.Bool,
      date: IDL.Nat64,
      totalItemsSold: IDL.Nat
    }))], ['query']),
    'getGroupReceipts': IDL.Func([IDL.Text], [IDL.Opt(IDL.Vec(IDL.Record({
      receiptId: IDL.Text,
      groupId: IDL.Text,
      customerName: IDL.Text,
      managerOnDuty: IDL.Text,
      phoneNumber: IDL.Text,
      address: IDL.Text,
      items: IDL.Vec(IDL.Record({ name: IDL.Text, quantity: IDL.Nat, price: IDL.Float64 })),
      subtotal: IDL.Float64,
      tax: IDL.Float64,
      total: IDL.Float64,
      debitTend: IDL.Float64,
      changeDue: IDL.Float64,
      lastFourDigits: IDL.Text,
      paymentSuccessful: IDL.Bool,
      date: IDL.Nat64,
      totalItemsSold: IDL.Nat
    })))], ['query'])
  });
};

async function main() {
  const agent = new HttpAgent({ host: MAINNET });
  await agent.fetchRootKey();

  const API = Actor.createActor(API_INTERFACE, {
    agent,
    canisterId: API_CANISTER_ID,
  });

  try {
    // Generate API Key
    const apiKey = await API.generateApiKey();
    console.log("Generated API Key:", apiKey);

    // Submit first receipt
    const receipt1 = await API.storeReceipt(
      apiKey,
      "John Doe",
      "Manager1",
      "123-456-7890",
      "123 Main St",
      [{ name: "Item1", quantity: 2, price: 10.99 }],
      21.98,
      1.76,
      23.74,
      25.00,
      1.26,
      "1234",
      true
    );
    console.log("Stored Receipt 1 ID:", receipt1);

    // Retrieve the first receipt
    if (receipt1) {
      const retrievedReceipt = await API.getReceipt(apiKey, receipt1[0]);
      console.log("Retrieved Receipt 1:", retrievedReceipt);
    }

    // Submit second receipt with random information
    const receipt2 = await API.storeReceipt(
      apiKey,
      "Jane Smith",
      "Manager2",
      "987-654-3210",
      "456 Elm St",
      [
        { name: "Item2", quantity: 1, price: 15.99 },
        { name: "Item3", quantity: 3, price: 5.99 }
      ],
      33.96,
      2.72,
      36.68,
      40.00,
      3.32,
      "5678",
      true
    );
    console.log("Stored Receipt 2 ID:", receipt2);

    // Retrieve receipts by group ID
    const groupReceipts = await API.getGroupReceipts(apiKey);
    console.log("Group Receipts:", groupReceipts);

  } catch (error) {
    console.error("Error:", error);
  }
}

main();