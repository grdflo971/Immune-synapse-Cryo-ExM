
// Get LAMP1 vesicule diameter and the number of PERFORIN and GRANZYMEB foci within each vesicule
// This macro is designe to open .tif images obtained using the "Cryo-ExM_get_vesicules_cropAndResize" macro.
// It was inspired by the "PickCentriolDim" plugin of the centriol lab (https://github.com/CentrioleLab)


run("Close All");

// Method used to determine the bottom and top plane of the cell: "manual"
method = "manual"

// Set working directory
dirdata = getDirectory("Choose the folder you would like to analyze");  

// Set the output file name
Dialog.create("Filename");
Dialog.addString("Name of your result file", "output.csv");
Dialog.show();
filename = Dialog.getString();

// Extension of the files
extension = ".tif";
ext_size = lengthOf(extension);

// Set the number of channels to analyze peak to peak 
Dialog.create("How many channels do you want to measure peak to peak?");
Dialog.addNumber("Number of channels to measure peak to peak:", 1);
Dialog.show();
channel_nb = Dialog.getNumber();
print("Channel_nb: ", channel_nb);

// Create variables for channel names and numbers
staining = newArray(0);
staining_channel = newArray(0);

for (channel = 0; channel < channel_nb; channel++) {
	Dialog.create("Staining_"+channel+1);
	Dialog.addString("Protein:", "Lamp1");
	Dialog.addNumber("Channel:", 3);
	Dialog.show();
	staining[channel] = Dialog.getString();
	staining_channel[channel] = Dialog.getNumber();
}
Array.print("staining:", staining);
Array.print("staining_channel:", staining_channel);


// Set variables to count the number of lytic granules (here Perforine and GranzymeB)
staining_nb = 2
granule_staining = newArray(0);
granule_channel = newArray(0);

// Identify the channels to count granules
for (chl = 0; chl < staining_nb; chl++) {
	Dialog.create("Identify channels to count granules");
	Dialog.addString("Granule_protein:", "Perforin");
	Dialog.addNumber("Corresponding_channel:", chl+1);
	
	Dialog.show();
	granule_staining[chl] = Dialog.getString();
	granule_channel[chl] = Dialog.getNumber();
	
}
Array.print("granule_staining: ", granule_staining);
Array.print("granule_channel: ", granule_channel);

// Get the tools to adjust channels an brightness
run("Brightness/Contrast...");
run("Channels Tool...");

// Get file list
ImageNames=getFileList(dirdata);
vesicule_nb = -1


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
    run(col[channel-1]);
    
    // The user get to select the max points
    selectWindow("Plot");
    setTool("multipoint");
    waitForUser("Select the 2 maximums");
    roiManager("Add");
    roiManager("Select", 0);
    run("Measure");
    x1 = getResult("X", 0);
    y1 = getResult("Y", 0);
    x2 = getResult("X", 1);
    y2 = getResult("Y", 1);
    run("Clear Results");
	
	// Manually select the points at 50% of the peaks intensity
	if (method == "manual") {
		// Draw new graph with 50% lines
	    selectWindow("Plot");
	    Plot.getValues(x, y);
	    Plot.getLimits(xMin, xMax, yMin, yMax);
	    Plot.create("Plot Values", "X", "Y", x, y);
	    Plot.setLineWidth(2);
	    Plot.drawLine(0, y1 / 2, x1, y1 / 2);
	    Plot.drawLine(x2, y2 / 2, xMax, y2 / 2);
	    run(col[channel-1]);
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
	    run("Clear Results");
	    roiManager("Reset");
	   
	    close("Plot Value");
	}
	
	else { // if method is "auto": automatically calculate the 50% points from your selected max points
		selectWindow("Plot");
	    Plot.getValues(x, y);
	   	val_y1 = newArray(0);
	   	val_y2 = newArray(0);
		for(k=0 ;k<lengthOf(y)-1; k++) {
			if ((y[k]<=y1/2 && y1/2<=y[k+1]) || (y[k+1]<=y1/2 && y1/2<=y[k])) {
				print(x[k]);
				val=newArray(0);
				val[0]=x[k];
				val_y1=Array.concat(val_y1, val);
			}
			if ((y[k]<=y2/2 && y2/2<=y[k+1]) || (y[k+1]<=y2/2 && y2/2<=y[k])) {
				val=newArray(0);
				val[0]=x[k];
				val_y2=Array.concat(val_y2, val);
			}}
		Array.print(val_y1);
		Array.print(val_y2);
		Array.getStatistics(val_y1, min, max, mean, stdDev);
		x1_50 = min;
		Array.getStatistics(val_y2, min, max, mean, stdDev);
		x2_50 = max;
		
		close("Plot");
		}
    // Return the x value of the 2 50% points
    return newArray(x1_50, x2_50);
}

