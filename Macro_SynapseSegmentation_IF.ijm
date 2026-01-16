// Fiji Macro by Elisa
// Macro segment T cells on activating surfaces using .lif files from Leica. This macro si suited for classical immunofluorecence staining.
// It provides ROI file.

run("Close All")

dirdata = getDirectory("Choose the folder you would like to analyze");
dir=dirdata+"Segmented"+File.separator();
File.makeDirectory(dir);

// Identify image extention from .lif after thunder lightning processing
extension1 = "Lng_LVCC";
extension2 = "Lng_SVCC";
ext_size = lengthOf(extension1);

Dialog.create("Choose the segmentation method");
Dialog.addCheckbox("watershed", false);
Dialog.addCheckbox("Dapi", false);
Dialog.show();
method=  Dialog.getCheckbox();

// Select the Actin and DAPI channels
Dialog.create("What is the Actin channel?");
Dialog.addNumber("Actin_channel:", 1);
Dialog.show();
Actin_channel = Dialog.getNumber();

Dialog.create("What is the DAPI channel?");
Dialog.addNumber("DAPI_channel:", 2);
Dialog.show();
DAPI_channel = Dialog.getNumber();


// File list
ImageNames=getFileList(dirdata); 
nbimages=lengthOf(ImageNames); 


nbSerieMax=50;
series=newArray();
for(i=0; i<nbSerieMax; i=i+1) {
	series[i] = "series_"+i+1+" ";
}
Array.print(series);

// Open all the lif files
for (i=0; i<lengthOf(ImageNames); i++) {

	// Select only the MT images
	 if (endsWith(ImageNames[i], ".lif")) {
		name_size = lengthOf(ImageNames[i]) - 4;
		LifName = substring(ImageNames[i],0 ,name_size);
		print("LifName: ",LifName);
		
		for(image_serie=0 ; image_serie<nbSerieMax; image_serie++){
			
			run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series[image_serie]);
			
			Name = getTitle();
			print("Name: ", Name);
			
			// segment only the Lng_LVCC images
			if (endsWith(Name, extension1)||endsWith(Name, extension2)) {
				
				
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
				Stack.setPosition(Actin_channel,13,1);				
				run("Enhance Contrast", "saturated=0.35");
			
				Stack.setChannel(DAPI_channel);
				run("Enhance Contrast", "saturated=0.35");

				if(isOpen("ROI Manager")) {
					roiManager("reset");}

				Stack.setPosition(Actin_channel,13,1);
				
		
				// segmentation on actin zproj and watershed
				if (method == "watershed") {
					run("Duplicate...", "title=duplic duplicate channels="+Actin_channel);
					run("Z Project...", "projection=[Max Intensity]");
					rename("Mask_Actin");
					run("Gaussian Blur...", "sigma=4");
					setAutoThreshold("Huang dark no-reset");
					run("Convert to Mask");
					run("Fill Holes");
					run("Watershed");
				
					// Get particles excluding the edge
					run("Analyze Particles...", "size=50-Infinity exclude overlay add");
					print("particule exclusion <50");
					roiManager("show all");
					
					if (roiManager("count")==0) {
						run("Analyze Particles...", "size=10-Infinity overlay add");
						roiManager("show all");
						print("particule exclusion <10");
					}
					
					close("Mask_Actin");
					close("duplic");
				}else {// For segmentation with nucleus
					run("Z Project...", "projection=[Max Intensity]");
					rename("Zproj");
				
					// segmentation via DAPI channel
					run("Duplicate...", "title=DAPI duplicate channels="+DAPI_channel);
					run("Subtract Background...", "rolling=60");
					
					run("Gaussian Blur...", "sigma=10");
					run("Find Maxima...", "noise=200 output=[Segmented Particles] exclude");
					rename("Mask_DAPI");
					
					/// Make Cell Mask
					selectWindow("Zproj");
					run("Duplicate...", "title=Mask_Actin duplicate channels="+Actin_channel);
					run("Gaussian Blur...", "sigma=4");
					setAutoThreshold("Huang dark no-reset");
					run("Convert to Mask");
					run("Fill Holes");
				
					/// Combine Masks
					imageCalculator("AND create", "Mask_DAPI","Mask_Actin");
					selectWindow("Result of Mask_DAPI");
					run("Analyze Particles...", "size=50-Infinity exclude overlay add");
					roiManager("show all without labels");
					
					close("Result of Mask_DAPI");
					close("Mask_Actin");
					close("Mask_DAPI");
					close("DAPI");
					close("Zproj");
				}
				
				selectWindow(Name);
				roiManager("Show All");
				Stack.setDisplayMode("composite");
				roiManager("Save", dir + LifName+sav_roi+Serie_nb+"RoiSet.zip");
				
			}else {
					selectWindow(Name);
					run("Close");
				}
		}
	 }
}
run("Tile");

showMessage("Your cell segmentation is done, check if you need to correct manually");
