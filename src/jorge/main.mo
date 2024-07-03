import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";
import Hash "mo:base/Hash";
import Text "mo:base/Text";

actor BasicToken {

    // Token metadata
    private let _name : Text = "BasicToken";
    private let _symbol : Text = "BTK";
    private let _decimals : Nat = 18;
    private var totalSupply : Nat = 0;

    // Comparison and hash functions for Principal
    private func comparePrincipal(p1 : Principal, p2 : Principal) : Bool {
        p1 == p2
    };

    private func hashPrincipal(p : Principal) : Hash.Hash {
        Text.hash(Principal.toText(p))
    };

    // Balances mapping
    private var balances : TrieMap.TrieMap<Principal, Nat> = TrieMap.TrieMap(comparePrincipal, hashPrincipal);

    // Events for the token transfer
    private type TransferEvent = {
        from: Principal;
        to: Principal;
        amount: Nat;
    };

    // Function to initialize the token supply
    public shared(msg) func initialize(initialSupply: Nat) : async () {
        let caller = msg.caller;
        balances.put(caller, initialSupply);
        totalSupply := initialSupply;
    };

    // Function to get the balance of a given address
    public query func balanceOf(owner: Principal) : async Nat {
        switch (balances.get(owner)) {
            case (?balance) balance;
            case null 0;
        }
    };

    // Function to transfer tokens
    public shared(msg) func transfer(to: Principal, amount: Nat) : async Bool {
        let caller = msg.caller;
        switch (balances.get(caller)) {
            case (?callerBalance) {
                if (callerBalance < amount) {
                    return false;
                } else {
                    balances.put(caller, callerBalance - amount);
                    let recipientBalance = switch (balances.get(to)) {
                        case (?balance) balance;
                        case null 0;
                    };
                    balances.put(to, recipientBalance + amount);
                    return true;
                }
            };
            case null return false;
        }
    };

    // Function to get the total supply of tokens
    public query func getTotalSupply() : async Nat {
        totalSupply
    };

    // Public functions to access token metadata
    public query func name() : async Text { _name };
    public query func symbol() : async Text { _symbol };
    public query func decimals() : async Nat { _decimals };
}
