#Install-Module -Name ImportExcel -Force

# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$hostname = "http://splitten:8080"
$responseUnpakFiles = Invoke-WebRequest -Uri $hostname/unpack -Method GET -UseBasicParsing 

[string[]]$splitResult = $responseUnpakFiles.Content.Split([Environment]::NewLine)

$wrkPath = '/wrk/'

$archiveName = $splitResult[0].Replace("/", "")

# Define the root path (the one that contains Folder1, Folder2 etc)
$rootPath = $wrkPath + $archiveName

# Define the target path (where we'll create the new structure)
$targetPath = '/wrk/'

# Collect the file information, order by descending size (largest first)
$files = Get-ChildItem $rootPath -File -Recurse | Where { !$_.Extension.Equals(".metadata") } | Sort-Object Length -Descending 

# Define max bin size as the size of the largest file 
$max = (50*1024*1024) # put size here instead (files larger than X bytes will end up in a lone bin)

# Create a list of lists to group our files by
$bins = [System.Collections.Generic.List[System.Collections.Generic.List[System.IO.FileInfo]]]::new()

:FileIteration
foreach($file in $files){
    # Walk through existing bins to find one that has room
    for($i = 0; $i -lt $bins.Count; $i++){
        if(($bins[$i]|Measure Length -Sum).Sum -le ($max - $file.Length)){
            # Add file to bin, continue the outer loop
            $bins[$i].Add($file)
            continue FileIteration
        }
    }
    # No existing bins with capacity found, create a new one and add the file
    $newBin = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    $newBin.Add($file)
    $bins.Add($newBin)
}

#split the documents first
$binNumber = 0;
# Now go through the bins and move the files to the new directory
foreach($bin in $bins){
    # Create a new randomly named folder for the files in the bin
    $directory = New-Item $targetPath -Name $($binNumber.ToString("0000")) -ItemType Directory -Force
    foreach($file in $bin){
        
        $finalDestination = $targetPath + $($binNumber.ToString("0000")) + "/" + $file.FullName.Replace($wrkPath, "")
        #Write-Host $finalDestination
        #touch it, to create parent folders
        $n = New-Item -ItemType File -Path $finalDestination -Force
        #move and overwrite
        $m1 = Move-Item $file.FullName -Destination $finalDestination -Force
        #while here, why not move the metadata too
        $metadata = $file.FullName + ".metadata"
        $m2 = Move-Item $metadata -Destination $($finalDestination + ".metadata") -Force
    }
    $binNumber++
}

#now the metadata files
$files = Get-ChildItem $rootPath -File -Recurse | Where { $_.Extension.Equals(".metadata") } | Sort-Object Length -Descending 
foreach($file in $files){
    #use copy, cause each bin may contain the parent folder(s)
    For($i=0;$i -lt $binNumber;$i++){

        $finalDestinationFileName = $file.Name
        $finalDestinationFolder = $targetPath + $($i.ToString("0000")) + "/" + $file.Directory.Fullname.Replace($wrkPath, "")
        $finalDestination = $targetPath + $($i.ToString("0000")) + "/" + $file.Fullname.Replace($wrkPath, "")
        
        Write-Host (Test-Path $finalDestinationFolder) " - " $finalDestinationFolder

        if((Test-Path $finalDestinationFolder) -eq $true){           
            #Write-Host "From : " $file " To : " $finalDestination
            $c = Copy-Item $file.FullName -Destination $finalDestination -Force
        }
    }
}

#remove the target
Remove-Item $rootPath -Recurse -Force

For($i=0;$i -lt $binNumber;$i++){

    $archive = $targetPath + $($i.ToString("0000")) + "/" #/wrk/0000/

    $tarArchiveName = $archiveName + "." + $($i.ToString("0000")) + ".tar" #Provincie Noord-Holland.0000.tar


    $collectionPartFolder = $($i.ToString("0000"))
    $script = "#!/bin/sh
pwd
cd $archive
tar -cvf '$tarArchiveName' '$archiveName' && rm -R '$archiveName'"

    $shellScript = $wrkPath + "pack.sh"
    $script | Out-File -Force -FilePath $shellScript -Encoding utf8 -NoNewline

    $responseRename = Invoke-WebRequest -Uri $hostname/chmod -Method GET -UseBasicParsing
    $responseRename = Invoke-WebRequest -Uri $hostname/dos2unix -Method GET -UseBasicParsing
    $responseRename = Invoke-WebRequest -Uri $hostname/pack -Method GET -UseBasicParsing
    
    Move-Item $($archive + "*.tar") -Destination $targetPath
    Remove-Item $archive -Recurse -Force
}