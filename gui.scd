var sampleHome       = "samples";
var randomBlackBoard = Dictionary.new;
var synthLookup      = List.new;
var mainWindow       = Window("random composer", Rect(0,0,1400,1000)).front;
var allSamples       = List.new();
var gui              = RcGui.new;
var isRecording      = false;
var defaultSoundDev  = 1;

try {
    MIDIIn.connect;
} {};

Server.default.options.inDevice_("Built-in Microph");
Server.default.options.outDevice_("Built-in Output");

s.reboot();
s.waitForBoot();

~runOnAppClock = { |func| AppClock.sched(0, { func.value(); nil }); };

~doShellCmd = { arg commandline, func;
    var piper = Pipe.new(commandline, "r");
    l = piper.getLine;
    while ( {l.notNil}, { func.value(l); l = piper.getLine; }, {});
    piper.close;
};

~doShellCmd.value("find " + sampleHome +
	" -type f \\( -name \\*.wav -o -name \\*.aiff \\) -print", { |l|
		allSamples.add(RcSample.new(l, l[(sampleHome.size+1)..3000]))
	});

// Load the comments for each sample.
allSamples.do { |sample,idx|
    ~doShellCmd.value("exiftool -Comment " + sample.filename + " | colrm 1 34",
        { arg comment;
            var cnt = allSamples.size;
            sample.comment = comment;
            ("" + idx + "," + (cnt + idx) + "," + ((cnt*2)+idx)+":" +
                sample.basename + "->" + sample.comment).postln;
        }
    );
};

~setDials = { |sample|
    if( sample.notNil, {
        sample.getn(0, 14, { |ary|
            ~runOnAppClock.value({
                (0..7).do { |idx| gui.knobs[idx].value = ary[idx]; };
            });
        });
    }, { (0..7).do { |idx| gui.knobs[idx].value = 0; }; });
};

~playSample = { |num,vel|
	var note = gui.obtainNote;
    if (note.notNil, {
        var sampleIdx   = num.abs % allSamples.size;
        var sample      = allSamples[sampleIdx];
        var filename    = sample.filename;
        var comment     = sample.comment;
        var buffer      = Buffer.read(s, filename);

        note.synth = Synth.new(synthLookup[gui.synthType].first, [
            "num",       num,
            "vel",       vel,
            "buffer",    buffer,
            "arg0",      64,
            "arg1",      vel,
            "arg2",      32,
            "sampleIdx", sampleIdx
        ]);

        ~runOnAppClock.value({
            ~setDials.value(note.synth);
			gui.noteOn(note, num, vel, sample.basename +
				["(",sample.comment,")"].join + synthLookup[gui.synthType][1]);
        });
    });
};

~playSinOsc = { |num,vel|
	var note = gui.obtainNote;
    if (note.notNil, {
        note.synth = Synth.new(synthLookup[gui.synthType].first, [
            "num",    num,
            "vel",    vel,
            "buffer", nil,
            "arg0",   64,
            "arg1",   vel,
            "arg2",   32,
        ]);

        ~runOnAppClock.value({
            ~setDials.value(note.synth);
			gui.noteOn(note, num, vel, ["Freq: ", num.freq].join +
				synthLookup[gui.synthType][1]);
        });
    });
};

// this is the lookup for the different types of synth's, there are - at time
// of writing - four different synth definitions.
synthLookup = RcSynthDef.new(~playSinOsc, ~playSample).synthLookup;
gui.synthLookup = synthLookup;
gui.allSamples = allSamples;

~controlPads = { |src, chan, num, val|
    if ( (num > 19) && (num < 36), {
		var idx,ref;
		if ( val == 0, {
			~runOnAppClock.value({
				gui.releasePad(num);
			});
		}, {
			// freeze and keep.
			// first ensure that the pad isn't already taken, then find the
			// index of an sample that is playing via a key from the keyboard.
			if ( gui.padTaken(num).not, {
				~runOnAppClock.value({
					var note = gui.playingNote;

					if ( note.notNil, {
						var pad;
						note.synth.set(\padNr, num);
						note.synth.getn(0, 14, { |ary|
							~runOnAppClock.value({
								pad = gui.setupPad(num,ary,note);
								gui.setActivePad(pad);
								note.hide();
							});
						});
					});
				});
			});
		});
	});
};

