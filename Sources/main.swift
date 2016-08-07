import CGtk
import GLib
import GObject
import GIO
import Gtk

var settings: Gtk.Settings!
let cwd = getCurrentDir()!
let appInvocation = Process.arguments[0]
let appFull = findProgramInPath(program: appInvocation)!
let appDir = pathGetDirname(fileName: appFull)!
let appName = pathGetBasename(fileName: appInvocation)!

/// Convenience extensions for GtkBuilder to search for .ui files
extension Builder {
    /// Search for the given resource
    ///
    /// - parameter resource:   resource file to search for
    convenience init?(_ resource: String) {
        self.init()
        var lastError: ErrorProtocol?
        for path in ["Resources", cwd, "\(appDir)/Resources", "\(appDir)/../Resources", "/usr/share/\(appName)", "/usr/local/share/\(appName)", "/Library/Application Support/\(appName)"] {
            do {
                let _ = try addFrom(file: "\(path)/\(resource)")
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
}
/// Bind all the widgets together
///
/// - parameter builder: GtkBuilder to extract the widgets from
///
func connectWidgets(from builder: Builder) {
    let get = builder.getObject
    let leftEntry    = EntryRef(cPointer: get(name: "leftText"))
    let rightEntry   = EntryRef(cPointer: get(name: "rightText"))
    let plusButton   = ToggleButtonRef(cPointer: get(name: "plus"))
    let minusButton  = ToggleButtonRef(cPointer: get(name: "minus"))
    let timesButton  = ToggleButtonRef(cPointer: get(name: "times"))
    let divButton    = ToggleButtonRef(cPointer: get(name: "divide"))
    var textView     = TextViewRef(cPointer: get(name: "textView"))
    var resultLabel  = LabelRef(cPointer: get(name: "resultLabel"))
    let equalsButton = ButtonRef(cPointer: get(name: "equalsButton"))
    //
    // operations associated with the widgets
    //
    let buttons = [plusButton, minusButton, timesButton, divButton]
    let operators: Dictionary<String, (Double, Double) -> Double> = [
        "+" : (+),  "-" : (-),  "*" : (*),  "/" : (/)
    ]
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
    let setOperator: (ToggleButtonRef) -> () -> () = { pressedButton in
        var button = pressedButton
        let label = button.label!
        let newOperator = operators[label]!
        return {
            if recursive { return }
            recursive = true
            op = newOperator
            opLabel = label
            for var other in buttons { other.active = false }
            button.active = true
            calculate()
            recursive = false
        }
    }
    //
    // connect the widgets
    //
    leftEntry.connect( ComboBoxTextSignalName.changed, handler: calculate)
    rightEntry.connect(ComboBoxTextSignalName.changed, handler: calculate)

    equalsButton.connect(signal:.clicked, to: record)

    for button in buttons {
        button.connect(signal:.toggled, to: setOperator(button))
    }
}

//
// run the application
//
guard let status = Application.run(startupHandler: {
    var app = $0
    settings = Settings.getDefault()
    if let builder = Builder("menus.ui") {
        app.menubar = UnsafeMutablePointer(builder.getObject(name: "menubar"))
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
    guard let box = builder.getObject(name: "vbox") else {
        print("Could not build application window")
        app.quit()
        return
    }
    var window = ApplicationWindowRef(application: app)
    let widget = WidgetRef(cPointer: box)
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
