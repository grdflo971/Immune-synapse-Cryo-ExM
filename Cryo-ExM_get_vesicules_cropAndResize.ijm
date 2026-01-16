// Designe to work on .lif files from Leica. 
// This macro allows to go get all lng_SVCC or lng_LVCC images in a lif file.
// It allows to create several ROIs on the selected stack images.
// For each ROI, it will crop the image and ask to select the desire Z range, by defining the lower and upper Z stack. 
// The selescted ROIs will be resized following the same process than the "crop and resize" macro of the centriol lab.
// the picture are automatically saved as tif image in the crop & and resize folder. 

run("Close All");
roiManager("reset");

// Open brigthness/contrast and channel tools
run("Brightness/Contrast...");
run("Channels Tool...");

// Set working directory
dirdata = getDirectory("Choose the folder you would like to analyze");

// Make two folders to save images and results
dir_result = dirdata+"Crop & resize"+File.separator();
dir_roi = dirdata+"ROI"+File.separator();
File.makeDirectory(dir_result); 
File.makeDirectory(dir_roi);

// Extension of the files
extension1 = "Lng_SVCC";
extension2 = "Lng_LVCC";
ext_size = lengthOf(extension1);

// Method used to determine the bottom and top plane of the cell: "manual"
ROI="manual";
method="manual"

//Set the total_channel variable containing the number of channels in the image
Dialog.create("How many channels in the image");
Dialog.addNumber("Total channels of the image:", 4);
Dialog.show();
total_channel = Dialog.getNumber();

// Set the channels number to use for Z stack selection
Dialog.create("Choose the channels to use for Z stack selection");
Dialog.addNumber("LAMP1 channel for Z stack selection:", 3);
Dialog.show();
Lamp_channel = Dialog.getNumber();

// Set a variable returning the number of channels that will be display to help fo granule detection
Dialog.create("How many stainings do you want to display?");
Dialog.addNumber("Number of channels to display for selection:", 2);
Dialog.show();
staining_nb = Dialog.getNumber();

// Set the channels to display for vesicules selection
Display_channel = newArray(0); // Creates a variable that contains the chosen channel numbers 

for (channel = 0; channel < staining_nb; channel++) {
	Dialog.create("Choose the channels to display to help the selection");
	Dialog.addNumber(channel+1+"_channel_to_display:", 1);
	Dialog.show();
	Display_channel[channel] = Dialog.getNumber();
}

// Initialize an array with "0" for all channels
activeChannelsArray = newArray(total_channel);
for (i = 0; i < total_channel; i++) {
    activeChannelsArray[i] = "0"; // Start with all channels inactive
}

// Set corresponding channels to "1" based on the Display_channel array
for (Display = 0; Display < lengthOf(Display_channel); Display++) {
    channelIndex = Display_channel[Display] - 1; 
    
    if (channelIndex < total_channel) {
        activeChannelsArray[channelIndex] = "1"; 
    }
}

// Manually concatenate the array elements into a string
finalActiveChannels = "";
for (i = 0; i < lengthOf(activeChannelsArray); i++) {
    finalActiveChannels = finalActiveChannels + activeChannelsArray[i];
}
print("finalActiveChannels: " + finalActiveChannels);

// Get all files names in the folder
ImageNames=getFileList(dirdata); 
cell_nb = -1;


nbSerieMax=50;
series=newArray();
for(i=1;i<nbSerieMax;i=i+1) {
	series[i]="series_"+i+" ";
}


