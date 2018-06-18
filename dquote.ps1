param(
[string]$fileName    # 処理対象ファイル名(フルパス)
)

# エラーがあった時点で処理終了
$ErrorActionPreference = "stop"

$parentDir = Split-Path -Parent $fileName
$fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($fileName);
$outputFileName = Join-Path $parentDir $fileNameWithoutExtension"_dquote.csv"

Import-Csv -Encoding Default $fileName |`
Export-Csv -Encoding Default -NoTypeInformation $outputFileName
