import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";

actor ReceiptSystem {
    // Type definitions
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
        date : Time.Time;
        totalItemsSold : Nat;
    };

    // State variables
    private stable var nextReceiptId : Nat = 0;
    private stable var nextGroupId : Nat = 0;

    private var receipts = HashMap.HashMap<Text, Receipt>(0, Text.equal, Text.hash);
    private var groupReceipts = HashMap.HashMap<Text, Buffer.Buffer<Text>>(0, Text.equal, Text.hash);
    private var userGroups = HashMap.HashMap<Principal, Text>(0, Principal.equal, Principal.hash);

    // Helper function to generate unique IDs
    private func generateUniqueId(prefix : Text) : Text {
        let id = switch (prefix) {
            case "R" { nextReceiptId += 1; nextReceiptId };
            case "G" { nextGroupId += 1; nextGroupId };
            case _ { 0 };
        };
        prefix # Nat.toText(id)
    };

    // Function to register a new user and get their group ID
    public shared(msg) func registerUser() : async Text {
        let caller = msg.caller;
        switch (userGroups.get(caller)) {
            case (?existingGroupId) {
                // User already registered
                existingGroupId
            };
            case null {
                // New user, generate a new group ID
                let newGroupId = generateUniqueId("G");
                userGroups.put(caller, newGroupId);
                groupReceipts.put(newGroupId, Buffer.Buffer<Text>(0));
                newGroupId
            };
        }
    };

    // Function to get a user's group ID
    public shared(msg) func getMyGroupId() : async ?Text {
        userGroups.get(msg.caller)
    };

    // Function to store a new receipt
    public shared(msg) func storeReceipt(
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
    ) : async Text {
        let receiptId = generateUniqueId("R");
        let groupId = switch (userGroups.get(msg.caller)) {
            case (?id) { id };
            case null {
                // If the user doesn't have a group ID, create one
                let newGroupId = generateUniqueId("G");
                userGroups.put(msg.caller, newGroupId);
                groupReceipts.put(newGroupId, Buffer.Buffer<Text>(0));
                newGroupId
            };
        };

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
            date = Time.now();
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

        receiptId
    };

    // Function to get a receipt by its ID
    public query func getReceipt(receiptId : Text) : async ?Receipt {
        receipts.get(receiptId)
    };

    // Function to get all receipt IDs for a group
    public query func getGroupReceiptIds(groupId : Text) : async [Text] {
        switch (groupReceipts.get(groupId)) {
            case (null) { [] };
            case (?buffer) { Buffer.toArray(buffer) };
        }
    };

    // Function to get all receipts for a group
    public query func getGroupReceipts(groupId : Text) : async [Receipt] {
        switch (groupReceipts.get(groupId)) {
            case (null) { [] };
            case (?buffer) {
                let receiptIds = Buffer.toArray(buffer);
                Array.mapFilter<Text, Receipt>(receiptIds, func(id) { receipts.get(id) })
            };
        }
    };
}