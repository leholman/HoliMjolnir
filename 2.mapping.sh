#### 2.1 Eukaryotic Mapping 
cd ../2.mapping
find -L /datasets/globe_databases/holi_db \( -name '*.bt2' -o -name '*.bt2l' \) |

# ── 1. Pick newest date for each family (refseq/plant, nt, etc.) ──
awk -F/ '
{
  fam  = $(NF-3) "/" $(NF-2);   # e.g. refseq/plant
  date = $(NF-1);               # e.g. 20250505
  line = $0;                    # full path including part-number & extension

  # remember newest date
  if (date > newest[fam]) newest[fam] = date;

  # keep every line, keyed by fam|date
  bucket[fam, date] = bucket[fam, date] ? bucket[fam, date] ORS line : line;
}
END {
  # spit out only lines that belong to the newest date for each family
  for (key in bucket) {
    split(key, a, SUBSEP); fam = a[1]; date = a[2];
    if (date == newest[fam]) print bucket[key];
  }
}' |

# ── 2. Now strip .rev.N.bt2[l] or .N.bt2[l] so we have a clean prefix ──
sed -E 's/\.rev\.[0-9]+\.?bt2l?$|\.?[0-9]+\.?bt2l?$//' |

# ── 3. Remove any duplicates that are left ──
sort -u > databases.txt

## find samples
find /projects/seachange/people/gwm297/SeaChange_WP2/1.premapping/ -type f -name '*fastq.gz' | sort > samples.txt


# Define the input files
sample_list="samples.txt"
database_list="databases.txt"

# Empty the output file
> commands.txt

# Loop through sample names
while IFS= read -r file; do
    # Extract base sample name without suffix
    loopfile=$(basename "$file" | sed -E 's/.trim.vs.d1.fastq.gz$//')
 mkdir $loopfile
    # Loop through database names
    while IFS= read -r DB; do
        # Generate the command
        command="bowtie2 -k 1000 -t -x $DB -U $file --no-unal --threads 24 | samtools view -bS - > ${loopfile}/${loopfile}.$(basename $DB).bam"
        
        # Print the command to a text file
        echo "$command" >> commands.txt
    done < "$database_list"
done < "$sample_list"