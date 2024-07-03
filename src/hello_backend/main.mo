import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";

actor {
    stable var cubePositions : [(Text, (Float, Float, Float))] = [("Player1", (0.0, 0.0, 0.0)), ("Player2", (1.0, 1.0, 1.0))];

    public query func getPositions() : async [(Text, (Float, Float, Float))] {
        return cubePositions;
    };

    public func updatePosition(player : Text, position : (Float, Float, Float)) : async () {
        let buffer = Buffer.Buffer<(Text, (Float, Float, Float))>(cubePositions.size());
        for (cube in Iter.fromArray(cubePositions)) {
            if (cube.0 != player) {
                buffer.add(cube);
            }
        };
        buffer.add((player, position));
        cubePositions := Buffer.toArray(buffer);
    };
};