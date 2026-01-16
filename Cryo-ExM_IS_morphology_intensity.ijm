// This macro allows to get several morphological and molecular informations:
//		Cell size in the z Axis
//		Synaptic area
// 		Synaptic dome position in the z axis
//		Total Fluorescence intensity of the intire cell
//		Fluorecence intensity of at the synapse area
// It requieres to pre-segment the cells using Cryo-ExM_synapse_segmentation or manual segmentation.



run("Close All");
roiManager("reset");
run("Brightness/Contrast...");

// Chose the working directory
dirdata = getDirectory("Choose the folder you would like to analyze");

// Create one folder "quantification" folder to save the data
dir_result = dirdata+"Quantifications"+File.separator();
File.makeDirectory(dir_result); 

// Store the "Segmented" folder path
dir_roi = dirdata+"Segmented"+File.separator();

// Create one folder "Synapse_projection_images" folder to save the data
dir_syn = dirdata+"Synapse_projection_images"+File.separator();
File.makeDirectory(dir_syn); 


// Extension of the files
extension = "Lng_LVCC";
ext_size = lengthOf(extension);

// Method used to determine the bottom and top plane of the cell: "manual"
method= "manual";
	
// Identify the actin channel
Dialog.create("Choose the corresponding channels");
Dialog.addNumber("Actin:", 2);
Dialog.show();
Actin_channel = Dialog.getNumber();


// Indicate the number of stainning you want to analyse
Dialog.create("How many stainings will you analyse?");
Dialog.addNumber("How many stainings will you analyse?:", 2);
Dialog.show();
staining_nb = Dialog.getNumber();


// Indicate the name of the protein and the conresponding channel number
staining = newArray(0);
staining_channel = newArray(0);

for (channel = 0; channel < staining_nb; channel++) {
	Dialog.create("Staining_"+channel+1);
	Dialog.addString("Protein:", "Protein ID");
	Dialog.addNumber("Channel:", 1);
	Dialog.show();
	staining[channel] = Dialog.getString();
	staining_channel[channel] = Dialog.getNumber();
}
	


// Get all file names in the folder
ImageNames=getFileList(dirdata); 
cell_nb = -1;

// Initialize Results table and ROI Manager
if(isOpen("Results")) {
		selectWindow("Results");
		run("Close");
		}
		
if(isOpen("ROI Manager")) {
	roiManager("reset");
	}

// Initialise the Series array
nbSerieMax = 50;
series=newArray();
for(i=1;i<nbSerieMax;i=i+1) {
	series[i]="series_"+i+" ";
}

// Get the Series number of each ROI saved afetr using the cell segmentation macros
roi_name = getFileList(dir_roi);
print("ROI_name: ");
Array.print(roi_name);

roi_serie =newArray();

// iterate over the names of the ROI files to get the ID number of the image
for(roi=0; roi<lengthOf(roi_name); roi++){
	
	roiset = roi_name[roi];
	
	// Find index of "Image " and "_Lng"
	roi_img_index = indexOf(roiset, "Image ");	
	roi_lng_index = indexOf(roiset, "RoiSet");
	
	// Addapting to the LasX last update 
	if (roi_img_index >= 0 && roi_lng_index > roi_img_index) {
	    start = roi_img_index + lengthOf("Image ");
	    roi_serie[roi] = substring(roiset, start, roi_lng_index);
	    print("roi_serie1: ", roi_serie[roi]);
	    sav_roi = "_Image ";
	   	    
		} else { // If the image name contains "Series" instead of image (due to LasX update)
			roi_img_index = indexOf(roiset, "Series");
			print("Fallback roi_img_index: ", roi_img_index);
			sav_roi = "_Series";
			
			if (roi_img_index >= 0 && roi_lng_index > roi_img_index) {
			    start = roi_img_index + lengthOf("Series");
			    roi_serie[roi] = substring(roiset, start, roi_lng_index);
			    print("roi_serie2: ", roi_serie[roi]);
			    
			    } else {
			    	print("Could not extract series number from name: ", roiset);
				}
		}
}
print("ROI_serie: ");
Array.print(roi_serie);

