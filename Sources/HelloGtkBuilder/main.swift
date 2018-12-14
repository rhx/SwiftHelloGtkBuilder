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
    let leftEntry    = EntryRef(cPointer: get("leftText")!)
    let rightEntry   = EntryRef(cPointer: get("rightText")!)
    let plusButton   = ToggleButtonRef(cPointer: get("plus")!)
    let minusButton  = ToggleButtonRef(cPointer: get("minus")!)
    let timesButton  = ToggleButtonRef(cPointer: get("times")!)
    let divButton    = ToggleButtonRef(cPointer: get("divide")!)
    var textView     = TextViewRef(cPointer: get("textView")!)
    var resultLabel  = LabelRef(cPointer: get("resultLabel")!)
    let equalsButton = ButtonRef(cPointer: get("equalsButton")!)
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
    leftEntry.connect( EditableSignalName.changed, handler: calculate)
    rightEntry.connect(EditableSignalName.changed, handler: calculate)

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
        builder.getObject(name: "menubar").withMemoryRebound(to: GMenuModel.self, capacity: 1) { app.menubar = $0 }
    }
    if app.prefersAppMenu(), let builder = Builder("appmenu.ui") {
        builder.getObject(name: "appmenu").withMemoryRebound(to: GMenuModel.self, capacity: 1) { app.appMenu = $0 }
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
