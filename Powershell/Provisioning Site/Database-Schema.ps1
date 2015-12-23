<#
.Synopsis
    Azure SQL database operation.
 .DESCRIPTION
    This script is used to create object in azure sql database.
 .EXAMPLE
    Database-Schema 'ServerName', 'UserName', 'Password', 'Location', 'DatabaseEdition', 'DatabaseName'
 .INPUTS    
    1. ServerName
        Azure sql database server name for connection.
    2. UserName
        Username for sql database connection.
    3. Password
        Password for sql database connection.
    4. Location
        Location ('East US', 'West US', 'South Central US', 'North Central US', 'Central US', 'East Asia', 'West Europe', 'East US 2', 'Japan East', 'Japan West', 'Brazil South', 'North Europe', 'Southeast Asia', 'Australia East', 'Australia Southeast') for object creation
    5. DatabaseEdition
        DatabaseEdition ('Basic','Standard', 'Premium') for object creation    
    6. DatabaseName
        Azure sql database name.    

 .OUTPUTS
    Message creation of DB schema.
 .NOTES
    All parameters are mandatory.
 .COMPONENT
    The component this cmdlet belongs to Azure Sql.
 .ROLE
    The role this cmdlet belongs to the person having azure sql access.
 .FUNCTIONALITY
    The functionality that best describes this cmdlet.
#>
function Database-Schema
{
    [CmdletBinding()]
    Param
    (        
        # SQL server name for connection.
        [Parameter(Mandatory=$true)]
        [String]
        $ServerName,

        # SQL database server location
        [Parameter(Mandatory=$true, HelpMessage="Please specify location for AzureSQL server ('East US', 'West US', 'South Central US', 'North Central US', 'Central US', 'East Asia', 'West Europe', 'East US 2', 'Japan East', 'Japan West', 'Brazil South', 'North Europe', 'Southeast Asia', 'Australia East', 'Australia Southeast')?")]
        [ValidateSet('East US', 'West US', 'South Central US', 'North Central US', 'Central US', 'East Asia', 'West Europe', 'East US 2', 'Japan East', 'Japan West', 'Brazil South', 'North Europe', 'Southeast Asia', 'Australia East', 'Australia Southeast')]
        [String]
        $Location,

        # SQL database server location
        [Parameter(Mandatory=$true, HelpMessage="Please specify edition for AzureSQL database ('Basic','Standard', 'Premium')?")]
        [ValidateSet('Basic','Standard', 'Premium')]
        [String]
        $DatabaseEdition,
	
        # SQL db user name for connection.
        [Parameter(Mandatory=$true)]
        [String]
        $UserName,

        # SQL db password for connection.
        [Parameter(Mandatory=$true)]
        [String]
        $Password,
                
		# SQL Database name.
        [Parameter(Mandatory=$true)]
        [String]        
        $DatabaseName
    )
    Process
    {
		#COMMENT THIS OUT AFTER
		#Add-AzureAccount
		Switch-AzureMode AzureServiceManagement -WarningVariable null -WarningAction SilentlyContinue
		
        $dbServerExists=$true
		
		#
        # ****** Check Server exists ******
        #		
            Write-Host "### Checking whether Azure SQL Database Server $ServerName already exists. ###" -foregroundcolor "yellow"
            $existingDbServer=Get-AzureSqlDatabaseServer -ServerName $ServerName -ErrorVariable existingDbServerErrors -ErrorAction SilentlyContinue

            If($existingDbServer.ServerName -eq $ServerName) 
            {
                Write-Host "### Azure SQL Database Server: $ServerName exists. ###" -foregroundcolor "yellow"
                $dbServerExists=$true
            }
            else
            {
                Write-Host "### Existing Azure SQL Database Server: $ServerName does not exist. ###" -foregroundcolor "red"
                $dbServerExists=$false
	        }
        #
        # ****** Check Database exists ******
        #

	        Try
			{
				$azureSqlDatabaseExists = Get-AzureSqlDatabase -ServerName $ServerName -DatabaseName $DatabaseName  -ErrorVariable azureSqlDatabaseExistsErrors -ErrorAction SilentlyContinue

				if($azureSqlDatabaseExists.Count -gt 0)
				{
					Write-Host $DatabaseName " Database already exists on the server '" $ServerName "'"  -foregroundcolor "green"
				}
				elseif($azureSqlDatabaseExists.Count -eq 0)
				{
					$dbExists=$false
					$MaxDatabaseSizeGB=5
						
					Write-Host " "
					Write-Host "### Creating database ' " $DatabaseName " ' ###"
					New-AzureSqlDatabase -ServerName $ServerName -DatabaseName "$DatabaseName" -Edition "$DatabaseEdition"
					Write-Host "Success: New database $DatabaseName created" -foregroundcolor "green"
				}

				Invoke-SQLcmd -InputFile ".\Database-Schema.sql" -ServerInstance "tcp:$($ServerName).database.windows.net,1433" -Username $UserName@$ServerName -Password $Password -EncryptConnection -QueryTimeout 300 -Database WingTipTicketsProvisioningSite
					
				Write-Host "SUCCESS: Database Schema updated. " -foregroundcolor "green"		
			}
			catch
			{
				Write-Error "Error -- $Error "
				$dbExists=$false
			}
		
	}
}