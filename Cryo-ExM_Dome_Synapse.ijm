
// Macro to mesure the synaptic dome in T cells.
// It provides the mesurement of the distance between the manually defined cell botom plan and 50% of the Actin signal bellow and above the dome. 
// It requieres to pre-segment the cells using Cryo-ExM_synapse_segmentation or manual segmentation.



run("Close All");

// Method used to determine the bottom and top plane of the cell: "manual"
method = "manual"

// Set working directory
dirdata = getDirectory("Choose the folder you would like to analyze");  

dir_result = dirdata+"Quantifications"+File.separator();
File.makeDirectory(dir_result); 


// Extension of the files
extension = "Lng_LVCC";
ext_size = lengthOf(extension);

// Set the number of channels to analyze peak to peak 
Dialog.create("How many channels do you want to measure peak to peak?");
Dialog.addNumber("Number of channels to measure peak to peak:", 1);
Dialog.show();
channel_nb = Dialog.getNumber();
print("Channel_nb: ", channel_nb);

Dialog.create("What is tubuline channel?");
Dialog.addNumber("What is tubuline channel?:", 4);
Dialog.show();
tubuline = Dialog.getNumber();
print("Channel_nb: ", tubuline);

// Create variables for channel names and numbers
staining = newArray(0);
staining_channel = newArray(0);

for (channel = 0; channel < channel_nb; channel++) {
	Dialog.create("Staining_"+channel+1);
	Dialog.addString("Protein:", "Actin");
	Dialog.addNumber("Channel:", 2);
	Dialog.show();
	staining[channel] = Dialog.getString();
	staining_channel[channel] = Dialog.getNumber();
}
Array.print("staining:", staining);
Array.print("staining_channel:", staining_channel);


// Get the tools to adjust channels an brightness
run("Brightness/Contrast...");
run("Channels Tool...");

// Get file list
ImageNames=getFileList(dirdata);

cell_nb = -1;

if(isOpen("Results")) {
	selectWindow("Results");
	run("Close");}

if(isOpen("ROI Manager")) {
	roiManager("reset");}


// Analysis function: plot profile according to your selected line and measure the maxima and 50% points
function getPointsFromChannel(channel) {
	roiManager("reset");
	Stack.setChannel(channel);
	
    // Open the "Plot Profile" window
    run("Plot Profile");
    rename("Plot");
//    run(col[channel-1]);
   
    // The user get to select the max points
    selectWindow("Plot");
    setTool("multipoint");
    waitForUser("Select the Actin maximums");
    roiManager("Add");
    roiManager("Select", 0);
    run("Measure");
    x1 = getResult("X", 0);
    y1 = getResult("Y", 0);
    print("x1: ", x1);
    print("y1: ", y1);
    run("Clear Results");
    roiManager("Reset");
	
	// Manually select the points at 50% of the peaks intensity
	if (method == "manual") {
		// Draw new graph with 50% lines
	    selectWindow("Plot");
	    Plot.getValues(x, y);
	    Plot.getLimits(xMin, xMax, yMin, yMax);
	    Plot.create("Plot Values", "X", "Y", x, y);
	    Plot.setLineWidth(2);
	    Plot.drawLine(x1, y1 / 2, xMin, y1 / 2);
	    Plot.drawLine(x1, y1 / 2, xMax, y1 / 2);

	    Plot.show();
	    close("Plot");
	
	    // Get 50% points
	    setTool("multipoint");
	    waitForUser("Select the 2 50% points");
	    roiManager("Add");
	    roiManager("Select",0 );
	    run("Measure");
	    x1_50 = getResult("X", 0);
	    x2_50 = getResult("X", 1);
	    print("x1_50: ", x1_50);
    	print("x2_50: ", x2_50);
	    
	    run("Clear Results");
	    roiManager("Reset");
	   
	    

    // Return the x value of the 2 50% points
    return newArray(x1_50, x2_50);
	}
}

