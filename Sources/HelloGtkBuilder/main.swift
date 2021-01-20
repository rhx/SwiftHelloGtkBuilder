import Foundation

import CGtk
import GLib
import GLibObject
import GIO
import Gtk

var settings: Gtk.Settings!
var appActionEntries = [
    GActionEntry(name: g_strdup("quit"), activate: { Gtk.ApplicationRef(gpointer: $2).quit() }, parameter_type: nil, state: nil, change_state: nil, padding: (0, 0, 0))
]

#if XCODE
//
// Xcode does not include the SPM-generated module finder,
// so we include our own.  This follows the example from
// Fabrizio Duroni's blog:
// https://www.fabrizioduroni.it/2020/10/19/swift-package-manager-resources.html
//
// NOTE:
// Since Xcode does not actually create the resource bundle,
// you need to first create it from the command line using
// swift build `./run-gir2swift.sh flags -noUpdate`
// then link the generated bundle into Xcode's products folder
// (which you can find by right-clicking on Products/HelloGtkBuilder,
// and selectin "Show in Finder"), e.g.:
// ln -s $PWD/.build/x86_64-apple-macosx/debug/HelloGtkBuilder_HelloGtkBuilder.bundle /Users/USERNAME/Library/Developer/Xcode/DerivedData/HelloGtkBuilder-ggjpqkaqtvyfzyarafdunoqwodzz/Build/Products/Debug
import class Foundation.Bundle

private class BundleFinder {}

extension Foundation.Bundle {
    /// Returns the resource bundle associated with the current Swift module.
    static var module: Bundle = {
        let bundleName = "HelloGtkBuilder_HelloGtkBuilder"

        let candidates = [
            // The Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // The Bundle should be present here when the package is linked into a framework.
            Bundle(for: BundleFinder.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
        ]

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        fatalError("unable to find a bundle named \(bundleName).bundle")
    }()
}
#endif

/// Convenience extensions for GtkBuilder to load .ui files using Package Manager `Bundle.module`
extension Builder {
    /// Search for the given resource in the module bundle
    ///
    /// - parameter resource: resource <file>.ui to search for
    convenience init?(_ resource: String) {
        self.init()

        guard let filepath = Bundle.module.path(forResource: resource, ofType: "ui") else {
            return nil
        }

        do {
            let _ = try addFromFile(filename: filepath)
        } catch {
            print(error)
            return nil
        }

    }

    /// Get the given object and wrap it in the given `Object` subtype
    /// - Parameters:
    ///   - identifier: A name identifying the object in the builder file
    ///   - cons: A type constructor taking a raw pointer to an underlying `GObject` class/subclass pointer and returning a type reference
    /// - Returns: The constructed type
    func get<T: ObjectProtocol>(_ identifier: UnsafePointer<gchar>, _ cons: (UnsafeMutableRawPointer) -> T) -> T {
        cons(getObject(name: identifier)!.ptr)
    }
}

/// Bind all the widgets together
///
/// - parameter builder: GtkBuilder to extract the widgets from
///
func connectWidgets(from builder: Builder) {
    let leftEntry    = builder.get("leftText",  EntryRef.init)
    let rightEntry   = builder.get("rightText", EntryRef.init)
    let plusButton   = builder.get("plus", ToggleButtonRef.init)
    let minusButton  = builder.get("minus", ToggleButtonRef.init)
    let timesButton  = builder.get("times", ToggleButtonRef.init)
    let divButton    = builder.get("divide", ToggleButtonRef.init)
    let textView     = builder.get("textView", TextViewRef.init)
    let resultLabel  = builder.get("resultLabel", LabelRef.init)
    let equalsButton = builder.get("equalsButton", ButtonRef.init)
    //
    // operations associated with the widgets
    //
    let buttons = [plusButton, minusButton, timesButton, divButton]
    let add: (Double, Double) -> Double = (+)
    let sub: (Double, Double) -> Double = (-)
    let div: (Double, Double) -> Double = (/)
    let mul: (Double, Double) -> Double = (*)
    let operators = [ "+" : add,  "-" : sub,  "*" : mul,  "/" : div ]
    var opLabel = "+"
    var op = operators[opLabel]!
    let calc: () -> (l: String, r: String, result: String)? = {
        let leftText  = leftEntry.text
        let rightText = rightEntry.text
        guard let  leftValue =  leftText.flatMap(Double.init),
              let rightValue = rightText.flatMap(Double.init) else {
                return nil
        }
        let result = op(leftValue, rightValue)
        return ("\(leftValue)", "\(rightValue)", "\(result)")
    }
    let calculate: SignalHandler = {
        let _ = calc().map { resultLabel.text = $0.result }
    }
    let record: SignalHandler = {
        guard let (l, r, result) = calc() else { return }
        resultLabel.text = result
        let record = textView.text
        let content = record + "\n\(l) \(opLabel) \(r) = \(result)"
        textView.text = content
    }
    var recursive = false
    let setOperator: (ToggleButtonRef) -> () = { button in
        let label = button.label!
        let newOperator = operators[label]!
        if recursive { return }
        recursive = true
        op = newOperator
        opLabel = label
        for other in buttons { other.active = false }
        button.active = true
        calculate()
        recursive = false
    }
    //
    // connect the widgets
    //
    leftEntry.onEditingDone  { _ in calculate() }
    rightEntry.onEditingDone { _ in calculate() }

    equalsButton.onClicked { _ in record() }

    buttons.forEach { $0.onToggled(handler: setOperator) }
}

//
// run the application
//
guard let status = Application.run(startupHandler: { app in
    app.addAction(entries: &appActionEntries, nEntries: appActionEntries.count, userData: app.ptr)
    settings = Settings.getDefault()
    if let builder = Builder("menus") {
        app.menubar = builder.get("menubar", MenuModelRef.init)
    }
    if app.prefersAppMenu(), let builder = Builder("appmenu") {
        app.appMenu = builder.get("appmenu", MenuModelRef.init)
    }
}, activationHandler: { app in
    guard let builder = Builder("appwindow") else {
        print("Could not build the application user interface")
        app.quit()
        return
    }
    //
    // set up the window
    //
    guard let box = builder.getObject(name: "vbox") else {
        print("Could not build application window")
        app.quit()
        return
    }
    let window = ApplicationWindowRef(application: app)
    let widget = WidgetRef(raw: box.ptr)
    window.add(widget: widget)
    window.title = "Hello GtkBuilder"
    window.canFocus = true
    window.borderWidth = 1
    window.grabFocus()
    window.showAll()
    widget.grabFocus()
    //
    // connect the widgets
    //
    connectWidgets(from: builder)
}) else {
    fatalError("Could not create Application")
}
guard status == 0 else {
    fatalError("Application exited with status \(status)")
}
