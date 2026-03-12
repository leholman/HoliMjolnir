#!/bin/bash
#SBATCH --job-name=metaDMG_updated_nov25
#SBATCH --output=metaDMG_updated_nov25_%A_%a.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=150G
#SBATCH --time=15:00:00
#SBATCH --array=1-81%10

# Directory
cd /projects/path_to_files

# Get the sample name for this array task
#SAMPLE_LIST=base_bam_nobact.txt
SAMPLE_LIST=bam_list.txt
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

OUTPUT_PATH=/projects/path/metaDMG_Nov25
INPUT_PATH=/projects/path_to_files

echo "Processing sample: $SAMPLE"

# Step 1: Taxonomic classification
/projects/seachange-AUDIT/apps/metaDMG_19Nov25/metaDMG-cpp/metaDMG-cpp lca \
  --names /projects/seachange-AUDIT/data/NCBI_Taxonomy_updated2025/names.dmp \
  --nodes /projects/seachange-AUDIT/data/NCBI_Taxonomy_updated2025/nodes.dmp \
  --acc2tax /projects/seachange-AUDIT/data/NCBI_Taxonomy_updated2025/combined_acc2tax2025.txt.gz \
  --sim_score_low 0.95 --sim_score_high 1.0 --how_many 15 --weight_type 1 --lca_rank family \
  --fix_ncbi 0 --threads 8 --filtered_acc2tax $OUTPUT_PATH/${SAMPLE}.comp.no_bact.filtered.acc2tax \
  --bam $INPUT_PATH/${SAMPLE}.no_bact.bam \
  --out_prefix $OUTPUT_PATH/${SAMPLE}.comp.no_bact

# Step 2: Damage estimation
/projects/seachange-AUDIT/apps/metaDMG_19Nov25/metaDMG-cpp/metaDMG-cpp dfit \
  $OUTPUT_PATH/${SAMPLE}.comp.no_bact.bdamage.gz --threads 6 \
  --names /projects/seachange-AUDIT/data/NCBI_Taxonomy_updated2025/names.dmp \
  --nodes /projects/seachange-AUDIT/data/NCBI_Taxonomy_updated2025/nodes.dmp \
  --showfits 2 --nopt 10 --nbootstrap 20 --doboot 1 --seed 1234 --lib ds \
  --out_prefix $OUTPUT_PATH/${SAMPLE}.comp.no_bact

# Step 3: Aggregation
/projects/seachange-AUDIT/apps/metaDMG_19Nov25/metaDMG-cpp/metaDMG-cpp aggregate \
  $OUTPUT_PATH/${SAMPLE}.comp.no_bact.bdamage.gz \
  --names /projects/seachange-AUDIT/data/NCBI_Taxonomy_updated2025/names.dmp \
  --nodes /projects/seachange-AUDIT/data/NCBI_Taxonomy_updated2025/nodes.dmp \
  --lcastat $OUTPUT_PATH/${SAMPLE}.comp.no_bact.stat.gz \
  --dfit $OUTPUT_PATH/${SAMPLE}.comp.no_bact.dfit.gz \
  --out_prefix $OUTPUT_PATH/${SAMPLE}.comp.no_bact.agg

echo "Sample ${SAMPLE} completed successfully."
