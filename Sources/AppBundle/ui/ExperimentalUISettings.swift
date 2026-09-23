struct ExperimentalUISettings {
    var displayStyle: MenuBarStyle { .systemText }
}

enum MenuBarStyle: String {
    case monospacedText
    case systemText
    case squares
    case i3
    case i3Ordered
}
