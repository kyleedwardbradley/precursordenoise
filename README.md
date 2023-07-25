# precursordenoise
This repository contains code supporting a re-analysis of data published in Bletery, Q. and Nocquet, J.M. (2023). 
The precursory phase of large earthquakes. Science 381, 297-301. DOI:10.1126/science.adg2565

The re-analysis blog post is here: https://earthquakeinsights.substack.com/p/earthquake-precursors-not-so-fast

This code attempts to remove a common mode signal from GPS time series data by calculating an average displacement for all GPS
sites located farther than 200km away from the ultimate earthquake epicenter. Because these far-field sites should have 0
displacement due to earthquake precursor effects, they provide an estimate of the time-varying common mode signal. The resulting 
average time series is subtracted from all time series in each earthquake dataset before running the published analysis code.

To use this code, 
  1. Download all of the supplementary data files from the article and extract them into a new folder. 
  2. Set up a Python + GMT environment as per the instructions in the supplementary info.
     Note that you need to install the pyeq and pyacs packages following the author instructions. A conda environment
     works well for this process. Keep using conda install (with -c conda-forge) and pip install until you have the
     environment working. GMT 6.4 was used in the re-analysis.
     Side note: If installation of pyeq fails due to an error importing sphinx, comment out lines 49 and 50 in setup.py:
       # from sphinx.setup_command import BuildDoc
       # cmdclass = {'build_sphinx': BuildDoc}
  4. Use jupytr notebook to run ./make_stack.ipynb to replicate the figures in the original paper.
  5. Place the common_mode_denoise.sh script in the folder.
  6. Run ./common_mode_denoise.sh to perform the common mode calculation and subtraction. This creates some PDF figures
     and replaces the TS_*.dat files with corrected files; the original files are archived.
  8. Run ./make_dot_product.py to re-create the dot product data files
  9. Use jupytr notebook to run ./make_stack.ipynb again, making sure to re-run all cells, to create new figures from
     the denoised data. Some cells may fail if trend fitting is impossible; ignore those failures and continue.
  10. Adjusting the y-axis scaling of figures using (e.g.) plt.ylim([-0.05,0.15]) may be necessary to compare between original and
      updated figures.

Any comments or queries about the code should be sent to geokyle@gmail.com
