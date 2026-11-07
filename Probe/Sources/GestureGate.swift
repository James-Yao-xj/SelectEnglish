/// Emit one trigger until the pressure gesture ends.
struct GestureGate {
    /// True after stage 2 has been seen in the current gesture.
    private var triggered = false

    /// Return true once per gesture. Stage 0 or mouse-up resets the gate.
    mutating func receive(stage: Int) -> Bool {
        if stage == 0 { triggered = false }
        guard stage == 2, !triggered else { return false }
        triggered = true
        return true
    }
}
