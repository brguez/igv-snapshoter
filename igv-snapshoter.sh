#!/bin/bash


<<authors
******************************************************************************
	
	igv-snapshoter.sh
	
	Copyright (c) 2016 Bernardo Rodríguez-Martín
	
	Mobile Genomes and Disease group.
	Universidad de Vigo (Spain)

	Licenced under the GNU General Public License 3.0 license.
******************************************************************************
authors


# Function 1. Print basic usage information
############################################
function usageDoc
{
cat <<help
	

**** igv-snapshoter.sh	version $version ****
Execute  for one dataset (sample).
	
*** USAGE

	$0 -i <TraFic_insertions> -b <BAM> -s <sample_identifier> [OPTIONS]

*** MANDATORY 
		
	-i	<TXT>		TraFiC TE somatic insertion calls for a given sample.		

	-b	<BAM>		BAM file with the WGS reads aligned in the reference genome.	
	
	-s	<STRING>	Sample id. Output file will be named accordingly.	
		
*** [OPTIONS] can be:
* General:
 
	-g 	<STRING>        Genome version. Default=hg19.

	-m	<INTEGER>       Margin for those orphan and partnered transductions whose source element has not been identified.
                       		Coordinates range extended up and down-stream N bases from the transduced region to span the source element.
                        	Default: N=5000.
	
	-M 	<INTEGER>       Margin for the snapshot. Coordinates range extended up and down-stream N bases from the region of interest.
                        	Default: N=1000.

  	-t      <TXT>      	Additional track to be displayed in the screenshot. E.g. genomic repeats or gene annotation. 
				Supported formats: GFF2, GFF3 and GTF. Default: no track.

	-h	<INTEGER>	Sets the number of vertical pixels (height) of each panel to include in image. Increase it to see more
                        	data, decrease it to create smaller images. 
				Default: N=1000.

	-f 	<FORMAT>    	Snapshot image format. Supported formats: png, jpg and svg. 
				Default: png.	

	-o	<PATH>		Output directory. Default current working directory. 
	
	-h			Display usage information.
		

help
}

# Function 2. Parse user's input
################################
function getoptions {

while getopts ":i:b:s:g:m:M:t:H:f:o:h" opt "$@"; 
do
   case $opt in   	
      
      ## MANDATORY ARGUMENTS
      i)
	  if [ -n "$OPTARG" ];
	  then
              input=$OPTARG
	  fi
	  ;;
      
      b)
	  if [ -n "$OPTARG" ];
	  then
              bam=$OPTARG
	  fi
	  ;;
      
      s)
	  if [ -n "$OPTARG" ];
	  then
              sampleId=$OPTARG
	  fi
	  ;;
      
      ## OPTIONS
      g)
	  if [ -n "$OPTARG" ];
	  then
              genome=$OPTARG
	  fi
	  ;;

      m)
	  if [ -n "$OPTARG" ];
	  then
              margin=$OPTARG
	  fi
	  ;;

      M)
	  if [ -n "$OPTARG" ];
	  then
	     marginPlot=$OPTARG
	  fi
	  ;;
      
      t)
	  if [ -n "$OPTARG" ];
	  then
             track=$OPTARG
	  fi
	  ;;
    
      H)
	  if [ -n "$OPTARG" ];
	  then
              maxHeight=$OPTARG
	  fi
	  ;;    
	
      f)
	  if [ -n "$OPTARG" ];
	  then
              format=$OPTARG
	  fi
	  ;;

      o)
	  if [ -n "$OPTARG" ];
	  then
       	      outDir=$OPTARG
	  fi
	  ;;

      h)
	  usageDoc;
	  exit 1
	  ;;
      
      :)
          echo "Option -$OPTARG requires an argument." >&2
          exit 1
  esac
done
}

# Function 3. Print log information (Steps and errors)
#######################################################
function log {
    string=$1
    label=$2
    if [[ ! $ECHO ]];then
        if [[ "$label" != "" ]];then
            printf "[$label] $string"
        else
            printf "$string"
        fi
    fi
}

