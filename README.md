# rmake 

Formerly `SGE-make`.
A better way to submit multiple jobs to a grid engine, with options for controlling the wrapper (`rmake`) and the underlying `make` call.

# Introduction

The purpose of `rmake`<sup>1</sup> is to execute a makefile by submitting individual `make` commands as individual jobs to the gridengine. This is necessary when (1) syntax of your makefile is complicated enough that it does not work correctly wtih `qmake`, or (2) when you want to use the global queue of the gridengine without modifying your makefile. 

`rmake` does this by recognizing the jobs you would like to submit and sending them one by one to `qsub`. To do so, `rmake` requires that your directory already be setup to handle [recursive make](https://www.gnu.org/software/make/manual/html_node/Recursion.html). In other words, the directory structure must look something like this:

    subjects/
     + Makefile
     + make_rest.mk
     + subj1/
     |  + Makefile  (hopefully a symlink to subjects/make_rest.mk)
     |  + T1.nii.gz (or other data)
     + subj2/
     |  + Makefile
     |  + T1.nii.gz
     + subj3/
     + subj4/
     + ...

where the top-level '`Makefile`' contains commands like below to allow recursion.

    SUBJECTS=$(wildcard test.*)
    .PHONY: all $(SUBJECTS) 
    
    all: $(SUBJECTS)
    
    $(SUBJECTS):
        $(MAKE) --directory=$@ $(TARGET)

`subjects/make_rest.mk` (for example), contains actual commands, for example:

    T1_brain.nii.gz: T1.nii.gz
        bet $< $@

`subj*/Makefile` are symlinks to `subjects/make_rest.mk` *not* `subjects/Makefile.`

This is the way that people are encouraged to structure subject-level processing. `rmake` will perform a brief sanity to check to ensure this directory structure is enforced, but be aware willy-nilly directory structure might result in weird errors.

<sup>1</sup> Because "*r*" comes after "*q*," you see.

# Using `rmake`

To distinguish the options to `rmake` from options to the underlying `make` call we use the convention that lowercase flags are passed to the underlying 
`make` call, and uppercase flags control `rmake`.

**Note**: `qsub` won't accept job names that start with a number, so `rmake` automatically prepends "s" to IDs that start with a number. 

## `rmake` options

Options with and asterisk `*` require an argument

 * **`-C`**     Print only the changes to make flags (a subset of `-H`).
 * **`-D`**     Recon; do everything but submit `qsub` jobs.
 * **`-H`**     Print a help message and exit.
 * **`-M`**     Debug; print arguments to make call. (No qsub submission.)
 * **`-N *`**   Set job name; if not set, it will be set to target, then   
                a random name.
 * **`-O`**     Save output/error files to `qout-$user/`  and `qerr-$user`.
 * **`-P`**     Append `<date>_<time>`` to the jobid.
 * **`-Q *`**   Choose which queue. If left unspecified, queue will be chosen
                by qsub.
 * **`-S *`**   Run qsub on these subjects only; if not set, run on all.
 * **`-T *`**   Set the target for make. Will accept multiple 
                space-separated targets, if the argument is quoted.

**Note**: Mistyping or chosing a nonexistent queue will result in the error 

    Unable to run job: Job was rejected because job requests unknown queue "<queue>".


## `make` options

Options can be passed to the underlying `make` call as well. Lowercase options are exactly the same as in the `make` man page (e.g. `-n`), and some uppercase options have been mapped to lowercase.

**These are the uppercase flag to lowercase flag mappings:**

 * **`-I *`**   include dir         ->  `-a *`
 * **`-B`**     unconditional make  ->  `-b`
 * **`-L`**     check symlink times ->  `-m`
 * **`-W *`**   consider always new ->  `-z *`

The following `make` flags are not supported, either because there is no point (`-{C, f, r, R, S}`) or because they would hurt performance(`-{j, l}`).

**Disabled flags:**

 * **`-C`**   Ignored (no use)
 * **`-f`**   Disabled; we need symlinks named 'Makefile'
 * **`-j/l`** Not useful; exit here.
 * **`-r/R`** Built-in rules/variables aren't used in our applications, no reason to disable them.
 * **`-S`**   Ignored, `-k` is never inherited in context.
 
## Calling `rmake`

Invoking `rmake` is simple. For example, to make the target `sleep` for everyone, call it with the `-T` flag.

>`rmake -T sleep`

`rmake` can be called without the `-T` flag, in which case the default target will be the first target in the makefile within each subject directory.

You can also pass multiple targets to `rmake`, for example. Take care to quote them. Targets will be combined into the job name with a comma.

>`rmake -T "sleep1 sleep2"`

The name of this job will be something like `s99.sleep1,sleep2`.

If you don't want your jobs to stop, you can pass that command to `make` like so (option can occur in any order):

>`rmake -k -T sleep`

You can also call `rmake` only on a subset of the subjects with `-S`. If `-S` is not set, the default behavior is to work on them all.

Select subjects like so:

>`rmake -T sleep -S "subj1 subj2"`

**Note the argument to -S has to be quoted (if there is more than one). `rmake` will perform a small sanity check if it thinks you have misquote the argument to `-S`, but will attempt to run.**

You can also use a regex. For example, to select only subjects beginning with `100-`:

>`rmake -T sleep -S "100???"`

Note that the regex must be quoted as well, as it is expanded by the shell before being sent to `rmake`.

## Output

Each `qsub` job results in the creation of two files, named `name.[e,o]ID`, where `name` is the name you gave the job, and `ID` is a numerical ID `qsub` assigned it. If you pass the `-O` option to rmake, these will instead be sorted to directories `qout-$user` and `qerr-$user`

The files with `e` in the name contain the output of `STDERR` if the job had been executed normally, `o` files, `STDOUT`. 

These files may be removed if you are satisfied with how your job executed.

# Using the example

You'll notice that the repository contains 10 `test.*` directories, each with a single symlink named `Makefile`. The repository is set up so that you can test rmake right here by running `rmake -T sleep`, which creates the files `hexdump.txt` and `sleep.txt`

The target `sleep` relies on `hexdump.txt`, so in order to rerun jobs, all the `hexdump.txt` files need to be removed.

# Contact

Trevor K.M. Day 
    Email: `tkmday@uw.edu`
    GitHub: @TrevorKMDay

