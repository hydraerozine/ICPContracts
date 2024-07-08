import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";

actor TokenA {
    private let tokenName : Text = "Token A";
    private let tokenSymbol : Text = "TKA";
    private stable var totalSupply : Nat = 1_000_000_000;

    private var balances : HashMap.HashMap<Principal, Nat> = HashMap.HashMap<Principal, Nat>(1, Principal.equal, Principal.hash);

    public shared(msg) func balanceOf() : async Nat {
        let caller = msg.caller;
        switch (balances.get(caller)) {
            case null { 0 };
            case (?balance) { balance };
        };
    };

    public shared(msg) func transfer(to : Principal, amount : Nat) : async Bool {
        let from = msg.caller;
        switch (balances.get(from)) {
            case null { return false };
            case (?fromBalance) {
                if (fromBalance < amount) { return false };
                let newFromBalance : Nat = fromBalance - amount;
                balances.put(from, newFromBalance);

                let toBalance = switch (balances.get(to)) {
                    case null { amount };
                    case (?existing) { Nat.add(existing, amount) };
                };
                balances.put(to, toBalance);
                return true;
            };
        };
    };

    public func mint(to : Principal, amount : Nat) : async () {
        let toBalance = switch (balances.get(to)) {
            case null { amount };
            case (?existing) { Nat.add(existing, amount) };
        };
        balances.put(to, toBalance);
        totalSupply := Nat.add(totalSupply, amount);
    };

    public query func getMetadata() : async (Text, Text, Nat) {
        (tokenName, tokenSymbol, totalSupply)
    };
}