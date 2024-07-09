import { Actor, HttpAgent } from "@dfinity/agent";
import fetch from 'node-fetch';

global.fetch = fetch;

const API_CANISTER_ID = "bkyz2-fmaaa-aaaaa-qaaaq-cai";
const LOCAL_NETWORK = "http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/";

const API_INTERFACE = ({ IDL }) => {
  return IDL.Service({
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
  });
};

const getReceipt = async (apiKey, receiptId) => {
  const agent = new HttpAgent({ host: LOCAL_NETWORK });
  await agent.fetchRootKey();

  const API = Actor.createActor(API_INTERFACE, {
    agent,
    canisterId: API_CANISTER_ID,
  });

  try {
    const receipt = await API.getReceipt(apiKey, receiptId);
    console.log("Retrieved Receipt:", receipt);
  } catch (error) {
    console.error("Failed to get receipt:", error);
  }
};

getReceipt("your-api-key", "receipt-id"); // Replace with actual values