~noteOn = { |src, chan, num, vel|
	synthLookup[gui.synthType][2].value(num,vel);
};

~noteOff = { |src,chan,num,vel|
	~runOnAppClock.value({gui.noteOff( num, vel )});
};

~controlSetSynthValue = { |src, chan, num, val|
	if ( num < 9, {
		var synth = gui.currentSynth;

		var newval = gui.knobs[num-1].value;

		if ( gui.dialValues[num-1].notNil ) {
			// If we're randomly composing, then use the dial values. If
			// we're not randomly composing, then use smaller steps to avoid
			// spring in the dial values.
			if ( randomBlackBoard["randomstep"].isNil, {
				newval = newval - if(val > gui.dialValues[num-1], {-1}, {1});
			}, {
				newval = newval - (gui.dialValues[num-1] - val);
			});
		};

		if ( synth.notNil ) { synth.set(["arg",num-1].join, newval); };

		gui.dialValues[num-1] = val;
		~runOnAppClock.value({
			gui.knobs[num-1].value = newval;
			gui.dialChanged(num-1, newval);
		});
	});
};

MIDIIn.addFuncTo(\noteOff, ~noteOff);
MIDIIn.addFuncTo(\noteOn,  ~noteOn);
MIDIIn.addFuncTo(\control, ~controlPads);
MIDIIn.addFuncTo(\control, ~controlSetSynthValue);


// Random music functionality

randomBlackBoard.add("randomstep" -> nil);


~queryPadsFrozen = {
	gui.pads.select { |a| a.isDefined }.collect { |a| a.noteNum };
};

~queryNotesOn = {
    gui.notes.select { |n| n.noteNum.notNil }.collect { |l| l.noteNum };
};

~randomUpdateInterval = { |knob|
    randomBlackBoard["randomstep"] = knob.value;
};

~randomDialChange = {
	var knob = (1..8).scramble.first;
	var val = 128.rand;
	// freqShift is rather extreme, therefore limit this to a specific
	// value range.
	if ( knob == 5, { val = (57..71).scramble.first });
    ~controlSetSynthValue.value(nil,nil,knob,val);
};

~randomSelectorChange = {
	var pad = gui.pads.select { |a| a.isDefined }.scramble.first;
	if ( pad.notNil, { gui.setActivePad(pad) });
};

~randomPadFreeze = {
    var lstPadsFrozen = ~queryPadsFrozen.value();

    var padNr = (20..35).select { |idx|
        lstPadsFrozen.indexOf(idx).isNil
    }.scramble.first;

    if ( padNr.isNil, {
        ~randomPadUnfreeze.value()
    }, {
        ~controlPads.value(nil,nil,padNr,1);
    });
};

~randomPadUnfreeze = {
    var padNr = ~queryPadsFrozen.value().scramble.first;

    if ( padNr.isNil, {
        ~randomPadFreeze.value()
    }, {
        ~controlPads.value(nil,nil,padNr,0);
    });
};

~randomNoteOn = {
    var lstNotesOn = ~queryNotesOn.value();

    var note = (0..(allSamples.size-1)).select { |idx|
        lstNotesOn.indexOf(idx).isNil
    }.scramble.first;

    if ( lstNotesOn.size > 9, {
        ~randomNoteOff.value()
    }, {
        ~noteOn.value(nil,nil,note,128.rand);
    });
};

~randomNoteOff = {
    var note = ~queryNotesOn.value().scramble.first;

    if ( note.notNil && (~queryNotesOn.value().size > 1), {
        ~noteOff.value(nil,nil,note,128.rand);
    }, { ~randomNoteOn.value() });
};

