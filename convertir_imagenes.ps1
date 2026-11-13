Add-Type -AssemblyName System.Drawing

$imgDir = "C:\ProyectosJhoel\Arqui\1erParcialArqui2026\imagenes"
$outputOriginalDir = Join-Path $imgDir "base64_original"
$outputExcelDir = Join-Path $imgDir "base64_excel"

if (-not (Test-Path $outputOriginalDir)) {
    New-Item -ItemType Directory -Path $outputOriginalDir | Out-Null
}
if (-not (Test-Path $outputExcelDir)) {
    New-Item -ItemType Directory -Path $outputExcelDir | Out-Null
}

$files = Get-ChildItem -Path $imgDir -Filter "*.png" | Sort-Object Name

$results = @()
$jsonDict = @{}
$jsonExcelDict = @{}

foreach ($file in $files) {
    # 1. Original Base64
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $b64Original = [System.Convert]::ToBase64String($bytes)
    
    $origTxtPath = Join-Path $outputOriginalDir ($file.BaseName + ".txt")
    [System.IO.File]::WriteAllText($origTxtPath, $b64Original)
    $jsonDict[$file.BaseName] = $b64Original

    # 2. Optimized for Excel (<= 32,767 characters limit per cell in Excel)
    # Resize to max 220x220 maintaining aspect ratio and compress as JPEG
    $origImg = [System.Drawing.Image]::FromFile($file.FullName)
    
    $maxDim = 220
    $width = $origImg.Width
    $height = $origImg.Height
    
    if ($width -gt $height) {
        $newWidth = $maxDim
        $newHeight = [int]($height * ($maxDim / $width))
    } else {
        $newHeight = $maxDim
        $newWidth = [int]($width * ($maxDim / $height))
    }

    $bmp = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::White)
    $g.DrawImage($origImg, 0, 0, $newWidth, $newHeight)
    $g.Dispose()
    $origImg.Dispose()

    # Save to memory stream as JPEG quality 75
    $ms = New-Object System.IO.MemoryStream
    $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.FormatDescription -eq "JPEG" }
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]75)
    
    $bmp.Save($ms, $jpegCodec, $encoderParams)
    $bmp.Dispose()
    
    $excelBytes = $ms.ToArray()
    $ms.Dispose()

    $b64Excel = [System.Convert]::ToBase64String($excelBytes)
    $excelTxtPath = Join-Path $outputExcelDir ($file.BaseName + ".txt")
    [System.IO.File]::WriteAllText($excelTxtPath, $b64Excel)
    $jsonExcelDict[$file.BaseName] = $b64Excel

    $results += [PSCustomObject]@{
        Name = $file.Name
        OrigKB = [math]::Round($bytes.Length / 1KB, 1)
        OrigChars = $b64Original.Length
        ExcelKB = [math]::Round($excelBytes.Length / 1KB, 1)
        ExcelChars = $b64Excel.Length
        FitsExcel = ($b64Excel.Length -le 32767)
    }
}

# Save JSON summaries
$jsonAllOriginal = Join-Path $imgDir "todas_base64_original.json"
$jsonDict | ConvertTo-Json | Set-Content -Path $jsonAllOriginal

$jsonAllExcel = Join-Path $imgDir "todas_base64_para_excel.json"
$jsonExcelDict | ConvertTo-Json | Set-Content -Path $jsonAllExcel

# Print table
$results | Format-Table -AutoSize
