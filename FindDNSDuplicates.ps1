#-------- Change this to a primary DNS server ---------------
$DNSServerName = "LabDC01.test.lab.local"

#-------- Change this to the desired output path ------------
$OutputPath = "C:\temp\DNS Duplicates.csv"
#------------------------------------------------------------

$AllZones = Get-DnsServerZone -ComputerName $DNSServerName

$APTRRecords = @()
$NonUniqueRecords = @()

foreach ($Zone in $AllZones) {
    $AllRecords = $Zone | Get-DnsServerResourceRecord -ComputerName $DNSServerName | Select-Object RecordType, HostName, @{n = 'IP'; E = { $_.RecordData.IPV4Address } }, @{n = 'PTRHostName'; E = { $_.RecordData.PtrDomainName } }, Timestamp
    foreach ($Record in $AllRecords) {
        if ($Record.Hostname -ne "@" -and $Record.RecordType -eq "A") {
            if($Record.Timestamp -eq $null){
                $TimeStamp = "static"
            }else{
                $TimeStamp = $Record.Timestamp
            }


            $SaveRecord = [PSCustomObject]@{
                RecordType   = $Record.RecordType
                Hostname     = $Record.HostName + $Zone.ZoneName
                IP           = $Record.IP
                Zonename     = $Zone.ZoneName
                TimeStamp    = $TimeStamp
            }

            $APTRRecords += $SaveRecord
        }elseif ($Record.Hostname -ne "@" -and $Record.RecordType -eq "PTR"){
            if($Record.Timestamp -eq $null){
                $TimeStamp = "static"
            }else{
                $TimeStamp = $Record.Timestamp
            }

            $ZoneName = $Zone.ZoneName #ex XXX.in-addr.arpa or XXX.XXX.in-addr.arpa
            $Octets = $Record.Hostname #ex XXX.XXX or just XXX

            $FinalIP = ""
            $IPArray = $ZoneName.Replace(".in-addr.arpa", "")
            $IPArray = $Octets.Split(".") + $IPArray.split(".")
            [array]::Reverse($IPArray)

            foreach($element in $IPArray){
                $FinalIP += $element + "."
            }

            if($FinalIP.Length -gt 1){
                $FinalIP = $FinalIP.Substring(0, $FinalIP.Length-1) #remove trailing "."
            }

            $SaveRecord = [PSCustomObject]@{
                RecordType   = $Record.RecordType
                Hostname     = $Record.PTRHostName
                IP           = $FinalIP
                Zonename     = $Zone.ZoneName
                TimeStamp    = $TimeStamp
            }

            $APTRRecords += $SaveRecord
        }
    }
}


for ($i=0; $i -lt $APTRRecords.Count; $i++){
    $CurrentRecord = $APTRRecords[$i]

    $MatchFound = $false
    for($l=0; $l -lt $APTRRecords.Count; $l++){
        if($l -eq $i){
            $l++ #dont compare to the same element we are already at, jump to next one
        }

        $CompareRecord = $APTRRecords[$l]

        if(($CurrentRecord.RecordType -eq $CompareRecord.RecordType) -and ($CurrentRecord.Hostname -ne $null -and $CurrentRecord.IP -ne $null)){
            if(($CurrentRecord.Hostname -eq $CompareRecord.Hostname) -or ($CurrentRecord.IP -eq $CompareRecord.IP)){
                Write-Host Duplicate Found: $CompareRecord.Hostname equals $CurrentRecord.Hostname OR $CompareRecord.IP equals $CurrentRecord.IP

                $MatchFound = $true
                $NonUniqueRecords += $CompareRecord
                $APTRRecords[$l] = $null
            }
        }

    }

    if($MatchFound){ #add the record we were checking against the array as well
        $NonUniqueRecords += $CurrentRecord
        $APTRRecords[$i] = $null
    }
}


$NonUniqueRecords | Sort-Object RecordType, HostName, IP | Export-CSV -Path $OutputPath -NoTypeInformation -UseCulture -Encoding UTF8
