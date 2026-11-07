/// Check release, repeated pressure, and pressure reversal without a new click.
func triggers(_ stages: [Int]) -> Int {
    var gate = GestureGate()
    return stages.filter { gate.receive(stage: $0) }.count
}
precondition(triggers([0, 1, 1, 0]) == 0)
precondition(triggers([0, 1, 2, 2, 1, 2, 0]) == 1)
precondition(triggers([1, 2, 0, 1, 2, 0]) == 2)
precondition(triggers([2, 2, 0, 2]) == 2)
print("Gesture gate: 4 checks passed")
