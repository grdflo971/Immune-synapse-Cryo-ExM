
//--- Segmentation of the cells based on the Actin Channel---
// This macro is designed to work with .lif files from Leica, containing thunder lightning images with the Lng_LVCC denoising processing.

run("Close All");

// get the data directory
dirdata = getDirectory("Choose the folder you would like to analyze");
// Create a Segmentation folder to save the segmented cell ROI
dir_roi = dirdata+"Segmented"+File.separator();
File.makeDirectory(dir_roi); 

// Extension of the files
extension = "Lng_LVCC";
ext_size = lengthOf(extension);

// Select the channels of interest
Dialog.create("What is the channel number to segment?");
Dialog.addNumber("Indicate the channel number to segment the cells", 2);
Dialog.show();
staining_nb = Dialog.getNumber();


Dialog.create("What is the dapi channel?");
Dialog.addNumber("Indicate the Dapi channel number", 4);
Dialog.show();
Dapi_nb = Dialog.getNumber();


/// tableau contenant le nom des fichier contenus dans le dossier dirdata
ImageNames = getFileList(dirdata);
Array.show("ImageNames: ", ImageNames);

cell_nb = -1;

if(isOpen("Results")) {
		selectWindow("Results");
		run("Close");
		}
		
if(isOpen("ROI Manager")) {
	roiManager("reset");
	}


nbSerieMax=50;
series=newArray();
for(i=1; i<nbSerieMax; i=i+1) {
	series[i] = "series_"+i+" ";
}
Array.print(series);

// Open all the lif files-------------------------------------------------------------------------------
for (i=0; i<lengthOf(ImageNames); i++) { // Loop over images contained in dirdata

	// Open all images and Roi
	 if (endsWith(ImageNames[i], ".lif")) {
		name_size = lengthOf(ImageNames[i]) - 4;
		LifName=substring(ImageNames[i],0 ,name_size);
		print("LifName: ", LifName);
		
		for(image_serie=0 ; image_serie<nbSerieMax; image_serie++){
		run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series[image_serie]);
		
			Name = getTitle();
			print("Name: ", Name);
				
			
			// segment only the Lng_LVCC images
			if (endsWith(Name, extension)) {
				
				// To adapte to LasX last update from Leica
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
					
				
				// Adjust colors and channels
				Stack.setPosition(staining_nb,15,1);
				Stack.setChannel(staining_nb);
				run("Enhance Contrast", "saturated=0.35");

				Stack.setPosition(Dapi_nb,50,1);
				Stack.setChannel(Dapi_nb);
				run("Enhance Contrast", "saturated=0.35");
				
				
				if(isOpen("ROI Manager")) {
					roiManager("reset");					
				}
				
				Stack.setPosition(staining_nb,15,1);
				
				
//------------- Segmentation with nucleus------------------------------------------------------------
				selectWindow(Name);
				run("Duplicate...", "title=DAPI duplicate channels="+Dapi_nb);
				run("Z Project...", "projection=[Max Intensity]"); //Note: For some images, resluts are more acurate with a "[Sum Slices]"
				wait(500);
				run("Enhance Contrast", "saturated=0.35");

			
				// segmentation via DAPI channel
				run("Mean...", "radius=50");				
				setAutoThreshold("Otsu dark no-reset");
				run("Convert to Mask");
				run("Distance Map");
				run("Find Maxima...", "noise=100 output=[Segmented Particles]");
				rename("Mask_DAPI");
				close("MAX_DAPI");
				close("DAPI");
				
//-------------- Make Cell Mask using the defined channel-------------------------------------------------------------------------
				selectWindow(Name);
				run("Duplicate...", "title=Actin duplicate channels="+staining_nb);
				// Work with Z-projection
				run("Z Project...", "projection=[Sum Slices]"); //Note: For some images, resluts are more acurate with a "[Max intensity]"
				wait(500);
				run("Gaussian Blur...", "sigma=5");
				run("Unsharp Mask...", "radius=4 mask=0.8 stack"); //Note: Adjust radiuss if the segmentation is not accurate
				run("Enhance Contrast", "saturated=0.35");
				setAutoThreshold("Huang dark no-reset");
				run("Convert to Mask");
				run("Fill Holes");
				rename("Mask_Actin");
				close("Actin");
			
//-------------- Combine Masks-------------------------------------------------------------------------
				imageCalculator("AND create", "Mask_DAPI","Mask_Actin");
				selectWindow("Result of Mask_DAPI");				
		
				run("Analyze Particles...", "size=300-Infinity overlay add"); //Note: the size parameter can be adjusted depending on the cell size
				
				close("Result of Mask_DAPI");
				close("Mask_Actin");
				close("Mask_DAPI");
				
				selectWindow(Name);
				roiManager("Show All");
				roiManager("Save", dir_roi + LifName+sav_roi+Serie_nb+"RoiSet.zip");

			}else {
				close(Name);
			}
	 	}
	}
}

run("Tile");
showMessage("Your cell segmentation is done, check if you need to correct manually");
				
	
		
				
				
				
				
				
				
				
				