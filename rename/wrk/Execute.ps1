# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$workfolder = "/wrk/"

$hostname = "http://rename:8080"

$responseUnpakFiles = Invoke-WebRequest -Uri $hostname/unpack -Method GET -UseBasicParsing 

$splitResult = $responseUnpakFiles.Content.Split([Environment]::NewLine)

$archive = $splitResult[0].Replace("/", "")

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
                }
                else{
                    $fileTarget = $workfolder + "target.xml"
                    $copy = ([System.IO.FileInfo]$file).CopyTo($fileTarget, 1)
                   $originalBestandLocation = ([System.IO.FileInfo]$file).FullName #set again, to be sure
                }
            }

            #start transforming by invoke webrequest
            $responseRename = Invoke-WebRequest -Uri $hostname/rename -Method GET -UseBasicParsing 

            Write-Host "Hierna toe bijwerken : "$originalBestandLocation
            $updatedXml = $responseRename.Content
            $xml = New-Object "System.Xml.XmlDocument"
            $xml.LoadXml($updatedXml)
            $xml.Save($originalBestandLocation)
        } 
    }
}

$script = "tar -cvf '$archive.tar' '$archive' && rm -R '$archive'"

$shellScript = $workfolder + "pack.sh"
$script | Out-File -Force -FilePath $shellScript -Encoding utf8 -NoNewline

$responseRename = Invoke-WebRequest -Uri $hostname/pack -Method GET -UseBasicParsing 

