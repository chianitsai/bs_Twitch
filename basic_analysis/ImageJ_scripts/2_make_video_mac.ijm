/* AIM of this macro:
 *  - create video from single images previously saved by Matlab
 *  - 4 differet videos will be created: 
 *  	- Non Moving cells:
 *  		- Phase contract image with contours and trajectory 
 *  		- Fluorescent image with poles position
 *  	- Moving cells:
 *  		- The same
*/

// TO MODIFY:


number=newArray("177", "1047" ,"1178" ,"2453" ,"2454" ,"2455" ,"2456"); 
Pil_type=newArray("fliC-", "fliC- pilA-", "fliC- pilA_T8V", "fliC- pilA_E11L", "fliC- pilA_Y30T", "fliC- pilA_R36E", "fliC- pilA_R36N");
//"fliC- cyaB- pCuAlgent_mNG_cyaB CuA20",

dates=newArray("20240813"); // once per whole number array
interval=newArray("5s interval-2h"); // once per whole number array
//dir_data="X:/uppersat-raw/Gani_sv_WS/bs_Twitch_data_storage/Fluorescence/";
dir_data="/Volumes/Gani_sv_WS/bs_Twitch_data_storage/";

do_fluocircles = 0;
do_nonmoving = 1;

addition = ""; // addition to the filename "C_with_trajectory+addition+_1.tif", eg "_noSL". If no addition leave empty: ""

setBatchMode(true)

for (f = 0; f < lengthOf(number); f++) {

	folder_name=number[f]+" "+Pil_type[f];

	for(d = 0; d < lengthOf(dates); d++) {

		date = dates[d];

		for(g = 0; g < lengthOf(interval); g++) {
	
			// STEP 1: open correct folder and get number of files for the loop:
			dir=dir_data+folder_name+"/"+date+"/"+interval[g];
			print(dir);
			file=getFileList(dir);
			print("\\Clear"); // clear 'LOG' page
			//print(file.length) // check point
			//print(file[0])	// check point
			//file.length
			
			for(j=0; j<file.length; j++) { // file.length
					directory=dir+"/"+file[j]+"/Movie";
					print("Working on:"); // check point
					print(directory); // check point
				
				if (do_nonmoving) {
				// -----------STEP 2: NON MOVING CELLS-----------------------------------------------------
					if (do_fluocircles) {
					 // STEP a): Fluorescent with poles
						run("Image Sequence...", "open=["+directory+"/Non_Moving_Fluo_with_poles_1.tif] file=Non_Moving_Fluo_with_poles_ sort");
						saveAs("Tiff", directory+"/Non_Moving_Fluo_with_poles.tif");
						close();
						
						list=getFileList(directory);
						for (i=0; i<list.length ; i++){
							if (startsWith(list[i],"Non_Moving_Fluo_with_poles_")) {
								//print(directory+"/"+list[i]);
								ok=File.delete(directory+"/"+list[i]);
								}
						}
					}
					
				  // STEP b): phase contract with contours and trajectories
					run("Image Sequence...", "open=["+directory+"/Non_Moving_PC_with_trajectory_1.tif] file=Non_Moving_PC_with_trajectory_ sort");
					saveAs("Tiff", directory+"/Non_Moving_PC_with_trajectory.tif");
					close();
					
					list=getFileList(directory);
					for (i=0; i<list.length ; i++){
						if (startsWith(list[i],"Non_Moving_PC_with_trajectory_")) {
							ok=File.delete(directory+"/"+list[i]);
							}
					}
				}
					
				// -----------STEP 3: MOVING CELLS-----------------------------------------------------
				if (do_fluocircles) {
				 // STEP a): Fluorescent with poles
					run("Image Sequence...", "open=["+directory+"/Fluo_with_poles"+addition+"_1.tif] file=Fluo_with_poles"+addition+"_ sort");
					saveAs("Tiff", directory+"/Fluo_with_poles"+addition+".tif");
					close();
					
					list=getFileList(directory);
					for (i=0; i<list.length ; i++){
						if (startsWith(list[i],"Fluo_with_poles"+addition+"_")) {
						//	print(directory+"/"+list[i]);
							ok=File.delete(directory+"/"+list[i]);
							}
					}
				}
				
				  // STEP b): phase contract with contours and trajectories	
					run("Image Sequence...", "open=["+directory+"/PC_with_trajectory"+addition+"_1.tif] file=PC_with_trajectory"+addition+"_ sort");
					saveAs("Tiff", directory+"/PC_with_trajectory"+addition+".tif");
					close();
					
					list=getFileList(directory);
					for (i=0; i<list.length ; i++){
						if (startsWith(list[i],"PC_with_trajectory"+addition+"_")) {
							ok=File.delete(directory+"/"+list[i]);
							}
					}
			}
		}
	}
}

setBatchMode(false);

	print("Done with:"); // check point
	Array.print(number); // check point