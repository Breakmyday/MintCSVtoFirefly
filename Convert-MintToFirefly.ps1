# Gets the newest Transaction.csv file in the current users download directory. 
$MintCSV = Get-ChildItem -Path "$env:USERPROFILE\Downloads" | Where-Object {$_.Name -like "*Transactions*.csv"} | Sort-Object CreationTime -Descending | Select-Object -First 1
$csv = Import-Csv -Path $MintCSV.FullName | Select-Object -Property @{ Name = 'Date'; Expression = {(Get-Date $_.Date).ToShortDateString()}}, Description, "Original Description", Amount, "Transaction Type", Category, "Account Name", Labels, Notes

# Output file for the modified Mint csv.
$Output = "C:\Temp\firefly.csv"

$list = foreach ($item in $csv) {
    $Date     = $null
    $Debit    = $null
    $Credit   = $null

    $Date    = Get-Date $item.Date

    # If the transaction meets the below skip it. Prevents common duplicate transactions.
    if ($item.'Account Name' -eq 'PayPal Account' -or 
        $item.Category -eq "Credit Card Payment" -or 
        ($item.Category -eq "Transfer" -and $item.Description -like "*Transfer*")
    ) {continue}

    # Set value for Credit and Debit
    if ($item."Transaction Type" -eq "debit") {$Debit = $item.Amount}
    if ($item."Transaction Type" -eq "credit") {$Credit = $item.Amount}

    [PSCustomObject]@{
        "Transaction Date" = Get-date $Date -Format 'M/d/yyyy'
        Description        = $item.Description
        Category           = $item.Category
        Debit              = $Debit
        Credit             = $Credit
        Account            = ""
        Notes              = $item.'Original Description'
    }
}

# Sorts transactions by newest to oldest and exports them to the $ouput
$list | Sort-Object {$_."Transaction Date" -as [datetime]}  -Descending | Export-Csv -Path $Output -NoTypeInformation -Force