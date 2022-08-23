# Content of this repository

The different [**ImageJ**](https://fiji.sc/) and [**MATLAB**](https://ch.mathworks.com/products/matlab.html) scripts in this repository can be used to analyse **twitching behaviour** and **protein localization** of isolated twitching bacteria. Only isolated bacteria are correctly tracked and they must be flat on the microscope glass to ensure the whole cell body is in the same focal plane to measure fluorescent signals correctly along the whole cell. 

* In a basic analysis cells are getting segmented and tracked, and the fluorescence of the polar and cytoplasmic areas is measured for fluorescent images. All of this information is saved in a file see **readMe_variables.docx** in basic_analysis for a detailed list of saved data).

* The information saved in variables.mat contains:
  * information about the cell segmentation
  * information about the cell tracking
  * cell speed and movement direction
  * fluorecent measurements of cell poles and cytoplasms
  
* In different downstream analyses graphs are plotted for various measurements. The following scripts are available, they are explained in detail further below:
  * **reversals_phase_contrast** - measures the rate of direction changes (reversals) of twitching cells
  * **displacement_maps_speed** - measures cell speed and plots direction-corrected displacement maps
  * **pole_asymmetry_motile** - measures the size of subpopulations with symmetric and asymmetric protein localization between cell poles 
  * **alignment_motile** - measures the correlation of protein localization and twitching direction of the moving asymmetric subpopulation
  * **pole2pole_oscillations** - measures at which rate the localization of a protein switches between poles
  * **polar_loc_speed_motile** - measures cell speed + distribution, polar protein localization + distribution in motile cells, polar protein localization vs cell speed in motile cells; can handle two fluorescent channels, plots also polar protein localization of channel 1 vs 2  
  
* Additionally, there are a number of short auxiliary scripts used for data maintenance and quick checks 
 
 
 # How to use
 
Some analyses are mainly used for phase contrast image sequences and don't require fluorescence microscopy. Other scripts combine cell tracking from phase contrast image sequences with fluorescence measurements. Some analysis steps require dedicated settings or scripts for phase contrast only and phase contrast + fluorescence data.

The general workflow is as follows: 
 * Step 1: Preparation of microscopy data for segmentation and tracking
 * Step 2: Automated segmentation + tracking with [**BacStalk**](https://drescherlab.org/data/bacstalk/docs/index.html) and saving of **variables.mat**
 * Step 3: **Verifying correct tracking** by generating and checking movies
 * Step 4: Running downstream graph plotting scripts as required 
 
