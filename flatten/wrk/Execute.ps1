Install-Module -Name ImportExcel -Force

#Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
$workfolder = "/wrk/"
$hostname = "http://flatten:8080"

$responseUnpakFiles = Invoke-WebRequest -Uri $hostname/unpack -Method GET -UseBasicParsing 

$splitResult = $responseUnpakFiles.Content.Split([Environment]::NewLine)

$totalDictionary = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.Collections.Generic.Dictionary``2[System.String,System.String]]"
$totalHeaderColumns = New-Object "System.Collections.Generic.HashSet[string]"
$totalHeaderColumns.Add("Bestandslocatie")

foreach($line in $splitResult.Where({$_.EndsWith(".metadata")}))
{
    $fileSource = $workfolder + $line
    $fileTarget = $workfolder + "target.xml"

    Copy-Item $fileSource $fileTarget 

    $responseFlatten = Invoke-WebRequest -Uri $hostname/flatten -Method GET -UseBasicParsing 
    
    $splitKeyValueLines = $responseFlatten.Content.Split([Environment]::NewLine)

    $singleMetadatadict = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.String]"

    foreach($keyValue in $splitKeyValueLines)
    {        
        #simplify current flatten output
        $split = $keyValue.Split("|").Count
        
        if($split -eq 2){

            $key = $keyValue.Split("|")[0].Trim()
            $val = $keyValue.Split("|")[1].Trim()
               
            #add to column list to track headers (unique names)
            $isSet = $totalHeaderColumns.Add($key)

            if($singleMetadatadict.ContainsKey($key)){
                $newValue = $singleMetadatadict[$key] + [Environment]::NewLine + $val
                $singleMetadatadict[$key] = $newValue
            }
            else{
                $singleMetadatadict.Add($key, $val)
            }
        }        
    }
    
    $totalDictionary.Add($line, $singleMetadatadict)
}

Write-Host "Total count :" $totalHeaderColumns.Count
#Write-Host $totalHeaderColumns
#//add column headers first
$dataTable = New-Object System.Data.DataTable("Flatten")
foreach($header in $totalHeaderColumns){    
    $column = $dataTable.Columns.Add($header)
}

Write-Host "Total dictionary :" $totalDictionary.Count #count metadata files
foreach($record in $totalDictionary.Keys){#dictionary
    $currentFile = $record
    $currentData = $totalDictionary[$record]
    
    #create new datatable row and add a record with values
    $row=$dataTable.NewRow()
    Write-Host $currentFile 
    $row["Bestandslocatie"] = $currentFile  
    foreach($item in $currentData.Keys){
        $dataHeader = $item
        $dataValue = $currentData[$item]
        $row[$dataHeader]=$currentData[$item]
    }
    $dataTable.Rows.Add($row)#add and loop next    
}

$xlfile = $workfolder+"PSreports.xlsx"
Remove-Item $xlfile -ErrorAction SilentlyContinue

$dataTable | Export-Excel $xlfile -AutoSize -TableName Flatten -WorksheetName Flatten