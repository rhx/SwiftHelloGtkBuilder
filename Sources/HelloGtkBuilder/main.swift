import CGtk
import GLib
import GLibObject
import GIO
import Gtk

var settings: Gtk.Settings!
let cwd = getCurrentDir()!
var appInvocation = CommandLine.arguments[0]
var appFull = findProgramInPath(program: appInvocation)!
let appDir = pathGetDirname(fileName: appFull)!
let appName = pathGetBasename(fileName: appInvocation)!
var appActionEntries = [
    GActionEntry(name: g_strdup("quit"), activate: { Gtk.ApplicationRef(gpointer: $2).quit() }, parameter_type: nil, state: nil, change_state: nil, padding: (0, 0, 0))
]

/// Convenience extensions for GtkBuilder to search for .ui files
extension Builder {
    /// Search for the given resource
    ///
    /// - parameter resource:   resource file to search for
    convenience init?(_ resource: String) {
        self.init()
        var lastError: Error?
        for path in ["Resources", cwd, "\(appDir)/Resources", "\(appDir)/../Resources", "/usr/share/\(appName)", "/usr/local/share/\(appName)", "/Library/Application Support/\(appName)"] {
            do {
                let _ = try addFromFile(filename: "\(path)/\(resource)")
                lastError = nil
                break
            } catch {
                lastError = error
                print(error)
            }
        }
        if let error = lastError {
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
    if let builder = Builder("menus.ui") {
        app.menubar = builder.get("menubar", MenuModelRef.init)
    }
}, activationHandler: { app in
    guard let builder = Builder("appwindow.ui") else {
        print("Could not build the application user interface")
        app.quit()
        return
    }
    //
    // set up the window
    //
    let box = builder.get("vbox", BoxRef.init)
    let window = ApplicationWindowRef(application: app)
    window.set(child: box)
    window.title = "Hello GtkBuilder"
    window.canFocus = true
    _ = window.grabFocus()
    window.present()
    _ = box.grabFocus()
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
