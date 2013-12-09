
for d in `cat $TCGAFMP_ROOT_DIR/shscript/tumor_list.txt`

    do

	echo " "
	echo " "
	echo " ******************************************************************** "
	echo $d

	cd /titan/cancerregulome11/TCGA/repositories/dcc-mirror/public/tumor/$d/
        mkdir cgcc
        chmod g+w cgcc
        cd cgcc
        mkdir jhu-usc.edu
        chmod g+w jhu-usc.edu
        cd jhu-usc.edu

        mkdir humanmethylation450
        chmod g+w humanmethylation450
        cd humanmethylation450
        mkdir methylation
        chmod g+w methylation
        cd methylation

	rm -fr index.html
	wget -e robots=off --wait 1 --debug --no-clobber --continue --server-response --no-directories \
	     --accept "*Level_3*.tar.gz" --accept "*mage-tab*.tar.gz" --accept "*CHANGES*txt" \
             -R "*images*" -R "*Level_1*" -R "*Level_2*" \
	     --verbose \
	     --recursive --level=1 \
	     https://tcga-data.nci.nih.gov/tcgafiles/ftp_auth/distro_ftpusers/anonymous/tumor/$d/cgcc/jhu-usc.edu/humanmethylation450/methylation

	cd /titan/cancerregulome11/TCGA/repositories/dcc-mirror/public/tumor/$d/cgcc/jhu-usc.edu/

        mkdir humanmethylation27
        chmog g+w humanmethylation27
        cd humanmethylation27
        mkdir methylation
        chmod g+w methylation
        cd methylation

	rm -fr index.html
	wget -e robots=off --wait 1 --debug --no-clobber --continue --server-response --no-directories \
	     --accept "*Level_3*.tar.gz" --accept "*mage-tab*.tar.gz" --accept "*CHANGES*txt" \
             -R "*images*" -R "*Level_1*" -R "*Level_2*" \
	     --verbose \
	     --recursive --level=1 \
	     https://tcga-data.nci.nih.gov/tcgafiles/ftp_auth/distro_ftpusers/anonymous/tumor/$d/cgcc/jhu-usc.edu/humanmethylation27/methylation

    done

