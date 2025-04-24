/* AIM of this macro:
 *  - create folder in correct position to run the Matlab analysis directely after
 *  - open the .nd2 file and save as tiff the two channel separately (C0-Phase contract & C1- fluorescent channel)
 *  - C0 channel save each time fram indipendently (for backstalk)
 *  - save a csv file in the folder with all the info on the video ((original name, pixel size, time interval) that will be use for the analysis
*/

// TO MODIFY:

index_int=2; // normally 2, for divided images 4
index_time=3; // normally 3, for divided images 5

number=newArray("923n2619"); 
Pil_type=newArray("mNG_PilG mKate"); 

same_date = 0; // if same date 1, uses the first date/folder_name entry for all numbers, otherwise put date/folder_name for every item of the number vector

folder_name=newArray("20250403_Laure_twitching"); // per number use / instead of \
date=newArray("20250203"); // per number

match=".*_5s.*" // what to look for in file name
dir_save="X:/uppersat-raw/Gani_sv_WS/bs_Twitch_data_storage/Laure/"; // !! change here the directory where the folders are!!

only_PC=0 // 1 if YES, 0 if NO
correct_drift=1 // 1 if YES, 0 if NO -> runs MultiStackReg_translation plugin, works well with multi channel stacks

reg_file_loc = "X:/uppersat-raw/Gani_sv_WS/git/bs_Twitch/basic_analysis/ImageJ_scripts/TransformationMatrices.txt"; // folder where registration file is saved, must exist

// STEP 1: chose folder nd2 douments are
//dir_data=getDirectory("Choose a Directory")

dir_data = "X:/uppersat-raw/Gani_sv_WS/Microscopy/Widefield/"

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

		// STEP 5 : save phase contract channel al C0-data + save each time frae separately (for BackStalk)
			selectWindow("C1-data"+".tif");
			if(correct_drift){
				stack_name_ref = "C1-data"+".tif";
				run("MultiStackReg", "stack_1="+stack_name_ref+" action_1=Align file_1=["+reg_file_loc+"] stack_2=None action_2=Ignore file_2=[] transformation=Translation save");
			}
			C0_data=new_directory+"/C0-data.tif";
			saveAs("Tiff", C0_data);
			run("Image Sequence... ", "format=TIFF name=C0-data_t digits=3 save=["+new_directory+"]");
			close();
			}
			
		// STEP 6 : save fluorescent channel al C1-data and C2-data
			// C1 usually mNeonGreen
			selectWindow("C2-data"+".tif");
			run("Subtract Background...", "rolling=50 stack");
			if(correct_drift){
				stack_name_fluo_1 = "C2-data"+".tif";
				run("MultiStackReg", "stack_1="+stack_name_fluo_1+" action_1=[Load Transformation File] file_1=["+reg_file_loc+"] stack_2=None action_2=Ignore file_2=[] transformation=Translation");
			}
			C1_data=new_directory+"/C1-data.tif";
			run("Yellow");
			saveAs("Tiff", C1_data);
			close();

			// C2 usually mScarlet-I
			selectWindow("C3-data"+".tif");
			run("Subtract Background...", "rolling=50 stack");
			if(correct_drift){
				stack_name_fluo_2 = "C3-data"+".tif";
				run("MultiStackReg", "stack_1="+stack_name_fluo_2+" action_1=[Load Transformation File] file_1=["+reg_file_loc+"] stack_2=None action_2=Ignore file_2=[] transformation=Translation");
			}
			C2_data=new_directory+"/C2-data.tif";
			run("Yellow");
			saveAs("Tiff", C2_data);
			close();
		
			
			if(only_PC) {	
		// STEP 6 : save phase contract channel al C0-data + save each time frae separately (for BackStalk)
			if(correct_drift){
				stack_name_ref = "C1-data"+".tif";
				run("MultiStackReg", "stack_1="+stack_name_ref+" action_1=Align file_1=["+reg_file_loc+"] stack_2=None action_2=Ignore file_2=[] transformation=Translation save");
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
