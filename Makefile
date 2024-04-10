test-setup:
	make s3-bucket
	make put-zip-file
	make get-zip-file
	make put-function
	make get-function
	make get-files-config
	make invoke-put-function

s3-bucket:
	awslocal s3 mb s3://new-test-bucket

put-function:
	awslocal lambda create-function \
		--function-name put-files \
		--runtime python3.12 \
		--role arn:aws:iam::123456789012:role/irrelevant \
		--handler lambda_handler.lambda_handler \
		--zip-file fileb://put-files/function.zip && \
	awslocal lambda wait function-active-v2 --function-name put-files


get-function:
	awslocal lambda create-function \
		--function-name get-files \
		--runtime python3.12 \
		--role arn:aws:iam::123456789012:role/irrelevant \
		--handler lambda_handler.lambda_handler \
		--zip-file fileb://get-files/function.zip && \
	awslocal lambda wait function-active-v2 --function-name get-files

put-zip-file:
	cd put-files && \
	rm -rf function.zip && \
	zip function.zip lambda_handler.py && \
	cd -

get-zip-file:
	cd get-files && \
	rm -rf function.zip && \
	zip function.zip lambda_handler.py && \
	cd -

get-files-config:
	awslocal lambda put-function-event-invoke-config \
		--function-name get-files \
		--maximum-event-age-in-seconds 3600 \
		--maximum-retry-attempts 0 && \
	awslocal s3api put-bucket-notification-configuration \
    --bucket new-test-bucket \
    --notification-configuration "{\"LambdaFunctionConfigurations\": [{\"LambdaFunctionArn\": \"$$(awslocal lambda get-function --function-name get-files | jq -r .Configuration.FunctionArn)\", \"Events\": [\"s3:ObjectCreated:*\"]}]}"

invoke-put-function:
	awslocal lambda invoke \
		--function-name put-files \
		--payload file://put-files/event.json \
		put-files/response.json
