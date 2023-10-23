function Calculate-File-Hash {
    param (
        $filepath
    )
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}
function Erase-Baseline-If-Already-Exists() {
    $baselineExists = Test-path -Path "C:\Users\Elle\Desktop\Cyber Projects\FIM Lab"
    
    if ($baselineExists){
        #Delete it
        Remove-Item -Path "C:\Users\Elle\Desktop\Cyber Projects\FIM Lab"
    }
}

write-Host ""
write-Host "What would you like to do?"
write-Host "A) Collect new Baseline?"
write-Host "B) Beging Monitoring files with saved Baseline?"
write-Host ""

$response = Read-Host -Prompt "Please eneter 'A' or 'B'"


if ($response -eq "A".ToUpper()) {
    #Delete baseline.txt if it already exist
    Erase-Baseline-If-Already-Exists

    #Calculate Hash from the target files and store in baseline.txt
    #Collect all files in the target folder
    $files = Get-childItem -Path .\Files

    #For each file, calculate the hash and write it to baseline.txt
    foreach ($f in $files){
        $hash= Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.hash)" | Out-File -FilePath .\baseline.txt -Append
    }
}

elseif ($response -eq "B".ToUpper()) {

    $fileHashDictionary = @{}

    #Load file|hash from baseline.txt and sore them in a dictionary
    $filePathsAndHashes = Get-Content -Path .\baseline.txt
   
    foreach($f in $filePatchesAndHashes){
        $fileHashDictionary[$f.Split("|")[0]] = $f.Split("|")[1]
    }

    #Begin (continously) monitoring files with saved Baseline
        while ($true){
        Start-Sleep -Seconds 1

        $files = Get-childItem -Path .\Files

        #For each file, calculate the hash and write it to baseline.txt
foreach ($f in $files){
    $hash = Calculate-File-Hash $f.FullName
    
    # Check if file exists in dictionary
    if ($fileHashDictionary.ContainsKey($hash.Path)){
        # Check if the hash matches the baseline
        if ($fileHashDictionary[$hash.Path] -ne $hash.Hash){
            # File has changed, notify user
            Write-Host "$($hash.Path) has changed!" -ForegroundColor Yellow
        }
    }
    else {
        # File is not in the baseline, so it's new
        Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
        # Add the new file to the dictionary
        $fileHashDictionary[$hash.Path] = $hash.Hash
    }
}

    # Remove files that no longer exist from the dictionary
    foreach ($key in $fileHashDictionary.Keys) {
        $baselineFileStillExists = Test-Path -Path $key
        if (-Not $baselineFileStillExists) {
            # One of the baseline files must have been deleted, notify the user
            Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed 
        }
        }
    }
}