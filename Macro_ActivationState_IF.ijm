// Macro designed by Elise Paulin
// Open segmentation ROIs and .lif corresponding and ask the user the activation state according to actin shape
//                         ____
//                   .---'-    \
//      .-----------/           \
//     /           (         ^  |   __
//&   (             \        O  /  / .'
//'._/(              '-'  (.   (_.' /
//     \                    \     ./
//      |    |       |    |/ '._.'
//       )   @).____\|  @ |
//   .  /    /       (    |   
//  \|, '_:::\  . ..  '_:::\ ..\).

run("Close All");

dirdata = getDirectory("Choose the folder you would like to analyze");  
dir_result = dirdata+"Quantifications"+File.separator();
dir_roi = dirdata+"Segmented"+File.separator();
File.makeDirectory(dir_result); 

// Extension of the files
extension = "Lng_LVCC";
ext_size = lengthOf(extension);

// Select the good channels
Dialog.create("What is the Actin channel?");
Dialog.addNumber("Actin_channel:", 3);
Dialog.show();
Actin_channel = Dialog.getNumber();

ImageNames=getFileList(dirdata); 
cell_nb = -1;

// Initialize the result arrays
Activation_Status=newArray(0);
Img = newArray(0);
cell = newArray(0);

if(isOpen("Results")) {
		selectWindow("Results");
		run("Close");
		}
		
if(isOpen("ROI Manager")) {
	roiManager("reset");
	}

nbSerieMax=50;
series="";
for(i=1;i<nbSerieMax;i=i+1) {
	series=series+"series_"+i+" ";
}

// Open all the lif files
for (i=0; i<lengthOf(ImageNames); i++) { 

	// Open all images and Roi
	 if (endsWith(ImageNames[i], ".lif")) {
		name_size = lengthOf(ImageNames[i]) - 4;
		LifName=substring(ImageNames[i],0 ,name_size);
		run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series);
		Names = getList("image.titles");

		for(image=0;image<lengthOf(Names);image++) {
			Name = Names[image];
			if (endsWith(Name, extension)) {
				Serie_nb = substring(Name,lengthOf(Name)-12,lengthOf(Name)-9);
				Name_raw = substring(Name,0,lengthOf(Name)-9);
				selectWindow(Name);
				run("Duplicate...", "title=Total_Image duplicate");
				Stack.setPosition(3,20,1);
				Stack.setChannel(Actin_channel);
				run("Enhance Contrast", "saturated=0.35");
				selectWindow(Name_raw);
				close();
				
				roiManager("Open", dir_roi+LifName+"_serie"+Serie_nb+"RoiSet.zip");
				n= roiManager("count");

				
				for (object = 0; object < n; object++) {
					cell_ID = Serie_nb+"_cell"+object;
				    cell_nb++;
				
		  			selectWindow("Total_Image");
				    roiManager("select", object);
		  			run("Duplicate...", "title=deconv_cell duplicate channels="+Actin_channel);
		  			run("Clear Outside", "stack");
			
		  			// to see on Zproj
		  			run("Z Project...", "projection=[Max Intensity]");
		  			
		  			Dialog.create("Activation state");
					Dialog.addCheckbox("Discard", false);
					Dialog.addCheckbox("NA", false);
					Dialog.addCheckbox("Early", false);
					Dialog.addCheckbox("Early Ring", false);
					Dialog.addCheckbox("Ring", false);
					Dialog.addCheckbox("Early Contraction", false);
					Dialog.addCheckbox("Contraction", false);
					Dialog.show();
					Discard=  Dialog.getCheckbox();
					NA=  Dialog.getCheckbox();
					Early=  Dialog.getCheckbox();
					Early_Ring=  Dialog.getCheckbox();
					Ring=  Dialog.getCheckbox();
					Early_Contraction=  Dialog.getCheckbox();
					Contraction=  Dialog.getCheckbox();
		  
		  			if (Discard==true) {
		  				Activation_Status[cell_nb]= "Discard";
		  			}
		  			if (Early==true) {
		  				Activation_Status[cell_nb]= "Early";
		  			}
		  			if (NA==true) {
		  				Activation_Status[cell_nb]= "Non Activated";
		  			}
		  			if (Early_Ring==true) {
		  				Activation_Status[cell_nb]= "Early Ring";
		  			}
		  			if (Ring==true) {
		  				Activation_Status[cell_nb]= "Ring";
		  			}
		  			if (Early_Contraction==true) {
		  				Activation_Status[cell_nb]= "Early Contraction";
		  			}
					if (Contraction==true) {
		  				Activation_Status[cell_nb]= "Contraction";
		  			}
		
		
				Img[cell_nb] = LifName;
				cell[cell_nb] =cell_ID;
				close();
				close();
				
				}
				close("deconv_cell");
				close("Total_Image");
				close(Name);
				roiManager("reset");	
			}
		}
	}
}


for(j=0;j<lengthOf(Img);j++) {
	setResult("Image Name",j,Img[j]);
	setResult("Cell_ID",j,cell[j]);
	setResult("Activation_Status",j,Activation_Status[j]);
	updateResults();
}

selectWindow("Results");
saveAs("Results",dir_result+"Results_ActivationStatus.csv");
showMessage("No more picture");
														
			
