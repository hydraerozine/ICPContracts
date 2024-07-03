import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Array "mo:base/Array";

actor AICanister {
    // Simulated AI state
    private var context : [Text] = [];
    private let maxContextLength : Nat = 5;

    // Function to process input and generate a response
    public func processInput(input : Text) : async Text {
        // Add input to context
        context := Array.append(context, [input]);
        if (context.size() > maxContextLength) {
            context := Array.tabulate(maxContextLength, func (i : Nat) : Text {
                context[i + context.size() - maxContextLength]
            });
        };

        // Simulate AI processing (replace this with actual AI logic later)
        let response = simulateAIResponse(input);

        // Add response to context
        context := Array.append(context, [response]);
        if (context.size() > maxContextLength) {
            context := Array.tabulate(maxContextLength, func (i : Nat) : Text {
                context[i + context.size() - maxContextLength]
            });
        };

        response
    };

    // Simulate AI response (placeholder for actual AI logic)
    private func simulateAIResponse(input : Text) : Text {
        "Simulated AI response to: " # input
    };

    // Function to get the current context
    public query func getContext() : async [Text] {
        context
    };

    // Function to clear the context
    public func clearContext() : async () {
        context := [];
    };
}