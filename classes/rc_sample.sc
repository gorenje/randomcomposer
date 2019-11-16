RcSample {
	var <>filename;
	var <>comment;
	var <>basename;

	*new { |fname,bname|
		^super.new.init(fname,bname);
	}

	init { |fname,bname|
		filename = fname;
		basename = bname;
		comment = "No Comment Set";
	}
}