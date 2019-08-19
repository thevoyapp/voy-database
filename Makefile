REGION := us-east-2
ACCOUNT := 076279718063

do:

manual-update:
	bash manual-update.sh

database-update:
	bash database-update.sh

run:
	aws lambda invoke --function-name manual-database-task response.txt
	@cat response.txt
	@echo ""
	# aws lambda invoke --function-name manual-database-task \
	# 	--invocation-type RequestResponse \
	# 	--log-type Tail \
	# 	/tmp/out | jq ".LogResult" | base64 --decode

deploy:
	aws cloudformation deploy \
		--template-file database.yml \
		--stack-name databasev2 \
		--s3-bucket "cf-$(REGION)-$(ACCOUNT)-bucket" \
		--s3-prefix database/ \
		--profile default \
		--region "$(REGION)"
