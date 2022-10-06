
two_h = 1;
profiles = 1;

manual = 1;

if (manual) {
	makeRectangle(360, 100, 2752, 1568);
}else {
	if (two_h) {
		if (profiles) {
			makeRectangle(2258, 106, 832, 712);
		}else {
			makeRectangle(2283, 99, 807, 807);
		}
	}else {
		makeRectangle(350, 106, 2739, 1562);
	}
}

run("Crop");
run("Select All");
run("Copy to System");
run("Close All");