# Function 4. Print a section header for the string variable
##############################################################
function printHeader {
    string=$1
    echo "`date` ***** $string *****"
}


# Function 5. Execute and print to stdout commands 
###################################################
function run {
    command=($1)
    if [[ $2 ]];then
         ${2}${command[@]}
    else
        echo -e "\t"${command[@]}""
        eval ${command[@]}
    fi
}


# SETTING UP THE ENVIRONMENT
############################

# igv-snapshoter version 
version=v1

# Enable extended pattern matching 
shopt -s extglob

# 1. Root directory
##############################
# to set the path to the bin and python directories. 

path="`dirname \"$0\"`"              # relative path
rootDir="`( cd \"$path\" && pwd )`"  # absolute path

if [ -z "$rootDir" ] ; 
then
  # error; for some reason, the path is not accessible
  # to the script
  log "Path not accessible to the script\n" "ERROR" 
  exit 1  # fail
fi


# 2. Parse input arguments with getopts  
########################################

# A) Display help and exit if no input argument is provided
if [ $# -eq 0 ];
then
    usageDoc
    exit 0
else
    getoptions $@ # call Function 2 and passing two parameters (name of the script and command used to call it)	
fi

# 3. Check input variables 
##########################

## Mandatory arguments
## ~~~~~~~~~~~~~~~~~~~

if [[ ! -e $input ]]; then log "The TraFiC TE insertion calls file does not exist. Mandatory argument -i\n" "ERROR" >&2; usageDoc; exit -1; fi
if [[ ! -e $bam ]]; then log "The BAM file does not exist. Mandatory argument -b" "ERROR" >&2; usageDoc; exit -1; fi
if [[ $sampleId == "" ]]; then log "The sample id is not provided. Mandatory argument -s\n" "ERROR" >&2; usageDoc; exit -1; fi


## Optional arguments
## ~~~~~~~~~~~~~~~~~~

# Genome version
if [[ "$genome" == "" ]]; 
then 
	genome='hg19'; 
fi

# Transductions margin
if [[ "$margin" == "" ]]; 
then 
	margin='5000'; 
fi

# IGV plot margin
if [[ "$marginPlot" == "" ]]; 
then 
	marginPlot='1000'; 
fi

# Text file with IGV track information
if [[ "$track" == "" ]]
then
    track="none"	
elif [ ! -s "$track" ]
then 
    log "Your text file with IGV track information does not exist. Option -t\n" "ERROR" >&2; 
    usageDoc; 
    exit -1; 
fi

# Maximum snapshot height
if [[ "$maxHeight" == "" ]]; 
then 
	maxHeight='1000'; 
fi

# Snapshot format
if [[ "$format" == "" ]]; 
then 
	format='png'; 
else	
	if [[ "$format" != @(png|jpg|svg) ]];
	then
		log "Please specify a proper image format [png|jpg|svg]. Option -f\n" "ERROR" >&2;
		usageDoc;
		exit -1; 
	fi
fi

# Output directory
if [[ "$outDir" == "" ]]; 
then 
	outDir=${SGE_O_WORKDIR-$PWD};
else
	if [[ ! -e "$outDir" ]]; 
	then
		log "Your output directory does not exist. Option -o\n" "ERROR" >&2;
		usageDoc; 
		exit -1; 
	fi	
fi

# 4. Programs/Scripts
######################
srcDir=$rootDir/src

SOMATIC2BED=$srcDir/somatic2bed_TraFiC.py
BED2BATCH=$srcDir/bed2IgvBatch.py

## DISPLAY PROGRAM CONFIGURATION  
##################################
printf "\n"
header=" IGV-SNAPSHOTER CONFIGURATION FOR $sampleId"
echo $header
eval "for i in {1..${#header}};do printf \"-\";done"
printf "\n\n"
printf "  %-34s %s\n\n" "igv-snapshoter $version"
printf "  %-34s %s\n" "***** MANDATORY ARGUMENTS *****"
printf "  %-34s %s\n" "input:" "$input"
printf "  %-34s %s\n" "bam:" "$bam"
printf "  %-34s %s\n\n" "sampleId:" "$sampleId"
printf "  %-34s %s\n" "***** OPTIONAL ARGUMENTS *****"
printf "  %-34s %s\n" "genome:" "$genome"
printf "  %-34s %s\n" "margin:" "$margin"
printf "  %-34s %s\n" "marginPlot:" "$marginPlot"
printf "  %-34s %s\n" "track:" "$track"
printf "  %-34s %s\n" "maxHeight:" "$maxHeight"
printf "  %-34s %s\n" "format:" "$format"
printf "  %-34s %s\n\n" "outDir:" "$outDir"
	 
	
##########
## START #
##########
header="Executing igv-snapshoter $version for $lid"
echo $header
eval "for i in {1..${#header}};do printf \"-\";done"
printf "\n\n"
start=$(date +%s)

logFile=$outDir/snapshoter.log
	 
# 1) Produces a bed file with the transposable element (TE) insertion and
###########################################################################
# transduced region coordinates from TraFiC somatic calls.
###########################################################
# output is: 
###########
# - $outDir/${sampleId}.bed	

insertionCoords=$outDir/${sampleId}.bed

if [ ! -s $insertionCoords ]; 
then
	step="INSERTIONS2BED"
	startTime=$(date +%s)
	printHeader "Executing conversion of insertion coordinates into bed step"  
	
	run "python $SOMATIC2BED $input $sampleId --margin $margin --outDir $outDir > snapshoter.log" "$ECHO"	

	if [ -s $insertionCoords ]; 
	then
		endTime=$(date +%s)
		printHeader "Step completed in $(echo "($endTime-$startTime)/60" | bc -l | xargs printf "%.2f\n") min"
	else	    
		log "Error converting into bed\n" "ERROR" 
	        exit -1
	fi
else
	printHeader "Bed file already exists... skipping step"
fi

# 2) Produces an IGV batch file with all the information needed to produce
###########################################################################
# snapshots of a set of genomic regions of interest.
#####################################################
# output is: 
###########
# - $outDir/${sampleId}.batch	

batchFile=$outDir/${sampleId}.batch

if [ ! -s $batchFile ]; 
then
	step="BED2BATCH"
	startTime=$(date +%s)
	printHeader "Executing igv batch file generation step"  

	run "python $BED2BATCH $insertionCoords $bam $sampleId --genome $genome --track $track --margin $marginPlot --max-height $maxHeight --format $format --outDir $outDir >> snapshoter.log" "$ECHO"

	if [ -s $batchFile ]; 
	then
		endTime=$(date +%s)
		printHeader "Step completed in $(echo "($endTime-$startTime)/60" | bc -l | xargs printf "%.2f\n") min"
	else	    
		log "Error generating batch file\n" "ERROR" 
	        exit -1
	fi
else
	printHeader "Batch file already exists... skipping step"
fi

# 3) Execute the IGV on the already generated batch file:
########################################################
# to take the snapshots
#######################
# output are: 
###########
# - $
# 
step="IGV-SNAPSHOTS"
startTime=$(date +%s)
printHeader "Executing igv batch file generation step"  

mkdir $outDir/snapshots
cd $outDir/snapshots
run "/Users/brodriguez/Research/Apps/IGV/2.3.72/igv.sh /Users/brodriguez/Research/Scripts/Bash/igv-snapshoter/conf/igv_session.xml -g $genome -b $batchFile" "$ECHO"


######################
# 4) CLEANUP AND END #
######################

#rm $insertionCoords $batchFile 

end=$(date +%s)
printHeader "igv-snapshoter.sh for $sampleID completed in $(echo "($end-$start)/60" | bc -l | xargs printf "%.2f\n") min "

# disable extglob
shopt -u extglob

exit 0

