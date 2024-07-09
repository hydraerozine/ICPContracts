import { Actor, HttpAgent } from "@dfinity/agent";
import fetch from 'node-fetch';

global.fetch = fetch;

const API_CANISTER_ID = "bkyz2-fmaaa-aaaaa-qaaaq-cai";
const LOCAL_NETWORK = "http://bkyz2-fmaaa-aaaaa-qaaaq-cai.localhost:4943/";

const API_INTERFACE = ({ IDL }) => {
  return IDL.Service({
    'generateApiKey': IDL.Func([], [IDL.Text], []),
  });
};

const generateApiKey = async () => {
  const agent = new HttpAgent({ host: LOCAL_NETWORK });
  await agent.fetchRootKey();

  const API = Actor.createActor(API_INTERFACE, {
    agent,
    canisterId: API_CANISTER_ID,
  });

  try {
    const apiKey = await API.generateApiKey();
    console.log("Generated API Key:", apiKey);
  } catch (error) {
    console.error("Failed to generate API key:", error);
  }
};

generateApiKey();
