# Walkthrough

This walkthrough is based off of LocalStack's own [Quick Start](https://docs.localstack.cloud/getting-started/quickstart/), its purpose is to demonstrate the capabilities of LocalStack. It is not important to understand everything that we will do, this is only to show-off a little of what is possible.

# Setup and Prerequisites

## Install Python

Follow this [link](https://kinsta.com/knowledgebase/install-python/#mac) for instructions.

## Install Homebrew

In order to install several of these packages, [Homebrew](https://brew.sh/) is used. Homebrew is a free software package management system that simplifies the installation of software on macOS and Linux.

To install it, run:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## (Optionally) Install Make

We use Make to manage our development and testing tasks. To install it, run:

```
brew install make
```

## Install/Update Docker

This tool requires Docker version > 4.20. To install, see [here](https://docs.docker.com/desktop/install/mac-install/). To update:

- Open Docker Desktop
- Click on gear in top left
- Choose Software Updates
- Download update
- Update and Restart

## Create a virtual env and Install required packages

Rather than installing several packages directly, you can use a virtual env to install only what is necessary.

```
python -m venv env
source env/bin/activate
pip install -r requirements-dev.txt
```

## Install LocalStack

To effectively mimic AWS functionality, [LocalStack](https://docs.localstack.cloud/getting-started/) and its [aws wrapper](https://github.com/localstack/awscli-local) are used. To install, run:

```
brew install localstack/tap/localstack-cli
```

# Setup Local AWS

### Start LocalStack

Now that we've installed everything, let's get started. Run:

```
localstack start -d
```

This will create a LocalStack container in detached mode. (With detached mode you can still use your same terminal instance for other work, similar to Docker containers.)

# Add Some Resources

Our project will be incredibly simple and a bit redundant because this is only a simple demonstration. We will create 2 lambda functions and an S3 bucket.

- `put-files` function will take an event and load it into an S3 bucket.
- `get-files` function will be invoked by the s3 bucket receiving an item and will simply print that output.

### First, we must create the S3 bucket:

```
awslocal s3 mb s3://new-test-bucket
```

### Second, let's create our first function:

We first need to zip up our function code

```
cd put-files; rm -rf function.zip; zip function.zip lambda_handler.py; cd -
```

Now, we can create our function:

```
awslocal lambda create-function \
    --function-name put-files \
    --runtime python3.12 \
    --role arn:aws:iam::123456789012:role/irrelevant \
    --handler lambda_handler.lambda_handler \
    --zip-file fileb://put-files/function.zip
```

You should be able to inspect the logs of the LocalStack container to see the creation of these two resources. You can also run: `awslocal lambda list-functions` and see your function.

Let's invoke the function and see what happens:

```
awslocal lambda invoke \
    --function-name put-files \
    --payload file://put-files/event.json \
    put-files/response.json
```

If we copy the object to our local using:
```
awslocal s3 cp s3://new-test-bucket/test.txt .
```
We can see that it does indeed contain what we expect.

### Third, create the second function:

Now that we have a function that can put objects into a bucket, let's create a function that can be invoked by the bucket!

```
cd get-files; rm -rf function.zip; zip function.zip lambda_handler.py; cd -
```

```
awslocal lambda create-function \
    --function-name get-files \
    --runtime python3.12 \
    --role arn:aws:iam::123456789012:role/irrelevant \
    --handler lambda_handler.lambda_handler \
    --zip-file fileb://get-files/function.zip
```

In order to be invoked by the S3 bucket, we need some extra AWS things:

```
awslocal lambda put-function-event-invoke-config \
    --function-name get-files \
    --maximum-event-age-in-seconds 3600 \
    --maximum-retry-attempts 0
```
```
awslocal s3api put-bucket-notification-configuration \
    --bucket new-test-bucket \
    --notification-configuration "{\"LambdaFunctionConfigurations\": [{\"LambdaFunctionArn\": \"$(awslocal lambda get-function --function-name get-files | jq -r .Configuration.FunctionArn)\", \"Events\": [\"s3:ObjectCreated:*\"]}]}"
```

### Fourth, combine all three resources:

Now we should be able to invoke our original function again and see that our second function is also invoked.

```
awslocal lambda invoke \
    --function-name put-files \
    --payload file://put-files/event.json \
    put-files/response.json
```
