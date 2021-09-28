# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$workfolder = "/wrk/"

$hostname = "http://restructure:8080"

$responseUnpakFiles = Invoke-WebRequest -Uri $hostname/unpack -Method GET -UseBasicParsing 

$splitResult = $responseUnpakFiles.Content.Split([Environment]::NewLine)

$archive = $splitResult[0].Replace("/", "")

$proccesedFiles = New-Object "System.Collections.Generic.HashSet[string]"
$foldersToDelete = New-Object "System.Collections.Generic.HashSet[string]"

foreach($line in $splitResult.Where({$_.EndsWith(".metadata")}))
{
    $currentItem = $workfolder + $line
    $metadata = Get-Item $currentItem
    
    if($metadata.Directory.GetFiles("*.metadata").Count -eq 2){
    
        if($metadata.Name.Replace(".metadata", "") -eq $metadata.Directory.Name){
            #record
            $originalBestandLocation = ""
            #start copy to wrk folder
            $currentRecordFiles = $metadata.Directory.GetFiles("*.metadata")
            
            foreach($file in $currentRecordFiles){
                if(([System.IO.FileInfo]$file).Name.Replace(".metadata", "") -eq $metadata.Directory.Name){
                    $fileRecord = $workfolder + "record.xml"
                    $copy = ([System.IO.FileInfo]$file).CopyTo($fileRecord, 1)
                    ([System.IO.FileInfo]$file).Delete()
                }
                else{
                    $fileTarget = $workfolder + "target.xml"
                    $copy = ([System.IO.FileInfo]$file).CopyTo($fileTarget, 1)
                    $originalBestandLocation = $file.FullName #([System.IO.FileInfo]$file).Directory.Parent.FullName + "\" + ([System.IO.FileInfo]$file).Name #set again, to be sure   
                    $add = $proccesedFiles.Add($file.FullName)
                    $add = $foldersToDelete.Add($file.Directory.FullName);
                }
            }

            #start transforming by invoke webrequest
            $responseRename = Invoke-WebRequest -Uri $hostname/restructure -Method GET -UseBasicParsing 

            Write-Host "Hierna toe bijwerken : "$originalBestandLocation
            $updatedXml = $responseRename.Content
  
            $xml = New-Object "System.Xml.XmlDocument"
            $xml.LoadXml($updatedXml)
            $xml.Save($originalBestandLocation)
        }   
    }
}

#Move the files 1 folder up
foreach($item in $proccesedFiles){
    $binFile = $item.Replace(".metadata", "");
    $metadata = Get-Item $item
    $file = Get-Item $binFile

    $mX = $metadata.Directory.Parent.FullName
    $fX = $file.Directory.Parent.FullName
    $mY = $metadata
    $fY = $file

    Move-Item -Path $mY -Destination $mX -Force
    Move-Item -Path $fY -Destination $fX -Force

}

#Remove record folders
foreach($item in $foldersToDelete){
    Remove-Item -Path $item -Force
}

$script = "tar -cvf '$archive.tar' '$archive' && rm -R '$archive'"

$shellScript = $workfolder + "pack.sh"
$script | Out-File -Force -FilePath $shellScript -Encoding utf8 -NoNewline

$responseRename = Invoke-WebRequest -Uri $hostname/pack -Method GET -UseBasicParsing