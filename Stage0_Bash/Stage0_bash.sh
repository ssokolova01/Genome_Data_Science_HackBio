#!/bin/bash
# HackBio Stage 0 – Project 1: Bash Basics
# Author: Svetlana

# Task 1: Print my name.
echo "Svetlana"

# Task 2: Create a folder titled your name.
mkdir Svetlana

# Task 3: Create another new directory titled `biocomputing` and change to that directory with one line of command.
mkdir biocomputing && cd biocomputing/

# Task 4: Download 3 files.
wget https://raw.githubusercontent.com/HackBio-Internship/Bash_NGS_Starters/refs/heads/main/biocomp_samp/wildtype.fna && wget https://raw.githubusercontent.com/HackBio-Internship/Bash_NGS_Starters/refs/heads/main/biocomp_samp/wildtype.gbk && wget https://raw.githubusercontent.com/HackBio-Internship/Bash_NGS_Starters/refs/heads/main/biocomp_samp/wildtype.gbk

# Task 5: Move the .fna file to the folder titled your name.
mv wildtype.fna ../Svetlana/

# Task 6: Delete the duplicate gbk file.
rm wildtype.gbk.1

# Task 7. Confirm if the .fna file is mutant or wild type (tatatata vs tata).
grep -i "tatatata" ../Svetlana/wildtype.fna
# .fna file contains mutant sequence
grep -ic "tatatata" ../Svetlana/wildtype.fna
# at least in 18 lines
grep -qi "tatatata" ../Svetlana/wildtype.fna && echo "Mutant"
# print Mutant when demanded pattern is present

# Task 8. If mutant, print all matching lines into a new file.
grep -i "tatatata" ../Svetlana/wildtype.fna > ../Svetlana/mutant_lines.fna

# Task 9. Count number of lines (excluding header) in the .gbk file.
tail -n +2 wildtype.gbk | wc -l
# File wildtype.gbk has 57 line excluding the header.

# Task 10. Print the sequence length of the .gbk file. (Use the LOCUS tag in the first line).
grep "LOCUS" wildtype.gbk | awk '{print $3}'

# Task 11. Print the source organism of the .gbk file. (Use the SOURCE tag in the first line).
grep "SOURCE" wildtype.gbk | awk '{print $2,$3}'

# Task 12. List all the gene names of the .gbk file. Hint {grep '/gene='}.
# (/gene= appears twice – on the gene and CDS features – so sort -u removes the duplicate;
#  this record contains a single gene: lexA)
grep '/gene=' wildtype.gbk | awk -F'"' '{print $2}' | sort -u

# Task 13. Clear your terminal space and print all commands used today.
# (command history works in an interactive terminal; it prints nothing when run inside a script)
clear && history

# Task 14. List the files in the two folders.
ls -lh ../biocomputing ../Svetlana










