#Requires -Version 7.0
Set-StrictMode -Off
<#
.SYNOPSIS
  Layout helpers for the UCKK Ops Console GUI.

.DESCRIPTION
  This file contains only visual/layout helpers.

  It must not:
    - execute business actions;
    - modify local files, Git, Moodle, or server state;
    - run SSH or shell commands;
    - write reports or logs directly;
    - contain workflow logic.

  The GUI file builds screens with these helpers.
  The Actions file connects buttons to action handlers.
#>

function Get-UckkLayoutListCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return 0
    }

    if ($Value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return 0
        }

        return 1
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $count = 0

        foreach ($key in $Value.Keys) {
            $count++
        }

        return $count
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $count = 0

        foreach ($item in $Value) {
            $count++
        }

        return $count
    }

    return 1
}

function Initialize-UckkWinForms {
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
}

function New-UckkFont {
    [CmdletBinding()]
    param(
        [int]$Size = 10,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
    )

    return [System.Drawing.Font]::new("Segoe UI", $Size, $Style)
}

function New-UckkMainForm {
    [CmdletBinding()]
    param(
        [string]$Title = "UCKK Ops Console",
        [int]$Width = 1180,
        [int]$Height = 760
    )

    $form = [System.Windows.Forms.Form]::new()
    $form.Text = $Title
    $form.Width = $Width
    $form.Height = $Height
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.MinimumSize = [System.Drawing.Size]::new(980, 640)
    $form.Font = New-UckkFont
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
    $form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)

    return $form
}

function New-UckkRootLayout {
    [CmdletBinding()]
    param()

    $root = [System.Windows.Forms.TableLayoutPanel]::new()
    $root.Dock = [System.Windows.Forms.DockStyle]::Fill
    $root.ColumnCount = 1
    $root.RowCount = 3
    $root.Padding = [System.Windows.Forms.Padding]::new(10)
    $root.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)

    [void]$root.RowStyles.Add(
        [System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 64)
    )
    [void]$root.RowStyles.Add(
        [System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 100)
    )
    [void]$root.RowStyles.Add(
        [System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 118)
    )

    return $root
}

function New-UckkHeaderPanel {
    [CmdletBinding()]
    param(
        [string]$Title = "UCKK Ops Console",
        [string]$Subtitle = "Console locale pour Local, Git, Serveur, Médiathèque et Données Moodle"
    )

    $panel = [System.Windows.Forms.Panel]::new()
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.BackColor = [System.Drawing.Color]::White
    $panel.Padding = [System.Windows.Forms.Padding]::new(14, 8, 14, 8)

    $titleLabel = [System.Windows.Forms.Label]::new()
    $titleLabel.Text = $Title
    $titleLabel.AutoSize = $true
    $titleLabel.Font = New-UckkFont -Size 16 -Style ([System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = [System.Drawing.Point]::new(10, 8)

    $subtitleLabel = [System.Windows.Forms.Label]::new()
    $subtitleLabel.Text = $Subtitle
    $subtitleLabel.AutoSize = $true
    $subtitleLabel.Font = New-UckkFont -Size 9
    $subtitleLabel.ForeColor = [System.Drawing.Color]::DimGray
    $subtitleLabel.Location = [System.Drawing.Point]::new(12, 38)

    [void]$panel.Controls.Add($titleLabel)
    [void]$panel.Controls.Add($subtitleLabel)

    return $panel
}

function New-UckkTabControl {
    [CmdletBinding()]
    param()

    $tabs = [System.Windows.Forms.TabControl]::new()
    $tabs.Dock = [System.Windows.Forms.DockStyle]::Fill
    $tabs.Font = New-UckkFont -Size 10
    $tabs.Padding = [System.Drawing.Point]::new(16, 6)

    return $tabs
}

function New-UckkTabPage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    $page = [System.Windows.Forms.TabPage]::new()
    $page.Text = $Title
    $page.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
    $page.Padding = [System.Windows.Forms.Padding]::new(10)

    return $page
}

function New-UckkTwoColumnLayout {
    [CmdletBinding()]
    param(
        [int]$LeftWidth = 360
    )

    $layout = [System.Windows.Forms.TableLayoutPanel]::new()
    $layout.Dock = [System.Windows.Forms.DockStyle]::Fill
    $layout.ColumnCount = 2
    $layout.RowCount = 1

    [void]$layout.ColumnStyles.Add(
        [System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Absolute, $LeftWidth)
    )
    [void]$layout.ColumnStyles.Add(
        [System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 100)
    )

    [void]$layout.RowStyles.Add(
        [System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 100)
    )

    return $layout
}

function New-UckkVerticalLayout {
    [CmdletBinding()]
    param(
        [int]$Padding = 8
    )

    $layout = [System.Windows.Forms.FlowLayoutPanel]::new()
    $layout.Dock = [System.Windows.Forms.DockStyle]::Fill
    $layout.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $layout.WrapContents = $false
    $layout.AutoScroll = $true
    $layout.Padding = [System.Windows.Forms.Padding]::new($Padding)
    $layout.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)

    return $layout
}