// Set Measurments
run("Set Measurements...", "area mean min shape integrated redirect=None decimal=3");

// Open all the lif files
for (i=0; i<lengthOf(ImageNames); i++) { // Loop over the .lif files
	
	// Open all images and ROI one by one
	if (endsWith(ImageNames[i], ".lif")) {
		name_size = lengthOf(ImageNames[i]) - 4;
		LifName=substring(ImageNames[i],0 ,name_size);
		print("LifName: ",LifName);
		
		for(image_serie=0 ; image_serie<nbSerieMax; image_serie++){
			run("Bio-Formats Importer", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series[image_serie]);
		
			Name = getTitle();
			print("Name: ", Name);
			
			// Distance between each stack (voxel size)
			getVoxelSize(width, height, depth, unit);
			voxel_depth = depth;
			pix_width = width;
			
			// Only select images with the Lng_LVCC extantion
			if (endsWith(Name, extension)) {
				
				// Find index of "Image " and "_Lng"
				lng_index = indexOf(Name, "_Lng");
				img_index = indexOf(Name, "Image ");
								
				if (img_index >= 0 && lng_index > img_index) {
				    start = img_index + lengthOf("Image ");
				    Serie_nb = substring(Name, start, lng_index);
				    print("Series_number1: ", Serie_nb);
				    sav_image = "_Image ";
				    
					} else { // If the image name contains "Series" instead of image (due to LasX update)
						img_index = indexOf(Name, "Series");
						print("Fallback img_index: ", img_index);
						
						if (img_index >= 0 && lng_index > img_index) {
						    start = img_index + lengthOf("Series");
						    Serie_nb = substring(Name, start, lng_index);
						    print("Series_number2: ", Serie_nb);
						    sav_image = "_Series";
						    
						    } else {
						    	print("Could not extract series number from name: ", Name);
							}
					}		
					
				
				// Found the ROI segementation file corresponding tot the picture  
				roiManager("reset");
				
				found = false;								
				for (s=0; s<lengthOf(roi_serie); s++){
					roi_file = roi_serie[s];
					print("roi_file: ", roi_file);
					
					if (roi_file == Serie_nb){
						roiFilePath = dir_roi+LifName+sav_roi+Serie_nb+"RoiSet.zip";
						print("roiFilePath: ", roiFilePath);
						
						if (File.exists(roiFilePath)){
						
						roiManager("Open", roiFilePath);
						
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
				
				// Make duplicate image and enhance contrast to facilitate the flow		
				selectWindow(Name);
				run("Duplicate...", "title=Total_Image"+Serie_nb+ " duplicate");
				Stack.setPosition(Actin_channel,20,1);
				Stack.setChannel(Actin_channel);
				run("Enhance Contrast", "saturated=0.35");
				
				//count the number of ROIs opened in the roi manager
				n= roiManager("count");
				
				// Get each cell of the image from the ROI
				for (object = 0; object < n; object++) {
					cell_nb = cell_nb + 1;
					cell_ID = Serie_nb+"_cell"+object + 1;

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
					// Get the top and the bottom of the cell manually -------------------------------------------	
					
					if (method=="manual") { // The user choose the planes by hand
						selectWindow("deconv_cell"+cell_ID);
						getDimensions(width, height, channels, slices, frames);
						run("Select None");
						
						// Duplicate the actine channel to make sure to get the right Z plan number
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
						
						// Select the interface between the cell and the coverslip surface by moving through the z-stacks
						waitForUser("Select the FIRST SYNAPTIC plane"); 
						Z0 = getSliceNumber();
						
						// Select the position of the dome by moving through the z-stacks
						waitForUser("Select the TOP SYNAPTIC plane"); 
						Z1 = getSliceNumber();
						
						// Select the position of the top of the cell by moving through the z-stacks
						waitForUser("Select the TOP CELL plan"); 
						Z2 = getSliceNumber();
						
						// Calculate the slice number 
						low_slice = (Z0/nSlices)*slices;
						Z_low = Math.ceil(low_slice);
						print("Z_low:", Z_low);
						
						top_slice = (Z1/nSlices)*slices;
						Z_top = Math.ceil(top_slice);
						print("Z_top:", Z_top);
	
						top_cell = (Z2/nSlices)*slices;
						Z_cell = Math.ceil(top_cell);
						print("Z_cell_top:", Z_cell);
						
						
						Z0 = Z_low;
						print("Z0", Z0);
		  			
						Z1 = Z_top;
						print("Z1", Z1);
						Z2 = Z_cell;
						print("Z2", Z2);

						CellSize = (Z2-Z0)*voxel_depth;
						Synapse_size = (Z1-Z0)*voxel_depth;
						
					}
					Stack.stopOrthoViews;		
		  			close("Actine");
		  			close("MaskCell");
		  			
//-----------------Get cell dimentions ---------------------------------------------
		  			// Create the result table
					if (isOpen("Synaptic_dimentions")==false) {
					Table.create("Synaptic_dimentions");
					}
					
					// Add the image and cell ID in the result table
			  		selectWindow("Synaptic_dimentions");
					Table.set("Image Name",cell_nb,LifName);
					Table.set("Cell_ID",cell_nb,cell_ID);
					
					// Add the synaptic dimentions
					Table.set("Voxel_depth",cell_nb,voxel_depth);
					Table.set("Number_of_z_stack",cell_nb,slices);
	  				Table.set("First_synaptic_plan",cell_nb,Z0);
	  				Table.set("Dome_plan",cell_nb,Z1);
	  				Table.set("Top_cell_plan",cell_nb,Z2);
					Table.set("Cell_size (µm)",cell_nb,CellSize);
					Table.set("Synapse_size (µm)",cell_nb,Synapse_size);
					Table.update;
					
				
//----Get total Florescence intensity of the protein of interest ---------------------------------------------
				
					//loop over the chosen channels to measure the total fluorescence intensity of each channels per cells
					for (channel = 0; channel < staining_nb; channel++) {
						run("Set Measurements...", "area mean min shape integrated redirect=None decimal=3");
						
		  				// Duplicate the channel of interste 
						selectWindow("Total_Image"+Serie_nb);
						run("Duplicate...", "title="+staining[channel]+" duplicate channels="+staining_channel[channel]);
						selectWindow(staining[channel]);
						
						// SUM z-stacks of the entire cell (between Z0 to Z2)
						run("Z Project...", "start=Z0 stop=Z2 projection=[Sum Slices]"); 
						makeRectangle(10, 11, 38, 38);
						waitForUser("Move ROI to measure the backgound fluorecence for the ENTIRE cell");
						run("Measure");
						
						// Store the measures
						Tot_area_backgound = getResult("Area",0);
						Tot_IntDen_background = getResult("IntDen",0); 					
						Tot_Mean_background = getResult("Mean",0);
						Tot_RawIntDen_background = getResult("RawIntDen",0);
						run("Clear Results");
						close("SUM_"+staining[channel]);
						
						// Measure background for the synapse Z projection
						selectWindow(staining[channel]);
						
						// save the stack of the defined synapse for further analysis
						run("Duplicate...", "title="+staining[channel]+" duplicate range=Z0-Z1 use");
						saveAs("Tiff", dir_syn+LifName+sav_roi+Serie_nb+"_synapse_"+staining[channel]+".tif");
						close(LifName+sav_roi+Serie_nb+"_synapse_"+staining[channel]+".tif");
						
						// SUM Z projection of the synaptic plan (Z0 to Z1)
						run("Z Project...", "start=Z0 stop=Z1 projection=[Sum Slices]"); 
						makeRectangle(10, 11, 38, 38);
						waitForUser("Move ROI to measure the backgound for the SYNAPTIC plan");
						run("Measure");
						// Store the measures
						Syn_Area_backgound = getResult("Area",0);
						Syn_IntDen_background = getResult("IntDen",0); 					
						Syn_Mean_background = getResult("Mean",0);
						Syn_RawIntDen_background = getResult("RawIntDen",0);
						run("Clear Results");
						close("SUM_"+staining[channel]);
						
						
						//select deconvolved image.This image was clear outside the cell ROI to avoid any problem with the cell measurments 
		  				selectWindow("deconv_cell"+cell_ID);
						run("Select None");
			  			run("Duplicate...", "title="+staining[channel]+" duplicate channels="+staining_channel[channel]);
		  			    
		  			    //get measurments at the synapse plan
		  				selectWindow(staining[channel]);	  			
		  				run("Z Project...", "start=Z0 stop=Z1 projection=[Sum Slices]");// between first synapse plan Z0 and the synapse dome plan Z1
		  				run("Clear Results");
		  				roiManager("Measure");
		  				// Store the measures
		  				Rawdensity_syn =getResult("RawIntDen", 0);
		  				IntDen_syn = getResult("IntDen",0); 					
						Mean_syn = getResult("Mean",0);
						
		  				run("Clear Results");
		  				close("SUM_"+staining[channel]);
		  				
		  				//get measurments of the entire cell
		  				selectWindow(staining[channel]);	  			
		  				run("Z Project...", "start=Z0 stop=Z2 projection=[Sum Slices]");
		  				run("Clear Results");
		  				roiManager("Measure");
		  				// Store the measures
		  				Rawdensity_tot =getResult("RawIntDen", 0);
		  				IntDen_tot = getResult("IntDen",0); 					
						Mean_tot = getResult("Mean",0);
						
		  				run("Clear Results");
		  				close("SUM_"+staining[channel]);
		  				
		  				if (isOpen("Total_Intensity_Results")==false) {
							Table.create("Total_Intensity_Results");
							}
							
						selectWindow("Total_Intensity_Results");
		  				 // Add the image and cell ID in the result table
				  		Table.set("Image Name",cell_nb,LifName);
						Table.set("Cell_ID",cell_nb,cell_ID);
						Table.set("Synapse_area",cell_nb,Area);
						Table.set("Pixel_width",cell_nb,pix_width);
		  				// measurments at the synapse
						Table.set(staining[channel]+"_RawIntDen_at_synapse",cell_nb,Rawdensity_syn);
						Table.set(staining[channel]+"_IntDen_at_synapse",cell_nb,IntDen_syn);
						Table.set(staining[channel]+"_mean_synapse",cell_nb,Mean_syn);
						
						// measurments for the background at synapse
						Table.set(staining[channel]+"_background_area_syn",cell_nb,Syn_Area_backgound);
						Table.set(staining[channel]+"_RawIntDen_background_syn",cell_nb,Syn_RawIntDen_background);
						Table.set(staining[channel]+"_IntDen_background_syn",cell_nb,Syn_IntDen_background);
						Table.set(staining[channel]+"_mean_background_syn",cell_nb,Syn_Mean_background);
						
						// measurments for the entire cell
						Table.set(staining[channel]+"_RawIntDen_total_cell",cell_nb,Rawdensity_tot);
						Table.set(staining[channel]+"_IntDen_total_cell",cell_nb,IntDen_tot);
						Table.set(staining[channel]+"_mean_total_cell",cell_nb,Mean_tot);
						
						// measurments of the background for the entire cell
						Table.set(staining[channel]+"_background_area_cell",cell_nb,Tot_area_backgound);
						Table.set(staining[channel]+"_RawIntDen_background_cell",cell_nb,Tot_RawIntDen_background);
						Table.set(staining[channel]+"_IntDen_background_cell",cell_nb,Tot_IntDen_background);
						Table.set(staining[channel]+"_mean_background_cell",cell_nb,Tot_Mean_background);
						
						Table.update;
						
						close(staining[channel]);
						
					}
					close("deconv_cell"+cell_ID);
				}close("Total_Image"+Serie_nb);
				
			}else {
				print("Image without Lng_LVCC was closed: ", Name);
				close(Name);				
			}
			print("Image Lng_LVCC was closed: ", Name);
			close(Name);
			
			
		}
	}
}
if (isOpen("Synaptic_dimentions")==true) {
selectWindow("Synaptic_dimentions");
saveAs("Results", dir_result+"Synaptic_dimentions.csv");	
}	

if (isOpen("Total_Intensity_Results")==true) {
selectWindow("Total_Intensity_Results");
saveAs("Results", dir_result+"Total_Intensity_Results.csv");	
}

showMessage("Your analysis is done");				