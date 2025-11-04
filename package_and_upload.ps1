# Package eWebsite contents (files at root of archive) and upload to LocalStack S3
# Run from D:\HSU\AWS_LocalStack\LocalStack

param(
  [string]$SourceDir = "./eWebsite",
  [string]$Bucket = "ewebsite",
  [bool]$TriggerPipeline = $true
)

Write-Host "Uploading website files from $SourceDir to s3://$Bucket/eWebsite/ (recursive sync)"

if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory '$SourceDir' does not exist. Run this script from the repo root where eWebsite/ lives."
    exit 1
}

# Use awslocal s3 sync to recursively upload files to the eWebsite/ prefix
Write-Host "Running: awslocal s3 sync $SourceDir s3://$Bucket/eWebsite/ --delete"
$syncOut = awslocal s3 sync $SourceDir "s3://$Bucket/eWebsite/" --delete 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "awslocal s3 sync failed: $syncOut"
    exit $LASTEXITCODE
}

Write-Host "Upload complete"

# Optionally trigger the CodePipeline so the Build stage runs immediately
if ($TriggerPipeline) {
  Write-Host "Starting pipeline 'pipeline' in LocalStack..."
  $startOut = awslocal codepipeline start-pipeline-execution --name pipeline 2>&1
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Failed to start pipeline: $startOut"
  } else {
    Write-Host "Pipeline started: $startOut"
  }
}