<# 
    .SYNOPSIS 
        
 
    .DESCRIPTION 
		
 
    .NOTES 
        Name: CredentialStore.psm1 
        Author: Baur Simon 
        Created: 6 Feb 2017 
        Version History 
            Version 1.0 -- 6 Feb 2017 
                -Initial Version 
#>
#region Private Functions

#endregion Private Functions

#region Public Functions

################################################################################

function NewCredentialsKey($file, $force=$false) {
	Try {
		If ((Test-Path $file) -And ($force -eq $false)){
			Write-Verbose "Key File already exists.!."
			return $true
		}
		$Key = New-Object Byte[] 16   # You can use 16, 24, or 32 for AES
		[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
		$Key | out-file $file
	} Catch {
		Write-Verbose "Failed to create $file"
		return $false
	}
	return $true
}

function GetCredentialsKey($file) {
	$key = $null
	Try {
		if (-not ($file | Test-Path)) {
			NewCredentialsKey -file $file
		}
		$key = Get-Content $file
	} Catch {
		Write-Verbose "Failed to get $file"
		return $null
	}
	return $key
}

################################################################################

function CredentialsToFile($file, $keyfile, $credentials) {
	Try {
		$User = $credentials.Username
		$Pass = $credentials.GetNetworkCredential().Password
		Add-Type -assemblyname System.DirectoryServices.AccountManagement 
		#$DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine)
		#$Result = $DS.ValidateCredentials($User, $Pass)
		#if ($Result -ne "True") {
		#	return $false
		#}
		$key = GetCredentialsKey -file $keyfile
		$credentials.Password | ConvertFrom-SecureString -key $key | Out-File $file
	} Catch {
		Write-Verbose "Failed to save Credentials to $file"
		return $false
	}
	return $true
}

function CredentialsFromFile($file, $keyfile, $username) {
	$credentials = $null
	Try {
		$key = GetCredentialsKey -file $keyfile
		if ($key -ne $null -And (Test-Path $file)) {
			$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, (Get-Content $file | ConvertTo-SecureString -Key $key)
		} else {
			return $null
		}
	} Catch {
		Write-Verbose "Failed to get Credentials from $fullPath"
		return $null
	}
	return $credentials
}

################################################################################

#function CredentialsFromPlainText($password, $username) {
#	$PasswordFile = $PSScriptRoot + "\TCPServer.pass"
#	$KeyFile = $PSScriptRoot + "\TCPServer.key"
#	$Key = Get-Content $KeyFile
#	$Key | ConvertTo-SecureString -AsPlainText -Force
#	$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile
#}

################################################################################

#endregion Public Functions

#region Aliases

#New-Alias -Name APIService -Value Altaro-APIService

#endregion Aliases

#region Export Module Members

Export-ModuleMember -Function NewCredentialsKey
Export-ModuleMember -Function GetCredentialsKey
Export-ModuleMember -Function CredentialsToFile
Export-ModuleMember -Function CredentialsFromFile
#Export-ModuleMember -Function CredentialsFromPlainText

#Export-ModuleMember -Alias APIService

#endregion Export Module Members
