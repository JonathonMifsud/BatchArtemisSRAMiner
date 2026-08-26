import sys
import re

if len(sys.argv) != 3:
    print("Usage: python3 convert_logan_contigs_to_megahit.py <input_fasta> <output_fasta>")
    sys.exit(1)

input_fasta = sys.argv[1]
output_fasta = sys.argv[2]

# Compile the regex pattern outside the loop for efficiency
pattern = re.compile(r'(ka|km):f:([0-9\.]+)')

with open(input_fasta, 'r') as infile, open(output_fasta, 'w') as outfile:
    for line in infile:
        if line.startswith('>'):
            # This is a header line
            parts = line.split()
            accession = parts[0][1:].split('_')[0]  # Extract accession without '>'
            count = parts[0].split('_')[1]  # Extract count
            abundance_match = pattern.search(line)
            abundance = abundance_match.group(2) if abundance_match else '0'

            # Prepare the new header
            new_header = f">c{count}_ka_f_{abundance}_len"
        else:
            # This is a sequence line
            seq_len = len(line.strip())
            full_header = f"{new_header}{seq_len}_{accession}\n"
            outfile.write(full_header)
            outfile.write(line)

print(f"Conversion complete! Modified FASTA saved to {output_fasta}")
