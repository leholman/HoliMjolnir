## First we run this script to QC, merge and discard poor sequences before mapping
ls *_R1.fastq.gz | sed 's/_R1.fastq.gz$//' | sort | uniq |
while IFS= read -r i; do

sbatch <<EOL
#!/bin/bash
#SBATCH --job-name=Prep.1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --time=03:00:00
#SBATCH --mem=100G
cd /home/gwm297/data/SeaChange_WP2/0.rawdata/

module purge
module load conda
source ~/.bashrc
conda activate sga-env
module load fastp
module load vsearch
echo "Trimming $i"
fastp  -i "${i}_R1.fastq.gz" -I "${i}_R2.fastq.gz" -m --merged_out "${i}.trim.fastq" -V --detect_adapter_for_pe -D --dup_calc_accuracy 5  -g -x -q 30 -e 25 -l 30 -y -c -p -h '${i}.fastp.report.html' -w 8
echo "Dedup $i"
vsearch --fastx_uniques "${i}.trim.fastq" --fastqout "${i}.trim.vs.fastq" --minseqlength 30 --strand both
read_count=\$(( \$(wc -l < ${i}.trim.vs.fastq) / 4 ))
echo "${i},\$read_count" >> vsearch.counts.csv
sga preprocess --dust-threshold=4 -m 30 "${i}.trim.vs.fastq"  -o "${i}.trim.vs.d4.fastq"
read_count=\$(( \$(wc -l < ${i}.trim.vs.d4.fastq) / 4 ))
echo "${i},\$read_count" >> sga.counts.csv
gzip "${i}.trim.vs.d4.fastq"

mv "${i}.trim.vs.d4.fastq.gz" "../1.premapping/${i}.trim.vs.d4.fastq.gz"
EOL
done;

### now we extract all the outputs from the html files
ls *.fastp.report.html | sed 's/.fastp.report.html//' | sort > sample_names.txt
sort -t',' -k1,1 vsearch.counts.csv > sorted.vsearch.counts.csv

echo "Sample,sequencing,duplication rate,raw reads,fastP filtered reads,too short reads,low complexity,low quality,GC content,Insert Size Peak,no overlap percent,ID2,premapping reads" > data.summary.output.csv

paste -d ',' \
  sample_names.txt \
  <(for f in $(cat sample_names.txt); do val=$(grep 'sequencing' $f.fastp.report.html | cut -f5 -d">" | cut -f1 -d"<" | awk 'NR==1'); echo "${val:-NA}"; done) \
  <(for f in $(cat sample_names.txt); do val=$(grep 'duplication rate' $f.fastp.report.html | cut -f5 -d">" | cut -f1 -d"%"); echo "${val:-NA}"; done) \
  <(for f in $(cat sample_names.txt); do val=$(grep 'total reads' $f.fastp.report.html | cut -f5 -d">" | cut -f1 -d"<" | awk 'NR==1'); echo "${val:-NA}"; done) \
  <(for f in $(cat sample_names.txt); do val=$(grep 'total reads' $f.fastp.report.html | cut -f5 -d">" | cut -f1 -d"<" | awk 'NR==2'); echo "${val:-NA}"; done) \
  <(for f in $(cat sample_names.txt); do val=$(grep 'reads too short' $f.fastp.report.html | cut -f5 -d">" | cut -f1 -d"<" | cut -f2 -d"(" | cut -f1 -d"%"); echo "${val:-NA}"; done) \
  <(for f in $(cat sample_names.txt); do val=$(grep 'low complexity' $f.fastp.report.html | cut -f5 -d">" | cut -f1 -d"<" | cut -f2 -d"(" | cut -f1 -d"%"); echo "${val:-NA}"; done) \
  <(for f in $(cat sample_names.txt); do val=$(grep 'low quality' $f.fastp.report.html | cut -f5 -d">" | cut -f2 -d"(" | cut -f1 -d"%"); echo "${val:-NA}"; done) \
  <(for f in $(cat sample_names.txt); do val=$(grep 'GC content' $f.fastp.report.html | cut -f5 -d">" | cut -f1 -d"<" | awk 'NR==2'); echo "${val:-NA}"; done) \
  <(for f in $(cat sample_names.txt); do val=$(grep 'Insert size peak' $f.fastp.report.html | cut -f5 -d">" | cut -f1 -d"<"); echo "${val:-NA}"; done) \
  <(for f in $(cat sample_names.txt); do val=$(grep 'This estimation is based on paired-end overlap analysis' $f.fastp.report.html | sed -E 's/.* ([0-9]+\.[0-9]+)% .*/\1/'); echo "${val:-NA}"; done) \
  <(cut -d',' -f1 sorted.vsearch.counts.csv) \
  <(cut -d',' -f2 sorted.vsearch.counts.csv) \
  >> data.summary.output.csv
