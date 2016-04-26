#!/usr/bin/env python

## Load modules/libraries
import sys
import argparse
import os

## Get user's input 
parser = argparse.ArgumentParser(description= """Produces a bed file with the transposable element (TE) insertion and transduced region coordinates from TraFiC somatic calls.""")
parser.add_argument('somaticTraFiC', help='TraFiC TE insertion calls for a given sample.')
parser.add_argument('sampleId', help='sample identifier (output file named accordingly to this id).')
parser.add_argument('--margin', default='5000', dest='margin', type=int, help='margin for those orphan and partnered transductions whose source element has not been identified. Coordinates range extended up and down-stream N bases from the transduced region to span the source element. Default: N=5000.' )
parser.add_argument('-o', '--outDir', default=os.getcwd(), dest='outDir', help='output directory. Default: current working directory.' )

args = parser.parse_args()
inputFile = args.somaticTraFiC
name = args.sampleId 
margin = args.margin
outDir = args.outDir

scriptName = os.path.basename(sys.argv[0])

## Display configuration to standard output
print
print "***** ", scriptName, "configuration *****"
print "somaticTraFiC: ", inputFile
print "sampleId: ", name
print "margin: ", margin
print "outDir: ", outDir
print 

print "***** Executing ", scriptName, "with", name, " *****"
print 
print "..."
print 

## Open input and output files
somaticInsertions=open(inputFile, 'r')

fileName = name + ".bed"
outFilePath = outDir + "/" + fileName
outFile = open( outFilePath, "w" )

## Parse input file line by line
for line in somaticInsertions:
    line = line.rstrip('\n')
    line = line.split("\t")
    projectId = line[0]
    tumourId = line[1]
    donorId = line[2]
    insertChr = line[3]
    
    # + cluster end < - cluster beg: 
    if line[4] < line[5]:
	insertBeg = line[4]
    	insertEnd = line[5]
    # - cluster beg < + cluster end
    else:
    	insertBeg = line[5]
    	insertEnd = line[4]

    family = line[6]
    gene = line[7]
    insertType = line[8]
    sourceChr = line[9]
    sourcePos1 = line[10]
    sourcePos2 = line[11]
    strand = line[12]
    transducedPos1 = line[13]
    transducedPos2 = line[14]
    dist2source = line[15]
    size = line[16]
    nbReadsPlus = line[17]
    nbReadsMinus = line[18]

    # Discard donors without any transposable element (TE) insertion 
    if family != "empty":  
        
        # Report TE insertion coordinates in bed format
        featureName = projectId + "#" + donorId + "#" + tumourId + ":" + "insertionBkp" + "-" + family + "-" + insertType + ":" + insertChr + "_" + insertBeg + "_" + insertEnd  
        row = insertChr + "\t" + insertBeg + "\t" + insertEnd + "\t" + featureName + "\n"
        outFile.write(row)
        
        # Additionally, report transduction coordinates if it is a Td1 
        # (partnered transduccion) or a Td2 (Orphan transduction)
        # Coordinates will depend on the orientation of the TE
        if insertType == "td1" or insertType == "td2":
            
            # A) TE orientation unknown:   
            # ---source?---  ---TransducedRegion---  ---source?---
            if strand == "putative":
                beg = int(transducedPos1) - margin
                end = int(transducedPos2) + margin
            
            # B) TE in positive strand
            # ---source---  ---TransducedRegion---  
            elif strand == "plus":
                beg = sourcePos1
                end = transducedPos2
            
            # C) TE in negative strand
            # ---TransducedRegion---  ---source---
            else:
                beg = transducedPos1
                end = sourcePos2
            
            # Report the coordinates
            featureName = projectId + "#" + donorId + "#" + tumourId + ":" + "transducedRegion" + "-" + family + "-" + insertType + ":" + insertChr + "_" + insertBeg + "_" + insertEnd 
            row = sourceChr + "\t" + str(beg) + "\t" + str(end) + "\t" + featureName + "\n"
            outFile.write(row)
        
# Close output and end
outFile.close()

print "***** Finished! *****"
print 


