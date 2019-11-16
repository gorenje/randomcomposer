RcSynthDef {

    var <>synthLookup;

    *new { |a,b|
        ^super.new.init(a,b);
    }

	def01 {
		// play samples
		SynthDef.new(synthLookup[0].first, { |arg0=64,  arg1=32, arg2=32, arg3=64,
			arg4=64, arg5=64, arg6=64, arg7=64,
			vel=nil, num=nil, out=0, buffer=nil,
			sampleIdx=inf, padNr=nil|

			var pan       = [-1,1,\lin].asSpec.map([0,127,\lin].asSpec.unmap(arg0));
			var vol       = ((arg1+1) / 128) * 4;
			var rate      = ((arg2+1) / 128) * 4;
			var roomsize  = arg3 / 128;
			var freqShift = [-5000,5000,\lin].asSpec.map([0,128,\lin].asSpec.unmap(arg4));
			var damp      = arg5 / 128;
			var mix       = arg6 / 128;
			var elevation = [-1,1,\lin].asSpec.map([0,127,\lin].asSpec.unmap(arg7));
			var left, right, output;

			#left, right = BufRd.ar(2, buffer,
				Phasor.ar(0, BufRateScale.kr(buffer) * rate, 0, BufFrames.kr(buffer)));

			#left,right = BiPanB2.ar(left, right, azimuth: elevation, gain: vol);

			output = Balance2.ar(left, right, pos: pan); //, level: vol);


			output = FreeVerb.ar(output * EnvGate.new(i_level:0, fadeTime: 1),
				mix: mix, room:roomsize, damp:damp);

			output = FreqShift.ar(output, freq: freqShift);

			Out.ar(out, output * EnvGate.new);
		}).add;

	}

	def02 {
		// sin oscillations
		SynthDef.new(synthLookup[1].first, { |arg0=64,  arg1=32, arg2=32, arg3=64,
			arg4=64, arg5=64, arg6=64, arg7=64,
			vel=nil, num=nil, out=0, buffer=nil,
			sampleIdx=inf, padNr=nil|

			var pan       = [-1,1,\lin].asSpec.map([0,127,\lin].asSpec.unmap(arg0));
			var vol       = ((arg1+1) / 128);
			var phase     = ((arg2+1) / 128) * 2pi;
			var roomsize  = arg3 / 128;
			var freqShift = [-10000,10000,\lin].asSpec.map([0,128,\lin].asSpec.unmap(arg4));
			var damp      = arg5 / 128;
			var mix       = arg6 / 128;
			var elevation = [-1,1,\lin].asSpec.map([0,127,\lin].asSpec.unmap(arg7));
			var freq      = [20,20000,\lin].asSpec.map([0,108,\lin].asSpec.unmap(num));
			var left, right, output;

			left = SinOsc.ar(freq, phase: phase * 0.9, mul:vol) *
			EnvGate.new(i_level:0, fadeTime: 1);
			right = SinOsc.ar(freq, phase: phase * 1.1, mul: vol) *
			EnvGate.new(i_level:0, fadeTime: 1);
			#left,right = BiPanB2.ar(left, right, azimuth: elevation);

			output = Balance2.ar(left, right, pos: pan); //, level: vol);

			output = FreeVerb.ar(output * EnvGate.new(i_level:0, fadeTime: 1),
				mix: mix, room:roomsize, damp:damp);

			output = FreqShift.ar(output, freq: freqShift);

			Out.ar(out, output * EnvGate.new);
		}).add;

	}

	def03 {
		// sin oscillations + saw osciallation
		SynthDef.new(synthLookup[2].first, { |arg0=64,  arg1=32, arg2=32, arg3=64,
			arg4=64, arg5=64, arg6=64, arg7=64,
			vel=nil, num=nil, out=0, buffer=nil,
			sampleIdx=inf, padNr=nil|

			var pan       = [-1,1,\lin].asSpec.map([0,127,\lin].asSpec.unmap(arg0));
			var vol       = ((arg1+1) / 128);
			var phase     = ((arg2+1) / 128) * 2pi;
			var roomsize  = arg3 / 128;
			var freqShift = [-10000,10000,\lin].asSpec.map([0,128,\lin].asSpec.unmap(arg4));
			var damp      = arg5 / 128;
			var mix       = arg6 / 128;
			var elevation = [-1,1,\lin].asSpec.map([0,127,\lin].asSpec.unmap(arg7));
			var freq      = [20,20000,\lin].asSpec.map([0,108,\lin].asSpec.unmap(num));
			var left, right, output;

			left = SinOsc.ar(freq, phase: phase * 0.9, mul:vol) *
			EnvGate.new(i_level:0, fadeTime: 1);
			right = Saw.ar(freq: freq, mul:vol) * EnvGate.new(i_level:0, fadeTime: 1);

			#left,right = BiPanB2.ar(left, right, azimuth: elevation);

			output = Balance2.ar(left, right, pos: pan); //, level: vol);

			output = FreeVerb.ar(output * EnvGate.new(i_level:0, fadeTime: 1),
				mix: mix, room:roomsize, damp:damp);

			output = FreqShift.ar(output, freq: freqShift);

			Out.ar(out, output * EnvGate.new);
		}).add;
	}

	def04 {
		// Play samples backwards
		SynthDef.new(synthLookup[3].first, { |arg0=64,  arg1=32, arg2=32, arg3=64,
			arg4=64, arg5=64, arg6=64, arg7=64,
			vel=nil, num=nil, out=0, buffer=nil,
			sampleIdx=inf, padNr=nil|

			var pan       = [-1,1,\lin].asSpec.map([0,127,\lin].asSpec.unmap(arg0));
			var vol       = ((arg1+1) / 128) * 4;
			var rate      = ((arg2+1) / 128) * 4;
			var roomsize  = arg3 / 128;
			var freqShift = [-5000,5000,\lin].asSpec.map([0,128,\lin].asSpec.unmap(arg4));
			var damp      = arg5 / 128;
			var mix       = arg6 / 128;
			var elevation = [-1,1,\lin].asSpec.map([0,127,\lin].asSpec.unmap(arg7));
			var left, right, output;

			#left, right = PlayBuf.ar(2, buffer,
				rate: BufRateScale.kr(buffer) * -1 * rate,
				startPos: BufFrames.ir(buffer) - 1, loop: 1);

			#left,right = BiPanB2.ar(left, right, azimuth: elevation, gain: vol);

			output = Balance2.ar(left, right, pos: pan); //, level: vol);

			output = FreeVerb.ar(output * EnvGate.new(i_level:0, fadeTime: 1),
				mix: mix, room:roomsize, damp:damp);

			output = FreqShift.ar(output, freq: freqShift);

			Out.ar(out, output * EnvGate.new);
		}).add;
	}

	init { |playOsc, playSample|
        synthLookup = List.new();

		synthLookup.add(["sample-synth",          "Samples",           nil]);
		synthLookup.add(["sinosc-synth",          "Sin Oscilater",     nil]);
		synthLookup.add(["sinoscsaw-synth",       "Sin Saw Oscilater", nil]);
		synthLookup.add(["sample-synth-backward", "Samples Backward",  nil]);

		this.def01();
		this.def02();
		this.def03();
		this.def04();

		synthLookup[0][2] = playSample;
		synthLookup[1][2] = playOsc;
		synthLookup[2][2] = playOsc;
		synthLookup[3][2] = playSample;
    }
}