// colors for the different channels graphs
col = newArray("Cyan", "Magenta","Green");



// loop on all images
for(i=0 ;i<lengthOf(ImageNames); i++) {
	if (endsWith(ImageNames[i], ".tif")) {
		
		open(dirdata+ImageNames[i]);
		vesicule_nb = vesicule_nb+1; 
		Vesicule_ID = substring(ImageNames[i],lengthOf(ImageNames[i])-23,lengthOf(ImageNames[i])-4);
		
		
		Stack.setChannel(1);
		run("Cyan");
		rename("vesicule");
		Stack.setDisplayMode("color");
		setTool("line");
		run("Line Width... ");
		
		for(c = 0; c < lengthOf(staining_channel); c++) {
			selectWindow("vesicule");	
			Stack.setChannel(staining_channel[c]);
			run("Enhance Contrast", "saturated=0.0000000005");
		}
		
		waitForUser("select a profile");
		
		
		
		// to get the measurement on all channels
		for(j=0 ;j<channel_nb; j++) {
			selectWindow("vesicule");			
			channel = staining_channel[j];
			print("channel variable in the loop: ", channel);
			
			label = staining[j];
			print("label variable in the loop: ", label);
			
			resultPoints = getPointsFromChannel(channel);
				
			
			// Create the result table if not already opened
			if (isOpen("Prot_Measurement")==false) {
				Table.create("Prot_Measurement");
			}
			
			// result window update
			selectWindow("Prot_Measurement");
			Table.set("Vesicule_ID",vesicule_nb,Vesicule_ID);
			Table.set(label+"_pk1",vesicule_nb,resultPoints[0]);
			Table.set(label+"_pk2",vesicule_nb,resultPoints[1]);
			Table.update;
		}
	
	
	// Count granules within the LAMP1 vesicule	
		for (count = 0; count < lengthOf(granule_staining); count++) {
			roiManager("reset");
			selectWindow("vesicule");
			run("Select None");
			
			channelIndex = granule_channel[count];
			
			Stack.setChannel(channelIndex);
			resetMinAndMax();
			Property.set("CompositeProjection", "Sum");
			Stack.setDisplayMode("composite");
			
			setTool("multipoint");
			waitForUser("Count the granules:" + granule_staining[count]);
			
			// Check if a multi-point selection exists
			if (selectionType == -1) {
			    n_granuls = 0; // No selection at all
			
			} else if (selectionType == 10) {
			    // Multi-point tool has been used
			    x = newArray();
			    y = newArray();
			    getSelectionCoordinates(x, y);
			    n_granuls = lengthOf(x);
			} else {
			    // Something else was selected (e.g., not multi-point)
			    showMessage("Please use the multi-point tool to mark granules.");
			    exit();
			}
			print("n_granules: ", n_granuls);
			
			
			// Add count to the table
			selectWindow("Prot_Measurement");
			Table.set(granule_staining[count]+"_granules_count",vesicule_nb,n_granuls);
			Table.update;
			
			}
			close("vesicule");	
			
		}
	
		run("Close All");
	}


// Result window saving
selectWindow("Prot_Measurement");
saveAs("Results", dirdata + filename);
showMessage("No more pictures");	 			
run("Close All");