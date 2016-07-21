# SGE-make
Running make on an SGE 

# Introduction

The purpose of `rmake`<sup>1</sup> is to supercede `qmake` and submit jobs to the grid engine in a more manageable way (read: jobs Tara can kick off her machines).

`rmake` does this by recognizing the jobs you would like to submit and sending them one by one to `qsub`. In order to do so, `rmake` requires that your directory already be setup to handle [recursive make](https://www.gnu.org/software/make/manual/html_node/Recursion.html). I.e. the directory structure must look something like this:

    subjects/
     + Makefile
     + make_rest.mk
     + subj1/
     |  + Makefile  (hopefully a symlink to subjects/Makefile)
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

`rmake` will perform a brief sanity to check to ensure this directory structure is enforced, but be aware willy-nilly directory structure might result in weird errors.

<sup>1</sup> Because *r* comes after *q*, you see.

# Using `rmake`

The options to `rmake` are predicated on the following conceit:

 * `-a`: Options to the underlying `make` call.
 * `-A`: Options to `rmake`.

## `rmake` options

Options with and asterisk `*` require an argument

 * **`-C`**      Print only the changes to make flags (a subset of `-H`).
 * **`-D`**      Recon; do everything but submit `qsub` jobs.
 * **`-H`**      Print a help message and exit.
 * **`-M`**      Debug; print arguments to make call. (No qsub submission.)
 * **`-N *`**    Set job name; if not set, it will be set to target, then a random name.
 * **`-P`**      Append `<date>_<time>`` to the jobid.
 * **`-S *`**    Run qsub on these subjects only; if not set, run on all.
 * **`-T *`**    Set the target for make.

## `make` options

Options can be passed too to `make` itself. Lowercase options retain their identifier (e.g. `-n`), and some uppercase options have been mapped to lowercase.

**These are the `A -> a` mappings:**

 * **`-I *`**   include dir         ->  `-a *`
 * **`-B`**     unconditional make  ->  `-b`
 * **`-L`**     check symlink times ->  `-m`
 * **`-W *`**   consider always new ->  `-z *`

The following flags are not callable, either because there is no point (`-{C, f, r, R, S}`) or because they would be actively harmful to our system (`-{j, l}`).

**Disabled flags:**

 * **`-C`**   Ignored (no use)
 * **`-f`**   Disabled; we need symlinks named 'Makefile'
 * **`-j/l`** Not useful; exit here.
 * **`-r/R`** Built-in rules/variables aren't used in our applications, no reason to disable them.
 * **`-S`**   Ignored, `-k` is never inherited in context.
 
## Calling `rmake`

Invoking `rmake` is simple. For example, to make the target `sleep` for everyone, call it with the `-T` flag.

>`rmake -T sleep`

`rmake` can be called without the `-T` flag, in which case the default behavior of `make`, were it executed without a target will occur in each subject directory.

If you don't want your jobs to stop, you can pass that command to `make` like so (option can occur in any order):

>`rmake -k -T sleep`

You can also call `rmake` only on a subset of the subjects with `-S`. If `-S` is not set, the default behavior is to work on them all.

Select subjects like so:

>`rmake -T sleep -S "subj1 subj2"`

**Note the argument to -S has to be quoted (if there is more than one). `rmake` will perform a small sanity check if it thinks you have misquote the argument to `-S`, but will attempt to run.**

You can also use a regex. For example, to select only subjects beginning with `100-`:

>`rmake -T sleep -S "100???"`

Note that the regex must be quoted as well, as it is expanded by the shell before being sent to `rmake`.

# Output

Each `qsub` job results in the creation of two files, named `name.[e,o]ID`, where `name` is the name you gave the job, and `ID` is a numerical ID `qsub` assigned it.

The files with `e` in the name contain the output of `STDERR` if the job had been executed normally, `o` files, `STDOUT`. 

These files may be removed if you are satisfied with how your job executed.

# Contact

Trevor McAllister-Day -- `tkmday@uw.edu`