~randomAction = {
    if ( gui.currentSynth.isNil, {~randomNoteOn.value()});

    switch( 30.rand,
        10, { ~randomNoteOn.value() },
        11, { ~randomNoteOff.value() },
        12, { ~randomPadUnfreeze.value() },
        13, { ~randomPadFreeze.value() },

        14, { ~randomSelectorChange.value() },
        15, { ~randomSelectorChange.value() },
        16, { ~randomSelectorChange.value() },

        17, { ~randomSampleSelection.value() },
        18, { ~randomSampleSelection.value() },

        { ~randomDialChange.value() }
    );
};

~randomSampleSelection = {
	// avoid the oscillations ... they aren't cool
	~runOnAppClock.value({
		gui.synthSelection.valueAction_([0,3].scramble.first);
	});
};


// GUI Definition

// Various actions for the buttons on the GUI.

~randomButtonAction = {
	if ( randomBlackBoard["randomstep"].isNil, {
		randomBlackBoard["randomstep"] = 1;
		AppClock.sched(0, {
			~randomAction.value();
			randomBlackBoard["randomstep"];
		});
		randomBlackBoard["dial"].visible = true;
	}, {
		randomBlackBoard["randomstep"] = nil;
		randomBlackBoard["dial"].visible = false;
	});
};

~recordAction = {
	if ( isRecording, {
		s.stopRecording;
		isRecording = false;
	}, {
		s.record;
		isRecording = true;
	});
};

~exitAction = {
	if ( isRecording, { s.stopRecording; });
	0.exit;
};

~outputDeviceSelection = { |button|
	s.options.outDevice = ServerOptions.outDevices[button.value];
	s.reboot();
	s.waitForBoot();
};

~inputDeviceSelection = { |button|
	s.options.inDevice = ServerOptions.inDevices[button.value];
	s.reboot();
	s.waitForBoot();
};

~sampleRateAction = {
	"open -a 'Audio MIDI Setup'".unixCmd;
};

ServerMeterView.new(s, mainWindow, 1250@10, 2, 2);

{
	var freqScope = FreqScopeView(mainWindow, Rect(750, 550, 500, 0), s);
	var viewSteth = FlowView(mainWindow, Rect(1250, 550, 370, 370));
	var volView = View(mainWindow, Rect(1250, 230, 480, 480));

	freqScope.freqMode_(1); // change to log scale so we can see them
	freqScope.inBus_(1); // look at bus 1
	freqScope.dbRange_(200); // expand amplitude range
	freqScope.active_(false); // turn scope off (watch CPU)
	freqScope.active_(true); // turn it back on

	Stethoscope.new(s, view: viewSteth);
	mainWindow.onClose_({ freqScope.kill });
	s.volume.gui(volView);

}.value();

{
	var view, recButton, exitButton, randomButton;
	var outDevSelector, inDevSelector, sampleRateButton;

	recButton = Button(mainWindow, Rect(10, 10, 120, 25));
	recButton.states = [["Start Recording", Color.black, Color.white],
		["Stop Recording", Color.white, Color.red]];
	recButton.action = ~recordAction;

	exitButton = Button(mainWindow, Rect(640, 10, 120, 25));
	exitButton.states = [["Quit", Color.black, Color.white]];
	exitButton.action = ~exitAction;

	outDevSelector = PopUpMenu(mainWindow, Rect(780, 10, 150, 25));
	outDevSelector.items = ServerOptions.outDevices;
	outDevSelector.action = ~outputDeviceSelection;

	inDevSelector = PopUpMenu(mainWindow, Rect(940, 10, 150, 25));
	inDevSelector.items = ServerOptions.inDevices;
	inDevSelector.action = ~inputDeviceSelection;

	sampleRateButton = Button(mainWindow, Rect(1100, 10, 120, 25));
	sampleRateButton.states = [["Sample Rate", Color.black, Color.white]];
	sampleRateButton.action = ~sampleRateAction;

	gui.synthSelection = PopUpMenu(mainWindow, Rect(140, 10, 150, 25));
	gui.synthSelection.items = synthLookup.collect { |a| a[1] };
	gui.synthSelection.action = { |button|
		~runOnAppClock.value({
			gui.synthType = button.value;
		})
	};

	randomButton = Button(mainWindow, Rect(300, 10, 150, 25));
	randomButton.states = [["Start Randomisation", Color.black, Color.white],
		["Stop Randomisation", Color.white, Color.red]];
	randomButton.action = ~randomButtonAction;

	randomBlackBoard["dial"] = EZKnob(mainWindow, Rect(470, 10, 150, 25),
		"Interval",
		ControlSpec.new(minval: 0.1, maxval: 5,
			warp: 'lin', step: 0.1, default: 0, units: "secs"),
		unitWidth:0, initVal: 1, layout:\horz, labelWidth: 40,
		action: ~randomUpdateInterval)
	.setColors(Color.grey,Color.white)
	.font_(Font("Helvetica",11))
	.visible_(false);

	view = FlowView(mainWindow, Rect(10, 50, 750, 60));

	// dial settings
	8.do { arg idx;
		var func = { |knob|
			var synth = gui.currentSynth;
			if ( synth.notNil, { synth.set(["arg",idx].join, knob.value) });
			gui.dialChanged(idx, knob.value);
		};

		var knob = EZKnob(view, 180@24, gui.knobNameLookup[idx],
			ControlSpec.new(minval: 0, maxval: 127,
				warp: 'lin', step: 1.0, default: 0, units: nil),
			unitWidth:0, initVal: 0, layout:\horz, labelWidth: 80, action: func)
		.setColors(Color.grey,Color.white)
		.font_(Font("Helvetica",11));

		gui.knobs.add(knob);
	};
}.value();

