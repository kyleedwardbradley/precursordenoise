# precursordenoise
This repository contains code supporting a rapid re-analysis of data published in Bletery, Q. and Nocquet, J.M. (2023). The precursory phase of large earthquakes. Science 381, 297-301. DOI:10.1126/science.adg2565

The re-analysis blog post is here: https://earthquakeinsights.substack.com/p/earthquake-precursors-not-so-fast

To use this code, 
  1. Download all of the supplementary data files from the article and extract them into a new folder. 
  2. Set up a Python environment as per the instructions in the supplementary info.
     Note that you need to install the pyeq and pyacs packages following the author instructions. A conda environment
     works well for this process. Keep using conda install (with -c conda-forge) and pip install until you have the
     environment working.
  3. Use jupytr notebook to run ./make_stack.ipynb to replicate the figures in the original paper.
  4. Place the common_mode_denoise.sh script in the folder.
  5. Run ./common_mode_denoise.sh to perform the common mode calculation and subtraction
  6. Run ./make_dot_product.py to re-create the dot products
  7. Use jupytr notebook to run ./make_stack.ipynb again, making sure to re-run all cells, to create new figures from
     the denoised data.

Any comments about the code should be sent to geokyle@gmail.com
