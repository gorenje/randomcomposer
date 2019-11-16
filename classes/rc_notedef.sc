RcNoteDef {
    var <>synth;
	var <>ezText;
	var <>isFree;
	var <>noteNum;

    *new { |ez_text|
        ^super.new.init(ez_text);
    }

    init { |ez_text|
		ezText = ez_text;
        synth = nil;
		isFree = true;
		noteNum = nil;
    }

	show { |labelString, textValue, synth|
		noteNum = labelString;
		isFree = false;
		ezText.value = textValue;
		ezText.labelView.string = labelString;
		ezText.visible_(true);
		synth = synth;
	}

	hide {
		ezText.visible_(false);
		synth = nil;
		isFree = true;
		noteNum = nil;
	}

	hideAndRelease {
		synth.set(\fadeTime, 2);
		synth.release;
		this.hide();
	}

	visible {
		^ezText.visible;
	}

	label {
		^ezText.labelView.string;
	}

	text {
		^ezText.value;
	}
}
