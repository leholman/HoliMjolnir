#### 2.1 Eukaryotic Mapping 
cd ../2.mapping
find -L /datasets/globe_databases/holi_db \( -name '*.bt2' -o -name '*.bt2l' \) |

# ── 1. Pick newest date for each family (refseq/plant, nt, etc.) ──
awk -F/ '
{
    # Find the field containing the 8-digit date (YYYYMMDD)
    date_field = 0;
    for (i = 1; i <= NF; i++) {
        if ($i ~ /^[0-9]{8}$/) {
            date_field = i;
            break;
        }
    }

    if (date_field > 0) {
        # Define family as everything before the date (e.g., .../holi_db/phylonorway)
        fam = "";
        for (j = 1; j < date_field; j++) {
            fam = (fam == "" ? $j : fam "/" $j);
        }

        date = $date_field;
        line = $0;

        # Track the newest date for phylonorway specific family path
        if (date > newest[fam]) {
            newest[fam] = date;
        }

        # Store lines in a bucket for that specific family and date
        bucket[fam, date] = bucket[fam, date] ? bucket[fam, date] ORS line : line;
    }
}
END {
    for (key in bucket) {
        split(key, a, SUBSEP);
        fam = a[1]; 
        date = a[2];
        # Only print the bucket if it matches the newest date found for that family
        if (date == newest[fam]) {
            print bucket[key];
        }
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


sbatch map.sh


