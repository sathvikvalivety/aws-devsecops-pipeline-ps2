# demos/05-cicd-pipeline.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 5: AWS CODEBUILD & CODEPIPELINE SHIFT-LEFT GATES     " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
& "$PSScriptRoot\..\pipeline\run-ci-pipeline.ps1"
