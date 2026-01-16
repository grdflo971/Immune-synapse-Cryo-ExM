// Granule segmentation  and mesurement using trainable Labkit 3D segmentation. 
// This macro is design to segment Perforin and GranzymeB lytic granules in 3D using pre-trained Labkit models.
// It requieres to pre-segment the cells using Cryo-ExM_synapse_segmentation or manual segmentation.
// It allows to get granule shape and fluorescence intensity. Does not provide granule polarization.
// The measures are not correct for expansion factor. Do not forget to correct after analysis.




run("Close All");
roiManager("reset");

// Chose the working directory where the .lif file is located
dirdata = getDirectory("Choose the folder you would like to analyze");
// Chose the working directory where the GranzB and perforin Labkit classifiers are stored
dirclassifier = getDirectory("Choose the folder containing the classifiers");
files = getFileList(dirclassifier);
Array.print(files);

// Choose the folder where the cell ROI are stored
dir_roi = dirdata+"Segmented"+File.separator();
// Make a folder to save the segmentation data
dir_result = dirdata+"Quantifications_Labkit"+File.separator();
// Make a folder to save the probability map images from Labkit
dir_probability = dirdata+"Porbability_map_Labkit"+File.separator();
// Make a folder to save the object map images
dir_Objectmap = dirdata+"Object_map-Labkit"+File.separator();
File.makeDirectory(dir_result); 
File.makeDirectory(dir_probability);
File.makeDirectory(dir_Objectmap);

// Extension of the files
extension = "Lng_LVCC";
ext_size = lengthOf(extension);

// Method used to determine the bottom and top plane of the cell: "manual"
method= "manual";

// Set variable granule polarization true
Granule_pol = true;


// Select the good channels
Dialog.create("Choose the corresponding channels");
Dialog.addNumber("Actin:", 2);
Dialog.show();
Actin_channel = Dialog.getNumber();

// Define the number of channels you want to analyse
Dialog.create("How many granule stainings will you analyse?");
Dialog.addNumber("Stainings number:", 2);
Dialog.show();
staining_nb = Dialog.getNumber();

// Create variables for channel names and number
staining = newArray(0);
staining_channel = newArray(0);

for (channel = 0; channel < staining_nb; channel++) {
	Dialog.create("Staining_"+channel+1);
	Dialog.addString("Protein:", "Perforin");
	Dialog.addNumber("Channel:", 1);
	Dialog.show();
	staining[channel] = Dialog.getString();
	staining_channel[channel] = Dialog.getNumber();
}



// Get all files names in the folder
ImageNames=getFileList(dirdata); 
cell_nb = -1;

// Initialize Results and ROI Manager
if(isOpen("Results")) {
		selectWindow("Results");
		run("Close");
		}
		
if(isOpen("ROI Manager")) {
	roiManager("reset");
	}

// Initialise the Series array of the pictures
nbSerieMax = 50;
series=newArray();

for(i=1;i<nbSerieMax;i=i+1) {
	series[i]="series_"+i+" ";
}



// Get the Series number of each ROI saved after using the cell segmentation macros
roi_name = getFileList(dir_roi);
print("ROI_name: ");
Array.print(roi_name);

roi_serie =newArray();

// iterate over the names of the ROI files to get the ID number of the image
for(roi=0; roi<lengthOf(roi_name); roi++){
	
	roiset = roi_name[roi];
	
	// Find index of "Image " and "_Lng"
	roi_img_index = indexOf(roiset, "Image ");	
	RoiSet_index = indexOf(roiset, "RoiSet");
	
	// Adapting to the LasX last update 
	if (roi_img_index >= 0 && RoiSet_index > roi_img_index) {
	    start = roi_img_index + lengthOf("Image ");
	    roi_serie[roi] = substring(roiset, start, RoiSet_index);
	    print("roi_serie1: ", roi_serie[roi]);
	    sav_roi = "_Image ";
	   	    
		} else { // If the image name contains "Series" instead of image (due to LasX update)
			roi_img_index = indexOf(roiset, "Series");
			print("Fallback roi_img_index: ", roi_img_index);
			sav_roi = "_Series";
			
			if (roi_img_index >= 0 && RoiSet_index > roi_img_index) {
			    start = roi_img_index + lengthOf("Series");
			    roi_serie[roi] = substring(roiset, start, RoiSet_index);
			    print("roi_serie2: ", roi_serie[roi]);
			    sav_roi = "_Series ";
			    
			    } else {
			    	print("Could not extract series number from name: ", roiset);
				}
		}
}

