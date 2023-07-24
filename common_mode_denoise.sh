#!/usr/bin/env bash

# This script must be in the folder containing data_byEQ/ and other supplementary data files/folders
# A working folder layout looks like this:
# -rw-r--r--@   1 kylebradley  staff     5623 Jul 24 16:52 EDTableS1.txt
# -rwxr-xr-x@   1 kylebradley  staff     7702 Jul 24 13:03 common_mode_removal.sh
# drwxrwxr-x@  97 kylebradley  staff     3104 Jul 24 16:54 data_byEQ
# drwxrwxr-x@  92 kylebradley  staff     2944 May 16 12:00 eq_stack_figures
# drwxrwxr-x@   6 kylebradley  staff      192 May 16 12:00 eq_stack_figures_excluded
# -rw-r--r--@   1 kylebradley  staff     3948 Jul 24 16:52 extract_UNR_time_series.py
# drwxrwxr-x@  37 kylebradley  staff     1184 May 16 12:00 figures
# drwxrwxr-x@  31 kylebradley  staff      992 May 16 12:00 figures_tohoku_test
# drwxrwxr-x@  18 kylebradley  staff      576 May 16 12:00 gmtfiles
# -rw-r--r--@   1 kylebradley  staff     4439 Jul 24 16:53 make_dot_product.py
# -rw-r--r--@   1 kylebradley  staff     1994 Jul 24 16:53 make_files_4_map_plot.py
# -rw-r--r--@   1 kylebradley  staff  3523292 Jul 24 16:53 make_stack.ipynb
# -rw-r--r--@   1 kylebradley  staff     4419 Jul 24 16:53 make_station_list.py
# -rw-r--r--@   1 kylebradley  staff     2016 Jul 24 16:53 make_synthetics.py
# -rw-r--r--@   1 kylebradley  staff     5838 Jul 24 16:53 make_test_1.py
# -rw-r--r--@   1 kylebradley  staff     3875 Jul 24 16:53 make_test_2.py
# -rw-r--r--@   1 kylebradley  staff     7308 Jul 24 16:53 mapplot.gmt
# -rw-r--r--@   1 kylebradley  staff     5497 Jul 24 16:53 output_make_test_1.txt
# -rw-r--r--@   1 kylebradley  staff    16850 Jul 24 16:53 output_make_test_2.txt
# -rw-r--r--@   1 kylebradley  staff    11352 Jul 24 16:53 scardec_M7_full.txt
# drwxr-xr-x@ 138 kylebradley  staff     4416 Jul 24 16:54 test_figures_1
# drwxr-xr-x@ 134 kylebradley  staff     4288 Jul 24 16:54 test_figures_2
# -rw-r--r--@   1 kylebradley  staff     7542 Jul 24 16:53 tohoku_test.ipynb
# -rw-r--r--@   1 kylebradley  staff      105 Jul 24 16:53 unzip_UNR_data.sh

# To archive events with only one site, set to 1
archive_flag=1

# Create a directory to store folder for earthquakes with only one site
mkdir -p ./archived_earthquakes/

# Distance for common mode noise site selection
# Sites farther than SELECTDIST are used for common mode noise average calculation; closer are not used
SELECTDIST=200k

