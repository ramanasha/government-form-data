.PHONY: data clean

# data maintained by hand
SOURCE_DATA=\
	data/task.tsv\
	data/question.tsv

# data derived from GOV.UK and registers
TARGET_DATA=\
	data/page.tsv\
	data/history.tsv\
	data/organisation.tsv\
	data/download.tsv\
	data/attachment.tsv

DATA=\
	$(SOURCE_DATA) \
	$(TARGET_DATA)


# data made for visualisations
INDEXES=\
	vis/orgs.json\
	vis/pages.tsv\
	vis/words.tsv\
	vis/ngrams/2.tsv\
	vis/ngrams/3.tsv\
	vis/ngrams/4.tsv\
	vis/ngrams/8.tsv\
	vis/ngrams/16.tsv\
	vis/ngrams/32.tsv\
	vis/ngrams/256.tsv

all: $(DATA) $(INDEXES)

server: $(INDEXES)
	python3 -m http.server

#
#  upload extracted document text and images to s3
#
s3cmd sync documents  s3://government-form-data/documents

#
#  build target data
#
data/organisation.tsv:	bin/organisations.py
	@mkdir -p cache/page
	python3 bin/organisations.py > $@

data/page.tsv:	bin/pages.py cache/govuk-pages.jsonl data/slug.tsv
	@mkdir -p cache/page
	python3 bin/pages.py < cache/govuk-pages.jsonl > $@

data/attachment.tsv:	bin/attachments.py data/page.tsv
	python3 bin/attachments.py < data/page.tsv > $@

data/history.tsv:	bin/history.py data/page.tsv
	python3 bin/history.py < data/page.tsv > $@

data/download.tsv:	bin/downloads.py data/attachment.tsv
	zcat cache/downloads.gz | python3 bin/downloads.py > $@

#
#  forms pages from GOV.UK search API
#
cache/govuk-pages.jsonl:	bin/govuk-pages.py
	@mkdir -p cache
	bin/govuk-pages.py > $@

#
#  visualisation data
#
vis/pages.tsv:	$(DATA) vis/pages.py
	python3 vis/pages.py > $@

vis/orgs.json:	$(DATA) vis/orgs.py
	python3 vis/orgs.py > $@

vis/ngrams/2.tsv:	bin/ngrams.py
	@mkdir -p vis/ngrams
	bin/ngrams.py 2 > $@

#
#  text analysis
#
vis/words.tsv:	bin/wordcount.py
	cat documents/attachment/*/document.txt | bin/wordcount.py > $@

vis/ngrams/3.tsv:	bin/ngrams.py
	@mkdir -p vis/ngrams
	bin/ngrams.py 3 > $@

vis/ngrams/4.tsv:	bin/ngrams.py
	@mkdir -p vis/ngrams
	bin/ngrams.py 4 > $@

vis/ngrams/8.tsv:	bin/ngrams.py
	@mkdir -p vis/ngrams
	bin/ngrams.py 8 > $@

vis/ngrams/16.tsv:	bin/ngrams.py
	@mkdir -p vis/ngrams
	bin/ngrams.py 16 > $@

vis/ngrams/32.tsv:	bin/ngrams.py
	@mkdir -p vis/ngrams
	bin/ngrams.py 32 > $@

vis/ngrams/256.tsv:	bin/ngrams.py
	@mkdir -p vis/ngrams
	bin/ngrams.py 256 5 > $@


#
# tika
#
init::	cache/tika.jar

cache/tika.jar:
	curl http://mirror.ox.ac.uk/sites/rsync.apache.org/tika/tika-app-1.15.jar > $@

#
#  python
#
init::
	pip3 install -r requirements.txt

flake8:
	flake8

clobber:
	rm -f $(TARGET_DATA) $(INDEXES)

clean:	clobber
	-rm -rf ./cache
	-find . -name '*.pyc' | xargs rm -f
	-find . -name '__pycache__' | xargs rm -rf
