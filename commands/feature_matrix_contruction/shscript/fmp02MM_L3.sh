#!/bin/bash

export LD_LIBRARY_PATH=/tools/lib/
export TCGA_MM_ROOT_DIR=/users/mmiler/tcga/sreynold_scripts/mm_src
export PYTHONPATH=$TCGA_MM_ROOT_DIR/pyclass:$TCGA_MM_ROOT_DIR/util:$PYTHONPATH

## this script should be called with the following parameters:
##      date, eg '29jan13'
##      snapshot, either 'dcc-snapshot' (most recent) or, eg, 'dcc-snapshot-29jan13;
##      one or more tumor types, eg: 'prad thca skcm stad'
curDate=$1
snapshotName=$2
tumor=$3

if [ -z "$curDate" ]
    then
        echo " this script must be called with a date string of some kind, eg 28feb13 "
        exit
fi
if [ -z "$snapshotName" ]
    then
        echo " this script must be called with a specific snapshot-name, eg dcc-snapshot "
        exit
fi
if [ -z "$tumor" ]
    then
        echo " this script must be called with at least one tumor type "
        exit
fi

echo " "
echo " "
echo " *******************"
echo " *" $curDate
echo " *" $snapshotName
echo " *******************"

args=("$@")
for ((i=2; i<$#; i++))
    do
        tumor=${args[$i]}

	## cd /titan/cancerregulome3/TCGA/outputs/$tumor
	cd /titan/cancerregulome14/TCGAfmp_outputs/$tumor

	echo " "
	echo " "
	date
	echo " Tumor Type " $tumor
	date

	if [ ! -d $curDate ]
	    then
		mkdir $curDate
	fi

	cd $curDate

	rm -fr level3.*.*.$curDate.log

	## COPY-NUMBER
	python $TCGA_MM_ROOT_DIR/parse_tcga.py $TCGA_MM_ROOT_DIR/parse_tcga.config \
                outSuffix=$curDate \
                out_directory=./ \
                platformID= broad.mit.edu/genome_wide_snp_6/snp/ \
                topdir=/titan/cancerregulome11/TCGA/repositories/$snapshotName/%s/tumor/%s/cgcc/%s >& level3.broad.snp_6.$curDate.log 

	## MICRO-RNA
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate bcgsc.ca/illuminaga_mirnaseq/mirnaseq $tumor $snapshotName                >& level3.bcgsc.ga_mirn.$curDate.log 
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate bcgsc.ca/illuminahiseq_mirnaseq/mirnaseq $tumor $snapshotName             >& level3.bcgsc.hiseq_mirn.$curDate.log 

	## MESSENGER-RNA
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate bcgsc.ca/illuminaga_rnaseq/rnaseq $tumor $snapshotName                    >& level3.bcgsc.ga_rnaseq.$curDate.log 
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate bcgsc.ca/illuminahiseq_rnaseq/rnaseq $tumor $snapshotName                 >& level3.bcgsc.hiseq_rnaseq.$curDate.log 
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate unc.edu/agilentg4502a_07_1/transcriptome $tumor $snapshotName             >& level3.unc.agil_07_1.$curDate.log 
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate unc.edu/agilentg4502a_07_2/transcriptome $tumor $snapshotName             >& level3.unc.agil_07_2.$curDate.log 
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate unc.edu/agilentg4502a_07_3/transcriptome $tumor $snapshotName             >& level3.unc.agil_07_3.$curDate.log 
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate unc.edu/illuminaga_rnaseq/rnaseq $tumor $snapshotName                     >& level3.unc.ga_rnaseq.$curDate.log 
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate unc.edu/illuminahiseq_rnaseq/rnaseq $tumor $snapshotName                  >& level3.unc.hiseq_rnaseq.$curDate.log 
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate unc.edu/illuminaga_rnaseqv2/rnaseqv2 $tumor $snapshotName                 >& level3.unc.ga_rnaseqv2.$curDate.log 
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate unc.edu/illuminahiseq_rnaseqv2/rnaseqv2 $tumor $snapshotName              >& level3.unc.hiseq_rnaseqv2.$curDate.log 

	## METHYLATION
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate jhu-usc.edu/humanmethylation27/methylation $tumor $snapshotName           >& level3.jhu-usc.meth27.$curDate.log 
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate jhu-usc.edu/humanmethylation450/methylation $tumor $snapshotName          >& level3.jhu-usc.meth450.$curDate.log 

	## RPPA
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate mdanderson.org/mda_rppa_core/protein_exp $tumor $snapshotName             >& level3.mda.rppa.$curDate.log 

	## MICRO-SATELLITE INSTABILITY
	python $TCGA_MM_ROOT_DIR/main/new_Level3_matrix.py $curDate nationwidechildrens.org/microsat_i/fragment_analysis $tumor $snapshotName >& level3.nwc.microsat_i.$curDate.log 

	## now we need to move any 'obsolete' expression datasets out of the way ...
	rm -fr $tumor.*.$curDate.tsv.bkp

	## new as of 25mar13 ... there is now GA_RNASeqV2 data for COAD, READ and UCEC which
	## we are going to say for now "outranks" any HiSeq_RNASeqV2 data ...
	if [ -f $tumor.unc.edu__illuminaga_rnaseqv2__rnaseqv2.$curDate.tsv ]
	    then
		if [ -f $tumor.unc.edu__illuminahiseq_rnaseqv2__rnaseqv2.$curDate.tsv ]
		    then
			echo " Illumina GA RNAseq V2 data exists ... moving HiSeq RNAseq V2 dataset to bkp "
		        mv $tumor.unc.edu__illuminahiseq_rnaseqv2__rnaseqv2.$curDate.tsv \
			   $tumor.unc.edu__illuminahiseq_rnaseqv2__rnaseqv2.$curDate.tsv.bkp
		fi
		if [ -f $tumor.unc.edu__illuminahiseq_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina GA RNAseq V2 data exists ... moving HiSeq RNAseq V1 dataset to bkp "
		        mv $tumor.unc.edu__illuminahiseq_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.unc.edu__illuminahiseq_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
		if [ -f $tumor.unc.edu__illuminaga_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina GA RNAseq V2 data exists ... moving GA RNAseq V1 dataset to bkp "
		        mv $tumor.unc.edu__illuminaga_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.unc.edu__illuminaga_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
		if [ -f $tumor.bcgsc.ca__illuminahiseq_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina GA RNAseq V2 data exists ... moving BCGSC HiSeq dataset to bkp "
		        mv $tumor.bcgsc.ca__illuminahiseq_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.bcgsc.ca__illuminahiseq_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
		if [ -f $tumor.bcgsc.ca__illuminaga_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina GA RNAseq V2 data exists ... moving BCGSC GA dataset to bkp "
		        mv $tumor.bcgsc.ca__illuminaga_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.bcgsc.ca__illuminaga_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
	fi
	

	## there are a few cases where there is a V1 and a V2 RNAseq dataset at this point, 
	## and we want to only use V2 if it is available ...
	if [ -f $tumor.unc.edu__illuminahiseq_rnaseqv2__rnaseqv2.$curDate.tsv ]
	    then
		if [ -f $tumor.unc.edu__illuminahiseq_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina HiSeq RNAseq V2 data exists ... moving HiSeq RNAseq V1 dataset to bkp "
		        mv $tumor.unc.edu__illuminahiseq_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.unc.edu__illuminahiseq_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
		if [ -f $tumor.unc.edu__illuminaga_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina HiSeq RNAseq V2 data exists ... moving GA RNAseq V1 dataset to bkp "
		        mv $tumor.unc.edu__illuminaga_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.unc.edu__illuminaga_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
		if [ -f $tumor.bcgsc.ca__illuminahiseq_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina HiSeq RNAseq V2 data exists ... moving BCGSC HiSeq dataset to bkp "
		        mv $tumor.bcgsc.ca__illuminahiseq_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.bcgsc.ca__illuminahiseq_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
		if [ -f $tumor.bcgsc.ca__illuminaga_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina HiSeq RNAseq V2 data exists ... moving BCGSC GA dataset to bkp "
		        mv $tumor.bcgsc.ca__illuminaga_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.bcgsc.ca__illuminaga_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
	fi
	
	## also HiSeq RNASeq outranks GA RNASeq ... (and any data from BCGSC)
	if [ -f $tumor.unc.edu__illuminahiseq_rnaseq__rnaseq.$curDate.tsv ]
	    then
		if [ -f $tumor.unc.edu__illuminaga_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina HiSeq RNAseq V1 data exists ... moving GA RNAseq V1 dataset to bkp "
		        mv $tumor.unc.edu__illuminaga_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.unc.edu__illuminaga_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
		if [ -f $tumor.bcgsc.ca__illuminahiseq_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina HiSeq RNAseq V1 data exists ... moving BCGSC HiSeq dataset to bkp "
		        mv $tumor.bcgsc.ca__illuminahiseq_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.bcgsc.ca__illuminahiseq_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
		if [ -f $tumor.bcgsc.ca__illuminaga_rnaseq__rnaseq.$curDate.tsv ]
		    then
			echo " Illumina HiSeq RNAseq V1 data exists ... moving BCGSC GA dataset to bkp "
		        mv $tumor.bcgsc.ca__illuminaga_rnaseq__rnaseq.$curDate.tsv \
			   $tumor.bcgsc.ca__illuminaga_rnaseq__rnaseq.$curDate.tsv.bkp
		fi
	fi
	
    done

echo " "
echo " fmp02B_L3 script is FINISHED !!! "
date
echo " "

