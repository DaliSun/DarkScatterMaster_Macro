// DarkScatterMaster 
// Author Dali Sun, dsun22@asu.edu
// Biodesign Institute
// Arizona State Univ. 
// Version 0.3
// Date: 03/01/2017
// Add Weak Signal vs Strong Signal option
// Note:: Please cite the following paper for using the code.
// Sun, D., J. Fan, et al. (2016). "Noise Reduction Method for Quantifying Nanoparticle Light Scattering in Low Magnification Dark-Field Microscope Far-Field Images." Analytical Chemistry.	




//Global Varibale
//---------------------------------
//Result varible
var Files=newArray;		//File Names
var Res=newArray; 		// Response
var I=newArray; 		// I'
var L=newArray; 		// Leverage

//internal use
var deb=0;
var MN="DarkScatterMaster"; //Macro Name
var dir_o;

// Input varible
var bROI; 		//disable ROI selection
var iCt,iCs; 	//Contour threshold and scale for ROI option
var sType; 		//quantification type: 0 red, 1 green, 2 enhanced
var bDSM; 		//enable ROI selection
var iLt,iHt; 	//Contour threshold and scale for ROI option
var bFo; 		//enable Images output (Fo) 
var bSm; 		//single mode
var bWSs;		//strong signal

macro "DarkScatterMaster" {

	if (deb) print("Macro Start");
	//Setting dialog
	SettingDialog();
	//Input validate
	if (!ValInput()){
		exit("Input Error");
	}
	//Processing
	if (bSm) {
		SingleProc();
	}else{
		BatchProc();
	}
	//Show result
	showResult();
}

//Setting Dialog
function SettingDialog(){
	Dialog.create(MN+" Option");
	Dialog.addMessage("Please config "+MN);
	//ROI
	Dialog.addMessage("ROI Configuration");
	Dialog.addCheckbox("Diable ROI", false);
	Dialog.addNumber("Contour Threshold", 253.02); // contour threshold
	Dialog.addNumber("Center Scale", 0.8);//trim diameter scale
		
	//Quantification
	Dialog.addMessage("Quantification Configuration");
	Dialog.addCheckbox("Diable DSM", false);
	Dialog.addChoice("Type:", newArray("Red", "Green", "Enhanced"));
	Dialog.addNumber("Low limit", 0);//threshold setting lth
	Dialog.addNumber("High limit", 62);// hth
			
	//Output
	Dialog.addMessage("Output Configuration");
	Dialog.addCheckbox("Output Filtered Images", false);
	
	// Running mode: batch folder mode and single image mode
	Dialog.addMessage("Mode Configuration");
	Dialog.addCheckbox("Single mode", false);
	// weak and strong signal option
	Dialog.addCheckbox("Strong Signal", false);
	Dialog.show();
	
	//Get Input
	bROI= Dialog.getCheckbox();
	iCt= Dialog.getNumber();
	iCs = Dialog.getNumber();
	bDSM = Dialog.getCheckbox();
	sType = Dialog.getChoice();
	iLt = Dialog.getNumber();
	iHt = Dialog.getNumber();	
	bFo = Dialog.getCheckbox();
	bSm = Dialog.getCheckbox();
	
	//weak strong swith, true strong
	bWSs=Dialog.getCheckbox();
}
//validate input
function ValInput(){
	rtn=true;
	if (!bDSM) rtn=(iLt<iHt)&rtn;
	return rtn;
}

