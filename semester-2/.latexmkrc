#!/bin/env perl

@default_files = ('baap-sem2.tex');

# This file was shamelessly copied from
# https://collaborating.tuhh.de/alex/latex-git-cookbook/-/blob/4174942b6674588d016189c708327dccbaac5b8d/.latexmkrc

# Shebang is only to get syntax highlighting right across GitLab, GitHub and IDEs.
# This file is not meant to be run, but read by `latexmk`.

# ======================================================================================
# Perl `latexmk` configuration file
# ======================================================================================

# In the line below replace 'main.tex' with the name of the main *LaTeX* file.
# This line is optional for single-file projects; using it means that latexmk
# may be invoked without a filename, even if the file main.tex doesn't yet exist:
#
# $ latexmk
#
# If the line is not used, and the target LaTeX file does not yet exist,
# its name must be supplied, e.g.:
#
# $ latexmk main
#
# It is compulsory for multiple file projects, so we avoid running pdflatex
# on child documents.
# @default_files=('main.tex');

# Default viewer
$pdf_previewer = "start evince %O %S";

# ======================================================================================
# PDF Generation/Building/Compilation
# ======================================================================================

# PDF-generating modes are:
# 1: pdflatex, as specified by $pdflatex variable (still largely in use)
# 2: postscript conversion, as specified by the $ps2pdf variable (useless)
# 3: dvi conversion, as specified by the $dvipdf variable (useless)
# 4: lualatex, as specified by the $lualatex variable (best)
# 5: xelatex, as specified by the $xelatex variable (second best)
$pdf_mode = 4;

# Treat undefined references and citations as well as multiply defined references as
# ERRORS instead of WARNINGS.
# This is only checked in the *last* run, since naturally, there are undefined references
# in initial runs.
# This setting is potentially annoying when debugging/editing, but highly desirable
# in the CI pipeline, where such a warning should result in a failed pipeline, since the
# final document is incomplete/corrupted.
#
# However, I could not eradicate all warnings, so that `latexmk` currently fails with
# this option enabled.
# Specifically, `microtype` fails together with `fontawesome`/`fontawesome5`, see:
# https://tex.stackexchange.com/a/547514/120853
# The fix in that answer did not help.
# Setting `verbose=silent` to mute `microtype` warnings did not work.
# Switching between `fontawesome` and `fontawesome5` did not help.
$warnings_as_errors = 0;

# Show used CPU time. Looks like: https://tex.stackexchange.com/a/312224/120853
$show_time = 1;

# Default is 5; we seem to need more owed to the complexity of the document.
# Actual documents probably don't need this many since they won't use all features,
# plus won't be compiling from cold each time.
$max_repeat=5;

# --shell-escape option (execution of code outside of latex) is required for the
#'svg' package.
# It converts raw SVG files to the PDF+PDF_TEX combo using InkScape.
#
# SyncTeX allows to jump between source (code) and output (PDF) in IDEs with support
# (many have it). A value of `1` is enabled (gzipped), `-1` is enabled but uncompressed,
# `0` is off.
# Testing in VSCode w/ LaTeX Workshop only worked for the compressed version.
# Adjust this as needed. Of course, only relevant for local use, no effect on a remote
# CI pipeline (except for slower compilation, probably).
#
# %O and %S will forward Options and the Source file, respectively, given to latexmk.
#
# `set_tex_cmds` applies to all *latex commands (latex, xelatex, lualatex, ...), so
# no need to specify these each. This allows to simply change `$pdf_mode` to get a
# different engine. Check if this works with `latexmk --commands`.
set_tex_cmds("--shell-escape --synctex=1 %O %S");

# option 2 is same as 1 (run biber when necessary), but also deletes the
# regeneratable bbl-file in a clenaup (`latexmk -c`). Do not use if original
# bib file is not available!
$bibtex_use = 1;  # default: 1

# Change default `biber` call, help catch errors faster/clearer. See
# https://web.archive.org/web/20200526101657/https://www.semipol.de/2018/06/12/latex-best-practices.html#database-entries
$biber = "biber --validate-datamodel %O %S";

# directory
$aux_dir = "build";
# Silence 'can not write' error on the first run of compiler
system("mkdir", "-p", "$aux_dir/questions");

# ======================================================================================
# Auxiliary Files
# ======================================================================================

# Let latexmk know about generated files, so they can be used to detect if a
# rerun is required, or be deleted in a cleanup.
# loe: List of Examples (KOMAScript)
# lol: List of Listings (`listings` and `minted` packages)
# run.xml: biber runs
# glg: glossaries log
# glstex: generated from glossaries-extra
push @generated_exts, 'loe', 'lol', 'run.xml', 'glg', 'glstex';

# Also delete the *.glstex files from package glossaries-extra. Problem is,
# that that package generates files of the form "basename-digit.glstex" if
# multiple glossaries are present. Latexmk looks for "basename.glstex" and so
# does not find those. For that purpose, use wildcard.
# Also delete files generated by gnuplot/pgfplots contour plots
# (.dat, .script, .table).
$clean_ext = "%R-*.glstex %R_contourtmp*.*";

# ======================================================================================
# bib2gls as a custom dependency
# ======================================================================================

# Grabbed from latexmk CTAN distribution:
# Implementing glossary with bib2gls and glossaries-extra, with the
# log file (.glg) analyzed to get dependence on a .bib file.
# !!! ONLY WORKS WITH VERSION 4.54 or higher of latexmk

# Add custom dependency.
# latexmk checks whether a file with ending as given in the 2nd
# argument exists ('toextension'). If yes, check if file with
# ending as in first argument ('fromextension') exists. If yes,
# run subroutine as given in fourth argument.
# Third argument is whether file MUST exist. If 0, no action taken.
add_cus_dep('aux', 'glstex', 0, 'run_bib2gls');

# PERL subroutine. $_[0] is the argument (filename in this case).
# File from author from here: https://tex.stackexchange.com/a/401979/120853
sub run_bib2gls {
    if ( $silent ) {
    #    my $ret = system "bib2gls --silent --group '$_[0]'"; # Original version
        my $ret = system "bib2gls --silent --group $_[0]"; # Runs in PowerShell
    } else {
    #    my $ret = system "bib2gls --group '$_[0]'"; # Original version
        my $ret = system "bib2gls --group $_[0]"; # Runs in PowerShell
    };

    my ($base, $path) = fileparse( $_[0] );
    if ($path && -e "$base.glstex") {
        rename "$base.glstex", "$path$base.glstex";
    }

    # Analyze log file.
    local *LOG;
    $LOG = "$_[0].glg";
    if (!$ret && -e $LOG) {
        open LOG, "<$LOG";
    while (<LOG>) {
            if (/^Reading (.*\.bib)\s$/) {
        rdb_ensure_file( $rule, $1 );
        }
    }
    close LOG;
    }
    return $ret;
}