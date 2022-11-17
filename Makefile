year_min = 2012
year_max = 2021

python_launch_cmd=python
python_launch_cmd=winpty python

date_formatted=$(shell date +%Y%m%d-%H%M%S)

# limit_args can be used in any step that reads a data file (ie explode and link) 
# It will reduce the number of records processed, to ensure a quick sanity check of the process
#limit_args= --limit=1000
limit_args=

# filter_args can be used in the link step to filter processing to a set of known records for debugging purposes.
filter_args=--filter_ids=77103635-1
filter_args=

archived_analyses: downloads/ipni-oa-data.zip 

data/ipniname-oastatus-wcvp-report-$*.csv: downloads/ipni-oa-data.zip
	mkdir -p data
	unzip -o $^ $@

###############################################################################
# Map WCVP data: ration between open and closed access
data/oaratio-wcvp-map-level-%.png: plotoageo.py data/ipniname-oastatus-wcvp-report-$*.csv
	$(python_launch_cmd) $^ $(limit_args) --tdwg_wgsrpd_level=$* --plot-maps $@
# Shorthand:
oaratio_level_1: data/oaratio-wcvp-map-level-1.png
oaratio_level_2: data/oaratio-wcvp-map-level-2.png
oaratio_level_3: data/oaratio-wcvp-map-level-3.png
###############################################################################


###############################################################################
# Map WCVP data: proportion of unfindable publications
data/findability-wcvp-map-level-%.png: plotoageo.py data/ipniname-oastatus-wcvp-report-$*.csv
	$(python_launch_cmd) $^ $(limit_args) --tdwg_wgsrpd_level=$* --plot-maps --unfindable=True  $@
# Shorthand:
findability_level_1: data/findability-wcvp-map-level-1.png
findability_level_2: data/findability-wcvp-map-level-2.png
findability_level_3: data/findability-wcvp-map-level-3.png
###############################################################################

oatrends_charts_year:=data/ipni-oatrend-year.png
oastatus_charts_year:= data/ipni-oastatustrendpc.png
oatrends_charts_publ:=data/ipni-oatrend-publ.png

findability_all:= findability_level_1 findability_level_2 findability_level_2
oaratio_all:= oaratio_level_1 oaratio_level_2 oaratio_level_3

all: $(findability_all) $(oaratio_all)

data_archive_zip:=$(shell basename $(CURDIR))-data.zip

archive: $(findability_all) $(oaratio_all)
	mkdir -p archive	
	echo "Archived on $(date_formatted)" >> data/archive-info.txt
	zip archive/$(data_archive_zip) data/archive-info.txt data/* -r
	
clean:
	rm -f data/*

cleancharts:
	rm -f data/*.png

sterilise:
	rm -f data/*
	rm -f downloads/*
