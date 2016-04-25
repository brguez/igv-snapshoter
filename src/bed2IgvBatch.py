#!/usr/bin/env python

## Load modules/libraries
import sys
import argparse
import os

## Get user's input 
parser = argparse.ArgumentParser(description= """Produces an IGV batch file with all the information needed to produce snapshots of a set of genomic regions of interest.""")
parser.add_argument('inputBed', help='BED file containing the regions of interest.')
parser.add_argument('inputBam', help='BAM file with the reads aligned in the reference genome.')
parser.add_argument('name', help='output file name.')
parser.add_argument('-g', '--genome', default="hg19", dest='genome', help='genome version. Default=hg19.')
parser.add_argument('--track', default="none", dest='track', help='additional track to be displayed in the screenshot. E.g. genomic repeats or gene annotation. Supported formats: GFF2, GFF3 and GTF. Default: no track.')
parser.add_argument('--margin', default='1000', dest='margin', type=int, help='margin for the snapshot. Coordinates range extended up and down-stream N bases from the region of interest. Default: N=1000.' )
parser.add_argument('--max-height', default='1000', dest='maxPanelHeight', type=int, help='sets the number of vertical pixels (height) of each panel to include in image. Increase it to see more data, decrease it to create smaller images. Default: N=1000.')
parser.add_argument('--format', default='png', dest='imgFormat', type=str, help='snapshot image format. Supported formats: png, jpg and svg. Default: png.')
parser.add_argument('-o', '--outDir', default=os.getcwd(), dest='outDir', help='output directory. Default: current working directory.' )

args = parser.parse_args()
inputBed = args.inputBed
inputBam = args.inputBam
name = args.name 
genome = args.genome
track = args.track
margin = args.margin
maxPanelHeight = args.maxPanelHeight 
imgFormat = args.imgFormat
outDir = args.outDir

scriptName = os.path.basename(sys.argv[0])

## Display configuration to standard output
print
print "***** ", scriptName, " configuration *****"
print "inputBed: ", inputBed 
print "inputBam: ", inputBam 
print "fileName: ", name
print "genome: ", genome
print "track: ", track
print "margin: ", margin
print "maxPanelHeight: ", maxPanelHeight
print "imgFormat: ", imgFormat
print "outDir: ", outDir
print 

print "***** Executing ", scriptName, "with", name, " *****"
print 
print "..."
print 

## Open input and output files
bed = open(inputBed, 'r')

outFilePath = outDir + "/" + name + ".batch"
outFile = open( outFilePath, "w" )

## Add basic tasks (create session, load genome, bam, optional track...) to batch file
outFile.write("%s\n" % "new")
outFile.write("%-1s %s\n" % ("genome", genome))
outFile.write("%-1s %s\n" % ("load", inputBam))

if track != "none":
    outFile.write("%-1s %s\n" % ("load", track))    

## Iterate over the bed file and create the tasks to take the snapshots of the regions of interest
for line in bed:
    line = line.rstrip('\n')
    line = line.split("\t")
    chrom = line[0]
    beg = int(line[1]) - int(margin) 
    end = int(line[2]) + int(margin)
    snapshotPos = "chr" + str(chrom) + ":" + str(beg) + "-" + str(end)
    snapshotName = line[3] + "." +  imgFormat
    
    # Write tasks to take the snapshots into the batch file 
    outFile.write("%-1s %s\n" % ("goto", snapshotPos))
    outFile.write("%-1s %s\n" % ("maxPanelHeight", maxPanelHeight))
    outFile.write("%-1s %s\n" % ("snapshot", snapshotName))

# Add exit task
outFile.write("%s\n" % "exit")

# Close batch file and ends
outFile.close()

print "***** Finished! *****"
print 

