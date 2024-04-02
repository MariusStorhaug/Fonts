﻿function Get-Font {
    <#
        .SYNOPSIS
            Retrieves the installed fonts.

        .DESCRIPTION
            Retrieves the installed fonts.

        .EXAMPLE
            Get-Font

            Gets all the fonts installed for the current user.

        .EXAMPLE
            Get-Font -Name 'Arial*'

            Gets all the fonts installed for the current user that start with 'Arial'.

        .EXAMPLE
            Get-Font -Scope 'AllUsers'

            Gets all the fonts installed for all users.

        .EXAMPLE
            Get-Font -Name 'Calibri' -Scope 'AllUsers'

            Gets the font with the name 'Calibri' for all users.

        .OUTPUTS
            [System.Collections.Generic.List[PSCustomObject]]
    #>
    [Alias('Get-Fonts')]
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    [CmdletBinding()]
    param(
        # Specifies the name of the font to get.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $Name = '*',

        # Specifies the scope of the font(s) to get.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Scope[]] $Scope = 'CurrentUser'
    )

    begin {
        $functionName = $MyInvocation.MyCommand.Name
        Write-Verbose "[$functionName]"

        $os = if ([System.Environment]::OSVersion.Platform -eq 'Win32NT') {
            'Windows'
        } elseif ($IsLinux) {
            'Linux'
        } elseif ($IsMacOS) {
            'MacOS'
        } else {
            throw 'Unsupported OS'
        }
        $fonts = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        $scopeCount = $Scope.Count
        Write-Verbose "[$functionName] - Processing [$scopeCount] scope(s)"
        foreach ($ScopeItem in $Scope) {
            $scopeName = $ScopeItem.ToString()

            Write-Verbose "[$functionName] - [$scopeName] - Getting font(s)"
            $fontFolderPath = $script:fontFolderPathMap[$os][$scopeName]
            Write-Verbose "[$functionName] - [$scopeName] - Font folder path: [$fontFolderPath]"
            $folderExists = Test-Path -Path $fontFolderPath
            Write-Verbose "[$functionName] - [$scopeName] - Folder exists: [$folderExists]"
            if (-not $folderExists) {
                return $fonts
            }
            $installedFonts = Get-ChildItem -Path $fontFolderPath -File
            $installedFontsCount = $($installedFonts.Count)
            Write-Verbose "[$functionName] - [$scopeName] - Filtering from [$installedFontsCount] font(s)"
            $nameCount = $Name.Count
            Write-Verbose "[$functionName] - [$scopeName] - Filtering based on [$nameCount] name pattern(s)"
            foreach ($fontFilter in $Name) {
                Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Filtering font(s)"
                $filteredFonts = $installedFonts | Where-Object { $_.Name -like $fontFilter }

                foreach ($fontItem in $filteredFonts) {
                    $fontName = $fontItem.BaseName
                    $fontPath = $fontItem.FullName
                    $fontScope = $scopeName
                    Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Found [$fontName] at [$fontPath]"

                    $font = [PSCustomObject]@{
                        Name  = $fontName
                        Path  = $fontPath
                        Scope = $fontScope
                    }

                    $fonts.Add($font)
                }
                Write-Verbose "[$functionName] - [$scopeName] - [$fontFilter] - Done"
            }
            Write-Verbose "[$functionName] - [$scopeName] - Done"
        }
    }

    end {
        Write-Verbose "[$functionName] - Done"
        return $fonts
    }
}
