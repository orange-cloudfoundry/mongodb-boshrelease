
TARGET?=dw
PIPELINES_LIST?=mongodb-broker-test-ci
SETTINGS?=settings.yml
delete-team:
	fly -t $(TARGET) destroy-team --team-name mongo --non-interactive
set-team:
	fly -t $(TARGET) login -n main ;	
	fly -t $(TARGET) set-team --team-name mongo --non-interactive --local-user jeremy
login:
	fly -t $(TARGET) login -n mongo -u jeremy -p jeremy

pipeline:
	for PIPELINE in $(PIPELINES_LIST) ; do \
		fly -t $(TARGET) set-pipeline -p $$PIPELINE --config $$PIPELINE.yml --non-interactive -l $(SETTINGS) ; \
	done	

unpause:
	for PIPELINE in $(PIPELINES_LIST) ; do \
		fly -t $(TARGET) unpause-pipeline -p $$PIPELINE ; \
	done	

trigger:
	fly -t $(TARGET) trigger-job -j mongodb-compilation/check-versions

delete:
	for PIPELINE in $(PIPELINES_LIST) ; do \
		fly -t $(TARGET) dp -p $$PIPELINE --non-interactive ; \
	done

check:
	fly -t $(TARGET) check-resource --resource $(PIPELINE)/check-versions
