import CGtk
import GObject
import GIO
import Gtk

var settings: Gtk.Settings!

func connectWidgets(from builder: Builder) {
    let get = builder.getObject
    let leftEntry    = EntryRef(cPointer: get(name: "leftText"))
    let rightEntry   = EntryRef(cPointer: get(name: "rightText"))
    let plusButton   = ToggleButtonRef(cPointer: get(name: "plus"))
    let minusButton  = ToggleButtonRef(cPointer: get(name: "minus"))
    let timesButton  = ToggleButtonRef(cPointer: get(name: "times"))
    let divButton    = ToggleButtonRef(cPointer: get(name: "divide"))
//    let statusBar    = StatusbarRef(cPointer: get(name: "statusBar"))
//    let valueSlider  = ScaleRef(cPointer: get(name: "slider"))
    var textView     = TextViewRef(cPointer: get(name: "textView"))
    var resultLabel  = LabelRef(cPointer: get(name: "resultLabel"))
    let equalsButton = ButtonRef(cPointer: get(name: "equalsButton"))
    //
    // connect the widgets
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
//        let buffer = TextBufferRef(textView.buffer)
//        var beg = GtkTextIter()
//        var end = GtkTextIter()
//        gtk_text_buffer_get_bounds(UnsafeMutablePointer(buffer.ptr), &beg, &end)
//        let record = buffer.getText(start: TextIterRef(&beg), end: TextIterRef(&end), includeHiddenChars: true) ?? ""
        let record = textView.text
        let content = record + "\n\(l) \(opLabel) \(r) = \(result)"
//        buffer.set(text: content, len: -1)
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
    let _ = equalsButton.connect(ButtonSignalName.clicked, handler: record)
    let _ =    leftEntry.connect(ComboBoxTextSignalName.changed, handler: calculate)
    let _ =   rightEntry.connect(ComboBoxTextSignalName.changed, handler: calculate)
    for button in buttons {
        let _ = button.connect(MenuButtonSignalName.toggled, handler: setOperator(button))
    }
}

//
// run the application
//
guard let status = Application.run(startupHandler: {
    var app = $0
    settings = Settings.getDefault()
    let builder = Builder()
    do {
        let _ = try builder.addFrom(file: "menus.ui")
        app.menubar = UnsafeMutablePointer(builder.getObject(name: "menubar"))
    } catch {
        print(error)
    }
}, activationHandler: { app in
    let builder = Builder()
    do {
        //
        // set up the window
        //
        let get = builder.getObject
        let _ = try builder.addFrom(file: "appwindow.ui")
        guard let box = get(name: "vbox") else {
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
    } catch {
        print(error)
    }
}) else {
    fatalError("Could not create Application")
}
guard status == 0 else {
    fatalError("Application exited with status \(status)")
}
