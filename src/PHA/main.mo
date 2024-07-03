import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Text "mo:base/Text";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Iter "mo:base/Iter";
import Char "mo:base/Char";
import Result "mo:base/Result";
import Array "mo:base/Array";

import Types "Types";

actor PhantasmaQueryCanister {
    let phantasmaRpcEndpoint = "https://pharpc1.phantasma.info/rpc";
    let contractName = "SATRN";

    public func getTokensListed() : async Text {
        var result = "";
        let totalCountResult = await fetchCountOfTokensListed();
        
        switch totalCountResult {
            case (#err(e)) { return "Error fetching token count: " # e };
            case (#ok(totalCount)) {
                for (i in Iter.range(0, totalCount - 1)) {
                    let tokenInfoResult = await fetchTokenInfoByIndex(Nat.toText(i));
                    switch tokenInfoResult {
                        case (#err(e)) { result #= "Error fetching token info for index " # Nat.toText(i) # ": " # e # "\n" };
                        case (#ok(tokenInfo)) {
                            let reserveValueResult = await fetchReserveValueForToken(tokenInfo);
                            let tokenDecimalsResult = await getTokenData(tokenInfo);
                            
                            switch (reserveValueResult, tokenDecimalsResult) {
                                case (#ok(reserveValue), #ok(tokenDecimals)) {
                                    let formattedReserveValue = formatNumber(reserveValue, tokenDecimals);
                                    result #= tokenInfo # ": " # formattedReserveValue # "\n";
                                };
                                case (_, _) {
                                    result #= tokenInfo # ": Error fetching data\n";
                                };
                            };
                        };
                    };
                };
            };
        };

        result
    };

    public func fetchCountOfTokensListed() : async Result.Result<Nat, Text> {
        let response = await makePhantasmaRequest("invokeRawScript", ["main", createScript(contractName, "getCountOfTokensOnList", [])]);
        switch response {
            case (#err(e)) { return #err(e) };
            case (#ok(text)) { return #ok(textToNat(text)) };
        }
    };

    public func fetchTokenInfoByIndex(index : Text) : async Result.Result<Text, Text> {
        await makePhantasmaRequest("invokeRawScript", ["main", createScript(contractName, "getTokenOnList", [index])])
    };

    public func fetchReserveValueForToken(tokenSymbol : Text) : async Result.Result<Nat, Text> {
        let response = await makePhantasmaRequest("invokeRawScript", ["main", createScript(contractName, "getReserveValue", [tokenSymbol])]);
        switch response {
            case (#err(e)) { return #err(e) };
            case (#ok(text)) { return #ok(textToNat(text)) };
        }
    };

    public func getTokenData(symbol : Text) : async Result.Result<Nat, Text> {
        let response = await makePhantasmaRequest("getToken", [symbol]);
        switch response {
            case (#err(e)) { return #err(e) };
            case (#ok(text)) {
                // Assuming the response includes decimals, we need to extract it
                // This might need adjustment based on the actual response structure
                return #ok(textToNat(text))
            };
        }
    };

    private func createScript(contract : Text, method : Text, params : [Text]) : Text {
        "CallContract(" # contract # "," # method # "," # joinParams(params) # ")"
    };

    private func textToNat(t : Text) : Nat {
        var n : Nat = 0;
        for (c in t.chars()) {
            let charCode = Char.toNat32(c);
            if (charCode >= 48 and charCode <= 57) {
                n := 10 * n + Nat32.toNat(charCode - 48);
            } else {
                return n;  // Stop at first non-digit
            };
        };
        n
    };

    private func formatNumber(number : Nat, decimals : Nat) : Text {
        let floatNumber = Float.fromInt(number) / Float.pow(10, Float.fromInt(decimals));
        Float.toText(floatNumber)
    };

    private func makePhantasmaRequest(method : Text, params : [Text]) : async Result.Result<Text, Text> {
        let body = createJsonRpcBody(method, params);

        let request : Types.HttpRequestArgs = {
            url = phantasmaRpcEndpoint;
            max_response_bytes = ?2000000;
            headers = [
                { name = "Content-Type"; value = "application/json" },
            ];
            body = ?Blob.toArray(Text.encodeUtf8(body));
            method = #post;
            transform = null;
        };

        let ic : Types.IC = actor ("aaaaa-aa");

        Cycles.add<system>(230_949_972_000);
        
        try {
            Debug.print("Sending request to: " # phantasmaRpcEndpoint);
            Debug.print("Request body: " # body);
            let response = await ic.http_request(request);
            
            Debug.print("Received response with status: " # Nat64.toText(Nat64.fromNat(response.status)));
            
            if (response.status == 200) {
                let responseBody = Text.decodeUtf8(Blob.fromArray(response.body));
                switch responseBody {
                    case null { return #err("Error: Invalid UTF-8 in response body") };
                    case (?text) {
                        Debug.print("Response body: " # text);
                        return #ok(extractResultFromJson(text))
                    };
                };
            } else {
                let responseBody = Text.decodeUtf8(Blob.fromArray(response.body));
                return #err("Error: Unexpected response status " # Nat64.toText(Nat64.fromNat(response.status)) # ". Body: " # debug_show(responseBody))
            };
        } catch (error) {
            let errorMessage = Error.message(error);
            Debug.print("Error making HTTP request: " # errorMessage);
            return #err("Error: Failed to make HTTP request. Details: " # errorMessage)
        };
    };

    private func createJsonRpcBody(method : Text, params : [Text]) : Text {
        "{\"jsonrpc\":\"2.0\",\"method\":\"" # method # "\",\"params\":" # arrayToText(params) # ",\"id\":1}"
    };

    private func arrayToText(arr : [Text]) : Text {
        "[" # Text.join(",", arr) # "]"
    };

    private func joinParams(params : [Text]) : Text {
        arrayToText(params)
    };

    private func extractResultFromJson(jsonText : Text) : Text {
        let parts = Text.split(jsonText, #text "\"result\":");
        if (Array.size(parts) > 1) {
            let afterResult = Array.get(parts, 1);
            let resultParts = Text.split(afterResult, #text ",\"id\":");
            if (Array.size(resultParts) > 0) {
                let result = Array.get(resultParts, 0);
                // Remove leading and trailing whitespace and quotes
                return Text.trim(result, #text " \t\n\r\"");
            } else {
                return "Error: Malformed JSON response";
            }
        } else {
            return "Error: Unable to parse JSON response";
        }
    }


    public query func transform(args : Types.TransformArgs) : async Types.HttpResponsePayload {
        return {
            status = args.response.status;
            body = args.response.body;
            headers = [
                { name = "Content-Security-Policy"; value = "default-src 'self'" },
                { name = "Referrer-Policy"; value = "strict-origin" },
                { name = "Permissions-Policy"; value = "geolocation=(self)" },
                { name = "Strict-Transport-Security"; value = "max-age=63072000" },
                { name = "X-Frame-Options"; value = "DENY" },
                { name = "X-Content-Type-Options"; value = "nosniff" },
            ];
        };
    };
}
