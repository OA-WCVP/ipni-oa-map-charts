year_min = 2012
year_max = 2021

level1_geojson_url = 'https://github.com/tdwg/wgsrpd/blob/52da7828aba9d461dd133c27b3bd7a4407161f54/geojson/level1.geojson'
level2_geojson_url = 'https://github.com/tdwg/wgsrpd/blob/52da7828aba9d461dd133c27b3bd7a4407161f54/geojson/level2.geojson'
level3_geojson_url = 'https://github.com/tdwg/wgsrpd/blob/52da7828aba9d461dd133c27b3bd7a4407161f54/geojson/level3.geojson'

python_launch_cmd=python
#python_launch_cmd=winpty python

date_formatted=$(shell date +%Y%m%d-%H%M%S)

# limit_args can be used in any step that reads a data file (ie explode and link) 
# It will reduce the number of records processed, to ensure a quick sanity check of the process
#limit_args= --limit=1000
limit_args=

# filter_args can be used in the link step to filter processing to a set of known records for debugging purposes.
filter_args=--filter_ids=77103635-1
filter_args=

archived_analyses: downloads/ipni-oa-data.zip 

data/ipniname-oastatus-wcvp-report-%.csv: downloads/ipni-oa-data.zip
	mkdir -p data
	unzip -o $^ $@
	
downloads/level1.geojson:
	mkdir -p downloads
	wget -O $@ $(level1_geojson_url)
	
downloads/level2.geojson:
	mkdir -p downloads
	wget -O $@ $(level2_geojson_url)
	
downloads/level3.geojson:
	mkdir -p downloads
	wget -O $@ $(level3_geojson_url)

###############################################################################
# Map WCVP data: ration between open and closed access
data/oaratio-wcvp-map-level-%.png: plotoageo.py data/ipniname-oastatus-wcvp-report-%.csv downloads/level%.geojson
	$(python_launch_cmd) $^ $(limit_args) --tdwg_wgsrpd_level=$* --plot-maps $@
# Shorthand:
oaratio_level_1: data/oaratio-wcvp-map-level-1.png
oaratio_level_2: data/oaratio-wcvp-map-level-2.png
oaratio_level_3: data/oaratio-wcvp-map-level-3.png
oaratio_all: data/oaratio-wcvp-map-level-1.png data/oaratio-wcvp-map-level-2.png data/oaratio-wcvp-map-level-3.png
###############################################################################


###############################################################################
# Map WCVP data: proportion of unfindable publications
data/findability-wcvp-map-level-%.png: plotoageo.py data/ipniname-oastatus-wcvp-report-%.csv downloads/level%.geojson
	$(python_launch_cmd) $^ $(limit_args) --tdwg_wgsrpd_level=$* --plot-maps data/oaratio-wcvp-map-level-$*.png data/findability-wcvp-map-level-$*.png
# Shorthand:
findability_level_1: data/findability-wcvp-map-level-1.png
findability_level_2: data/findability-wcvp-map-level-2.png
findability_level_3: data/findability-wcvp-map-level-3.png
findability_all: data/findability-wcvp-map-level-1.png data/findability-wcvp-map-level-2.png data/findability-wcvp-map-level-3.png

###############################################################################

oatrends_charts_year:=data/ipni-oatrend-year.png
oastatus_charts_year:= data/ipni-oastatustrendpc.png
oatrends_charts_publ:=data/ipni-oatrend-publ.png

findability_charts:= data/findability-wcvp-map-level-1.png data/findability-wcvp-map-level-2.png data/findability-wcvp-map-level-3.png
oa_charts: data/oaratio-wcvp-map-level-1.png data/oaratio-wcvp-map-level-2.png data/oaratio-wcvp-map-level-3.png

all: $(findability_charts) $(oaratio_charts)

data_archive_zip:=$(shell basename $(CURDIR))-data.zip

archive: $(findability_charts) $(oaratio_charts)
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
