#!/bin/bash

# I use this script to compare PDF output from two different versions
# of the DITA Open Toolkit (https://www.dita-ot.org/).

DITAOT1=/u/doc/dita-ot-3.4
DITAOT2=/u/doc/dita-ot-3.6
COMPARE_PDF=$(which compare_pdf_images.pl)

# This is the bash array of all .ditamap files to compare
DITAMAPS=(dita/*.ditamap)

# catch unset variable refereces, and ensure that $? works when "| tee" is used
set -u -o pipefail

# loop through all .ditamap files to compare
for MAP in ${DITAMAPS[@]}
do
  MAPBASE=$(basename -s '.ditamap' $MAP)
  echo "$MAP ($MAPBASE)"

  # create a working directory, named after the map's base name (without extension)
  # to place PDF files and transformation log files
  rm -rf "./compare/${MAPBASE}"
  mkdir -p "./compare/${MAPBASE}"

  # run the transformations to create 1.pdf and 2.pdf in the working directory
  ${DITAOT1}/bin/dita \
    --input="$MAP" \
    --format="pdf2" \
    --output="./compare/${MAPBASE}" -Dargs.output.base='1' > "./compare/${MAPBASE}/1.log" 2>&1
  ${DITAOT2}/bin/dita \
    --input="$MAP" \
    --format="pdf2" \
    --output="./compare/${MAPBASE}" -Dargs.output.base='2' > "./compare/${MAPBASE}/2.log" 2>&1

  # compare the PDFs (returns 0 for identicality, 1 for difference)
  ${COMPARE_PDF} "./compare/${MAPBASE}/1.pdf" "./compare/${MAPBASE}/2.pdf" | tee "./compare/${MAPBASE}/compare.log"

  # if the PDFs are identical, delete the working directory (we only keep differences for examination)
  if [ $? -eq 0 ]
  then
    rm -rf "./compare/${MAPBASE}"
  fi
done