function New-UckkGroupBox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [int]$Width = 330,
        [int]$Height = 160
    )

    $box = [System.Windows.Forms.GroupBox]::new()
    $box.Text = $Title
    $box.Width = $Width
    $box.Height = $Height
    $box.Font = New-UckkFont -Size 10 -Style ([System.Drawing.FontStyle]::Bold)
    $box.Padding = [System.Windows.Forms.Padding]::new(10)
    $box.Margin = [System.Windows.Forms.Padding]::new(0, 0, 0, 10)
    $box.BackColor = [System.Drawing.Color]::White

    return $box
}

function New-UckkGroupContentPanel {
    [CmdletBinding()]
    param()

    $panel = [System.Windows.Forms.FlowLayoutPanel]::new()
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $panel.WrapContents = $false
    $panel.AutoScroll = $true
    $panel.Padding = [System.Windows.Forms.Padding]::new(6, 14, 6, 6)
    $panel.BackColor = [System.Drawing.Color]::White

    return $panel
}

function New-UckkButton {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [int]$Width = 292,
        [int]$Height = 34,

        [string]$Name = ""
    )

    $button = [System.Windows.Forms.Button]::new()
    $button.Text = $Text
    $button.Width = $Width
    $button.Height = $Height
    $button.Margin = [System.Windows.Forms.Padding]::new(4, 4, 4, 4)
    $button.Font = New-UckkFont -Size 9

    if ($Name.Trim() -ne "") {
        $button.Name = $Name
    }

    return $button
}

function New-UckkDangerButton {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [int]$Width = 292,
        [int]$Height = 34,

        [string]$Name = ""
    )

    $button = New-UckkButton -Text $Text -Width $Width -Height $Height -Name $Name
    $button.ForeColor = [System.Drawing.Color]::DarkRed
    $button.Font = New-UckkFont -Size 9 -Style ([System.Drawing.FontStyle]::Bold)

    return $button
}

function New-UckkLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [int]$Width = 300,
        [int]$Height = 24,

        [switch]$Bold
    )

    $label = [System.Windows.Forms.Label]::new()
    $label.Text = $Text
    $label.Width = $Width
    $label.Height = $Height
    $label.Margin = [System.Windows.Forms.Padding]::new(4, 4, 4, 2)
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $label.Font = if ($Bold) {
        New-UckkFont -Size 9 -Style ([System.Drawing.FontStyle]::Bold)
    } else {
        New-UckkFont -Size 9
    }

    return $label
}

function New-UckkDescriptionLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [int]$Width = 720,
        [int]$Height = 48
    )

    $label = New-UckkLabel -Text $Text -Width $Width -Height $Height

    $label.ForeColor = [System.Drawing.Color]::DimGray
    $label.AutoEllipsis = $true

    return $label
}

function New-UckkReadOnlyTextBox {
    [CmdletBinding()]
    param(
        [string]$Text = "",
        [int]$Width = 720,
        [int]$Height = 120,
        [switch]$Multiline
    )

    $box = [System.Windows.Forms.TextBox]::new()
    $box.Text = $Text
    $box.Width = $Width
    $box.Height = $Height
    $box.ReadOnly = $true
    $box.Multiline = [bool]$Multiline
    $box.ScrollBars = if ($Multiline) {
        [System.Windows.Forms.ScrollBars]::Vertical
    } else {
        [System.Windows.Forms.ScrollBars]::None
    }
    $box.Font = New-UckkFont -Size 9
    $box.BackColor = [System.Drawing.Color]::White
    $box.Margin = [System.Windows.Forms.Padding]::new(4, 4, 4, 8)

    return $box
}

function New-UckkResultPanel {
    [CmdletBinding()]
    param()

    $panel = [System.Windows.Forms.GroupBox]::new()
    $panel.Text = "Dernier résultat"
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.Font = New-UckkFont -Size 10 -Style ([System.Drawing.FontStyle]::Bold)
    $panel.Padding = [System.Windows.Forms.Padding]::new(10)
    $panel.BackColor = [System.Drawing.Color]::White

    $layout = [System.Windows.Forms.TableLayoutPanel]::new()
    $layout.Dock = [System.Windows.Forms.DockStyle]::Fill
    $layout.ColumnCount = 2
    $layout.RowCount = 4

    [void]$layout.ColumnStyles.Add(
        [System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Absolute, 120)
    )
    [void]$layout.ColumnStyles.Add(
        [System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 100)
    )

    for ($i = 0; $i -lt 4; $i++) {
        [void]$layout.RowStyles.Add(
            [System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 25)
        )
    }

    $statusTitle = New-UckkLabel -Text "Statut :" -Width 110 -Bold
    $actionTitle = New-UckkLabel -Text "Action :" -Width 110 -Bold
    $summaryTitle = New-UckkLabel -Text "Résumé :" -Width 110 -Bold
    $nextTitle = New-UckkLabel -Text "Prochaine étape :" -Width 110 -Bold

    $statusValue = New-UckkLabel -Text "Prêt" -Width 800
    $statusValue.Name = "UckkResultStatus"

    $actionValue = New-UckkLabel -Text "Aucune action lancée." -Width 800
    $actionValue.Name = "UckkResultAction"

    $summaryValue = New-UckkLabel -Text "L application est prête." -Width 800
    $summaryValue.Name = "UckkResultSummary"

    $nextValue = New-UckkLabel -Text "Choisir une action." -Width 800
    $nextValue.Name = "UckkResultNextStep"

    [void]$layout.Controls.Add($statusTitle, 0, 0)
    [void]$layout.Controls.Add($statusValue, 1, 0)
    [void]$layout.Controls.Add($actionTitle, 0, 1)
    [void]$layout.Controls.Add($actionValue, 1, 1)
    [void]$layout.Controls.Add($summaryTitle, 0, 2)
    [void]$layout.Controls.Add($summaryValue, 1, 2)
    [void]$layout.Controls.Add($nextTitle, 0, 3)
    [void]$layout.Controls.Add($nextValue, 1, 3)

    [void]$panel.Controls.Add($layout)

    return $panel
}

