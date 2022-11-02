#-------- Change this to a primary DNS server ---------------
$DNSServerName = "LabDC01.test.lab.local"

#-------- Change this to the desired output path ------------
$OutputPath = "C:\temp\DNS Ping List.csv"
#------------------------------------------------------------

$AllZones = Get-DnsServerZone -ComputerName $DNSServerName

$Output = foreach ($Zone in $AllZones) {
    $StaticRecords = $Zone | Get-DnsServerResourceRecord -ComputerName $DNSServerName -RRType A | Where-Object Timestamp -eq $Null | Select-Object HostName, @{n = 'IP'; E = { $_.RecordData.IPV4Address } }
    foreach ($Record in $StaticRecords) {
        Write-Host Pinging $Record.Hostname ...
        if ($Record.Hostname -ne "@") {
            $FQDN = $Record.Hostname + "." + $Zone.ZoneName
        }
        else {
            $FQDN = $Zone.ZoneName
        }
        $IsResponding = Test-Connection $FQDN -Quiet -Count 1
        [pscustomobject]@{
            Hostname     = $Record.Hostname
            IP           = $Record.IP
            Zonename     = $Zone.ZoneName
            FQDN         = $FQDN
            IsResponding = $IsResponding
        }
    }
}

$Output | Sort-Object IsResponding, ZoneName, HostName | Export-CSV -Path $OutputPath -Encoding UTF8 -NoTypeInformation -UseCulture