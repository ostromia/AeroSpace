// Fork tweak: the "Experimental UI Settings" menu was removed from the menu bar, so
// the style is fixed here instead of being picked in the UI and stored in UserDefaults.
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