function Set-UckkResultPanel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.Forms.Control]$Root,

        [Parameter(Mandatory)]
        [object]$Result
    )

    $status = Find-UckkControl -Root $Root -Name "UckkResultStatus"
    $action = Find-UckkControl -Root $Root -Name "UckkResultAction"
    $summary = Find-UckkControl -Root $Root -Name "UckkResultSummary"
    $nextStep = Find-UckkControl -Root $Root -Name "UckkResultNextStep"

    if ($null -ne $status) {
        $status.Text = [string]($Result.status ?? "Prêt")
    }

    if ($null -ne $action) {
        $action.Text = [string]($Result.action ?? "Aucune action.")
    }

    if ($null -ne $summary) {
        $summary.Text = [string]($Result.summary ?? "")
    }

    if ($null -ne $nextStep) {
        $nextStep.Text = [string]($Result.nextStep ?? "")
    }
}

function Find-UckkControl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Windows.Forms.Control]$Root,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if ($Root.Name -eq $Name) {
        return $Root
    }

    foreach ($child in $Root.Controls) {
        $found = Find-UckkControl -Root $child -Name $Name
        if ($null -ne $found) {
            return $found
        }
    }

    return $null
}

function New-UckkActionGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [array]$Buttons,

        [int]$Width = 330
    )

    $height = 54 + ([Math]::Max(1, (Get-UckkLayoutListCount -Value $Buttons)) * 42)

    $group = New-UckkGroupBox -Title $Title -Width $Width -Height $height
    $content = New-UckkGroupContentPanel

    foreach ($buttonDef in $Buttons) {
        $label = [string]$buttonDef.Label
        $id = [string]$buttonDef.Id
        $danger = $false

        if ($buttonDef.PSObject.Properties.Name -contains "Danger") {
            $danger = [bool]$buttonDef.Danger
        }

        if ($danger) {
            $button = New-UckkDangerButton -Text $label -Name $id
        } else {
            $button = New-UckkButton -Text $label -Name $id
        }

        [void]$content.Controls.Add($button)
    }

    [void]$group.Controls.Add($content)

    return $group
}

function New-UckkInfoPanel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string[]]$Lines,

        [int]$Width = 720,
        [int]$Height = 160
    )

    $group = New-UckkGroupBox -Title $Title -Width $Width -Height $Height
    $content = New-UckkGroupContentPanel

    foreach ($line in $Lines) {
        [void]$content.Controls.Add(
            (New-UckkLabel -Text $line -Width ($Width - 38) -Height 22)
        )
    }

    [void]$group.Controls.Add($content)

    return $group
}

function New-UckkPathPanel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [hashtable]$Paths,

        [int]$Width = 720,
        [int]$Height = 220
    )

    $group = New-UckkGroupBox -Title $Title -Width $Width -Height $Height
    $content = New-UckkGroupContentPanel

    foreach ($key in $Paths.Keys) {
        $line = "{0}: {1}" -f $key, $Paths[$key]
        [void]$content.Controls.Add(
            (New-UckkLabel -Text $line -Width ($Width - 38) -Height 22)
        )
    }

    [void]$group.Controls.Add($content)

    return $group
}

function New-UckkFooterPanel {
    [CmdletBinding()]
    param()

    $panel = [System.Windows.Forms.Panel]::new()
    $panel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $panel.BackColor = [System.Drawing.Color]::White
    $panel.Padding = [System.Windows.Forms.Padding]::new(10)

    $label = [System.Windows.Forms.Label]::new()
    $label.Text = "UCKK Ops Console — utiliser Simulation avant Appliquer. Recovery et Legacy ne sont pas des workflows normaux."
    $label.AutoSize = $true
    $label.Font = New-UckkFont -Size 9
    $label.ForeColor = [System.Drawing.Color]::DimGray
    $label.Location = [System.Drawing.Point]::new(10, 12)

    [void]$panel.Controls.Add($label)

    return $panel
}
