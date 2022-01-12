# Installing and importing modules
Install-Module Az
Import-Module Az

Install-Module AzTable
Import-Module AzTable

Install-Module NameIT
Import-Module NameIT

# Take in parameter
do {
    write-host -nonewline "Input number of webapps you want to create: "
    $inputString = read-host
    $value = $inputString -as [Double]
    $ok = $value -ne $NULL
    if ( -not $ok ) { write-host "You must enter a numeric value" } 
}
until ( $ok )
write-host "You entered: $value"
$WebAppCount = $inputString

# Connect to Azure account
Connect-AzAccount
# The SubscriptionId in which to create these objects
$SubscriptionId = '89f84202-1813-488f-9a98-a51759b140c5'
# Set the resource group name and location for your server
$resourceGroupName = "rg-CMPE363-assignment2-Vmen"
$location = "westus3"
# Set an admin login and password for your server
$adminSqlLogin = "dumbGoksu123"
$password = "cleverGoksu123"
# Set server name - the logical server name has to be unique in the system
$serverName = "server-assin2vmen"
# The sample database name
$databaseName = "Assn2DB"
# The ip address range that you want to allow to access your server
$startIp = "0.0.0.0"
$endIp = "0.0.0.0"

# Set subscription 
Set-AzContext -SubscriptionId $subscriptionId 

# Create a resource group
$resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a server with a system wide unique server name
$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, 
    $(ConvertTo-SecureString -String $password -AsPlainText -Force))

$storageAccountName = "assin2vmen"
$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName `
  -Name $storageAccountName `
  -Location $location `
  -SkuName Standard_LRS `
  -Kind Storage

$ctx = $storageAccount.Context

# Create a blank database with an S0 performance level
$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName "S0" `
    -SampleName "AdventureWorksLT"

# Make table
$tableName = "tblEmployee"
New-AzStorageTable –Name $tableName –Context $ctx

Get-AzStorageTable –Context $ctx | select $tableName

$partitionKey1 = "partition1"

$cloudTable = (Get-AzStorageTable –Name $tableName –Context $ctx).CloudTable

# Add a row
Add-AzTableRow `
    -table $cloudTable `
    -partitionKey $partitionKey1 `
    -rowKey ("aa") -property @{"EmpName"="Murat";"EmpSurname"="Ozgur";"EmpAddress"="420 Istanbul";"EmpPhone"="1010101010"}

# Add 50 random rows
for($i = 0; $i -le 70; $i++){
  Add-AzTableRow `
    -table $cloudTable `
    -partitionKey $partitionKey1 `
    -rowKey ($i) -property @{"EmpName"=Invoke-Generate '[person both first]';"EmpSurname"=Invoke-Generate '[person both last]';
    "EmpAddress"=Invoke-Generate '[address]';"EmpPhone"=Get-Random -Minimum 1000000000 -Maximum 1999999999}
} 

# Retrieve entities from table and see that Jessie2 has been deleted.
Get-AzTableRow -table $cloudTable | ft

# Making azure webapp
$appname = "Ass2vmen"
New-AzWebApp -ResourceGroupName $resourceGroupName -Name $appname -Location $location -AppServicePlan "ContosoServicePlan"

# Assign Connection String to Connection String 
Set-AzWebApp -ConnectionStrings @{ MyConnectionString = @{ Type="SQLAzure"; 
Value ="Server=tcp:$serverName.database.windows.net;Database=MySampleDatabase;User ID=$adminSqlLogin@$serverName;Password=$password;
Trusted_Connection=False;Encrypt=True;" } } -Name $appname -ResourceGroupName $resourceGroupName

# Deleting a row in a table
[string]$filter = `
  [Microsoft.Azure.Cosmos.Table.TableQuery]::GenerateFilterCondition("EmpName",`
  [Microsoft.Azure.Cosmos.Table.QueryComparisons]::Equal,"Murat")

# Retrieve entity to be deleted, then pipe it into the remove cmdlet.
$userToDelete = Get-AzTableRow `
    -table $cloudTable `
    -customFilter $filter
$userToDelete | Remove-AzTableRow -table $cloudTable

# Retrieve entities from table and see that Jessie2 has been deleted.
Get-AzTableRow -table $cloudTable | ft

# Pushing code to github
git clone https://github.com/ahmeda02/cmpe363-assin2-vmen.git
git init
git add Assignment2-Vmen.ps1
git commit -m "Pushing script"
git branch -M main
git remote add origin https://github.com/ahmeda02/cmpe363-assin2-vmen.git
git push -u origin main

# Creating Webapps (not sure if correct idk wtf this is)
for ($i = 1; $i -le $WebAppCount; $i++) {
    $apna = "webapp-CMPE363-assignment2-Vmen-$i"
    New-AzWebApp -ResourceGroupName $resourceGroupName -Name $apna -Location $location -AppServicePlan "ContosoServicePlan"
}

