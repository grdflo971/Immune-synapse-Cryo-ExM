// This macro is designed to make concentric bins within the synapse interface to measure the fluorescence intensity within each bins.
// It requieres to pre-segment the cells using Cryo-ExM_synapse_segmentation or manual segmentation.


run("Close All");
roiManager("reset");
run("Brightness/Contrast...");

// Chose the working directory
dirdata = getDirectory("Choose the folder you would like to analyze");

// Create one folder "quantification" folder to save the data
//dir_raw = dirdata+"Raw_Data"+File.separator();
dir_result = dirdata+"Quantifications"+File.separator();
// Store the "Segmented" folder path
dir_roi = dirdata+"Segmented"+File.separator();
File.makeDirectory(dir_result); 

// Extension of the files
extension = "Lng_LVCC";
ext_size = lengthOf(extension);

// Method used to determine the bottom and top plane of the cell: "manual"
method= "manual";

//define circles number
circles_nb =6;

// Select the good channels
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

// Voxel depth for the microscope
voxel_depth = 0.2130800;

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

// Initialise the Series array
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

// Set Measurments
run("Set Measurements...", "area mean min shape integrated redirect=None decimal=3");


for (i=0; i<lengthOf(ImageNames); i++) { 
	
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
				roiManager("reset")
				
				found = false;								
				for (s=0; s<lengthOf(roi_serie); s++){
					roi1 = roi_serie[s];
					print("roi1: ", roi1);
										
					if (roi1 == Serie_nb){
						roiFilePath = dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip";
												
						if (File.exists(roiFilePath)){
						roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
						
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
				
				
				selectWindow(Name);
				run("Duplicate...", "title=Total_Image"+Serie_nb+ " duplicate");
				Stack.setPosition(Actin_channel,20,1);
				Stack.setChannel(Actin_channel);
				run("Enhance Contrast", "saturated=0.35");
				
				roiManager("reset");
				roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
				n= roiManager("count");
				
				
				// Get each cell of the image from the ROI
				for (object = 0; object < n; object++) {
					cell_nb = cell_nb + 1;
					cell_ID = Serie_nb+"_cell"+object + 1;

					roiManager("reset");
					roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
					
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
						
						// Select the interface between the cell and the coverslip surface by moving through the z-stacks				
						selectImage("Actine");
						waitForUser("Select the FIRST SYNAPTIC plane");
						Z0 = getSliceNumber();
						
						waitForUser("Select the TOP SYNAPTIC plane");
						Z1 = getSliceNumber();
						
						// Calculate the slice number 
						low_slice = (Z0/nSlices)*slices;
						Z0 = Math.ceil(low_slice);
						print("Z0:", Z0);
						
						top_slice = (Z1/nSlices)*slices;
						Z1 = Math.ceil(top_slice);
						print("Z1:", Z1);
						
					}
					Stack.stopOrthoViews;
		  			close("Actine");
		  			
		  			
//-----------------Get total Florescence intensity of the protein of interest per bin---------------------------------------------
		  			// Create the result table
					if (isOpen("Concentric_total_intensity")==false) {
					Table.create("Concentric_total_intensity");
					}
					 // Add the image and cell ID in the result table
			  		selectWindow("Concentric_total_intensity");
					Table.set("Image Name",cell_nb,LifName);
					Table.set("Cell_ID",cell_nb,cell_ID);
					Table.update;
				
				
					//loop on the channels to measure the total intensity of each channels per cells
					for (channel = 0; channel < staining_nb; channel++) {
						
		  				// Measure background of the analysed channel
						selectWindow("Total_Image"+Serie_nb);
						run("Duplicate...", "title="+staining[channel]+" duplicate channels="+staining_channel[channel]);
						selectWindow(staining[channel]);
						
						//SUM z-stacks of the synaptic area between Z0 and Z1
						run("Z Project...", "start=Z0 stop=Z1 projection=[Sum Slices]");
						selectWindow("SUM_"+staining[channel]);
						run("Enhance Contrast", "saturated=0.00001");
						
						// Get Background Measurment
						makeRectangle(10, 11, 38, 38);		
						waitForUser("Move ROI to measure backgound");
						run("Measure");
						background_area = getResult("Area",0); 
						background_RawIntDen = getResult("RawIntDen",0); 
						background_IntDen = getResult("IntDen",0); 
						run("Clear Results");
						close("SUM_"+staining[channel]);
						
						//select deconvolved image
		  				selectWindow("deconv_cell"+cell_ID);
						run("Select None");
			  			run("Duplicate...", "title="+staining[channel]+" duplicate channels="+staining_channel[channel]);
		  			    selectWindow(staining[channel]);	  			
		  				run("Z Project...", "start=Z0 stop=Z1 projection=[Sum Slices]");
		  				
						 // Make concentric circles---------------------------------		  			    
						scaling = 1/circles_nb;
						for (circle = 1; circle < circles_nb; circle++){
							roiManager("Select", 0);
							scale = 1-(circle*scaling);
							run("Scale... ", "x="+scale+" y="+scale+" centered");
							roiManager("Add");
						}
						
						
						// Measure fluorescence intensity and Area in each been
						for (circle = 1; circle < circles_nb; circle++){
							selectWindow("SUM_"+staining[channel]);
							roiManager("Select", newArray(circle-1,circle));
							roiManager("XOR");
							
							run("Clear Results");
							selectWindow("SUM_"+staining[channel]);
							run("Measure");
							zone_area = getResult("Area", 0);
							Channel_RawIntDen = getResult("RawIntDen", 0);
							Channel_IntDen = getResult("IntDen",0);
							run("Clear Results");
							
							// Repartition result window update
							selectWindow("Concentric_total_intensity");
							Table.set(staining[channel]+"_Area_background",cell_nb,background_area);
							Table.set(staining[channel]+"_RawIntDen_background",cell_nb,background_RawIntDen);
							Table.set(staining[channel]+"_IntDen_background",cell_nb,background_IntDen);
							Table.set("Zone_"+circle+"_area",cell_nb,zone_area);
							Table.set(staining[channel]+"_"+circle+"_RawIntDen",cell_nb,Channel_RawIntDen);	
							Table.set(staining[channel]+"_"+circle+"_IntDen",cell_nb,Channel_IntDen);	
							Table.update;
						}
						close("SUM_"+staining[channel]);
						close(staining[channel]);
										
					}
					close("deconv_cell"+cell_ID);
				}
				close("Total_Image"+Serie_nb);
			} 
			else {
				close(Name);
			}
		}
	}
}

if (isOpen("Concentric_total_intensity")==true) {
selectWindow("Concentric_total_intensity");
saveAs("Results", dir_result+"Concentric_total_intensity.csv");	
}	

showMessage("No more pictures");	 			
run("Close All");
				