#!/bin/bash

: ${LD_LIBRARY_PATH:?" environment variable must be set and non-empty"}
: ${TCGAFMP_ROOT_DIR:?" environment variable must be set and non-empty"}

if [[ "$PYTHONPATH" != *"gidget"* ]]; then
    echo " "
    echo " your PYTHONPATH should include paths to gidget/commands/... directories "
    echo " "
    exit 99
fi

## this script should be called with the following parameters:
##      date, eg '29jan13'
##      snapshot, either 'dcc-snapshot' (most recent) or, eg, 'dcc-snapshot-29jan13;
##      one or more tumor types, eg: 'prad thca skcm stad'

WRONGARGS=1
if [ $# != 1 ]
    then
        echo " Usage   : `basename $0` <tumorType> "
        echo " Example : `basename $0` brca "
        exit $WRONGARGS
fi

tumor=$1

args=("$@")
for ((i=0; i<$#; i++))
    do
        tumor=${args[$i]}

	## cd /titan/cancerregulome3/TCGA/outputs/$tumor
	cd /titan/cancerregulome14/TCGAfmp_outputs/$tumor

	echo " "
	echo " "
	date
	echo " Tumor Type " $tumor
	date

	cd gnab

	## ----------------------------------------------------------------------------
	## first, we're going to do some tweaking of feature names and such and 
	## eventually write out a file called $tumor.gnab.tmpData1.tsv

	rm -fr gnab.tmp.?
	rm -fr gnab.tmp.??
	rm -fr $tumor.gnab.tmpData1.tsv

	## BUT now we actually need to remove the "A" or "B" or "C" or "D" from the end ...
	sed -e '2,$s/-01A	/-01	/' latest.gnab.txt | \
		sed -e '2,$s/-01B	/-01	/' | \
		sed -e '2,$s/-01C	/-01	/' | \
		sed -e '2,$s/-01D	/-01	/' | \
		sed -e '2,$s/-02A	/-02	/' | \
		sed -e '2,$s/-02B	/-02	/' | \
		sed -e '2,$s/-02C	/-02	/' | \
		sed -e '2,$s/-02D	/-02	/' | \
		sed -e '2,$s/-03A	/-03	/' | \
		sed -e '2,$s/-03B	/-03	/' | \
		sed -e '2,$s/-03C	/-03	/' | \
		sed -e '2,$s/-03D	/-03	/' | \
		sed -e '2,$s/-06A	/-06	/' | \
		sed -e '2,$s/-06B	/-06	/' | \
		sed -e '2,$s/-06C	/-06	/' | \
		sed -e '2,$s/-06D	/-06	/' >& gnab.tmp.1

	~/scripts/transpose gnab.tmp.1 >& gnab.tmp.2

	## now for some ugly processing ...
	sed -e '1s/	/B:GNAB	/' gnab.tmp.2 | sed -e '2,$s/^/B:GNAB:/g' | sed -e '2,$s/_/:::::/' | \
		sed -e '2,$s/	/_somatic	/' | sed -e '1s/GBM-/TCGA-/g' | \
		sed -e '1s/Native-//g' | sed -e '1s/-Tumor//g' >& gnab.tmp.3
	
	## change the iarc_freq feature(s) to "N" from "B"
	grep    "iarc_freq" gnab.tmp.3 | sed -e '1,$s/B:GNAB/N:GNAB/' >& gnab.tmp.3a
	
	## grab all the rest, then divide into features with decimals and features w/o
	grep -v "iarc_freq" gnab.tmp.3 >& gnab.tmp.3b
	grep -v "\." gnab.tmp.3b >& gnab.tmp.3c
	grep    "\." gnab.tmp.3b >& gnab.tmp.3d
	sed -e '1,$s/B:GNAB/N:GNAB/' gnab.tmp.3d >& gnab.tmp.3e
	
	cat gnab.tmp.3c gnab.tmp.3a gnab.tmp.3e >& gnab.tmp.4
	
	## NEW: put in a step here that checks/fixes the feature names (B: vs N:)
	## and also removes any features that are *uniform*
	python $TCGAFMP_ROOT_DIR/main/fixupGnabBits.py gnab.tmp.4 gnab.tmp.5.tsv

	## NEW: make sure that the barcodes are tumor-specific barcodes ...
	python $TCGAFMP_ROOT_DIR/main/tumorBarcodes.py gnab.tmp.5.tsv $tumor.gnab.tmpData1.tsv
	
	## rm -fr gnab.tmp.?
	## rm -fr gnab.tmp.??

	python $TCGAFMP_ROOT_DIR/main/quickLook.py $tumor.gnab.tmpData1.tsv | grep "Summary"

	## at this point we have a file called $tumor.gnab.tmpData1.tsv

	## ----------------------------------------------------------------------------
	## now the next step is to do some filtering ...
	## we are using a "top 2k smg" list generated by hand from firehose outputs

	rm -fr smg.log
	python ~/to_be_checked_in/TCGAfmp/main/filterByGeneList.py $tumor.gnab.tmpData1.tsv $tumor.gnab.tmpData2.tsv \
		~/TCGA/sig_genes.2k.26feb13.txt >& smg.log 

	## ----------------------------------------------------------------------------
	## filter the MAF file based on the blacklist ...

	## NEW (temporary?) removing this line:
	## 	../aux/$tumor.whitelist.pancan.tsv white strict
	python ~/to_be_checked_in/TCGAfmp/main/filterTSVbySampList.py \
		$tumor.gnab.tmpData2.tsv \
		$tumor.gnab.tmpData3.tsv \
		../aux/$tumor.blacklist.loose.tsv black loose \
		../aux/$tumor.whitelist.loose.tsv white loose \
                ../aux/$tumor.whitelist.strict.tsv white strict \
		>& filterSamp.gnab.tmpA.log

	## ----------------------------------------------------------------------------
	## and finally, we want to annotate these features with genomic coordinates
        python ~/to_be_checked_in/TCGAfmp/main/annotateTSV.py \
		$tumor.gnab.tmpData3.tsv hg19 $tumor.gnab.tmpData4b.tsv >& gnab.B.log 

	cd ..
	cd ..


    done

echo " "
echo " fmp03B_gnab script is FINISHED !!! "
date
echo " "
