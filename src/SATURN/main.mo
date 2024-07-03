import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

actor SimpleDEX {
    type TokenA = actor {
        balanceOf : shared () -> async Nat;
        transfer : shared (to : Principal, amount : Nat) -> async Bool;
    };

    type TokenB = actor {
        balanceOf : shared () -> async Nat;
        transfer : shared (to : Principal, amount : Nat) -> async Bool;
    };

    let tokenA : TokenA = actor("rwlgt-iiaaa-aaaaa-aaaaa-cai"); // Replace with actual Token A canister ID
    let tokenB : TokenB = actor("r7inp-6aaaa-aaaaa-aaabq-cai"); // Replace with actual Token B canister ID

    private var reserveA : Nat = 0;
    private var reserveB : Nat = 0;

    private var liquidityProviders : HashMap.HashMap<Principal, (Nat, Nat)> = HashMap.HashMap<Principal, (Nat, Nat)>(1, Principal.equal, Principal.hash);

    public shared(msg) func provideLiquidity(amountA : Nat, amountB : Nat) : async Bool {
        let caller = msg.caller;

        let success1 = await tokenA.transfer(Principal.fromActor(SimpleDEX), amountA);
        let success2 = await tokenB.transfer(Principal.fromActor(SimpleDEX), amountB);

        if (success1 and success2) {
            reserveA := Nat.add(reserveA, amountA);
            reserveB := Nat.add(reserveB, amountB);

            let currentProvision = switch (liquidityProviders.get(caller)) {
                case null { (0, 0) };
                case (?existing) { existing };
            };

            liquidityProviders.put(caller, (Nat.add(currentProvision.0, amountA), Nat.add(currentProvision.1, amountB)));
            return true;
        } else {
            return false;
        };
    };

    public shared(msg) func swap(tokenAAmount : Nat, tokenBAmount : Nat) : async Bool {
        let caller = msg.caller;

        if (tokenAAmount > 0 and tokenBAmount == 0) {
            // Swap A for B
            let amountOut = calculateSwapAmount(tokenAAmount, reserveA, reserveB);
            let success = await tokenA.transfer(Principal.fromActor(SimpleDEX), tokenAAmount);

            if (success) {
                reserveA := Nat.add(reserveA, tokenAAmount);
                reserveB := Nat.sub(reserveB, amountOut);
                return await tokenB.transfer(caller, amountOut);
            };
        } else if (tokenBAmount > 0 and tokenAAmount == 0) {
            // Swap B for A
            let amountOut = calculateSwapAmount(tokenBAmount, reserveB, reserveA);
            let success = await tokenB.transfer(Principal.fromActor(SimpleDEX), tokenBAmount);

            if (success) {
                reserveB := Nat.add(reserveB, tokenBAmount);
                reserveA := Nat.sub(reserveA, amountOut);
                return await tokenA.transfer(caller, amountOut);
            };
        };

        return false;
    };

    private func calculateSwapAmount(amountIn : Nat, reserveIn : Nat, reserveOut : Nat) : Nat {
        let amountInWithFee = Float.fromInt(Nat.mul(amountIn, 997));
        let numerator = Float.mul(amountInWithFee, Float.fromInt(reserveOut));
        let denominator = Float.add(Float.mul(Float.fromInt(reserveIn), 1000.0), amountInWithFee);
        let result = Float.mul(numerator, Float.div(1, denominator));
        return Int.abs(Float.toInt(result));
    };

    public query func getReserves() : async (Nat, Nat) {
        (reserveA, reserveB)
    };
}