//single processing
function SingleProc(){
	od = File.openDialog("Open image ..."); 
	fn = File.getName(od);
	dir = File.getParent(od) + "/";
	if (fn=="") exit("No Input Image");
	if (bFo){
		dir_o=getDirectory("Choose output Directory");
		if (dir_o=="") exit("No output folder");
	}
	Proc(fn,dir,dir_o);	
}
//batch mode for foler
function BatchProc(){
	dir=getDirectory("Choose a Directory");
	FileList=getFileList(dir);
	if (bFo){
		dir_o=getDirectory("Choose output Directory");
		if (dir_o=="") exit("No output folder");
	}
	setBatchMode(true);
	for (k=0;k<FileList.length;k++){
		fn=FileList[k];
		Proc(fn,dir,dir_o);
	}
}
//Processing Core
function Proc(fn,dir,dir_o){
	fp=dir+fn;
	open(fp);
	targetID=getImageID();
	selectImage(targetID);
	Files=Array.concat(Files,File.name);
	if (deb) print("Target Image ID:"+targetID);
	FN=File.name;
	FN_CP=FN + "-CP";
	run("Duplicate...", "title=["+FN_CP+"]");
	
	selectWindow(FN);
	run("Split Channels");
	gw=FN+" (green)";
	bw=FN+" (blue)";
	rw=FN+" (red)";	
	
	// Type selection
	if (sType=="Red"){
		imageCalculator("Subtract create", rw,bw);
	}else if (sType=="Green"){
		imageCalculator("Subtract create", gw,bw);
	} else {
		imageCalculator("Subtract create", rw,bw);
		RBw=getTitle();
		imageCalculator("Subtract create", gw,bw);
		GBw=getTitle();
		imageCalculator("AND", RBw,GBw);
	}
	Fi=getTitle();
		
	//No ROI selection
	if (!bROI){
		RoiSel(bw);
	}
	//Save output images
	if (bFo){
		saveAs("Tiff", dir_o+FN); 
	}
	run("Set Measurements...", "mean standard integrated display redirect=None decimal=4");
	
	if (bDSM){
		// Intensity Average Only
		selectWindow(FN_CP);
		run("Restore Selection");
		i=getMean();
		Res=Array.concat(Res,i);
	} else {
		// thresholding
		selectWindow(Fi);
		Fi_CP=Fi+"_MASK";
		run("Duplicate...", "title=["+Fi_CP+"]");
		selectWindow(Fi_CP);
		setThreshold(iLt, iHt);
		run("Create Selection");
		roiManager("Add");
		selectWindow(Fi);
		roiManager("AND");

		i=getMean();
		I=Array.concat(I,i);
		selectWindow(FN_CP);
		run("Restore Selection");
		l=getMean();
		L=Array.concat(L,l);
		
		//add for weak strong switch
		if (bWSs){
			Res=Array.concat(Res,sqrt(l));
		} else {
			Res=Array.concat(Res,sqrt(i*l));
		}
		CloseWin();
	}
}
function RoiSel(FN){
	selectWindow(FN);
	run("Fit Circle to Image", "threshold="+iCt); //fit Ct
	run("Scale... ", "x="+iCs+" y="+iCs+" centered");
	roiManager("Add");

}

function CloseWin(){
	while (nImages>0) { 
	  selectImage(nImages); 
	  close(); 
	}
	if (isOpen("ROI Manager")){
		roiManager("Deselect");
		roiManager("Delete");
		selectWindow("ROI Manager"); 
		run("Close"); 
	}
	if (isOpen("Results")){
		selectWindow("Results"); 
		run("Close"); 
	}
	if (isOpen("Log")){
		selectWindow("Log"); 
		run("Close"); 
	} 	
}

// Get Mean for Selection
function getMean(){
	run("Measure");
	selectWindow("Results"); // Area, Mean, StdDev
	value = getResult("Mean", 0); 
	run("Clear Results");
	return value;
}
// Show result window
function showResult(){
	if (nResults>=0) run("Clear Results");     // Check whether the results table is empty, if not clear it.
	for(n = 0; n < lengthOf(Res); n++)    {
		//i = nResults;
		setResult("File", n, Files[n]);
		if(!bDSM)setResult("I'", n, I[n]);
		if(!bDSM)setResult("L", n, L[n]);
		setResult("Response", n, Res[n]);
	}
	updateResults();
	if (deb) print("No of Result"+nResults);
}