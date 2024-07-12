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
import JSON "JSON";
import Float "mo:base/Float";

actor API {
    type HttpRequest = Types.HttpRequestArgs;
    type HttpResponse = Types.HttpResponsePayload;
    type JSON = JSON.JSON;

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
    private var apiKeys = HashMap.HashMap<Text, Text>(0, Text.equal, Text.hash);

    private func generateUniqueId(prefix : Text) : Text {
        let id = switch (prefix) {
            case "RA" { nextReceiptId += 1; nextReceiptId };
            case "GA" { nextGroupId += 1; nextGroupId };
            case _ { 0 };
        };
        prefix # Nat.toText(id)
    };

    public func http_request(request : HttpRequest) : async HttpResponse {
        let path = Array.filter<Text>(Iter.toArray(Text.split(request.url, #char '?')), func (t : Text) : Bool { t != "" })[0];

        switch (request.method, path) {
            case (#post, "/generate_api_key") {
                let apiKey = await generateApiKey();
                createResponse(200, #String(apiKey))
            };
            case (#post, "/store_receipt") {
                let result = await handleStoreReceipt(request.body);
                createResponse(200, result)
            };
            case (#get, "/receipt") {
                let apiKey = getQueryParam(request.url, "apiKey");
                let receiptId = getQueryParam(request.url, "receiptId");
                switch (apiKey, receiptId) {
                    case (?ak, ?rid) {
                        let result = await getReceipt(ak, rid);
                        createResponse(200, result)
                    };
                    case _ {
                        createResponse(400, #String("Missing apiKey or receiptId"))
                    };
                }
            };
            case (#get, "/group_receipts") {
                let apiKey = getQueryParam(request.url, "apiKey");
                switch (apiKey) {
                    case (?ak) {
                        let result = await getGroupReceipts(ak);
                        createResponse(200, result)
                    };
                    case _ {
                        createResponse(400, #String("Missing apiKey"))
                    };
                }
            };
            case _ {
                createResponse(404, #String("Not found"))
            };
        }
    };

    private func getQueryParam(url : Text, param : Text) : ?Text {
        let parts = Array.filter<Text>(Iter.toArray(Text.split(url, #char '?')), func (t : Text) : Bool { t != "" });
        if (parts.size() < 2) {
            return null;
        };
        let queryString = parts[1];
        let params = Iter.toArray(Text.split(queryString, #char '&'));
        
        let foundParam = Array.find<Text>(params, func (p : Text) : Bool {
            let keyValue = Iter.toArray(Text.split(p, #char '='));
            keyValue.size() == 2 and keyValue[0] == param
        });
        
        switch (foundParam) {
            case (null) { null };
            case (?p) {
                let keyValue = Iter.toArray(Text.split(p, #char '='));
                ?keyValue[1]
            };
        }
    }

    private func generateApiKey() : async Text {
        let randomBytes = await Random.blob();
        let apiKey = Blob.toArray(randomBytes);
        let apiKeyText = Text.join("", Iter.map<Nat8, Text>(apiKey.vals(), func (n: Nat8) : Text { 
            Nat.toText(Nat8.toNat(n))
        }));
        let groupId = generateUniqueId("GA");
        apiKeys.put(apiKeyText, groupId);
        apiKeyText
    };

    private func handleStoreReceipt(body : ?[Nat8]) : async JSON {
        switch (body) {
            case (null) { #String("Missing request body") };
            case (?b) {
                let jsonOpt = JSON.parseRawASCII(b);
                switch (jsonOpt) {
                    case (null) { #String("Invalid JSON") };
                    case (?json) {
                        let apiKey = getJsonString(json, "apiKey");
                        let customerName = getJsonString(json, "customerName");
                        let managerOnDuty = getJsonString(json, "managerOnDuty");
                        let phoneNumber = getJsonString(json, "phoneNumber");
                        let address = getJsonString(json, "address");
                        let items = getJsonArray(json, "items");
                        let subtotal = getJsonFloat(json, "subtotal");
                        let tax = getJsonFloat(json, "tax");
                        let total = getJsonFloat(json, "total");
                        let debitTend = getJsonFloat(json, "debitTend");
                        let changeDue = getJsonFloat(json, "changeDue");
                        let lastFourDigits = getJsonString(json, "lastFourDigits");
                        let paymentSuccessful = getJsonBoolean(json, "paymentSuccessful");

                        switch (apiKey, customerName, managerOnDuty, phoneNumber, address, items, subtotal, tax, total, debitTend, changeDue, lastFourDigits, paymentSuccessful) {
                            case (?ak, ?cn, ?mod, ?pn, ?addr, ?itm, ?st, ?tx, ?tt, ?dt, ?cd, ?lfd, ?ps) {
                                let itemDetails = parseItemDetails(itm);
                                let result = await storeReceipt(ak, cn, mod, pn, addr, itemDetails, st, tx, tt, dt, cd, lfd, ps);
                                switch (result) {
                                    case (null) #String("Invalid API key");
                                    case (?receiptId) #String(receiptId);
                                };
                            };
                            case _ { #String("Missing or invalid required fields") };
                        };
                    };
                };
            };
        };
    };

    private func getJsonArray(json : JSON, key : Text) : ?[JSON] {
        switch (json) {
            case (#Object(fields)) {
                for ((k, v) in fields.vals()) {
                    if (k == key) {
                        switch (v) {
                            case (#Array(a)) return ?a;
                            case _ return null;
                        };
                    };
                };
                null
            };
            case _ null;
        };
    };

    private func getJsonFloat(json : JSON, key : Text) : ?Float {
        switch (json) {
            case (#Object(fields)) {
                for ((k, v) in fields.vals()) {
                    if (k == key) {
                        switch (v) {
                            case (#Number(n)) return ?Float.fromInt(n);
                            case _ return null;
                        };
                    };
                };
                null
            };
            case _ null;
        };
    };

    private func getJsonBoolean(json : JSON, key : Text) : ?Bool {
        switch (json) {
            case (#Object(fields)) {
                for ((k, v) in fields.vals()) {
                    if (k == key) {
                        switch (v) {
                            case (#Boolean(b)) return ?b;
                            case _ return null;
                        };
                    };
                };
                null
            };
            case _ null;
        };
    };

    private func getJsonString(json : JSON, key : Text) : ?Text {
        switch (json) {
            case (#Object(fields)) {
                for ((k, v) in fields.vals()) {
                    if (k == key) {
                        switch (v) {
                            case (#String(s)) return ?s;
                            case _ return null;
                        };
                    };
                };
                null
            };
            case _ null;
        };
    };

    private func parseItemDetails(items : [JSON]) : [ItemDetails] {
        Array.mapFilter<JSON, ItemDetails>(items, func (item : JSON) : ?ItemDetails {
            switch (item) {
                case (#Object(fields)) {
                    let name = getJsonString(#Object(fields), "name");
                    let quantity = getJsonFloat(#Object(fields), "quantity");
                    let price = getJsonFloat(#Object(fields), "price");
                    switch (name, quantity, price) {
                        case (?n, ?q, ?p) {
                            ?{
                                name = n;
                                quantity = Int.abs(Float.toInt(q));
                                price = p;
                            }
                        };
                        case _ null;
                    };
                };
                case _ null;
            };
        });
    };

    private func storeReceipt(
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
        };
    };

    private func getReceipt(apiKey : Text, receiptId : Text) : async JSON {
        switch (apiKeys.get(apiKey)) {
            case (?groupId) {
                switch (receipts.get(receiptId)) {
                    case (?receipt) {
                        if (receipt.groupId == groupId) { 
                            receiptToJson(receipt)
                        } else { 
                            #String("Unauthorized access to receipt") 
                        };
                    };
                    case null { #String("Receipt not found") };
                };
            };
            case null { #String("Invalid API key") };
        };
    };

    private func getGroupReceipts(apiKey : Text) : async JSON {
        switch (apiKeys.get(apiKey)) {
            case (?groupId) {
                switch (groupReceipts.get(groupId)) {
                    case (?buffer) {
                        let receiptIds = Buffer.toArray(buffer);
                        let receiptsJson = Array.mapFilter<Text, JSON>(receiptIds, func(id) {
                            switch (receipts.get(id)) {
                                case (?receipt) ?receiptToJson(receipt);
                                case null null;
                            };
                        });
                        #Array(receiptsJson)
                    };
                    case null { #Array([]) };
                };
            };
            case null { #String("Invalid API key") };
        };
    };

    private func receiptToJson(receipt : Receipt) : JSON {
        #Object([
            ("receiptId", #String(receipt.receiptId)),
            ("groupId", #String(receipt.groupId)),
            ("customerName", #String(receipt.customerName)),
            ("managerOnDuty", #String(receipt.managerOnDuty)),
            ("phoneNumber", #String(receipt.phoneNumber)),
            ("address", #String(receipt.address)),
            ("items", #Array(Array.map<ItemDetails, JSON>(receipt.items, itemDetailsToJson))),
            ("subtotal", #Number(Float.toInt(receipt.subtotal * 100.0))),
            ("tax", #Number(Float.toInt(receipt.tax * 100.0))),
            ("total", #Number(Float.toInt(receipt.total * 100.0))),
            ("debitTend", #Number(Float.toInt(receipt.debitTend * 100.0))),
            ("changeDue", #Number(Float.toInt(receipt.changeDue * 100.0))),
            ("lastFourDigits", #String(receipt.lastFourDigits)),
            ("paymentSuccessful", #Boolean(receipt.paymentSuccessful)),
            ("date", #Number(Int.abs(Nat64.toNat(receipt.date)))),
            ("totalItemsSold", #Number(receipt.totalItemsSold))
        ])
    };

    private func itemDetailsToJson(item : ItemDetails) : JSON {
        #Object([
            ("name", #String(item.name)),
            ("quantity", #Number(item.quantity)),
            ("price", #Number(Float.toInt(item.price * 100.0)))
        ])
    };

    private func createResponse(status : Nat, body : JSON) : HttpResponse {
        {
            status = status;
            headers = [
                { name = "Content-Type"; value = "application/json" },
                { name = "Content-Security-Policy"; value = "default-src 'self'" },
                { name = "Referrer-Policy"; value = "strict-origin" },
                { name = "Permissions-Policy"; value = "geolocation=(self)" },
                { name = "Strict-Transport-Security"; value = "max-age=63072000" },
                { name = "X-Frame-Options"; value = "DENY" },
                { name = "X-Content-Type-Options"; value = "nosniff" },
            ];
            body = Blob.toArray(Text.encodeUtf8(JSON.show(body)));
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