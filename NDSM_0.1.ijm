//DSM_Near
iLt=0;
iHt=5;
size="0-0.0001";
FN=getTitle();
gw=FN+" (green)";
bw=FN+" (blue)";
rw=FN+" (red)";
run("Split Channels");
imageCalculator("Subtract create", rw,bw);
RBw=getTitle();
selectWindow(RBw);
setThreshold(iLt, iHt);
run("Analyze Particles...", "size="+size+" exclude  summarize in_situ");
