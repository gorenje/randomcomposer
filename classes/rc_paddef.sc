RcPadDef {
    var <>mainView;
    var <>commentText;
    var <>knobs;
    var <>typeText;
    var <>fileText;
    var <>synth;
	var <>noteNum;

    *new { |main_view, comment_view|
        ^super.new.init(main_view, comment_view);
    }

    init { |mView, cView|
        knobs         = List.new();
        commentText   = cView;
        mainView      = mView;
        synth         = nil;
    }

    setup { |values, noteText, synthType|
        8.do { |idx| knobs[idx].value = values[idx] };
        commentText.value = noteText;
        commentText.setColors(textBackground: Color.new(1,0.7,0.7));
        typeText.value = synthType;
    }

    activate { |knbs|
        mainView.background = Color.green;
        8.do { |idx| knbs[idx].value = knobs[idx].value };
    }

    inactive {
        mainView.background = nil;
    }

    isDefined {
        ^synth.notNil;
    }

    isActive {
        ^(mainView.background != nil);
    }

    reset {
        this.inactive();
        8.do { |idx| knobs[idx].value = 0 };
        mainView.background = nil;
        commentText.value = "";
        commentText.setColors(textBackground: Color.white);
        fileText.value = "";
        typeText.value = "";
        synth = nil;
    }
}