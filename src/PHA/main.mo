/*import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Text "mo:base/Text";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import Char "mo:base/Char";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Types "Types";

actor PhantasmaQueryCanister {
    let phantasmaRpcEndpoint = "https://pharpc1.phantasma.info/rpc";
    let contractName = "SATRN";

    public func fetchCountOfTokensListed() : async Result.Result<Nat, Text> {
        let response = await makePhantasmaRequest("invokeRawScript", ["main", createScript(contractName, "getCountOfTokensOnList", [])]);
        switch response {
            case (#err(e)) { #err(e) };
            case (#ok(text)) { #ok(textToNat(text)) };
        }
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
            transform = ?{
                function = transform;
                context = Blob.fromArray([]);
            };
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
                    case null { #err("Error: Invalid UTF-8 in response body") };
                    case (?text) {
                        Debug.print("Response body: " # text);
                        #ok(extractResultFromJson(text))
                    };
                };
            } else {
                let responseBody = Text.decodeUtf8(Blob.fromArray(response.body));
                #err("Error: Unexpected response status " # Nat64.toText(Nat64.fromNat(response.status)) # ". Body: " # debug_show(responseBody))
            };
        } catch (error) {
            let errorMessage = Error.message(error);
            Debug.print("Error making HTTP request: " # errorMessage);
            #err("Error: Failed to make HTTP request. Details: " # errorMessage)
        };
    };

    private func createJsonRpcBody(method : Text, params : [Text]) : Text {
        "{\"jsonrpc\":\"2.0\",\"method\":\"" # method # "\",\"params\":" # arrayToText(params) # ",\"id\":1}"
    };

    private func arrayToText(arr : [Text]) : Text {
        "[" # Text.join(",", arr) # "]"
    };

    private func createScript(contract : Text, method : Text, params : [Text]) : Text {
        "CallContract(" # contract # "," # method # "," # joinParams(params) # ")"
    };

    private func joinParams(params : [Text]) : Text {
        arrayToText(params)
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

    private func extractResultFromJson(jsonText : Text) : Text {
        let parts = Iter.toArray(Text.split(jsonText, #text "\"result\":"));
        if (parts.size() < 2) {
            return "Error: Unable to parse JSON response";
        };
        let afterResult = parts[1];
        let resultParts = Iter.toArray(Text.split(afterResult, #text ",\"id\":"));
        if (resultParts.size() < 1) {
            return "Error: Malformed JSON response";
        };
        let result = resultParts[0];
        // Remove leading and trailing whitespace and quotes
        Text.trim(result, #text " \t\n\r\"")
    };

    public query func transform(args : Types.TransformArgs) : async Types.HttpResponsePayload {
        {
            status = args.response.status;
            body = args.response.body;
            headers = [
                { name = "Content-Security-Policy"; value = "default-src 'self'" },
                { name = "Referrer-Policy"; value = "strict-origin" },
                { name = "Permissions-Policy"; value = "geolocation=(self)" },
                { name = "Strict-Transport-Security"; value = "max-age=63072000" },
                { name = "X-Frame-Options"; value = "DENY" },
                { name = "X-Content-Type-Options"; value = "nosniff" },
            ]
        }
    }
}*/