for this_dir in data_byEQ/*_MW_*; do 

    ( 
    cd $this_dir

    # Each time we run this script, obliterate the denoised .dat files and replace with original files
    mkdir -p ./saved_origfiles/

    echo "Processing DAT files in $this_dir"
    if [[ -d ./saved_origfiles/ && ! -z "$(ls -A ./saved_origfiles/)" ]]; then
        echo "Restoring original .dat files"
        rm -f *.dat
        mv ./saved_origfiles/*.dat ./
    fi

    # Select sites farther than X km from the earthquake location, then feed those to common mode calculation
    # Find the origin location from the scardec file
    gawk -v dir=${this_dir} < ../../scardec_M7_full.txt '
        {
            str=sprintf("data_byEQ/%s%s%sT%s:%s:%s_MW_%s",$2, $3, $4, $5, $6, $7, $1)
            if (str==dir) {
                print $9, $8
                printf("%s%s%sT%s:%s:%s_MW_%s",$2, $3, $4, $5, $6, $7, $1) > "origin_name.txt"
                exit
            }    
        }' > originloc.txt

    originlon=$(gawk < originloc.txt '{print $1}')
    originlat=$(gawk < originloc.txt '{print $2}')

    # We like longitude, latitude, ID format
    gawk < station_list.txt '{print $2, $3, $1}' > station_list_rearranged.txt

    # Select sites farther than specified distance from the epicenter
    gmt select station_list_rearranged.txt -fg -Ic -C${originlon}/${originlat}+d${SELECTDIST} | gawk '{print $1, $2, "TS_" $3 ".dat"}' > station_selected.txt
    # Select sites closer than specified distance from the epicenter
    gmt select station_list_rearranged.txt -fg  -C${originlon}/${originlat}+d${SELECTDIST} | gawk '{print $1, $2, "TS_" $3 ".dat"}' > station_not_selected.txt

    unset dat_files

    commonmode_selected_sites=($(gawk < station_selected.txt '{print $3}'))
    if [[ ${#commonmode_selected_sites[@]} -lt 3 ]]; then
        echo "There are not 3 or more sites farther than ${SELECTDIST}. Not calculating common mode noise."
    else
        dat_files=(${commonmode_selected_sites[@]})
    fi

    
    if [[ ${#dat_files[@]} -le 1 ]]; then
        echo "Only one .dat file (GPS site)."
        if [[ ${archive_flag} -eq 1 ]]; then
            echo "Archiving folder"
            cd ../..
            mv ${this_dir} ./archived_earthquakes/
        fi
    else
        echo "Proceeding with common mode calculation at sites ${dat_files[@]}"

        # Calculate the average East, North, Vertical components from all .dat files
        gawk '
        BEGIN {
            max=0
            min=0
        }
        { 
            # Sum the East, North, and Up components
            time[FNR]=$1; 
            e[FNR]=e[FNR]+$8; 
            n[FNR]=n[FNR]+$9; 
            v[FNR]=v[FNR]+$10 
        } 
        END { 
            for(i=1; i<=FNR; ++i) { 
                max=(e[i]/ARGIND>max)?e[i]/ARGIND:max
                max=(n[i]/ARGIND>max)?n[i]/ARGIND:max
                max=(v[i]/ARGIND>max)?v[i]/ARGIND:max
                min=(e[i]/ARGIND<min)?e[i]/ARGIND:min
                min=(n[i]/ARGIND<min)?n[i]/ARGIND:min
                min=(v[i]/ARGIND<min)?v[i]/ARGIND:min
                
                # Divide by the number of time series to get the average value
                print time[i], e[i]/ARGIND, n[i]/ARGIND, v[i]/ARGIND 
            }
            print time[1], time[FNR], min, max > "range.txt"
        }' ${dat_files[@]} > common_mode.txt

        # Make a figure using GMT
        tstart=$(gawk < range.txt '{print $1}')
        tend=$(gawk < range.txt '{print $2}')
        min=$(gawk < range.txt '{print $3}')
        max=$(gawk < range.txt '{print $4}')

        alldat_files=(*.dat)
        
        echo "Plotting common mode for far-field sites"

        gmt psxy common_mode.txt -R${tstart}/${tend}/${min}/${max} -Sc0.05i -Gblue -Bxaf -Byaf -JX10i/5i -i0,1 -K > farfield_average.ps
        gmt psxy common_mode.txt -R${tstart}/${tend}/${min}/${max} -Sc0.05i -Gred -Bxaf -Byaf -JX10i/5i -i0,2 -O -K >> farfield_average.ps
        gmt psxy common_mode.txt -R${tstart}/${tend}/${min}/${max} -Sc0.05i -Ggreen -Bxaf -Byaf -JX10i/5i -i0,3 -O -K >> farfield_average.ps
cat <<-EOF > legend.gmt
G -0.1i
H 8p,Times-Roman $(cat origin_name.txt)
H 8p,Times-Roman average of ${#dat_files[@]} / ${#alldat_files[@]} far-field sites
D 0.2i 1p
N 3
V 0 1p
S 0.1i c 0.15i blue 0.25p 0.15i E
S 0.1i c 0.15i red 0.25p 0.15i N
S 0.1i c 0.15i green 0.25p 0.15i V
EOF
        gmt pslegend legend.gmt -R${tstart}/${tend}/${min}/${max} -JX10i/5i -DjBL+w1.5i -O -F+gwhite  >> farfield_average.ps
        gmt psconvert farfield_average.ps -A+m0.5i -Tf && rm farfield_average.ps


        notsel_datafiles=($(gawk < station_not_selected.txt '{print $3}'))

        if [[ ${#notsel_datafiles[@]} -gt 3 ]]; then
            echo "Calculating common mode for sites within radius as well"
            gawk '
            BEGIN {
                max=0
                min=0
            }
            { 
                time[FNR]=$1; 
                e[FNR]=e[FNR]+$8; 
                n[FNR]=n[FNR]+$9; 
                v[FNR]=v[FNR]+$10 
            } 
            END { 
                for(i=1; i<=FNR; ++i) { 
                    print time[i], e[i]/ARGIND, n[i]/ARGIND, v[i]/ARGIND 
                }
            }' ${notsel_datafiles[@]} > nearfield_average.mode

            echo "Plotting near-field time series average"

            gmt psxy nearfield_average.mode -R${tstart}/${tend}/${min}/${max} -Sc0.05i -Gblue -Bxaf -Byaf -JX10i/5i -i0,1 -K > nearfield_average.ps
            gmt psxy nearfield_average.mode -R${tstart}/${tend}/${min}/${max} -Sc0.05i -Gred -Bxaf -Byaf -JX10i/5i -i0,2 -O -K >> nearfield_average.ps
            gmt psxy nearfield_average.mode -R${tstart}/${tend}/${min}/${max} -Sc0.05i -Ggreen -Bxaf -Byaf -JX10i/5i -i0,3 -O -K >> nearfield_average.ps
cat <<-EOF > legend.gmt
G -0.1i
H 8p,Times-Roman $(cat origin_name.txt)
H 8p,Times-Roman average of ${#notsel_datafiles[@]} / ${#alldat_files[@]} near-field sites
D 0.2i 1p
N 3
V 0 1p
S 0.1i c 0.15i blue 0.25p 0.15i E
S 0.1i c 0.15i red 0.25p 0.15i N
S 0.1i c 0.15i green 0.25p 0.15i V
EOF

            gmt pslegend legend.gmt -R${tstart}/${tend}/${min}/${max} -JX10i/5i -DjBL+w1.5i -O -F+gwhite  >> nearfield_average.ps
            gmt psconvert nearfield_average.ps -A+m0.5i -Tf && rm nearfield_average.ps
        fi

        # Archive the original data files and then subtract the common mode time series
        for this_file in *.dat; do 
            mv ${this_file} ./saved_origfiles/${this_file}
            gawk '
            # Read the common mode time series
            # File format is time East North Up
            (NR==FNR) { 
                ec[FNR]=$2; 
                nc[FNR]=$3; 
                vc[FNR]=$4 
            } 
            # Subtract. 
            # File format is 
            # J2000                              $8=East    $9=North  $10=Up
            # 352921500 55629 2011 3 9 068 20700 -0.0053114 0.0105504 0.0077437

            (NR!=FNR) { 
                $8=$8-ec[FNR]; 
                $9=$9-nc[FNR]; 
                $10=$10-vc[FNR]; 
                print $0 
            }' common_mode.txt ./saved_origfiles/${this_file} > ${this_file}
        done
    fi
    echo "Done"
    )
done

# REMEMBER to run ./make_dot_product.py in the root folder after successfully running this script!