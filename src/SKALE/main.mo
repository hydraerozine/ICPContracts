import Debug "mo:base/Debug";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Error "mo:base/Error";
import Text "mo:base/Text";
import Nat64 "mo:base/Nat64";
//import Iter "mo:base/Iter";

import Types "Types";

actor SkaleQueryCanister {
    let skaleRpcEndpoint = "https://staging-3.skalenodes.com:10136";

    public func getContractOwner(contractAddress : Text) : async Text {
        let body = "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"" # contractAddress # "\",\"data\":\"0x8da5cb5b\"}, \"latest\"],\"id\":1}";

        let request : Types.HttpRequestArgs = {
            url = skaleRpcEndpoint;
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
            Debug.print("Sending request to: " # skaleRpcEndpoint);
            let response = await ic.http_request(request);
            
            Debug.print("Received response with status: " # Nat64.toText(Nat64.fromNat(response.status)));
            
            if (response.status == 200) {
                let responseBody = Text.decodeUtf8(Blob.fromArray(response.body));
                switch (responseBody) {
                    case null { "Error: Invalid UTF-8 in response body" };
                    case (?text) {
                        Debug.print("Response body: " # text);
                        extractOwnerAddress(text)
                    };
                };
            } else {
                let responseBody = Text.decodeUtf8(Blob.fromArray(response.body));
                "Error: Unexpected response status " # Nat64.toText(Nat64.fromNat(response.status)) # ". Body: " # debug_show(responseBody);
            };
        } catch (error) {
            let errorMessage = Error.message(error);
            Debug.print("Error making HTTP request: " # errorMessage);
            "Error: Failed to make HTTP request. Details: " # errorMessage;
        };
    };

     private func extractOwnerAddress(jsonText : Text) : Text {
        Debug.print("Full JSON response: " # jsonText);
        
        let parts = Text.split(jsonText, #text "\"result\":\"");
        switch (parts.next()) {
            case null { 
                Debug.print("Error: Unable to find 'result' in JSON");
                "Error: Unable to parse JSON response" 
            };
            case (?beforeResult) {
                Debug.print("Before 'result:': " # beforeResult);
                switch (parts.next()) {
                    case null {
                        Debug.print("Error: No value after 'result'");
                        "Error: Malformed JSON response"
                    };
                    case (?afterResult) {
                        Debug.print("After 'result:': " # afterResult);
                        let resultParts = Text.split(afterResult, #text "\"");
                        switch (resultParts.next()) {
                            case null { 
                                Debug.print("Error: Unable to extract result value");
                                "Error: Malformed JSON response" 
                            };
                            case (?result) {
                                Debug.print("Extracted result: " # result);
                                if (result.size() == 66 and Text.startsWith(result, #text "0x")) {
                                    "Contract owner: " # result
                                } else {
                                    "Error: Invalid address format in response: " # result
                                }
                            };
                        };
                    };
                };
            };
        };
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
            ];
        };
    };
}