{
	// list of frozen samples
	var view2 = FlowView(mainWindow, Rect(10, 120, 1220, 420));
	//view2.background = Color.red;

	4.do { |idx|
		view2.startRow;

		if ( idx == 2, { 10.do { view2.startRow } } );

		4.do { |ridx|
			var view = FlowView(view2, Rect(100, 100, 300, 90));

			var txt = EZText(view, 400@20, nil, initVal: nil,
				labelWidth: 0, layout: \horz).
			setColors(Color.grey, Color.white, textBackground: Color.white);

			var details = RcPadDef.new(view, txt);

			// view.background = Color.green;
			view.startRow;

			view.mouseDownAction = { |view,x,y,modifier,button,clickcnt|
				// this function needs to be defined here since we're
				// referencing the context here -- i.e. using details which
				// is defined here.
				if ( details.isDefined(), { gui.setActivePad(details); });
			};

			txt.textField.enabled = false;
			gui.pads.add(details);

			2.do { |cidx|
				var txt;
				view.startRow;

				4.do { |kjdx|

					var knob_action = { |knob|
						var argidx = (cidx * 4) + kjdx;
						if ( details.synth.notNil, {
							details.synth.set(["arg",argidx].join, knob.value)
						});
					};

					var knob = EZKnob(view, 28@24,nil,
						ControlSpec.new(minval: 0, maxval: 127,
							warp: 'lin', step: 1.0, default: 0, units: nil),
						unitWidth: 0, initVal: 0, layout:\horz, labelWidth: 80,
						action: knob_action);
					knob.numberView.visible = false;
					knob.enabled = true;
					details.knobs.add(knob);
				};

				txt = EZText(view, 150@20, nil, initVal: nil,
					labelWidth: 0, layout: \horz).
				setColors(Color.grey, Color.white, textBackground: Color.white);
				txt.textField.enabled = false;
				if ( cidx == 0,
					{ details.typeText = txt }, { details.fileText = txt });
			};
		};
	}
}.value();

// list of notes being played
{
	var view = FlowView(mainWindow, Rect(10, 550, 750, 250));
	// max 10 since there are 10 fingers!
	10.do { |idx|
		var notedef;
		var txt = EZText(view, 700@20, "Key", initVal: nil,
			labelWidth: 120, layout: \horz)
		.setColors(Color.grey, Color.white, textBackground: Color.white)
		.enabled_(true)
		.visible_(false);

		notedef = RcNoteDef.new(txt);
		gui.notes.add(notedef);

		txt.labelView.mouseDownAction = { |view,x,y,modifier,button,clickcnt|
			~runOnAppClock.value({gui.noteOff(view.string.asInteger,0)});
		};
	};
}.value();
