# ==============
# Windows
# ==============
## Setup Environment
```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements-dev.txt
```
# ==============
# LocalStack
## Create bucket
```powershell
awslocal s3 mb s3://ewebsite
```

## Create source bucket with versioning
```powershell
awslocal s3api put-bucket-versioning `
    --bucket ewebsite `
    --versioning-configuration Status=Enabled
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

awslocal iam create-role --role-name codebuild-service-role --assume-role-policy-document file://LocalStack/config/codebuild-assume-role.json

awslocal iam put-role-policy --role-name codebuild-service-role --policy-name LocalCodeBuildDevPolicy --policy-document file://config/codebuild-role-policy.json
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

## Package site and upload source zip (simulate commit)
```powershell
Compress-Archive -Path .\eWebsite\ -DestinationPath .\eWebsite.zip -Force
awslocal s3 cp .\eWebsite.zip s3://ewebsite/eWebsite.zip
```
# start pipeline
```powershell
awslocal codepipeline start-pipeline-execution --name pipeline
```

## wait & inspect
```powershell
awslocal codepipeline list-pipeline-executions --pipeline-name pipeline
awslocal codepipeline get-pipeline-execution --pipeline-name pipeline --pipeline-execution-id <execution-id>
```

## Debugging: Get CodeBuild logs
```powershell
awslocal codepipeline list-action-executions --pipeline-name pipeline --max-items 50
```

## Synchronize website files to verify
```powershell
awslocal s3 sync .\eWebsite\ s3://ewebsite
awslocal s3 website s3://ewebsite/ --index-document index.html 
awslocal s3 ls s3://ewebsite/
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