// Open all the lif files
for (i=0; i<lengthOf(ImageNames); i++) { // Loop over .lif files 
	 
	 if (endsWith(ImageNames[i], ".lif")) {
		name_size = lengthOf(ImageNames[i]) - 4;
		LifName = substring(ImageNames[i],0 ,name_size);
		print("LifName: ", LifName);
		
		// Open all images and ROI one by one
		for(image_serie=0 ; image_serie<nbSerieMax; image_serie++){
			run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series[image_serie]);
			
			
			Names = getList("image.titles");
			l=lengthOf(Names);
			
			
			for(image=0 ; image<lengthOf(Names) && image < lengthOf(Names);image++) {
				Name = Names[image];
				
				// Only select images with the Lng_LVCC or Lng_SVCC extention
				if (endsWith(Name, extension1) || endsWith(Name, extension2)) {
					Serie_nb = substring(Name,lengthOf(Name)-12,lengthOf(Name)-9);
					selectWindow(Name);
					run("Duplicate...", "title=Total_Image"+Serie_nb+ " duplicate");
					
					// Display the defined channels and enhance contrast
					for (Display = 0; Display < lengthOf(Display_channel); Display ++){
						Stack.setPosition(Display_channel[Display],20,1);
						Stack.setChannel(Display_channel[Display]);
						run("Enhance Contrast", "saturated=0.25");
						print("Enhanced contrast for channel: " + Display_channel[Display]);
					}
					Stack.setDisplayMode("composite");
					Stack.setActiveChannels(finalActiveChannels);
					
					roiManager("reset");
			  			
					// Creat ROI corresponding to vesicules to analyse
					if (ROI=="manual"){
						do {				
							makeRectangle(418, 388, 39, 39);
							waitForUser("Move ROI to duplicate the zone of interest");
							roiManager("Add");
							roiManager("Show All");
							
							// Aske the user if more ROI have to be made
							Dialog.create("Do you want to make another ROI?");
							Dialog.addCheckbox("YES", false); // Will allow to draw another ROI on the image
							Dialog.addCheckbox("NO", false); // Will end the loop 
							Dialog.show();
							YES =  Dialog.getCheckbox();
							NO =  Dialog.getCheckbox();
							  
						} while (YES && !NO);	
		  				 
		  				// store number of ROI
						n= roiManager("count");
						
						
						// Get each vesicules from the ROI
						for (object = 0; object < n; object++) {
							cell_nb = cell_nb + 1;
							cell_ID = Serie_nb+"_vesicul_"+object + 1;
							roiManager("Show All");
							// Save the ROI set
							roiManager("Save", dir_roi + LifName+"_serie"+Serie_nb+"RoiSet.zip");
							
				  			selectWindow("Total_Image"+Serie_nb);
				  			Stack.setChannel(Lamp_channel);		  						  			
				  			
						    roiManager("select", object);
				  			run("Duplicate...", "title=deconv_cell"+cell_ID+ " duplicate");
						
						
						if (method=="manual") { // The user choose the planes by hand
								selectWindow("deconv_cell"+cell_ID);
								getDimensions(width, height, channels, slices, frames);
								run("Select None");
								
								// Set image on the LAMP1 channel
								Stack.setChannel(Lamp_channel);
								selectImage("deconv_cell"+cell_ID);
								
								// Run orthogonal view
								run("Orthogonal Views");
								wait(1000);
								titles = getList("image.titles");
								
								// Ensure orthogonal views are generated
		                        Stack.getOrthoViewsIDs(XY, YZ, XZ);
								selectImage("deconv_cell"+cell_ID);
								
								// Select the lower and upper plan of the vesicule
								waitForUser("Select the LOWER plane");
								Z0 = getSliceNumber();
								waitForUser("Select the UPPER plane");
								Z1 = getSliceNumber();
								
								selectImage("deconv_cell"+cell_ID);
								
								// Calculate the slice number 
								low_slice = (Z0/nSlices)*slices;
								Z0 = Math.ceil(low_slice);
								print("Z0", Z0);
								
								upper_slice = (Z1/nSlices)*slices;
								Z1 = Math.ceil(upper_slice);
								print("Z1", Z1);
								
							}
							Stack.stopOrthoViews;
							
							// Duplicate the selected ROI with the chosen Z stacks
				  			selectWindow("deconv_cell"+cell_ID);
				  			run("Duplicate...", "title=Total_Image_Dup duplicate slices="+Z0+"-"+Z1);
							rename("Crop_"+LifName+cell_ID);				
							run("Brightness/Contrast...");
							
							// Close the image containing the full Z stack
							close("deconv_cell"+cell_ID);
							
							// Make the crop and resize for the vesicule (inspiered from CropAndResize plugin from centriole lab)
						    selectImage("Crop_"+LifName+cell_ID);
						    getDimensions(width, height, channels, slices, frames);
						    run("Canvas Size...", "width=" + width*6 +" height=" + width*6 +" position=Center zero");
						    run("Scale...", "x=6 y=6 z=1.0 interpolation=Bilinear average" );
						    run("Set Scale...", "known=" + 1/6 +" pixel=1");
						    
							// Save the the crop and resized image as tif for further measurments
						    save(dir_result+ "Crop_"+LifName+"_series"+cell_ID + ".tif");
							close("Crop_"+LifName+cell_ID);
						}
						print("Done." );
					}
						
		  			
				}else {
					close(Name);
					}
					close(Name);
				}
			}
		}
	}
showMessage("No more pictures");	 			
run("Close All");
				
				
