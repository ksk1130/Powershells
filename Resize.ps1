param(
[string]$filename,      # 処理対象ファイル名
[string]$longside=1280, # 長辺ピクセル数を指定しなかったら1280px
[string]$overwrite="n"  # デフォルトは別名で保存
)

# エラーがあった時点で処理終了
$ErrorActionPreference = "stop"
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.IO")

# 保存用ファイルパス作成処理
# 引数1 ：元画像ファイルのフルパス
# 引数2 ：長辺ピクセル数
# 戻り値：<元ファイルのパス>「resized+長辺ピクセル数」<元ファイルの拡張子>
function script:GetNewFileName($originalFileName,$longside){
  # 元画像の格納ディレクトリを取得
  $private:path = [System.IO.Path]::GetDirectoryName($originalFileName)

  # 元画像のファイル名(拡張子除く)を取得
  $private:originalName = [System.IO.Path]::GetFileNameWithoutExtension($originalFileName)
  
  # 元画像の拡張子を取得(ピリオドは含まれる)
  $private:extensionName = [System.IO.Path]::GetExtension($originalFileName)
  
  # 回転後のファイル名(拡張子あり)を作成
  $private:newName = $originalName + "_resized" + $longside + $extensionName

  # 新ファイルパスを作成してリターン
  return [System.IO.Path]::Combine($path,$newName)
}

# リサイズ後サイズ計算処理(長辺ピクセル数をもとに、変更後ピクセル数を算出する)
# 引数1 ：元画像ファイルBitmap
# 引数2 ：長辺ピクセル数
# 戻り値：短辺ピクセル数
function script:CalcSize($sourceImage,$longside){
    $private:height = $sourceImage.height
    $private:width = $sourceImage.width
    $private:shortside = 0

    # 小数点1位は四捨五入
    # 横 >= 縦
    if($width -ge $height){
      $shortside = $height * ($longside / $width)
      $shortside = [math]::Truncate($shortside+.5)
    # 横 < 縦
    }else{
      $shortside = $width * ($longside / $height)
      $shortside = [math]::Truncate($shortside+.5)
    }

    return $shortside
}

# 画像回転処理
# 引数1 ：Bitmapオブジェクト
# 戻り値：なし
function RotateImage($sourceImage){
    $private:flip = -1

    # Exif情報を取得
    $private:properties = $sourceImage.PropertyItems
    foreach($property in $properties){
      # 回転は0x112 = 274
      if($property.Id -eq 274){
        # 値は配列(回転方向は0番目)
        $flip = $property.Value[0]
        break
      }
    }
    
    # 取得した値をもとに画像を回転する
    # 回転(時計回りで90,180,270と回転)
    if($flip -eq 6){ # 右90度
      $sourceImage.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone)
    }elseif($flip -eq 3){ # 180度
      $sourceImage.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone)
    }elseif($flip -eq 8){ # 左90度
      $sourceImage.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone)
    }
}

# メイン処理
# 引数1 ：長辺ピクセル数
# 引数2 ：元画像ファイルのフルパス
# 引数3 ：上書き(y) or コピー保存(n)
# 戻り値：なし
function script:Main($longside,$originalFileName,$overwrite){
  $private:sourceImage = $null
  $private:resizedImage = $null

  try{
      # 元画像取得(Bitmap)
      $sourceImage = New-Object System.Drawing.Bitmap($originalFileName)

      # 回転操作
      RotateImage $sourceImage

      # 短辺ピクセルを計算
      $private:shortside = CalcSize $sourceImage $longside

      $private:newWidth
      $private:newHeight

      # 修正後ピクセルを設定
      # 横 >= 縦
      if($sourceImage.Width -ge $sourceImage.Height){
        $newWidth = $longside
        $newHeight = $shortside
      # 横 < 縦
      }else{
        $newWidth = $shortside
        $newHeight = $longside
      }

      # 新画像Bitmap作成
      $private:newBitmap = New-Object System.Drawing.Bitmap($sourceImage,$newWidth,$newHeight)
      $private:newGraphics = [System.Drawing.Graphics]::FromImage($newBitmap)

      # 補間方式設定(デフォルト)
      $newGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::Default

      # リサイズ
      $newGraphics.DrawImage($sourceImage, 0, 0, $newWidth, $newHeight)
      
      # 上書き時の書き込みロック防止のため元Bitmapを閉じる
      $sourceImage.Dispose()
      
      if($overwrite -eq "n"){
        # 新ファイルネーム
        $private:newFileName = GetNewFileName $originalFileName $longside

        # 保存
        $newBitmap.Save($newFileName, [System.Drawing.Imaging.ImageFormat]::Jpeg)
      
        echo "保存完了しました:$newFileName"
      }else{
      
        # 保存
        $newBitmap.Save($originalFileName, [System.Drawing.Imaging.ImageFormat]::Jpeg)

        echo "保存完了しました:$originalFileName"
      }

  }catch{
    echo "例外が発生しました:$error"
  }finally{
    try{
      # 後始末
      if($null -ne $resizedImage){
        $resizedImage.Dispose()
      }
      if($null -ne $sourceImage){
        $sourceImage.Dispose()
      }
    }catch{
      echo "画像クローズ時の例外:$error"
    }
  }
}

# リサイズ処理の実行
Main $longside $filename $overwrite
