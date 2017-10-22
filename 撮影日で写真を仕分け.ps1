param(
[string]$filename    # 処理対象ファイル名(フルパス)
,[string]$targetDir  # 移動先親ディレクトリパス
,[switch]$test       # このパラメータがついていたら、ディレクトリ作成、コピーはしない
)

# エラーがあった時点で処理終了
$ErrorActionPreference = "stop"
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

# 撮影日取得処理
# 引数1 ：Bitmapオブジェクト
# 戻り値：なし
function GetSatsueiDate($sourceImage){
    $propDate=""
    
    # Exif情報を取得
    $private:properties = $sourceImage.PropertyItems
    foreach($property in $properties){
      if($property.Id -eq 36867){ #0x9003 PropertyTagExifDTOrig
        $propDate = [System.Text.Encoding]::ASCII.GetString($property.Value)
        break
      }
    }

    return $propDate
}

function script:makeFolderName($originalSatsueiDate){
    $folderName = ""

    if($originalSatsueiDate -eq $null -or $originalSatsueiDate.length -lt 1){
        return $folderName
    }

    # yyyy.mm.ddを抽出しyyyy-mm-ddに変換
    if($originalSatsueiDate -match "(?<SatsueiDate>\d\d\d\d.\d\d.\d\d?)"){
        $folderName = $Matches["SatsueiDate"].replace(":","-")
        return $folderName
    }else{
        return $folderName
    }
}


# メイン処理
# 引数1 ：元画像ファイルのフルパス
# 戻り値：なし
function script:Main(){
  $private:sourceImage = $null

  try{
      # 元画像取得(Bitmap)
      $sourceImage = New-Object System.Drawing.Bitmap($fileName)

      # 撮影日取得
      $satsueiDate = GetSatsueiDate $sourceImage

      # 元Bitmapを閉じる
      $sourceImage.Dispose()

      # 撮影日付をyyyy-mm-dd形式に変換し、フォルダ名を作成
      $folderName = makeFolderName $satsueiDate

      $joinedPath = Join-Path $targetDir $folderName

      if (Test-Path $joinedPath){
        echo "存在します:$joinedPath"
      }else{
        if($test -eq $false){
            echo "作成します:$joinedPath"
            mkdir $joinedPath >$null 2>&1
        }else{
            echo "作成します(テスト):$joinedPath"
        }
      }

      if($test -eq $false){
          cp $fileName $joinedPath
      }
  }catch{
    echo "例外が発生しました:$error"
  }finally{
    try{
      if($null -ne $sourceImage){
        $sourceImage.Dispose()
      }
    }catch{
      echo "画像クローズ時の例外:$error"
    }
  }
}

# 撮影日取得処理の実行
Main
