# compare-pdf-images

This is a perl script that visually compares two PDF files for differences by

* Using Ghostscript to render each PDF to a multipage TIFF
* Using ImageMagick to analyze the two multipage TIFFs for differences

This utility _does not compare text content_. It renders the PDFs to bitmap images, then reports if the pixels differ between them. With this approach, formatting changes (including changes in padding, margin, etc.) are detected.

## Getting Started

You can run these utilities on a native linux machine, or on a Windows 10 machine that has Windows Subsystem for Linux (WSL) installed. Other architectures can work, but this is what I have access to.

### Prerequisites

#### Ghostscript

You must have a Ghostscript installation on your machine that supports TIFF output.
(I am using 9.26, dated 2018-11-20.)
The script looks for `gs` in the environment search path.

#### ImageMagick

You must have an ImageMagick 7 installation on your machine that supports TIFF input.
The script looks for `magick` in the environment search path.

If you do not have ImageMagick 7 installed, and your Ubuntu repository still offers
6.x at the latest, I strongly suggest using ImageMagick Easy Install (IMEI):

https://github.com/SoftCreatR/imei

ImageMagick is easy to install from the source tarball, but many image formats
("delegates") are missing in a default Ubuntu installation, including TIFF. IMEI
automates all the tricky business of identifying and downloading the additional
development packages needed for a full-featured installation of ImageMagick 7.

### Installing

Download or clone the repository, then put its `bin/` directory in your search path.

For example, in the default bash shell, add this line to your `~/.profile` file:

```
PATH=~/compare-pdf-images/bin:$PATH
```

## Usage

`compare-pdf-images.pl` takes two PDF files as input, then reports visual differences (if any). The syntax is,

```
$ compare_pdf_images.pl -help
Usage:
      <pdf1> <pdf2>
            Two PDF files to compare
      -verbose
            Show additional information about reading and processing files
```

The basic usage is,

`$ compare_pdf_images.pl file1.pdf file2.pdf`

If the files are identical, the script reports:

`Of 47 pages, PDF images are identical.`

If the files differ, the script reports:

`Of 47 pages, PDF images differ at: 4-5, 17, 29-47.`

If the files have different page counts, both page counts are reported, and the additional pages are always reported as different:

`Of (47 and 51) pages, PDF images differ at: 4-5, 17, 29-51.`

The script returns `0` for identicality and `1` for difference. This allows scripts to check its return code.

By default, only a single-line result message is printed. To show analysis progress, along with the command lines used for analysis, use the `-verbose` option:

```
$ compare_pdf_images.pl pdf1.pdf pdf2.pdf -verbose
Rendering PDF file 'pdf1.pdf' to TIFF via the following command:
  gs -dNOPAUSE  -dBATCH -sDEVICE=tiff24nc -sOutputFile='/tmp/OfEL80deVf/1.tiff' -sCompression=lzw -dUseCropBox -r72 'pdf1.pdf'

Rendering PDF file 'pdf2.pdf' to TIFF via the following command:
  gs -dNOPAUSE  -dBATCH -sDEVICE=tiff24nc -sOutputFile='/tmp/OfEL80deVf/2.tiff' -sCompression=lzw -dUseCropBox -r72 'pdf2.pdf'

Comparing temporary TIFF files via the following command:
  magick '/tmp/OfEL80deVf/1.tiff' null: '/tmp/OfEL80deVf/2.tiff' -background None -compose Difference -layers Composite -format 'IsDifferent=%[fx:maxima==0?0:1]\n' info:

Of 2 pages, PDF images differ at: 1-2.
```

## Examples

### compare_ditaot_versions.sh

The [`compare_ditaot_versions.sh`](examples/compare_ditaot_versions.sh) script compares the PDF output from two different versions of the [DITA Open Toolkit](https://www.dita-ot.org/) for a set of .ditamap files. For each book, the PDFs are kept only if they don't match. This reduces the disk space required to run a full output regression test of many map files.

## Implementation Notes

I tried the PDF-to-TIFF conversion support built into ImageMagick (which calls Ghostscript internally I think?), but I was able to achieve better output by calling Ghostscript directly. The TIFF output is LZW-compressed.

The script places the TIFF files in a temporary directory that is deleted when the script exits. To obtain the TIFF files, run the comparison with `-verbose`, then adapt/run the PDF-to-TIFF rendering commands shown.

The rendering DPI is currently hardcoded at 72 DPI. I chose this so that [one point](https://en.wikipedia.org/wiki/Point_(typography)) in the PDF exactly matches one pixel in the TIFF.

## Author

My name is Chris Papademetrious. I'm a technical writer with [Synopsys Inc.](https://www.synopsys.com/), a semiconductor design and verification software company.

## License

This project is licensed under the GPLv3 license - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

This utility would not be possible without help from:

* [snibgo](https://github.com/snibgo), who basically did *all* the heavy lifting [by crafting the ImageMagick command line](https://github.com/ImageMagick/ImageMagick/discussions/3279) that compares the multipage TIFF images and reports differences in textual form. Everything else is just convenience stuff built around his work.

* [Synopsys Inc.](https://www.synopsys.com/) (my employer), for allowing me to share my work with the community.
