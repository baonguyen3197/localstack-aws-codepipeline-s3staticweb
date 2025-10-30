# ===========================================
# Windows
# ===========================================
## Setup Environment
```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements-dev.txt
```
# ===========================================
# LocalStack
## Create source bucket with versioning
```powershell
awslocal s3api put-bucket-versioning `
    --bucket source-bucket `
    --versioning-configuration Status=Enabled
```

## Create bucket
```powershell
awslocal s3 mb s3://ewebsite
```

## Create artifact store bucket
```bash
awslocal s3 mb s3://artifact-store-bucket
```

## Apply bucket policy to source bucket
```bash
awslocal s3api put-bucket-policy --bucket ewebsite --policy file://config/bucket_policy.json
```

## Create IAM Role and get its ARN
```bash
awslocal iam create-role --role-name role --assume-role-policy-document file://config/iam-role.json | jq .Role.Arn
```

```powershell
(awslocal iam create-role --role-name role --assume-role-policy-document file://config/iam-role.json | ConvertFrom-Json).Role.Arn
```

## Create pipeline & update if exists
```bash
awslocal codepipeline create-pipeline --pipeline file://config/declaration-localstack.json
awslocal codepipeline update-pipeline --pipeline file://config/declaration-localstack.json
```

## Verify the pipeline
```bash
awslocal codepipeline list-pipeline-executions --pipeline-name pipeline
```

## # package site and upload source zip (simulate commit)
```powershell
Compress-Archive -Path .\eWebsite\ -DestinationPath .\eWebsite.zip -Force
awslocal s3 cp .\eWebsite.zip s3://ewebsite/eWebsite.zip
```
# start pipeline
```powershell
$exec = awslocal codepipeline start-pipeline-execution --name pipeline | ConvertFrom-Json
$exec.pipelineExecutionId
```

# wait & inspect
```powershell
awslocal codepipeline list-pipeline-executions --pipeline-name pipeline
awslocal codepipeline get-pipeline-execution --pipeline-name pipeline --pipeline-execution-id $exec.pipelineExecutionId | ConvertFrom-Json | ConvertTo-Json -Depth 20
```

## Deploy website after pipeline Succeeded
```powershell
awslocal s3api put-bucket-website --bucket ewebsite --website-configuration file://config/website-config.json
awslocal s3api put-bucket-policy --bucket ewebsite --policy file://config/ewebsite-policy.json
```

## Verify
```powershell
awslocal s3api get-bucket-website --bucket ewebsite
awslocal s3api get-bucket-policy --bucket ewebsite
```

## Test website URL (Host header)
```
Invoke-WebRequest -Uri "http://localhost:4566/index.html" -Headers @{ Host = "ewebsite.s3-website.localhost.localstack.cloud:4566" } -UseBasicParsing
```