function DrawPerpendicularline(channel) {	
					
	selectWindow("MAX_Actin");
	run("Subtract Background...", "rolling=20 sliding");
	
	setTool("line");
	run("Line Width...", "line=1");	
	waitForUser("Draw LINE under the synapse edges?");
	run("Draw", "slice");
	
	getDimensions(width, height, channels, slices, frames);
    len = height / 2;
    
	// Get user line coordinates
    if (selectionType != 5) { // 5 = straight line
        exit("Please draw a straight line selection first.");
    }
    getLine(x1, y1, x2, y2, lineWidth);
 
    // Midpoint
    mx = (x1 + x2) / 2;
    my = (y1 + y2) / 2;

    // Original line vector
    dx = x2 - x1;
    dy = y2 - y1;

    // Perpendicular vector (rotated 90°)
    px = dy;
    py = -dx;

    // Normalize perpendicular vector
    mag = sqrt(px*px + py*py);
    px /= mag;
    py /= mag;

    // Half length of new line
    halfLen = len / 2;

    // Endpoints of perpendicular line
    x3 = mx;
    y3 = my;
    x4 = mx + px * halfLen;
    y4 = my + py * halfLen;

    // Draw perpendicular line
    run("Line Width... ", "line=50");
    makeLine(x3, y3, x4, y4);						    
}



nbSerieMax=50;
series=newArray();
for(i=0; i<nbSerieMax; i=i+1) {
	series[i] = "series_"+i+1+" ";
}
Array.print(series);


// loop on all images
for(i=0 ;i<lengthOf(ImageNames); i++) {
	
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
					    sav_roi = "_serie";
					    } else {
					    	print("Could not extract series number from name: ", Name);
						}
				}
				
				// Make duplicate image and enhance contrast to facilitate the flow		
				selectWindow(Name);
				
				
				for(k = 0; k <lengthOf(staining_channel); k++){
					
					selectWindow(Name);
					Stack.setPosition(staining_channel[k],20,1);
					Stack.setChannel(tubuline);
					run("Enhance Contrast", "saturated=0.35");
					Stack.setChannel(staining_channel[k]);
					run("Enhance Contrast", "saturated=0.35");
					Stack.setDisplayMode("composite");
					Stack.setActiveChannels("1100");
					
					waitForUser("Chose the z to project");
					Stack.getPosition(channel, slice, frame);
					low_z = slice;
					
					waitForUser("Chose the z to project");
					Stack.getPosition(channel, slice, frame);
					upper_z = slice;
					
					run("Duplicate...", "title=Actin duplicate channels="+staining_channel[i]);
					run("Z Project...", "start=low_z stop=upper_z projection=[Max Intensity]");

					cell_nb = cell_nb + 1;
					cell_ID = Serie_nb+"_cell1";

					// to get the measurement on all channels					
					channel = staining_channel[k];
					print("channel variable in the loop: ", channel);
					
					run("Select None");
					
					
					// Call function to draw perpendiculare line
					DrawPerpendicularline(channel);
					
					waitForUser("Adjust line lenth and width");
					
					label = staining[k];
					print("label variable in the loop: ", label);
					
					// Call function to get dimentions on the plot
					resultPoints = getPointsFromChannel(channel);
					
					
					// Create the result table if not already opened
					if (isOpen("Dome_Measurement")==false) {
						Table.create("Dome_Measurement");
					}
					
					// result window update
					selectWindow("Dome_Measurement");
					Table.set("Image Name",cell_nb,LifName);
					Table.set("Cell_ID",cell_nb,cell_ID);
					Table.set(label+"_pk_bellow",cell_nb,resultPoints[0]);
					Table.set(label+"_pk_above",cell_nb,resultPoints[1]);
					Table.update;
					
					
					close(staining[k]);
					close("Plot Values");
					close(Name);
					close("MAX_actin");
				
				}																						
				
				
			}else {
				close(Name);
			}
	
		}
	}
}


// Result window saving
selectWindow("Dome_Measurement");
saveAs("Results", dir_result+"Dome_Measurement.csv");
showMessage("No more pictures");	 			
run("Close All");