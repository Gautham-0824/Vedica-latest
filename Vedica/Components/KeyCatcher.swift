import SwiftUI
import UIKit

/// Invisible view that receives presses from a hardware keyboard (a Mac keyboard in the Simulator, or an iPad keyboard).
struct KeyCatcher: UIViewRepresentable {
    enum Key { case digit(String), delete, enter, toggleBox }
    let onKey: (Key) -> Void

    func makeUIView(context: Context) -> CatcherView {
        let v = CatcherView()
        v.onKey = onKey
        return v
    }

    func updateUIView(_ v: CatcherView, context: Context) {
        v.onKey = onKey
        DispatchQueue.main.async { if v.window != nil && !v.isFirstResponder { v.becomeFirstResponder() } }
    }

    final class CatcherView: UIView {
        var onKey: ((Key) -> Void)?
        override var canBecomeFirstResponder: Bool { true }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil { becomeFirstResponder() }
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            var handled = false
            for p in presses {
                guard let k = p.key else { continue }
                switch k.keyCode {
                case .keyboardDeleteOrBackspace, .keyboardDeleteForward:
                    onKey?(.delete); handled = true
                case .keyboardReturnOrEnter, .keypadEnter:
                    onKey?(.enter); handled = true
                case .keyboardTab, .keyboardUpArrow, .keyboardDownArrow:
                    onKey?(.toggleBox); handled = true
                default:
                    let c = k.charactersIgnoringModifiers
                    if c.count == 1, let d = c.first, d.isASCII, d.isNumber { onKey?(.digit(c)); handled = true }
                }
            }
            if !handled { super.pressesBegan(presses, with: event) }
        }
    }
}
