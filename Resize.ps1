param(
[string]$filename,      # �����Ώۃt�@�C����
[string]$longside=1280, # ���Ӄs�N�Z�������w�肵�Ȃ�������1280px
[string]$overwrite="n"  # �f�t�H���g�͕ʖ��ŕۑ�
)

# �G���[�����������_�ŏ����I��
$ErrorActionPreference = "stop"
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.IO")

# �ۑ��p�t�@�C���p�X�쐬����
# ����1 �F���摜�t�@�C���̃t���p�X
# ����2 �F���Ӄs�N�Z����
# �߂�l�F<���t�@�C���̃p�X>�uresized+���Ӄs�N�Z�����v<���t�@�C���̊g���q>
function script:GetNewFileName($originalFileName,$longside){
  # ���摜�̊i�[�f�B���N�g�����擾
  $private:path = [System.IO.Path]::GetDirectoryName($originalFileName)

  # ���摜�̃t�@�C����(�g���q����)���擾
  $private:originalName = [System.IO.Path]::GetFileNameWithoutExtension($originalFileName)
  
  # ���摜�̊g���q���擾(�s���I�h�͊܂܂��)
  $private:extensionName = [System.IO.Path]::GetExtension($originalFileName)
  
  # ��]��̃t�@�C����(�g���q����)���쐬
  $private:newName = $originalName + "_resized" + $longside + $extensionName

  # �V�t�@�C���p�X���쐬���ă��^�[��
  return [System.IO.Path]::Combine($path,$newName)
}

# ���T�C�Y��T�C�Y�v�Z����(���Ӄs�N�Z���������ƂɁA�ύX��s�N�Z�������Z�o����)
# ����1 �F���摜�t�@�C��Bitmap
# ����2 �F���Ӄs�N�Z����
# �߂�l�F�Z�Ӄs�N�Z����
function script:CalcSize($sourceImage,$longside){
    $private:height = $sourceImage.height
    $private:width = $sourceImage.width
    $private:shortside = 0

    # �����_1�ʂ͎l�̌ܓ�
    # �� >= �c
    if($width -ge $height){
      $shortside = $height * ($longside / $width)
      $shortside = [math]::Truncate($shortside+.5)
    # �� < �c
    }else{
      $shortside = $width * ($longside / $height)
      $shortside = [math]::Truncate($shortside+.5)
    }

    return $shortside
}

# �摜��]����
# ����1 �FBitmap�I�u�W�F�N�g
# �߂�l�F�Ȃ�
function RotateImage($sourceImage){
    $private:flip = -1

    # Exif�����擾
    $private:properties = $sourceImage.PropertyItems
    foreach($property in $properties){
      # ��]��0x112 = 274
      if($property.Id -eq 274){
        # �l�͔z��(��]������0�Ԗ�)
        $flip = $property.Value[0]
        break
      }
    }
    
    # �擾�����l�����Ƃɉ摜����]����
    # ��](���v����90,180,270�Ɖ�])
    if($flip -eq 6){ # �E90�x
      $sourceImage.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone)
    }elseif($flip -eq 3){ # 180�x
      $sourceImage.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone)
    }elseif($flip -eq 8){ # ��90�x
      $sourceImage.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone)
    }
}

# ���C������
# ����1 �F���Ӄs�N�Z����
# ����2 �F���摜�t�@�C���̃t���p�X
# ����3 �F�㏑��(y) or �R�s�[�ۑ�(n)
# �߂�l�F�Ȃ�
function script:Main($longside,$originalFileName,$overwrite){
  $private:sourceImage = $null
  $private:resizedImage = $null

  try{
      # ���摜�擾(Bitmap)
      $sourceImage = New-Object System.Drawing.Bitmap($originalFileName)

      # ��]����
      RotateImage $sourceImage

      # �Z�Ӄs�N�Z�����v�Z
      $private:shortside = CalcSize $sourceImage $longside

      $private:newWidth
      $private:newHeight

      # �C����s�N�Z����ݒ�
      # �� >= �c
      if($sourceImage.Width -ge $sourceImage.Height){
        $newWidth = $longside
        $newHeight = $shortside
      # �� < �c
      }else{
        $newWidth = $shortside
        $newHeight = $longside
      }

      # �V�摜Bitmap�쐬
      $private:newBitmap = New-Object System.Drawing.Bitmap($sourceImage,$newWidth,$newHeight)
      $private:newGraphics = [System.Drawing.Graphics]::FromImage($newBitmap)

      # ��ԕ����ݒ�(�f�t�H���g)
      $newGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::Default

      # ���T�C�Y
      $newGraphics.DrawImage($sourceImage, 0, 0, $newWidth, $newHeight)
      
      # �㏑�����̏������݃��b�N�h�~�̂��ߌ�Bitmap�����
      $sourceImage.Dispose()
      
      if($overwrite -eq "n"){
        # �V�t�@�C���l�[��
        $private:newFileName = GetNewFileName $originalFileName $longside

        # �ۑ�
        $newBitmap.Save($newFileName, [System.Drawing.Imaging.ImageFormat]::Jpeg)
      
        echo "�ۑ��������܂���:$newFileName"
      }else{
      
        # �ۑ�
        $newBitmap.Save($originalFileName, [System.Drawing.Imaging.ImageFormat]::Jpeg)

        echo "�ۑ��������܂���:$originalFileName"
      }

  }catch{
    echo "��O���������܂���:$error"
  }finally{
    try{
      # ��n��
      if($null -ne $resizedImage){
        $resizedImage.Dispose()
      }
      if($null -ne $sourceImage){
        $sourceImage.Dispose()
      }
    }catch{
      echo "�摜�N���[�Y���̗�O:$error"
    }
  }
}

# ���T�C�Y�����̎��s
Main $longside $filename $overwrite