// Set measurments
run("Set Measurements...", "area mean min shape integrated redirect=None decimal=3");

// Open all the lif files

for (i=0; i<lengthOf(ImageNames); i++) { //Loop over all images in the direction
	// Open all images and Roi
	 
	 if (endsWith(ImageNames[i], ".lif")) {
		name_size = lengthOf(ImageNames[i]) - 4;
		LifName=substring(ImageNames[i],0 ,name_size);
		print("LifName: ",LifName);
	

		for(image_serie=0 ; image_serie<nbSerieMax; image_serie++){
			run("Bio-Formats Importer", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series[image_serie]);
			Name = getTitle();
			
			if (endsWith(Name, extension)) {
				
				// Find index of "Image " and "_Lng"
				lng_index = indexOf(Name, "_Lng");
				img_index = indexOf(Name, "Image ");
				
				if (img_index >= 0 && lng_index > img_index) {
				    start = img_index + lengthOf("Image ");
				    Serie_nb = substring(Name, start, lng_index);
				    print("Series_number1: ", Serie_nb);
				    sav_roi = "_Image ";
					} else { // If the image name contains "Series" instead of image (due to LasX update)
						img_index = indexOf(Name, "Series");
						print("Fallback img_index: ", img_index);
						
						if (img_index >= 0 && lng_index > img_index) {
						    start = img_index + lengthOf("Series");
						    Serie_nb = substring(Name, start, lng_index);
						    print("Series_number2: ", Serie_nb);
						    sav_roi = "_Series";
						    } else {
						    	print("Could not extract series number from name: ", Name);
							}
					}	
								
//				Serie_nb = substring(Name,lengthOf(Name)-12,lengthOf(Name)-9);
				print("Serie_nb: ", Serie_nb);
				
				// Found the corresponding cell segmentation file 
				roiManager("reset");
				
				found = false;
								
				for (s=0; s<lengthOf(roi_serie); s++){
					roi1 = roi_serie[s];
					print("roi1: ", roi1);
										
					if (roi1 == Serie_nb){
						roiFilePath = dir_roi+LifName+sav_roi+Serie_nb+"RoiSet.zip";
						print("RoiFilePath: ", roiFilePath);
						
						if (File.exists(roiFilePath)){
						
						roiManager("Open", dir_roi+LifName+sav_roi+Serie_nb+"RoiSet.zip");
						
						found = true; 
						break;
						}
					}
				}
				
				if (!found) {
					print("No ROI found for serie_nb: " + Serie_nb + "RoiSet.zip");
					close();
					continue;
					
				}
				
				//Get voxel depth
				selectWindow(Name);
				getVoxelSize(width, height, depth, unit);
				voxel_depth = depth;
				
				
				// Make duplicate image and enhance contrast to facilitate the flow				
				selectWindow(Name);
				run("Duplicate...", "title=Total_Image"+Serie_nb+ " duplicate");
				Stack.setPosition(3,20,1);
				Stack.setChannel(Actin_channel);
				run("Enhance Contrast", "saturated=0.35");
				
				
				
				//count the number of ROIs opened in the roi manager
				n= roiManager("count");
				
				
				// Get each cell of the image from the ROI
				for (object = 0; object < n; object++) {
					cell_nb = cell_nb + 1;
					cell_ID = Serie_nb+"_cell"+object + 1;
					
				// Create cell images deconv 
					roiManager("reset");
					roiManager("Open", dir_roi+LifName+sav_roi+Serie_nb+"RoiSet.zip");
					
		  			selectWindow("Total_Image"+Serie_nb);		  			
				    roiManager("select", object);
		  			run("Duplicate...", "title=deconv_cell"+cell_ID+ " duplicate");
		  			roiManager("reset");
		  			roiManager("Add");
		  			run("Clear Outside", "stack");
		  			run("Clear Results");
		  			roiManager("Measure");
					Area = getResult("Area", 0);
					run("Clear Results");
		  			
		  			
		  			
					
//------------------ GET CELL SIZE AND SYNAPSE PLANE ----------------------------------------------------------------
					
					if (method=="manual") { // The user choose the planes by hand
								selectWindow("deconv_cell"+cell_ID);
								getDimensions(width, height, channels, slices, frames);
								run("Select None");
								
								// Duplicate the actine channel only to make sure to get the right Z plan number
								run("Duplicate...", "title=Actine duplicate channels="+Actin_channel);
								selectImage("Actine");
								
								// Run orthogonal view
								run("Orthogonal Views");
								// Wait for orthogonal views to be generated
								wait(1000);
								titles = getList("image.titles");
								
								// Ensure orthogonal views are generated
		                        Stack.getOrthoViewsIDs(XY, YZ, XZ);
								selectImage("Actine");
								beep();
								waitForUser("Select the FIRST SYNAPTIC plane");
								Z0 = getSliceNumber();
								
								waitForUser("Select the TOP CELL plan");
								Z2 = getSliceNumber();
								
								// Calculate the slice number 
								low_slice = (Z0/nSlices)*slices;
								Z0 = Math.ceil(low_slice);
								print("Z_low_synapse:", Z0);
								
								
								top_cell = (Z2/nSlices)*slices;
								Z2 = Math.ceil(top_cell);
								print("Z_top_cell:", Z2);
								
								CellSize = (Z2-Z0)*voxel_depth;
								
								
							}
							Stack.stopOrthoViews;							
				  			close("Actine");
				  			
							
				
//-----------------Get total Florescence of perforin and GranzymeB per cell---------------------------------------------
		  			// Create the result table
					if (isOpen("Total_Intensity_Results")==false) {
					Table.create("Total_Intensity_Results");
					}
					 // Add the image and cell ID in the result table
			  		selectWindow("Total_Intensity_Results");
					Table.set("Image Name",cell_nb,LifName);
					Table.set("Cell_ID",cell_nb,cell_ID);
					Table.update;
					
					
					// Create the result table for background measurments
					if (isOpen("Background_Intensity_Results")==false) {
					Table.create("Background_Intensity_Results");
					}
					 // Add the image and cell ID in the result table
			  		selectWindow("Background_Intensity_Results");
					Table.set("Image Name",cell_nb,LifName);
					Table.set("Cell_ID",cell_nb,cell_ID);
					Table.update;
				
					// Set a new array to get the name of the images from the segmentation
					ImageObject = newArray();
				
					// Set variable to store the number of detected granules 
					n_count = "";
					
				
					//loop on the channels to measure the total intensity of each channels per cells
					for (channel = 0; channel < staining_nb; channel++) {
										
						// Measure BACKGROUND of the analysed channel
						selectWindow("Total_Image"+Serie_nb);
						run("Duplicate...", "title="+staining[channel]+" duplicate channels="+staining_channel[channel]);
						selectWindow(staining[channel]);
						
						//make MAX intensity progection of the full cell (selected stack between Z0 and Z2)
						run("Z Project...", "start=" + Z0 + " stop=" + Z2 + " projection=[Max Intensity]"); 
						
						// Measure Background fluorescent intensity
						selectWindow("MAX_"+staining[channel]);
						makeRectangle(4, 2, 33, 33);
						beep();
						waitForUser("Move ROI to measure channel backgound");
						run("Measure");
						
						// Store the wanted Background values
						IntDen_image = getResult("IntDen",0); 					
						Mean_image = getResult("Mean",0);
						RawIntDen_image = getResult("RawIntDen",0);
						Area_image = getResult("Area",0);
						run("Clear Results");
						close("MAX_"+staining[channel]);
						
						// Update the backrgound table results
						selectWindow("Background_Intensity_Results");
		  				Table.set(staining[channel]+"_IntDen",cell_nb,IntDen_image);
		  				Table.set(staining[channel]+"_mean",cell_nb,Mean_image);
		  				Table.set(staining[channel]+"_RawIntDen",cell_nb,RawIntDen_image);
		  				Table.set(staining[channel]+"_Area",cell_nb,Area_image);		  				
						Table.update;
						
						close(staining[channel]);
						close("MAX_"+staining[channel]);
					
					
					// Measurment of the channel TOTAL INTENSITY on the deconv_cell image that was cleared outside ROI
						selectWindow("deconv_cell"+cell_ID); //This image has no signal outsid of the cell edges
						run("Select None");
			  			run("Duplicate...", "title="+staining[channel]+" duplicate channels="+staining_channel[channel]);
						
		  				selectWindow(staining[channel]);
		  				run("Z Project...", "start=" + Z0 + " stop=" + Z2 + " projection=[Max Intensity]");//The measure will be done on the Max intensity projection of the selected stacks
		  				run("Clear Results");
		  				roiManager("Measure");
		  				Rawdensity_Tot =getResult("RawIntDen", 0);
		  				Intdensity_Tot =getResult("IntDen", 0);
		  				run("Clear Results");
		  				
		  				selectWindow("Total_Intensity_Results");
		  				Table.set(staining[channel]+"_RawIntDen_background",cell_nb,RawIntDen_image);
		  				Table.set(staining[channel]+"_IntDen_background",cell_nb,IntDen_image);
		  				Table.set("Area",cell_nb,Area)
						Table.set(staining[channel]+"_RawIntDen",cell_nb,Rawdensity_Tot);
						Table.set(staining[channel]+"_IntDen",cell_nb,Intdensity_Tot);
						Table.update;
						
						close(staining[channel]);
						close("MAX_"+staining[channel]);
						
						
						
// ----------------- Granule SEGMENTATION  ----------------------------------------------------------------
						
						// Use Labkit trained model to segment the lytic granules--------------------------
						
						if (Granule_pol == true) {
							selectWindow("Total_Image"+Serie_nb);
							// get the ROI of the cell
							roiManager("reset");
							roiManager("Open", dir_roi+LifName+sav_roi+Serie_nb+"RoiSet.zip");
							roiManager("select", object);
				    		run("Duplicate...", "title="+staining[channel]+" duplicate channels="+staining_channel[channel]+ " slices="+Z0+"-"+Z2);
				    		
		  					roiManager("reset");
		  					roiManager("Add");
		  					
		  					
							//Found the Z slice that has the highest signal in order to reset minAndMax at this specific Z. 
							selectWindow(staining[channel]);
							// Initialize variables to store the maximum intensity and its corresponding Z-step
							number_of_slices1 = nSlices();
							maxIntensity1 = 0;
							maxIntensityZStep1 = -1; // Initialize with an invalid value
							
							// Loop through each Z-slice
							for (slices = 1; slices <= number_of_slices1; slices++) {
								selectWindow(staining[channel]);
								roiManager("Select", 0);
							    // Set the current slice
							    setSlice(slices);
							
							    // Get the intensity of channel 1 (adjust the channel number if needed)
							    run("Measure");
							    intensity1 = getResult("Mean");// Uses the RawIntDen to find the slice with the highest intencity
							    
							    // Check if the intensity is greater than the current maximum intensity
							    if (intensity1 > maxIntensity1) {
							        // Update the maximum intensity and its corresponding Z-step
							        maxIntensity1 = intensity1;
							        maxIntensityZStep1 = slices;							       							        
							    }							   
							} 
							close("Results");
						    selectWindow(staining[channel]);
						    setSlice(maxIntensityZStep1);
							print("Max intensity slice 1 : ", maxIntensityZStep1);
							
							//Rest the brightness at the slice with the maximum intensity
							resetMinAndMax();
							
		  					
//-------------------------- Use pre-trained LabKit models for 3D segmentation 
							selectWindow(staining[channel]);
							
							// Run the trained LabKit model to detectec granules and get a probability map
							run("Calculate Probability Map With Labkit", "input="+staining[channel]+" segmenter_file=[" +dirclassifier+staining[channel]+".classifier] use_gpu=false");
							wait(1000);
							
							//Get the probability map of the segmented objects
							selectImage("probability map for "+staining[channel]);
							Stack.setChannel(2);
							run("Duplicate...","title=Probability_map_"+staining[channel]+" duplicate channels=2");
					
//--------------------------Found the Z slice that has the highest signal in order to reset minAndMax at this specific Z.
							//This step is important and allows to get a more accurate thresholding.
							
							// Initialize variables to store the maximum intensity and its corresponding Z-step
							number_of_slices2 = nSlices();
							maxIntensity2 = 0;
							maxIntensityZStep2 = -1; // Initialize with an invalid value
							
							// Loop through each Z-slice
							for (slices = 1; slices <= number_of_slices2; slices++) {
								selectWindow("Probability_map_"+staining[channel]);
								roiManager("Select", 0);
							    // Set the current slice
							    setSlice(slices);
							
							    // Get the intensity of channel 1 (adjust the channel number if needed)
							    run("Measure");
							    intensity2 = getResult("RawIntDen");// Uses the RawIntDen to find the slice with the highest intencity
							    
							    // Check if the intensity is greater than the current maximum intensity
							    if (intensity2 > maxIntensity2) {
							        // Update the maximum intensity and its corresponding Z-step
							        maxIntensity2 = intensity2;
							        maxIntensityZStep2 = slices;							       							        
							    }							   
							} 
							close("Results");
						    selectWindow("Probability_map_"+staining[channel]);
						    setSlice(maxIntensityZStep2); // Set the probability map to the Z that has the highest RawIntDen.
							
							//Reset the brightness at the slice with the maximum RawIntDen.This makes the subsequant thresholding more accurate than if the resetMinAndMax is done on a slice with much lower signal
							resetMinAndMax();
							
							// Turn the image into 8-bit image
							close("probability map for "+staining[channel]);
							selectImage("Probability_map_"+staining[channel]);
		  					setOption("ScaleConversions", true);
							run("8-bit");
							
							// Save the probability_map as tif
							selectImage("Probability_map_"+staining[channel]);
		  					saveAs("Tiff", dir_probability + LifName+sav_roi+cell_ID+staining[channel]+"_Probability_map.tif");
							rename("Probability_map_"+staining[channel]);
		  					
		  					// Select the detected granules inside the Cell ROI, to eliminate potential unspecific signal outside the cell
				    		roiManager("select", 0);
							run("Clear Outside", "stack");
		  					run("Clear Results");
							
							
//------------------------- Get the ROI of each granules using 3D manager
							selectWindow("Probability_map_"+staining[channel]);
							setSlice(maxIntensityZStep2);
							run("Threshold...");
							setAutoThreshold("Otsu dark");							
							
							// Adjust the threshol manualy on the probakility map image
							beep();
							waitForUser("Adjuste threshold manualy");// Look at the object to check if the detection is good
							
							// Store Threshold 
							getThreshold(lower, upper);
							
							// Make binary image 
							run("Convert to Mask", "method=Otsu background=Dark black");
							rename("MASK_Probability_map_"+staining[channel]);
							
							// Run the 3D object counter, beacause it has a size exclusion filter. Min size set at 12 pixels
							run("3D Objects Counter", "threshold="+lower+" slice="+maxIntensityZStep2+" min.=12 max.=18825600 exclude_objects_on_edges objects"); //12 voxels approximatively correspond to an object with 80nm diameter based on calculation with the voxel size of the thunder leica microscope
							wait(1000);
							
							// Save the object_map as tif
							selectWindow("Objects map of MASK_Probability_map_"+staining[channel]);
		  					saveAs("Tiff", dir_Objectmap + LifName+sav_roi+cell_ID+staining[channel]+"_object_map.tif");
							rename("Objects map of MASK_Probability_map_"+staining[channel]);

//--------------------------Add objects to 3D manager for measurments 							
							// Add segmented granules to the 3D manager
							run("3D Manager");
							selectWindow("Objects map of MASK_Probability_map_"+staining[channel]);
							Ext.Manager3D_AddImage();
							close("MASK_Probability_map_"+staining[channel]);
							Ext.Manager3D_SelectAll();
							// Rename the ROI to make it easier to check during analysis
							Ext.Manager3D_Rename(staining[channel]); 
							
							// Get name of segmented image for colocalization analysis
							selectWindow("Objects map of MASK_Probability_map_"+staining[channel]);	
							run("Duplicate...", "title=Object_"+staining[channel]+" duplicate"); //Step needed because the name detected by 3D multicoloc is "Object". remove all spaces within the namegetTitle();
							ImageObject[channel] = getTitle(); // Returns the name of the image in the ImageObject array
							close("Objects map of MASK_Probability_map_"+staining[channel]);
							
							Ext.Manager3D_SelectAll;
							
							
//------------------------- Check if objects were added to the 3D manager
						    Ext.Manager3D_Count(nObjects);
						    print("Number of objects added to manager: ", nObjects);
						    
						    if (nObjects == 0) {
						        print("No granules detected in " + staining[channel] + ". Skipping measurement.");
						        n_count = false;
						        close("Probability_map_" + staining[channel]);
						        continue; // Skip to the next iteration						    
						    } else {
							
							
//------------------------- Start object measurment
							Ext.Manager3D_Measure();
							Ext.Manager3D_SaveResult("M",dir_result + LifName+sav_roi+cell_ID+staining[channel]+"_measure.csv");//"M" for measure window
							Ext.Manager3D_CloseResult("M"+LifName+sav_roi+cell_ID+staining[channel]+"_measure.csv");
							
//--------------------------Include Polarization index of each granules					
							open(dir_result + "M_"+LifName+sav_roi+cell_ID+staining[channel]+"_measure.csv");
							
							//Rename the table to "Result" to add measures 
							Table.rename("M_"+LifName+sav_roi+cell_ID+staining[channel]+"_measure.csv", "Results");
							selectWindow("Results");
							n_granuls = Table.size;
							
							if (n_granuls==0){
								close("Results");
							}else{
							
								for (granuls = 0; granuls < n_granuls; granuls++) {
									selectWindow("Results");
									
									//Get Z coordinate of the center of mass of the Granuls IN PIXEL SIZE
									granul_plane = getResult("CZ (pix)",granuls); 
									
									// Add data to the Result table
									Table.set("Image Name",  granuls, LifName );
									Table.set("Cell_ID",  granuls, cell_ID );
									Table.set("Granul_ID",  granuls, granuls + 1 );
									Table.set("Protein", granuls, staining[channel]);
									Table.set("Cell_size", granuls, CellSize);
									Table.update;
								}								
								
								//Rename the table and save the data
								Table.rename("Results", "M_"+LifName+sav_roi+cell_ID+staining[channel]+"_measure" );
								saveAs("Results", dir_result+"M_"+LifName+sav_roi+cell_ID+staining[channel]+"_measure.csv");
								close("M_"+LifName+sav_roi+cell_ID+staining[channel]+"_measure.csv");
							}							
							
							
//--------------------------Select the lng image to quantify fluorescence intensity of each granules
							selectWindow("deconv_cell"+cell_ID);
							run("Duplicate...", "title=Channel_"+staining[channel]+" duplicate channels="+staining_channel[channel]);
							Ext.Manager3D_SelectAll;
							Ext.Manager3D_Quantif;
							Ext.Manager3D_SaveResult("Q",dir_result + LifName+sav_roi+cell_ID+staining[channel]+"_Quantification.csv");//"Q" for quantification window
							Ext.Manager3D_CloseResult("Q"+LifName+sav_roi+cell_ID+staining[channel]+"_Quantification.csv");
							Ext.Manager3D_Save(dir_result + "Roi3D_"+LifName+sav_roi+cell_ID+"_"+staining[channel]+".zip");//Save the 3D ROI
							close("Channel_"+staining[channel]);
							
							
//--------------------------Make granul quantification database					
							open(dir_result + "Q_"+LifName+sav_roi+cell_ID+staining[channel]+"_Quantification.csv");
							//Rename the table to "Result" to add measures 
							Table.rename("Q_"+LifName+sav_roi+cell_ID+staining[channel]+"_Quantification.csv", "Results");
							selectWindow("Results");
							n_granul = Table.size;
							
							 
							
							if (n_granuls==0){
								close("Results");
							}else{
								for (granuls = 0; granuls < n_granuls; granuls++) {																	
									selectWindow("Results");
									Table.set("Image Name",  granuls, LifName );
									Table.set("Cell_ID",  granuls, cell_ID );
									Table.set("Granul_ID",  granuls, granuls + 1 );
									Table.set("Protein", granuls, staining[channel]);
									Table.update;								
								}
								Table.rename("Results", "Q_"+LifName+sav_roi+cell_ID+staining[channel]+"_Quantification");
								saveAs("Results", dir_result+"Q_"+LifName+sav_roi+cell_ID+staining[channel]+"_Quantification.csv");
								close("Q_"+LifName+sav_roi+cell_ID+staining[channel]+"_Quantification.csv");
								
								}
								Ext.Manager3D_SelectAll();
								Ext.Manager3D_Erase();								
							}
						
						}
						
					}
					
					
//--------------------------Assess all detected granuls for COLOCALIZATION  
					
					Array.show(ImageObject);
					if (n_count == false) {
						print("Skipping colocalization.");
						} else {
								// Use the 3D Multicoloc plugin
						    	run("3D MultiColoc", "image_a="+ImageObject[0]+" image_b="+ImageObject[1]);
								saveAs("Results", dir_result+"C_"+LifName+sav_roi+cell_ID+"_colocalization.csv");
								close("C_"+LifName+sav_roi+cell_ID+"_colocalization.csv");
								}
						
					for (chl = 0; chl < staining_nb; chl++) {
						selectImage("Object_"+staining[chl]);
						close("Object_"+staining[chl]);
						}
						
					
					for (chl = 0; chl < staining_nb; chl++) {
						close(staining[chl]);
						}
					close("deconv_cell"+cell_ID);
				}
				close("Total_Image"+Serie_nb);
			
				
			} else {
				close(Name);
			}
			close(Name);
		}
	
	}
}


if (isOpen("Total_Intensity_Results")==true) {
	selectWindow("Total_Intensity_Results");
	saveAs("Results", dir_result+"Total_Intensity_Results.csv");	
}	

if (isOpen("Background_Intensity_Results")==true) {
	selectWindow("Background_Intensity_Results");
	saveAs("Results", dir_result+"Background_Intensity_Results.csv");	
}			

showMessage("No more picture");
run("Close All");




