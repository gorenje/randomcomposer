RcGui {
    var <>notes, <>pads, <>knobs, <>synthType, <>knobNameLookup, <>dialValues;
	var <>synthSelection;

    var >synthLookup, >knobs, >allSamples;

    var midiToPadIdx, activePad, playingNotes;

    *new {
        ^super.new.init();
    }

	*appClockRun { |func|
		AppClock.sched(0, { func.value(); nil });
	}

    init {
        notes          = List.new();
		// pads are setup by the GUI code, so the first X pads are filled
		// in outside of this class.
        pads           = List.new();
        knobs          = List.new();
        knobNameLookup = Dictionary.new;
        dialValues     = Array.newClear(indexedSize: 8);
        synthType      = 0;
		playingNotes   = nil!1024;

        // Dial naming lookup
        knobNameLookup.add( 0 -> "Pan (64 = mid)");
        knobNameLookup.add( 1 -> "Volume (32 = 1-to-1)");
        knobNameLookup.add( 2 -> "Rate (32 = 1-to-1)");
        knobNameLookup.add( 3 -> "Room Size");
        knobNameLookup.add( 4 -> "Freq Shift (64 = 1-to-1)");
        knobNameLookup.add( 5 -> "Damp");
        knobNameLookup.add( 6 -> "Mix");
        knobNameLookup.add( 7 -> "Elevation");

        midiToPadIdx = Dictionary.new;
        // Pads 1 to 4, Bank A
        midiToPadIdx.add( 20 -> 4 );
        midiToPadIdx.add( 21 -> 5 );
        midiToPadIdx.add( 22 -> 6 );
        midiToPadIdx.add( 23 -> 7 );
        // Pads 5 to 8, Bank A
        midiToPadIdx.add( 24 -> 0 );
        midiToPadIdx.add( 25 -> 1 );
        midiToPadIdx.add( 26 -> 2 );
        midiToPadIdx.add( 27 -> 3 );
        // Pads 1 to 4, Bank B
        midiToPadIdx.add( 28 -> 12 );
        midiToPadIdx.add( 29 -> 13 );
        midiToPadIdx.add( 30 -> 14 );
        midiToPadIdx.add( 31 -> 15 );
        // Pads 5 to 8, Bank B
        midiToPadIdx.add( 32 -> 8 );
        midiToPadIdx.add( 33 -> 9 );
        midiToPadIdx.add( 34 -> 10 );
        midiToPadIdx.add( 35 -> 11 );
    }

    setupPad { |midiControlNum, synthValues, note|
        var pad = pads[midiToPadIdx[midiControlNum]];
        if ( pad.notNil, {
            pad.setup(synthValues, note.text, synthLookup[synthType][1]);

			// sampleIdx is location 12 in the values array...
			if (allSamples[synthValues[12]].notNil, {
				var sample = allSamples[synthValues[12]];
				pad.fileText.value = sample.basename;
				pad.commentText.value = sample.comment;
			});
			pad.synth = note.synth;
			pad.noteNum = midiControlNum;
        });
		^pad;
    }

	padTaken { |midiControlNum|
		var pad = pads[midiToPadIdx[midiControlNum]];
		^(pad.notNil && pad.isDefined);
	}

    setActivePad { |pad|
        pads.do { |p| p.inactive };
		activePad = nil;
		if ( this.playingNote.isNil, {
			pad.activate(knobs);
			activePad = pad;
		});
    }

    releasePad { |midiControlNum|
        var pad = pads[midiToPadIdx[midiControlNum]];
        if ( pad.notNil, {
			pad.synth.set(\fadeTime, 2);
			pad.synth.release;
			pad.reset();
			if ( activePad == pad, { activePad = nil });
		});
    }

    dialChanged { |idx, value|
        if ( this.playingNote.isNil && activePad.notNil, {
			activePad.knobs[idx].value = value
		});
    }

    noteOn { |note, num, vel, text|
        pads.do { |p| p.inactive };
		activePad = nil;
		playingNotes[num] = note.show(num, text, note.synth);
    }

	noteOff { |num, vel|
		if ( playingNotes[num].notNil, {
			if (playingNotes[num].synth.notNil,{
				playingNotes[num].hideAndRelease;
			});
			playingNotes[num] = nil;
		});
	}

	playingNote {
		^notes.reject { |n| n.isFree }.first;
	}

	obtainNote {
		var note = notes.select { |n| n.isFree }.first;
		if(note.notNil, { note.isFree = false; });
		^note;
	}

	currentSynth {
		var note = this.playingNote;
		if ( note.isNil, {
			if ( activePad.notNil, { ^activePad.synth }, { ^nil });
		}, { ^note.synth });
	}
}