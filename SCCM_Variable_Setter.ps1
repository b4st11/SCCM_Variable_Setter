<#
/////created by b4st11 10.05.2019
/////last modified by b4st11 14.05.2019
https://github.com/b4st11/SCCM_Variable_Setter
#>

param (
    [String][Alias("Config")]$ConfigFile = "config.xml"
)
$ConfigFile = $PSScriptRoot + "\" + $ConfigFile # F.e.: c:\scripts\configDesktop.xml


[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = @'
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        Title="" Height="200" Width="350">
    <Grid Name="gridMain" Margin="0,0,0,0">
        <Image Source="logo.png" Name="imgLogo" HorizontalAlignment="Left" Height="65" Margin="188,10,0,0" VerticalAlignment="Top" Width="126"/>
        <Button Name="btnOK" Content="OK" HorizontalAlignment="Left" Margin="214,0,0,19" VerticalAlignment="Bottom" Width="100" Height="30"/>
        <Button Name="btnCancel" Content="Cancel" HorizontalAlignment="Left" Margin="23,0,0,19" VerticalAlignment="Bottom" Width="100" Height="30"/>    
    </Grid>
</Window>
'@

#some XAML Stuff
$xdNS = $XAML.DocumentElement.NamespaceURI #to avoid empty xmlns=""
[int]$nextHeight = 80 #to determine the Height of the next element

#Set Logo
try{$XAML.Window.Grid.Image.Source = $PSScriptRoot + "\logo.png"
}
catch{
    Write-Host "Could not load Logo"
    $xaml.Window.Grid.RemoveChild($XAML.SelectSingleNode('//*[local-name() = ''Image'']')) | out-null
    $XAML.Window.SetAttribute("Height",130) | out-null
    $nextHeight = 10
}

#Begin functions
function readConfigXML {
    try {
        [xml]$configXML = Get-Content -path ($script:ConfigFile)
    }catch
    {
        Write-Host "Can't read configfile. Errormessage:"
        write-host $_.Exception.Message
        exit
    }
    
    $configXML.SelectNodes('//Config/*') | ForEach-Object{
        If ($_.LocalName -eq "TextBox"){
            addTextBoxToXAML -textBoxName $_.Name -labelContent $_.Label -TextBoxContent $_.Value
        } elseif ($_.LocalName -eq "ComboBox") {
            addComboBoxToXAML -comboBoxName $_.Name -labelContent $_.Label -comboBoxContent $_.Value
        } elseif ($_.LocalName -eq "CheckBox") {
            addCheckBoxToXAML -checkBoxName $_.Name -labelContent $_.Label
        } elseif ($_.LocalName -eq "Title") {
            addTitleToXAML -Title $_.'#text'
        }

        #Needed Later to link TSVariable to Elements
        Set-Variable -Name ("_" + $_.Name) -Value ($_.TSVariable) -Scope global # To avoid same variable name from XAMl XML and Cofig XML a _ will be used
    }
}

function main() {

    Foreach ($box in $TextBoxes) {
        $TSVariable = (Get-Variable ("_" + [String](Get-Variable $box.Name | select -ExpandProperty Name))).Value
        Write-host "Name: " $box.Name " Wert: " $Form.FindName($box.Name).Text " TSVariable: " $TSVariable
        $tsenv.Value($TSVariable) = $Form.FindName($box.Name).Text
    }

    Foreach ($box in $CheckBoxes) {
        $TSVariable = (Get-Variable ("_" + [String](Get-Variable $box.Name | select -ExpandProperty Name))).Value
        Write-host "Name: " $box.Name " Wert: " $Form.FindName($box.Name).IsChecked " TSVariable: " $TSVariable
        $tsenv.Value($TSVariable) = $Form.FindName($box.Name).IsChecked
    }
    Foreach ($box in $ComboBoxes) {
        $TSVariable = (Get-Variable ("_" + [String](Get-Variable $box.Name | select -ExpandProperty Name))).Value
        Write-host "Name: " $box.Name " Wert: " $Form.FindName($box.Name).Text " TSVariable: " $TSVariable
        $tsenv.Value($TSVariable) = $Form.FindName($box.Name).Text
    }

    $form.Close()
    exit
}

function addTitleToXAML {
param(
    [String]$Title
)
    $XAML.Window.SetAttribute("Title",$Title)
}

function addComboBoxToXAML {
 param(
     [String]$comboBoxName,
     [String]$comboBoxContent,
     [String]$labelContent
 )   
    
    [int]$windowHeight = $XAML.Window.GetAttribute("Height")
    $XAML.Window.SetAttribute("Height",$windowHeight + 30)

    #Create Label
    $element = $XAML.CreateElement("Label",$xdNS)
    $element.SetAttribute("Name","lbl" + $comboBoxName)
    $element.SetAttribute("Content",$labelContent)
    $element.SetAttribute("HorizontalAlignment","Left")
    $element.SetAttribute("Margin","23,$script:nextHeight,0,0")
    $element.SetAttribute("VerticalAlignment","Top")
    $element.SetAttribute("Width","118")
    $element.SetAttribute("Height","25")
    $element.SetAttribute("FontSize","11")
    $xaml.Window.Grid.AppendChild($element) | Out-Null

    #Create Combobox
    $element = $XAML.CreateElement("ComboBox",$xdNS)
    $element.SetAttribute("Name",$comboBoxName)
    $element.SetAttribute("SelectedIndex","0")
    $element.SetAttribute("HorizontalAlignment","Left")
    $element.SetAttribute("Margin","146,$script:nextHeight,0,0")
    $element.SetAttribute("VerticalAlignment","Top")
    $element.SetAttribute("Width","168")
    $element.SetAttribute("IsSynchronizedWithCurrentItem","False")
    $element.SetAttribute("Height","25")
    $element.SetAttribute("FontSize","11")
    $xaml.Window.Grid.AppendChild($element) | Out-Null

 
    ($comboBoxContent).Split(" ") | ForEach-Object {
        $element2 = $xaml.CreateElement("ComboBoxItem",$xdNS)
        $element2.SetAttribute("Content",$_)
        $element.AppendChild($element2) | Out-Null
    }

    $script:nextHeight = $script:nextHeight + 30
}
function addTextBoxToXAML {
param(
    [String]$textBoxName,
    [String]$textBoxContent = "",
    [String]$labelContent
)   

    [int]$windowHeight = $XAML.Window.GetAttribute("Height")
    $XAML.Window.SetAttribute("Height",$windowHeight + 30)

    #Create Label
    $element = $XAML.CreateElement("Label",$xdNS)
    $element.SetAttribute("Name","lbl" + $textBoxName)
    $element.SetAttribute("Content",$labelContent)
    $element.SetAttribute("HorizontalAlignment","Left")
    $element.SetAttribute("Margin","23,$script:nextHeight,0,0")
    $element.SetAttribute("VerticalAlignment","Top")
    $element.SetAttribute("Width","118")
    $element.SetAttribute("Height","25")
    $element.SetAttribute("FontSize","11")
    $xaml.Window.Grid.AppendChild($element) | Out-Null

    #Create Textbox
    $element = $XAML.CreateElement("TextBox",$xdNS)
    $element.SetAttribute("Name",$textBoxName)
    $element.SetAttribute("Text",$textBoxContent)
    $element.SetAttribute("HorizontalAlignment","Left")
    $element.SetAttribute("Margin","146,$script:nextHeight,0,0")
    $element.SetAttribute("VerticalAlignment","Top")
    $element.SetAttribute("Width","168")
    $element.SetAttribute("TextWrapping","Wrap")
    $element.SetAttribute("Height","25")
    $element.SetAttribute("FontSize","11")
    $xaml.Window.Grid.AppendChild($element) | Out-Null

    $script:nextHeight = $script:nextHeight + 30
}
function addCheckBoxToXAML {
param(
    [String]$checkBoxName,
    [String]$labelContent
)

    [int]$windowHeight = $XAML.Window.GetAttribute("Height")
    [int]$checkBoxMarginHeight = $script:nextHeight + 5
    $XAML.Window.SetAttribute("Height",$windowHeight + 30)

    $element = $XAML.CreateElement("Label",$xdNS)
    $element.SetAttribute("Name","lbl" + $checkBoxName)
    $element.SetAttribute("Content",$labelContent)
    $element.SetAttribute("HorizontalAlignment","Left")
    $element.SetAttribute("Margin","23,$script:nextHeight,0,0")
    $element.SetAttribute("VerticalAlignment","Top")
    $element.SetAttribute("Width","118")
    $element.SetAttribute("Height","25")
    $element.SetAttribute("FontSize","11")
    $xaml.Window.Grid.AppendChild($element) | Out-Null

    $element = $XAML.CreateElement("CheckBox",$xdNS)
    $element.SetAttribute("Name",$checkBoxName)
    $element.SetAttribute("IsChecked","True")
    $element.SetAttribute("HorizontalAlignment","Left")
    $element.SetAttribute("Margin","146,$checkBoxMarginHeight,0,0")
    $element.SetAttribute("VerticalAlignment","Top")
    $element.SetAttribute("Content","")
    $xaml.Window.Grid.AppendChild($element) | Out-Null

    $script:nextHeight = $script:nextHeight + 30
}

#Get Config From config.xml
readConfigXML

#Read XAML
try{$reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $Form=[Windows.Markup.XamlReader]::Load( $reader )
}
catch{
    Write-Host "Error! Cant Create Form. Check XAML"
    exit
}

#Store Form Objects In PowerShell
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name)}
$TextBoxes = $xaml.Window.Grid.TextBox
$ComboBoxes = $XAML.Window.Grid.ComboBox
$CheckBoxes = $XAML.Window.Grid.CheckBox

#Create SCCM TS Object and copy TS Variable Values to Powershell Variables
try{
    $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
    $tsenv.GetVariables() | % { Set-Variable -Name "$_" -Value "$($tsenv.Value($_))" }
}
catch {
    Write-Host "Could not create SCCM TS Object."
    #exit
}

#Set Default Values
try{
    #Hopefully you have a Textbox called Computername
    Computername.Text = $tsenv.Value("OSDComputername")
}
catch{
    Write-Host "Can't set default Value from Textbox Computername"
}

#Create Actions for Buttons
$btnCancel.Add_Click({$form.Close(); exit})
$btnOK.Add_Click({main})

#Show Form and set it to the foreground.
$Form.TopMost = $true
$Form.ShowDialog() | out-null

