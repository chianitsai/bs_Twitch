// @File(Label="Select data path", style="directory") choose_1
// @File(Label="Select data path", style="directory") choose_2
// @File(Label="Select data path", style="directory") choose_3


// delete or add above lines as required
// opens all movie folders in selected directory
// must be intervall directory!

print("\\Clear");

do_non_moving = 0;

addition = "_noSL"; // addition to the filename "C_with_trajectory+addition+_1.tif", eg "_noSL". If no addition leave empty: ""

dir=choose_1;
print(dir);

file=getFileList(dir);

for(j=0; j<file.length; j++) {
	l = lengthOf(file[j]);
	folder = file[j].substring(l-2,l-1);	
	directory=dir+File.separator+folder+File.separator+"Movie"+File.separator;
	print("Opening "+directory+"PC_with_trajectory"+addition+".tif");

	open(directory+"PC_with_trajectory"+addition+".tif");

	if (do_non_moving) {
		open(directory+"Non_Moving_PC_with_trajectory.tif");
	}
}

print("Done with "+dir);


dir=choose_2;
print(dir);

file=getFileList(dir);

for(j=0; j<file.length; j++) {
	l = lengthOf(file[j]);
	folder = file[j].substring(l-2,l-1);	
	directory=dir+File.separator+folder+File.separator+"Movie"+File.separator;
	print("Opening "+directory+"PC_with_trajectory"+addition+".tif");

	open(directory+"PC_with_trajectory"+addition+".tif");

	if (do_non_moving) {
		open(directory+"Non_Moving_PC_with_trajectory.tif");
	}
}

print("Done with "+dir);


dir=choose_3;
print(dir);

file=getFileList(dir);

for(j=0; j<file.length; j++) {
	l = lengthOf(file[j]);
	folder = file[j].substring(l-2,l-1);	
	directory=dir+File.separator+folder+File.separator+"Movie"+File.separator;
	print("Opening "+directory+"PC_with_trajectory"+addition+".tif");

	open(directory+"PC_with_trajectory"+addition+".tif");

	if (do_non_moving) {
		open(directory+"Non_Moving_PC_with_trajectory.tif");
	}
}

print("Done with "+dir);

/*
dir=choose_4;
print(dir);

file=getFileList(dir);

for(j=0; j<file.length; j++) {
	l = lengthOf(file[j]);
	folder = file[j].substring(l-2,l-1);	
	directory=dir+File.separator+folder+File.separator+"Movie"+File.separator;
	print("Opening "+directory+"PC_with_trajectory"+addition+".tif");

	open(directory+"PC_with_trajectory"+addition+".tif");

	if (do_non_moving) {
		open(directory+"Non_Moving_PC_with_trajectory.tif");
	}
}

print("Done with "+dir);


/*
dir=choose_5;
print(dir);

file=getFileList(dir);

for(j=0; j<file.length; j++) {
	l = lengthOf(file[j]);
	folder = file[j].substring(l-2,l-1);	
	directory=dir+File.separator+folder+File.separator+"Movie"+File.separator;
	print("Opening "+directory+"PC_with_trajectory"+addition+".tif");

	open(directory+"PC_with_trajectory"+addition+".tif");

	if (do_non_moving) {
		open(directory+"Non_Moving_PC_with_trajectory.tif");
	}
}

print("Done with "+dir);



dir=choose_6;
print(dir);

file=getFileList(dir);

for(j=0; j<file.length; j++) {
	l = lengthOf(file[j]);
	folder = file[j].substring(l-2,l-1);	
	directory=dir+File.separator+folder+File.separator+"Movie"+File.separator;
	print("Opening "+directory+"PC_with_trajectory"+addition+".tif");

	open(directory+"PC_with_trajectory"+addition+".tif");

	if (do_non_moving) {
		open(directory+"Non_Moving_PC_with_trajectory.tif");
	}
}

print("Done with "+dir);


dir=choose_7;
print(dir);

file=getFileList(dir);

for(j=0; j<file.length; j++) {
	l = lengthOf(file[j]);
	folder = file[j].substring(l-2,l-1);	
	directory=dir+File.separator+folder+File.separator+"Movie"+File.separator;
	print("Opening "+directory+"PC_with_trajectory"+addition+".tif");

	open(directory+"PC_with_trajectory"+addition+".tif");

	if (do_non_moving) {
		open(directory+"Non_Moving_PC_with_trajectory.tif");
	}
}

print("Done with "+dir);


dir=choose_8;
print(dir);

file=getFileList(dir);

for(j=0; j<file.length; j++) {
	l = lengthOf(file[j]);
	folder = file[j].substring(l-2,l-1);	
	directory=dir+File.separator+folder+File.separator+"Movie"+File.separator;
	print("Opening "+directory+"PC_with_trajectory"+addition+".tif");

	open(directory+"PC_with_trajectory"+addition+".tif");

	if (do_non_moving) {
		open(directory+"Non_Moving_PC_with_trajectory.tif");
	}
}

print("Done with "+dir);

/*
dir=choose_9;
print(dir);

file=getFileList(dir);

for(j=0; j<file.length; j++) {
	l = lengthOf(file[j]);
	folder = file[j].substring(l-2,l-1);	
	directory=dir+File.separator+folder+File.separator+"Movie"+File.separator;
	print("Opening "+directory+"PC_with_trajectory"+addition+".tif");

	open(directory+"PC_with_trajectory"+addition+".tif");

	if (do_non_moving) {
		open(directory+"Non_Moving_PC_with_trajectory.tif");
	}
}

print("Done with "+dir);
*/