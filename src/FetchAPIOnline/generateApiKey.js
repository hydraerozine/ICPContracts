import { Actor, HttpAgent } from "@dfinity/agent";
import fetch from 'node-fetch';

global.fetch = fetch;

const API_CANISTER_ID = "oq7qj-tiaaa-aaaap-qhn6a-cai";
const LOCAL_NETWORK = "https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.icp0.io/?id=oq7qj-tiaaa-aaaap-qhn6a-cai";

const API_INTERFACE = ({ IDL }) => {
  return IDL.Service({
    'generateApiKey': IDL.Func([], [IDL.Text], [])
  });
};

async function generateApiKey() {
  const agent = new HttpAgent({ host: LOCAL_NETWORK });
  await agent.fetchRootKey();

  const API = Actor.createActor(API_INTERFACE, {
    agent,
    canisterId: API_CANISTER_ID,
  });

  try {
    const apiKey = await API.generateApiKey();
    console.log("Generated API Key:", apiKey);
    return apiKey;
  } catch (error) {
    console.error("Error generating API key:", error);
    return null;
  }
}

generateApiKey();