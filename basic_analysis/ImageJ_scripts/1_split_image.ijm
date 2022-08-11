/* AIM of this macro:
 *  - create folder in correct position to run the Matlab analysis directely after
 *  - open the .nd2 file and save as tiff the two channel separately (C0-Phase contract & C1- fluorescent channel)
 *  - C0 channel save each time fram indipendently (for backstalk)
 *  - save a csv file in the folder with all the info on the video ((original name, pixel size, time interval) that will be use for the analysis
*/

// TO MODIFY:

index_int=2; // normally 2, for divided images 4
index_time=3; // normally 3, for divided images 5

number=newArray("1153","1287","1153"); 
Pil_type=newArray("Test_1153","Test_1287","Test_1153"); 

same_date = 0; // if same date 1, uses the first date/folder_name entry for all numbers, otherwise put date/folder_name for every item of the number vector

folder_name=newArray("20220722 Still and Twitch 1153 1286 1287 1294 1295","20220722 Still and Twitch 1153 1286 1287 1294 1295","20220721 Still and Twitch 1153 1324 1325 1471 1472"); // per number use / instead of \
date=newArray("20220722","20220722","20220721"); // per number

match=".*2h37_5s.*" // what to look for in file name
dir_save="G:/Marco/bs_Twitch_data_storage/"; // !! change here the directory where the folders are!!
only_PC=0 // 1 if YES, 0 if NO
correct_drift=0 // 1 if YES, 0 if NO -> runs StackReg_translation plugin !!! does NOT work well with fluo and PC images!!!

// STEP 1: chose folder nd2 douments are
//dir_data=getDirectory("Choose a Directory")

dir_data = "G:/Marco/Twitching Microscopy/Widefield/"

setBatchMode(true)

for(s=0; s<lengthOf(number);s++){

	if (same_date) {
		dir=dir_data+folder_name[0]+"/";
	}
	else {
		dir=dir_data+folder_name[s]+"/";
	}
	
	list=getFileList(dir); // here I get the list of all the microscopes videos of the folder 
	
	// STEP 2: create folder
	directory=dir_save+number[s]+" "+Pil_type[s]+"/";
	File.makeDirectory(directory);
	
	//name_folder=0; // variable define to increse folder number at each loop
	
	for(i=0; i<list.length;i++){
		if (startsWith(list[i],number[s])){
			if (matches(list[i], match)){ // change if all or only some of the files should be processed
			print("Working on:");
			print(dir); // check point
			print(list[i]); // check point
			// STEP a): split name of video to get all info necessary 2h37
			split_name=split(list[i],"_");
			interval=split_name[split_name.length-index_int]+" interval"; //split_name.length-?: for the interval time between frames
			interval=interval+"-"+split_name[split_name.length-index_time]; //split_name.length-?: to know after how long on on plate video had been recorded
		
			// STEP b): create folders
			if (same_date) {
				dir_date=directory+date[0];
			}
			else {
				dir_date=directory+date[s];
				}
			
			File.makeDirectory(dir_date);
			File.makeDirectory(dir_date+"/"+interval)
		
			nbr_folder=getFileList(dir_date+"/"+interval); // to know how many folders are aleady present 
			name_folder=nbr_folder.length+1;
			new_directory=dir_date+"/"+interval+"/"+name_folder;
			
			File.makeDirectory(new_directory)
			File.makeDirectory(new_directory+"/Movie") // MATLAB will save the each image separately there. Video_maker.ijm will make a video with images from there
		
		
		// STEP 3 : open video and extract info
			open(dir+list[i]);
			saveAs("Tiff", new_directory+"/data");
			getPixelSize(unit, pw, ph);
		
			if(!only_PC){
				
			
		// STEP 4: split the channels
			run("Split Channels");
			
		// STEP 5 : save fluorescent channel al C1-data
			selectWindow("C2-data"+".tif");
			run("Subtract Background...", "rolling=50 stack");
			if(correct_drift){
				run("StackReg ", "transformation=Translation");
			}
			C1_data=new_directory+"/C1-data.tif";
			saveAs("Tiff", C1_data);
			close();
		
		// STEP 6 : save phase contract channel al C0-data + save each time frae separately (for BackStalk)
			selectWindow("C1-data"+".tif");
			if(correct_drift){
				run("StackReg ", "transformation=Translation");
			}
			C0_data=new_directory+"/C0-data.tif";
			saveAs("Tiff", C0_data);
			run("Image Sequence... ", "format=TIFF name=C0-data_t digits=3 save=["+new_directory+"]");
			close();
			}
			
			if(only_PC) {	
		// STEP 6 : save phase contract channel al C0-data + save each time frae separately (for BackStalk)
			if(correct_drift){
				run("StackReg ", "transformation=Translation");
			}
			C0_data=new_directory+"/C0-data.tif";
			saveAs("Tiff", C0_data);
			run("Image Sequence... ", "format=TIFF name=C0-data_t digits=3 save=["+new_directory+"]");
			close();
				
			}
		// STEP 7: save csv file containing all the info needed for analysis (original name, pixel size, time interval)
			// save csv file
			print("\\Clear"); // clear 'LOG' page
			print(dir);
			print(list[i]);
			print(pw);
			print(ph);
			frame_interval=split(interval,"s");
			print(frame_interval[0]);
			selectWindow("Log");
			saveAs("Text",new_directory+"/parameters.csv");
			
			print("\\Clear"); // clear 'LOG' page
			ok = File.delete(new_directory+"/data.tif"); 
			}
		}		
	}
}

setBatchMode(false)

print("Done with:");
print(dir);
