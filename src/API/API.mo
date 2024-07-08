import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Random "mo:base/Random";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Types "Types";

actor API {
    type ItemDetails = {
        name : Text;
        quantity : Nat;
        price : Float;
    };

    type Receipt = {
        receiptId : Text;
        groupId : Text;
        customerName : Text;
        managerOnDuty : Text;
        phoneNumber : Text;
        address : Text;
        items : [ItemDetails];
        subtotal : Float;
        tax : Float;
        total : Float;
        debitTend : Float;
        changeDue : Float;
        lastFourDigits : Text;
        paymentSuccessful : Bool;
        date : Types.Timestamp;
        totalItemsSold : Nat;
    };

    private stable var nextReceiptId : Nat = 0;
    private stable var nextGroupId : Nat = 0;

    private var receipts = HashMap.HashMap<Text, Receipt>(0, Text.equal, Text.hash);
    private var groupReceipts = HashMap.HashMap<Text, Buffer.Buffer<Text>>(0, Text.equal, Text.hash);
    private var apiKeys = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash); // API Key to GroupId mapping

    private func generateUniqueId(prefix : Text) : Text {
        let id = switch (prefix) {
            case "RA" { nextReceiptId += 1; nextReceiptId };
            case "GA" { nextGroupId += 1; nextGroupId };
            case _ { 0 };
        };
        prefix # Nat.toText(id)
    };

    public func generateApiKey() : async Text {
        let randomBytes = await Random.blob();
        let apiKey = Blob.toArray(randomBytes);
        let apiKeyText = Text.join("", Iter.map(apiKey.vals(), func (n: Nat8) : Text { 
            Nat.toText(Nat8.toNat(n))
        }));
        let groupId = generateUniqueId("GA");
        apiKeys.put(apiKeyText, groupId);
        apiKeyText
    };

    public func storeReceipt(
        apiKey : Text,
        customerName : Text,
        managerOnDuty : Text,
        phoneNumber : Text,
        address : Text,
        items : [ItemDetails],
        subtotal : Float,
        tax : Float,
        total : Float,
        debitTend : Float,
        changeDue : Float,
        lastFourDigits : Text,
        paymentSuccessful : Bool
    ) : async ?Text {
        switch (apiKeys.get(apiKey)) {
            case (?groupId) {
                let receiptId = generateUniqueId("RA");
                let newReceipt : Receipt = {
                    receiptId = receiptId;
                    groupId = groupId;
                    customerName = customerName;
                    managerOnDuty = managerOnDuty;
                    phoneNumber = phoneNumber;
                    address = address;
                    items = items;
                    subtotal = subtotal;
                    tax = tax;
                    total = total;
                    debitTend = debitTend;
                    changeDue = changeDue;
                    lastFourDigits = lastFourDigits;
                    paymentSuccessful = paymentSuccessful;
                    date = Nat64.fromNat(Int.abs(Time.now()));
                    totalItemsSold = Array.foldLeft<ItemDetails, Nat>(items, 0, func(acc, item) { acc + item.quantity });
                };

                receipts.put(receiptId, newReceipt);

                let groupReceiptIds = switch (groupReceipts.get(groupId)) {
                    case (?buffer) { buffer };
                    case null {
                        let newBuffer = Buffer.Buffer<Text>(1);
                        groupReceipts.put(groupId, newBuffer);
                        newBuffer
                    };
                };
                groupReceiptIds.add(receiptId);

                ?receiptId
            };
            case null { null };
        }
    };

    public query func getReceipt(apiKey : Text, receiptId : Text) : async ?Receipt {
        switch (apiKeys.get(apiKey)) {
            case (?groupId) {
                switch (receipts.get(receiptId)) {
                    case (?receipt) {
                        if (receipt.groupId == groupId) { ?receipt } else { null }
                    };
                    case null { null };
                };
            };
            case null { null };
        }
    };

    public query func getGroupReceipts(apiKey : Text) : async ?[Receipt] {
        switch (apiKeys.get(apiKey)) {
            case (?groupId) {
                switch (groupReceipts.get(groupId)) {
                    case (?buffer) {
                        let receiptIds = Buffer.toArray(buffer);
                        ?Array.mapFilter<Text, Receipt>(receiptIds, func(id) { receipts.get(id) });
                    };
                    case null { ?[] };
                };
            };
            case null { null };
        }
    };

    // HTTPS outcall function
    public func makeHttpRequest(request : Types.HttpRequestArgs) : async Types.HttpResponsePayload {
        let ic : Types.IC = actor("aaaaa-aa");
        await ic.http_request(request)
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
        }
    };
}